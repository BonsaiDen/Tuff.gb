// Dependencies ---------------------------------------------------------------
var path = require('path'),
    Promise = require('bluebird'),
    streamifier = require('streamifier'),
    lz4 = require('lz4'),
    fs = Promise.promisifyAll(require('fs')),
    PNG = require('pngjs').PNG;

require('colors');


// Palette Defintions ---------------------------------------------------------
// ----------------------------------------------------------------------------
var Palette = {

    Background: {
        '255,0,255':   255,
        '255,255,255': 0,
        '163,163,163': 1,
        '82,82,82':    2,
        '0,0,0':       3
    },

    Sprite:  {
        '255,0,255': 0,
        '255,255,255': 1, // switched based on ingame OBJ palette
        '163,163,163': 2,
        '82,82,82': 3,    // switched based on ingame OBJ palette
        '0,0,0': 3
    },

    Collision: {
        '255,0,255': 0, // no collision
        '0,0,0': 1, // blocking
        '0,255,255': 2, // water top (swimming)
        '0,0,255': 3,  // water full (diving)
        '255,0,0': 4,  // danger (environmental hazard)
        '255,255,255': 5 // saving?
    }

};


// IO Wrapper -----------------------------------------------------------------
// ----------------------------------------------------------------------------
var IO = {

    _source: null,
    _dest: null,

    setSource: function(path) {
        IO._source = path;
    },

    setDest: function(path) {
        IO._dest = path;
    },

    load: function(name) {

        var file = path.join(IO._source, name);
        if ((/\.png$/).test(file)) {
            return IO.loadImage(file);

        } else if ((/\.json$/).test(file)) {
            return IO.loadJSON(file);

        } else if ((/\.js$/).test(file)) {
            return Promise.fulfilled(require(file));
        }

    },

    save: function(name, data) {
        return fs.writeFile(path.join(IO._dest, name), new Buffer(data));
    },

    saveAs: function(ext, name, data) {
        return IO.save(name.replace(/\.[^\.]{0,4}$/, '.' + ext), data);
    },

    loadImage: function(file) {

        var deffered = Promise.pending();
        fs.createReadStream(file).pipe(new PNG({
            filterType: 4

        })).on('parsed', function() {

            if (this.height % 8 !== 0 || this.width % 8 !== 0) {
                deffered.reject(new Error('[image] Error: Image size is not a multiple of 8x8px!'));

            } else {

                console.log(
                    '[image] Loaded image with %sx%s pixels (%sx%s tiles, %s bytes as tileset)',
                    this.width,
                    this.height,
                    this.width / 8,
                    this.height / 8,
                    this.width * this.height / 4
                );

                deffered.fulfill(this);

            }

        });

        return deffered.promise;

    },

    loadJSON: function(file) {
        return fs.readFileAsync(file).then(JSON.parse);
    }

};


// Data Compression -----------------------------------------------------------
// ----------------------------------------------------------------------------
var Pack = {

    lz4: function(buffer, storeSize, other) {

        var deffered = Promise.pending(),
            stream = streamifier.createReadStream(buffer),
            output = new Buffer([]),
            encoder = lz4.createEncoderStream({
                blockIndependence: true,
                highCompression: true,
                streamSize: false,
                blockChecksum: false,
                streamChecksum: false
            });

        encoder.on('data', function(chunk) {
            output = Buffer.concat([output, chunk]);
        });

        encoder.on('end', function() {

            // Strip header and other things which are not related to the block
            output = output.slice(11);
            console.log('[lz4] %s -> %s bytes', buffer.length, output.length, other);

            if (storeSize) {
                var size = buffer.length;
                deffered.fulfill(Buffer.concat(new Buffer([(size >> 8), size & 0xff]), output));

            } else {
                deffered.fulfill(output);
            }


        });

        stream.pipe(encoder);

        return deffered.promise;

    },


    pack: function(bytes, addSizePrefix) {

        var minRun = 3,
            maxRun = 128 + minRun - 1,
            maxCopy = 128,
            maxRead = maxCopy + minRun - 1,
            count = 0,
            buffer = new Array(maxRead),
            offset = 0,
            cur = bytes[0],
            compressed = [];

        function write(value) {
            compressed.push((value + 256) % 256);
        }

        function writeBuffer(length, offset) {
            for(var i = offset || 0; i < length; i++) {
                compressed.push(buffer[i]);
            }
        }

        while(cur !== undefined) {

            buffer[count] = cur;
            count++;

            if (count >= minRun) {

                // check for run
                for(var i = 2; i <= minRun; i++) {
                    if (cur !== buffer[count - i]) {
                        // no run
                        i = 0;
                        break;
                    }
                }

                if (i !== 0) {

                    // we have a run, write out buffer before run
                    if (count > minRun) {
                        write(count - minRun - 1);
                        writeBuffer(count - minRun);
                    }

                    // determine run length
                    count = minRun;

                    var next;
                    while((next = bytes[++offset]) === cur) {
                        count++;
                        if (maxRun === count) {
                            break;
                        }
                    }

                    // write out encoded run length and run symbol
                    write((minRun - 1) - count);
                    write(cur);

                    if (next !== undefined && count !== maxRun) {
                        buffer[0] = next;
                        count = 1;

                    } else {
                        // file or max run ends in a run
                        count = 0;
                    }

                }

            }

            if (maxRead === count) {

                // write out buffer
                write(maxCopy - 1);
                writeBuffer(maxCopy);

                // start new buffer
                count = maxRead - maxCopy;

                // copy excess front of buffer
                for(var e = 0; e < count; e++) {
                    buffer[e] = buffer[maxCopy + e];
                }

            }

            cur = bytes[++offset];

        }

        // Write out last buffer
        if (count !== 0) {

            if (count <= maxCopy) {
                write(count - 1);
                writeBuffer(count);

            } else {

                // we read more than the maximum of a single copy buffer
                write(maxCopy - 1);
                writeBuffer(maxCopy);

                // Write out remainder
                count -= maxCopy;

                write(count - 1);
                writeBuffer(count, maxCopy);

            }

        }

        if (addSizePrefix !== false) {
            var size = bytes.length;
            return [(size >> 8), size & 0xff].concat(compressed);

        } else {
            return compressed;
        }

    }

};


// Data Parsing and Conversion ------------------------------------------------
// ----------------------------------------------------------------------------
var Parse = {

    /** Convert a image into 8x8 tiles in Gameboy Format. */
    tilesFromImage: function(palette, r8x16, img) {

        var bytes = [];
        for(var y = 0; y < img.height / 8; y++) {
            for(var x = 0; x < img.width / 8; x++) {
                bytes.push.apply(bytes, Parse.tileFromImageBlock(img, palette, x, y));
            }
        }


        // This will re-order the tiles so that it's easier to use them for
        // sprites when using 8x16 sprites on the GameBoy
        if (r8x16) {
            bytes = Parse.toTileOrder16(bytes, img.width / 8, img.height / 8);
        }

        return bytes;

    },

    /** Encode a image of 16x16px tiles into a mapping of rows along with a index header. */
    rowMapFromImage: function(palette, columns, img) {

        var rowOffsets = [],
            rowBytes = [];

        // Split img into rows
        var bytesPerRow = 16 * 16 * 4 * columns; // 16x16 pixel, 4 channels (RGBA)
        for(var y = 0; y < img.height / 16; y++) {

            var subImage = {
                width: img.width,
                height: 16,
                data: img.data.slice(y * bytesPerRow, y * bytesPerRow + bytesPerRow)
            };

            var tileBytes = Parse.tilesFromImage(palette, true, subImage);
            rowOffsets.push((rowBytes.length >> 8), rowBytes.length & 0xff);
            rowBytes.push.apply(rowBytes, Pack.pack(tileBytes, false));

        }

        return rowOffsets.concat(rowBytes);

    },

    /** Convert a 8x8 image block into the Gameboy Tile Format. */
    tileFromImageBlock: function(img, palette, blockX, blockY) {

       var bytes = [];
       for(var py = 0; py < 8; py++) {

            var high = 0,
                low = 0;

            for(var px = 0; px < 8; px++) {

                var i = ((img.width * (blockY * 8 + py)) + blockX * 8 + px) << 2,
                    r = img.data[i],
                    g = img.data[i + 1],
                    b = img.data[i + 2];

                var p = r + ',' + g + ',' + b;
                if (palette.hasOwnProperty(p)) {

                    var v = palette[p];
                    if (v === 0) { // White
                        v = 0;

                    } else if (v === 1) { // light grey
                        low |= 1 << 7 - px;

                    } else if (v === 2) { // dark grey
                        high |= 1 << 7 - px;

                    } else if (v === 3) { // dark
                        high |= 1 << 7 - px;
                        low |= 1 << 7 - px;
                    }

                } else {
                    throw new TypeError('Color ' + p + ' at ' + blockX + 'x' + blockY + ' was not found in palette.');
                }

            }

            bytes.push(low, high);

        }

        return bytes;

    },

    /** Hash 8x8 image blocks and generate a hash -> index mapping as well as a index[hash] mapping. */
    hashImageBlocks: function(palette, unique, img) {

        var wx = img.width / 8,
            wy = img.height / 8,
            map = {
                width: wx,
                height: wy,
                index: [],
                offset: {}
            };

        for(var y = 0; y < wy; y++) {
            for(var x = 0; x < wx; x++) {

                var key = '', indexKey = '';
                for(var py = 0; py < 8; py++) {
                    for(var px = 0; px < 8; px++) {

                        var i = ((img.width * (y * 8 + py)) + x * 8 + px) << 2,
                            c = img.data[i] + ',' + img.data[i + 1] + ',' + img.data[i + 2];

                        if (palette.hasOwnProperty(c)) {
                            key += palette[c];
                            indexKey += palette[c] === 255 ? 0 : palette[c];

                        } else {
                            throw new TypeError('Color ' + c + ' at ' + x + 'x' + y + ' (' + x * 8 + 'px, ' + y * 8 + 'px) was not found in palette.');
                        }

                    }

                }

                // If the map has no mapping for the specific hash add it
                // otherwise ignore it and only keep the first occurance of the tile (thus ignoring duplicates, useful when mapping meta tiles to raw tiles).
                // UNLESS: unique === false in which case we want to map all blocks no matter where the occur (useful when mapping blocks to tile indices)
                if (!map.offset.hasOwnProperty(key) || !unique) {
                    map.offset[key] = wx * y + x;
                    map.index.push(indexKey);
                }

            }
        }

        return map;

    },

    /**
      * Re-order a array of parsed gameboy tiles for easier usage with 8x16 gameboy sprites.
      *
      * Meaning that the tile placement:
      *
      *     0 1 | 2 3
      *     4 5 | 6 7
      *
      * will become:
      *
      *     0 4 1 5 | 2 6 3 7
      *
      * Which means that it's easy to represent two 8x16 sprites as below as one 16x16 block in the source image.
      *
      *     A B  === 0 1
      *     A B  === 4 5
      *
      * Since hardware tiles on the GameBoy in 8x16 mode will use every even sprite + the one immediately following it.
      *
      */
    toTileOrder16: function(bytes, columns, rows) {

        var tiles = [],
            arranged = [];

        // 1 tile = 16 bytes
        for(var i = 0, l = bytes.length / 16; i < l; i++) {
            tiles.push(bytes.splice(0, 16));
        }

        // For every other row
        for(var y = 0; y < rows; y += 2) {

            // and every column in that row
            for(var x = 0; x < columns; x++) {

                var o = y * columns + x;

                // add the tile itself
                arranged.push.apply(arranged, tiles[o]);

                // plus the tile on the row exactly below it
                arranged.push.apply(arranged, tiles[o + columns]);

            }

        }

        return arranged;

    },

    /** Decompose image with 16x16 tiles into a mapping of four 8x8 tiles per 16x16 block. */
    blockDefsFromImage: function(palette, blocks, tiles) {

        var offsets = [[], [], [], []],
            tileMap = Parse.hashImageBlocks(palette, true, tiles),
            blockMap = Parse.hashImageBlocks(palette, false, blocks),
            blockIndex = 0;

        for(var y = 0; y < blockMap.height; y += 2) {
            for(var x = 0; x < blockMap.width; x += 2) {

                var i = blockMap.width * y + x,
                    bytes = [
                        i,
                        i + 1,
                        i + blockMap.width,
                        i + blockMap.width + 1
                    ];

                bytes = bytes.map(function(i) {

                    var t = tileMap.offset[blockMap.index[i]];
                    if (t === undefined) {

                        var y = ~~(i / blockMap.width),
                            bx = i - y * blockMap.width,
                            px = (i - y * blockMap.width) * 8;

                        throw new TypeError('Invalid tile data in block image ' + bx + 'x' + y + ' (' + px + 'px, ' + y * 8 + 'px) was not found in source tiles!');

                    }


                    return t;

                });

                offsets[0].push(bytes[0]);
                offsets[1].push(bytes[1]);
                offsets[2].push(bytes[2]);
                offsets[3].push(bytes[3]);

                blockIndex++;

            }
        }

        // Merge the offset arrays into one big array (removing and sub level arrays)
        return [].concat.apply([], offsets);

    }


};


// High Level Conversion ------------------------------------------------------
// ----------------------------------------------------------------------------
var Convert = {

    TileRowMap: function(file) {

        console.log('[tilerowmap] Converting tilerowmap "%s"...', file);

        return IO.load(file).then(function(img) {
            return Parse.rowMapFromImage(Palette.Sprite, 4, img);

        }).then(function(data) {
            return IO.saveAs('bin', file, data);

        }).then().then(function() {
            console.log('[tilerowmap] Done!');

        }).error(function(err) {
            console.error(('[tilerowmap] Error: ' + err).red);
        });

    },

    Tileset: function(file, r8x16) {

        console.log('[tileset] Converting tileset "%s"...', file);

        var palette = (/\.bg\.png$/).test(file) ? Palette.Background : Palette.Sprite;
        return IO.load(file).then(function(img) {
            return Parse.tilesFromImage(palette, r8x16, img);

        }).then(function(bytes) {
            return Pack.lz4(new Buffer(bytes));

        }).then(function(data) {
            return IO.saveAs('bin', file, data);

        }).then(function() {
            console.log('[tileset] Done!');

        }).error(function(err) {
            console.error(('[tileset] Error: ' + err).red);
        });

    },

    BlockDef: function(file, tileset) {

        console.log('[blocks] Parsing 16x16 block defs "%s" using tileset "%s"...', file, tileset);

        return Promise.props({
            blocks: IO.load(file),
            tiles: IO.load(tileset)

        }).then(function(result) {
            return Parse.blockDefsFromImage(Palette.Background, result.blocks, result.tiles);

        }).then(function(data) {
            return IO.saveAs('bin', file, data);

        }).then(function() {
            console.log('[blocks] Done!');

        }).error(function(err) {
            console.error(('[blocks] Error: ' + err).red);
        });

    },

    Map: function(file) {

        console.log('[map] Converting tiles JSON Map "%s"...', file);
        return IO.load(file).then(function(map) {

            // tiled index starts at i
            var data = map.layers[0].data.map(function(i) {
                    return ((i - 1) + 256) % 256;
                }),
                entityData = map.layers[1].data,
                mapBytes = [],
                roomOffsets = [],
                w = map.width,
                h = map.height,
                rx = w / 10,
                ry = h / 8;

            // Generate rooms
            for(var y = 0; y < ry; y++) {
                for(var x = 0; x < rx; x++) {

                    var tileBytes = [],
                        entityBytes = [];

                    for(var i = 0; i < 8; i++) {
                        var offset = ((y * 8 + i) * w) + x * 10;
                        tileBytes.push.apply(tileBytes, data.slice(offset, offset + 10));
                        entityBytes.push.apply(entityBytes, entityData.slice(offset, offset + 10));
                    }


                    // Push the data offset into the room index
                    roomOffsets.push((mapBytes.length >> 8), mapBytes.length & 0xff);

                    // Find Entities
                    var entities = [
                            0, 0,
                            0, 0,
                            0, 0,
                            0, 0
                        ],
                        entityIndex = -1;

                    entityBytes.map(function(value, index) {

                        if (value > 256) {

                            if (entityIndex === 7) {
                                throw new TypeError('More than 4 entities in map room ' + x + 'x' + y);
                            }

                            var ey = Math.floor(index / 10),
                                ex = index - ey * 10,
                                type = value - 256,
                                direction = 0;

                            entities[++entityIndex] = (type & 0x3f) | ((direction & 0x03) << 6);
                            entities[++entityIndex] = ((ey & 0x0f) << 4) | (ex & 0x0f);

                        } else if (value < 256 && value > 0) {
                            throw new TypeError('Invalid entity ' + value + ' in map room ' + x + 'x' + y);
                        }

                    });

                    tileBytes.push.apply(tileBytes, entities);

                    // Pack the room data and append it to the map data
                    mapBytes.push.apply(mapBytes, Pack.pack(tileBytes, false));

                }
            }

            return roomOffsets.concat(mapBytes);

        }).then(function(data) {
            return IO.saveAs('bin', file, data);

        }).then(function() {
            console.log('[map] Done!');

        }).error(function(err) {
            console.error(('[map] Error: ' + err).red);
        });

    },

    Collision: function(file) {

        console.log('[col] Converting tile collision data "%s"...', file);

        return IO.load(file).then(function(img) {
            return Parse.hashImageBlocks(Palette.Collision, false, img).index.map(function(key) {
                return +key.substring(0, 1);
            });

        }).then(function(data) {
            return IO.saveAs('bin', file, data);

        }).then(function() {
            console.log('[col] Done!');

        }).error(function(err) {
            console.error(('[col] Error: ' + err).red);
        });

    },

    Sounds: function(file) {

        return IO.load(file).then(function(sounds) {

            var result = {
                data: '',
                defs: ''
            };

            sounds.forEach(function(s, index) {

                var bytes = [
                    (s.priority << 2) | (s.envStepDir === 0 ? 1 : 2), // rising envelope means loop
                    0,
                    s.channel
                ];

                if (s.channel === 1) {

                    // convert sound length into frames
                    bytes[1] = s.looping ? 0 : Math.ceil((64 - s.soundLength) * (1 / 256) / (1 / 60));

                    // TODO support 0 lengths along with

                    // FF10
                    bytes.push(
                        ((s.sweepTime << 4) & 112) +
                        ((s.sweepDir << 3) & 8) +
                        (s.sweepShifts & 7)
                    );

                    // FF11
                    bytes.push(
                        ((s.dutyCycle << 6) & 192) +
                        (s.soundLength & 63)
                    );

                    // FF12 envelop
                    bytes.push(
                        ((s.envInitVol << 4) & 240) +
                        ((s.envStepDir << 3) & 8) +
                        (s.envStepTime & 7)
                    );

                    // FF 13 low frequency
                    bytes.push(s.frequency & 0xff);

                    // FF 14
                    bytes.push(
                        128 | 64 | ((s.frequency >> 8) & 0x07)
                    );

                } else if (s.channel === 4) {

                    // convert sound length into frames
                    if (s.soundLength) {
                        bytes[1] = s.looping ? 0 : Math.ceil((64 - s.soundLength) * (1 / 256) / (1 / 60));

                    // calculate frame length from envelope
                    } else if (!s.looping) {
                        // TODO support rising envelopes
                        // Length of each decrease step
                        // after this many seconds the volume will drop by one
                        var stepLength = s.envStepTime * (1 / 64);
                        // number of seconds it takes to reduce the sound to zero converted to frames
                        bytes[1] = Math.ceil((stepLength * s.envInitVol) / (1 / 60));

                    } else {
                        bytes[1] = 0;
                    }

                    // FF20 sound length
                    bytes.push(s.soundLength & 63);

                    // FF21 envelop
                    bytes.push(
                        ((s.envInitVol << 4) & 240) +
                        ((s.envStepDir << 3) & 8) +
                        (s.envStepTime & 7)
                    );

                    // FF22 polynomial counter
                    bytes.push(
                        ((s.shiftFreq << 4) & 240) +
                        ((s.polyStep << 3) & 8) +
                        (s.freqRatio & 7)
                    );

                    // FF23
                    bytes.push(128 | (s.soundLength > 0 ? 64 : 0));

                    // padding
                    bytes.push(255);

                }

                result.data += '    ; ' + s.id + '\n    DB ' + bytes.map(function(b) {
                    var s = b.toString('16');
                    return '$' + (s.length === 1 ? '0' + s : s);

                }).join(',') + '\n\n';

                result.defs += 'SOUND_' + s.id + ' EQU ' + (index + 1) + '\n';

            });

            return result;

        }).then(function(data) {
            return Promise.all([
                IO.saveAs('data.rsm', file, data.data),
                IO.saveAs('def.rsm', file, data.defs)
            ]);

        }).then(function() {
            console.log('[snd] Done!');

        }).error(function(err) {
            console.error(('[snd] Error: ' + err).red);
        });

    }

};

// Reverse Convert the Tile Defs from the binary and the tilesheet ------------
var Reverse = {

    TileDef: function() {

        // Convert the binary block definitions back into png image
        // This is useful for when editing the tileset graphics directly
        // Since you'd need to update all blocks in the block def png by hand
        return fs.readFileAsync('data/bin/blocks.def.bin').then(function(buffer) {

            var grid = Reverse.makeArray(32, 32),
                offsets = [],
                blocks = new Array(buffer.length);

            for(var i = 0, l = buffer.length; i < l; i++) {
                blocks[i] = buffer[i];
            }

            while(blocks.length) {
                offsets.push(blocks.splice(0, 256));
            }

            var width = 16,
                height = 16;

            for(var y = 0; y < height; y++) {
                for(var x = 0; x < width; x++) {

                    var index = width * y + x,
                        tiles = [
                            offsets[0][index],
                            offsets[1][index],
                            offsets[2][index],
                            offsets[3][index]
                        ];

                    grid[y * 2][x * 2] = tiles[0];
                    grid[y * 2 + 1][x * 2] = tiles[2];
                    grid[y * 2][x * 2 + 1] = tiles[1];
                    grid[y * 2 + 1][x * 2 + 1] = tiles[3];

                }
            }

            return Reverse.createImage(grid);

        });

    },

    makeArray: function(width, height) {

        var array = [];
        for(var y = 0; y < height; y++) {

            var sub = [];
            for(var x = 0; x < width; x++) {
                sub.push(0);
            }

            array.push(sub);

        }

        return array;

    },

    tileFromImageBlock: function(img, blockX, blockY) {

       var rows = [];
       for(var py = 0; py < 8; py++) {

            var line = [];
            for(var px = 0; px < 8; px++) {

                var i = ((img.width * (blockY * 8 + py)) + blockX * 8 + px) << 2,
                    r = img.data[i],
                    g = img.data[i + 1],
                    b = img.data[i + 2];

                line.push(r, g, b, 255);

            }

            rows.push(line);

        }

        return rows;

    },

    loadImage: function(file) {

        var deffered = Promise.pending();
        fs.createReadStream(file).pipe(new PNG({
            filterType: 4

        })).on('parsed', function() {

            if (this.height % 8 !== 0 || this.width % 8 !== 0) {
                deffered.reject(new Error('[image] Error: Image size is not a multiple of 8x8px!'));

            } else {

                console.log(
                    '[image] Loaded image with %sx%s pixels (%sx%s tiles, %s bytes as tileset)',
                    this.width,
                    this.height,
                    this.width / 8,
                    this.height / 8,
                    this.width * this.height / 4
                );

                deffered.fulfill(this);

            }

        });

        return deffered.promise;

    },

    createImage: function(grid) {

        var name = 'tiles.bg.png',
            out = 'blocks.def.png';

        return Reverse.loadImage(path.join(IO._source, name)).then(function(img) {

            var tiles = [],
                x, y;

            for(y = 0; y < img.height / 8; y++) {
                for(x = 0; x < img.width / 8; x++) {
                    tiles.push(Reverse.tileFromImageBlock(img, x, y));
                }
            }

            var raw = [];

            console.log(raw.length, tiles.length);

            for(y = 0; y < 32 * 8; y++) {
                for(x = 0; x < 32; x++) {
                    var t = tiles[grid[~~(y / 8)][x]];
                    raw.push.apply(raw, t[y % 8]);
                }
            }

            console.log(raw.length);

            var image = new PNG({
                width: 32 * 8,
                height: 32 * 8
            });

            image.data = raw;

            var output = new Buffer([]);
            image.on('data', function(chunk) {
                output = Buffer.concat([output, chunk]);
            });

            image.on('end', function() {
                fs.writeFile(path.join(IO._source, out), output);
            });

            image.pack();

            return null;

        });

    }

};


// Setup Paths ----------------------------------------------------------------
IO.setSource(path.join(process.cwd(), process.argv[2]));
IO.setDest(path.join(process.cwd(), process.argv[3]));


// Convert --------------------------------------------------------------------
if (process.argv[4] === '-reverse') {
    Reverse.TileDef();

} else {

    Promise.all([
        Convert.Tileset('tiles.bg.png'),
        Convert.TileRowMap('player.ch.png'),
        Convert.TileRowMap('entities.ch.png'),
        Convert.Collision('tiles.col.png'),
        Convert.Sounds('sounds.js'),
        Convert.BlockDef('blocks.def.png', 'tiles.bg.png').then(function() {
            return Convert.Map('main.map.json');
        })

    ]).then(function() {
        console.log('Complete!');

    }).error(function(err) {
        console.error(err.toString().red);
        process.exit(1);
    });

}

