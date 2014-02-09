// Dependencies ---------------------------------------------------------------
var path = require('path'),
    Promise = require('bluebird'),
    fs = require('fs'),
    PNG = require('pngjs').PNG;

require('colors');


// Gameboy Data Conversion ----------------------------------------------------
// ----------------------------------------------------------------------------
var gb = {

    rleMapValue: 249,

    base: path.join(process.cwd(), process.argv[2]),
    bin: path.join(process.cwd(), process.argv[3]),

    palette: {

        bg: {
            '255,0,255': 255,
            '255,255,255': 0,
            '163,163,163': 1,
            '82,82,82': 2,
            '0,0,0': 3
        },

        chars: {
            '255,0,255': 0,
            '255,255,255': 1, // switched based on char palette
            '82,82,82': 1,    // switched based on char palette
            '163,163,163': 2,
            '0,0,0': 3
        },

        col: {
            '255,0,255': 0, // no collision
            '0,0,0': 1, // blocking
            '0,255,255': 2, // water top (swimming)
            '0,0,255': 3,  // water full (diving)
            '255,0,0': 4,  // danger (environmental hazard)
            '255,255,255': 5 // saving?
        }

    },

    processImg: function(img, palette, r8x16) {

        var bytes = [];
        for(var y = 0; y < img.height / 8; y++) {
            for(var x = 0; x < img.width / 8; x++) {
                var r = gb.processTile(img, palette, x, y);
                if (r instanceof Array) {
                    bytes.push.apply(bytes, r);

                } else {
                    return r;
                }
            }
        }


        if (r8x16) {
            bytes = gb.rearrangeTiles16(bytes, img.width / 8, img.height / 8);
        }

        return bytes;

    },

    processTile: function(img, palette, blockX, blockY) {

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
                    return Promise.rejected('Color ' + p + ' at ' + blockX + 'x' + blockY + ' was not found in pallete.');
                }

            }

            bytes.push(low, high);

        }

        return bytes;

    },

    convert: {

        TileRowMap: function(file) {

            console.log('[tilerowmap] Converting tilerowmap "%s"...', file);

            var palette = gb.palette.chars;
            return gb.loadFile(file).then(function(img) {

                var rowOffsets = [],
                    rowBytes = [];

                // Split img into rows
                var bytesPerRow = 16 * 16 * 4 * 8;
                for(var y = 0; y < img.height / 16; y++) {

                    var sub = {
                        width: img.width,
                        height: 16,
                        data: img.data.slice(y * bytesPerRow, y * bytesPerRow + bytesPerRow)
                    };

                    var bytes = gb.processImg(sub, palette, true);
                    if (bytes instanceof Array) {
                        rowOffsets.push((rowBytes.length >> 8), rowBytes.length & 0xff);
                        rowBytes.push.apply(rowBytes, gb.pack(bytes));

                    } else {
                        return bytes;
                    }

                }

                return Promise.fulfilled(rowOffsets.concat(rowBytes));

            }).then(function(data) {
                file = file.replace(/\.png$/, '.bin');
                console.log('[tilerowmap] Saving tilerowmap "%s" (%s bytes RLE packed)...', file, data.length);
                return gb.saveFile(file, data);

            }).then(function() {
                console.log('[tilerowmap] Done!');

            }, function(err) {
                console.error(('[tilerowmap] Error: ' + err).red);
            });

        },

        Tileset: function(file, r8x16) {

            console.log('[tileset] Converting tileset "%s"...', file);

            var palette = gb.palette.chars;
            if ((/\.bg\.png$/).test(file)) {
                console.info('[tileset] Using background palette');
                palette = gb.palette.bg;

            } else {
                console.info('[tileset] Using character palette');
            }

            return gb.loadFile(file).then(function(img) {
                var bytes = gb.processImg(img, palette, r8x16);
                if (bytes instanceof Array) {
                    return Promise.fulfilled(gb.pack(bytes));

                } else {
                    return bytes;
                }

            }).then(function(data) {
                file = file.replace(/\.png$/, '.bin');
                console.log('[tileset] Saving tileset "%s" (%s bytes RLE packed)...', file, data.length);
                return gb.saveFile(file, data);

            }).then(function() {
                console.log('[tileset] Done!');

            }, function(err) {
                console.error(('[tileset] Error: ' + err).red);
            });

        },

        BlockDef: function(file, tileset) {

            console.log('[blocks] Parsing 16x16 block defs "%s" using tileset "%s"...', file, tileset);

            return Promise.props({
                blocks: gb.loadFile(file),
                tiles: gb.loadFile(tileset)

            }).then(function(result) {

                var offsets = [
                        [],
                        [],
                        [],
                        []
                    ],
                    tileMap = gb.hashTile8(result.tiles, gb.palette.bg, true),
                    blockMap = gb.hashTile8(result.blocks, gb.palette.bg, false),
                    blockIndex = 0;

                if (blockMap instanceof Promise) {
                    return blockMap;

                } else if (tileMap instanceof Promise) {
                    return tileMap;
                }

                for(var y = 0; y < blockMap.height; y += 2) {
                    for(var x = 0; x < blockMap.width; x += 2) {

                        var i = blockMap.width * y + x,
                            bytes = [
                                i,
                                i + 1,
                                i + blockMap.width,
                                i + blockMap.width + 1
                            ];

                        try {
                            bytes = bytes.map(function(i) {

                                var t = tileMap.offset[blockMap.index[i]];
                                if (t === undefined) {

                                    var y = ~~(i / blockMap.width),
                                        bx = i - y * blockMap.width,
                                        px = (i - y * blockMap.width) * 8;

                                    throw Promise.rejected(
                                        'Invalid tile data in block image ' + bx + 'x' + y + ' (' + px + 'px, ' + y * 8 + 'px) was not found in source tiles!'
                                    );

                                } else {
                                    return t;
                                }

                            });

                        } catch(e) {
                            return e;
                        }

                        offsets[0].push(bytes[0]);
                        offsets[1].push(bytes[1]);
                        offsets[2].push(bytes[2]);
                        offsets[3].push(bytes[3]);

                        blockIndex++;

                    }
                }

                return Promise.fulfilled([].concat.apply([], offsets));

            }).then(function(data) {
                file = file.replace(/\.png$/, '.bin');
                console.log('[blocks] Saving block definition "%s" (%s bytes per offset row)...', file, data.length / 4);
                return gb.saveFile(file ,data);

            }).then(function() {
                console.log('[blocks] Done!');

            }, function(err) {
                console.error(('[blocks] Error: ' + err).red);
            });

        },

        Map: function(file) {

            console.log('[map] Converting tiles JSON Map "%s"...', file);
            return gb.loadFile(file).then(function(map) {

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
                                    return Promise.rejected('More than 4 entities in map room ' + x + 'x' + y);
                                }

                                var ey = Math.floor(index / 10),
                                    ex = index - ey * 10,
                                    type = value - 256,
                                    direction = 0;

                                entities[++entityIndex] = (type & 0x3f) | ((direction & 0x03) << 6);
                                entities[++entityIndex] = ((ey & 0x0f) << 4) | (ex & 0x0f);

                            } else if (value < 256){
                                return Promise.rejected('Invalid entity ' + value + ' in map room ' + x + 'x' + y);
                            }

                        });

                        tileBytes.push.apply(tileBytes, entities);

                        // Pack the room data and append it to the map data
                        mapBytes.push.apply(mapBytes, gb.pack(tileBytes, false));

                    }
                }

                return Promise.fulfilled(roomOffsets.concat(mapBytes));

            }).then(function(data) {
                file = file.replace(/\.json$/, '.bin');
                console.log('[map] Saving packed data "%s" (%s bytes)...', file, data.length);
                return gb.saveFile(file ,data);

            }).then(function() {
                console.log('[map] Done!');

            }, function(err) {
                console.error(('[map] Error: ' + err).red);
            });

        },

        Collision: function(file) {

            console.log('[col] Converting tile collision data "%s"...', file);
            return gb.loadFile(file).then(function(tiles) {

                var colMap = gb.hashTile8(tiles, gb.palette.col);
                var data = colMap.index.map(function(key) {
                    return +key.substring(0, 1);
                });

                return Promise.fulfilled(data);

            }).then(function(data) {
                file = file.replace(/\.png$/, '.bin');
                console.log('[col] Saving tile collision data "%s" (%s bytes)...', file, data.length);
                return gb.saveFile(file ,data);

            }).then(function() {
                console.log('[col] Done!');

            }, function(err) {
                console.error(('[col] Error: ' + err).red);
            });

        }

    },


    // Helpers ----------------------------------------------------------------
    rearrangeTiles16: function(bytes, columns, rows) {

        // Re-arrange the data for simple use with 8x16 LCD sprites
        //
        // Meaning that the tile placement:
        // 0 1 | 2 3
        // 4 5 | 6 7
        //
        // will become:
        // 0 4 1 5 | 2 6 3 7

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


    hashTile8: function(img, palette, unique) {

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
                            return Promise.rejected('Color ' + c + ' at ' + x + 'x' + y + ' (' + x * 8 + 'px, ' + y * 8 + 'px) was not found in palette.');
                        }

                    }

                }

                if (!map.offset.hasOwnProperty(key) || !unique) {
                    map.offset[key] = wx * y + x;
                    map.index.push(indexKey);
                }

            }
        }

        return map;

    },

    loadFile: function(name) {

        var d = Promise.pending(),
            file = path.join(gb.base, name);

        if ((/\.png$/).test(file)) {
            fs.createReadStream(file).pipe(new PNG({
                filterType: 4

            })).on('parsed', function() {

                if (this.height % 8 !== 0 || this.width % 8 !== 0) {
                    console.error('[image] Error: Image size is not a multiple of 8x8px!');
                    process.exit(1);

                } else {
                    console.log(
                        '[image] Loaded image with %sx%s pixels (%sx%s tiles, %s bytes as tileset)',
                        this.width,
                        this.height,
                        this.width / 8,
                        this.height / 8,
                        this.width * this.height / 4
                    );

                    d.fulfill(this);

                }

            });

        } else if ((/\.json$/).test(file)) {
            fs.readFile(file, function(err, data) {
                if (err) {
                    d.reject(err);

                } else {
                    d.fulfill(JSON.parse(data));
                }
            });
        }

        return d.promise;

    },

    saveFile: function(name, data) {

        var d = Promise.pending(),
            file = path.join(gb.bin, name);

        var buf = new Buffer(data);
        fs.writeFile(file, buf, {
            encoding: 'binary'

        }, function(err) {
            err ? d.reject(err) : d.fulfill();
        });

        return d.promise;

    },

    pack: function(bytes, prefixSize) {

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

        if (gb.unpack(compressed).join(',') !== bytes.join(',')) {
            console.log(compressed, bytes);
            throw new Error('Data did not correctly decompress!!!');
            //console.log('PACKED ', compressed.length, 'of', bytes.length, 100 / bytes.length * compressed.length);
        }

        if (prefixSize !== false) {
            var size = bytes.length;
            return [(size >> 8), size & 0xff].concat(compressed);

        } else {
            return compressed;
        }

    },

    // Only here for verifying that the packed uncompressed correctly
    unpack: function(compressed) {

        var bytes = [],
            offset = 0,
            count = 0,
            //minRun = 3,
            cur = 0;

        while((count = compressed[offset++]) !== undefined) {

            if (count > 127) {

                //count = (minRun - 1) - (count - 256);
                count = 255 - (count - 3);

                if ((cur = compressed[offset++]) === undefined) {
                    count = 0;
                    throw new Error('Run block is too short');
                }

                while(count > 0) {
                    bytes.push(cur);
                    count--;
                }

            } else {

                count++;

                while(count > 0) {

                    if ((cur = compressed[offset++]) !== undefined) {
                        bytes.push(cur);

                    } else {
                        throw new Error('Copy block is too short');
                    }

                    count--;

                }

            }

        }

        return bytes;

    }

};


gb.convert.Tileset('tiles.bg.png').then(function() {

    gb.convert.Tileset('tiles.ch.png', true).then(function() {

        gb.convert.BlockDef('blocks.def.png', 'tiles.bg.png').then(function() {

            gb.convert.Map('main.map.json').then(function() {
                gb.convert.TileRowMap('tiles.ch.png', true);
                gb.convert.Collision('tiles.col.png');
                gb.convert.TileRowMap('entities.ch.png');

            }, function() {
                process.exit(1);
            });

        }, function() {
            process.exit(1);
        });

    }, function() {
        process.exit(1);
    });

}, function() {
    process.exit(1);
});

