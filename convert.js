// Dependencies ---------------------------------------------------------------
var path = require('path'),
    Promise = require('bluebird'),
    fs = require('fs'),
    PNG = require('pngjs').PNG;


// Gameboy Data Conversion ----------------------------------------------------
// ----------------------------------------------------------------------------
var gb = {

    rleMapValue: 249,

    base: path.join(process.cwd(), process.argv[2]),

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
            '255,255,255': 1,
            '163,163,163': 2,
            '0,0,0': 3
        },

        col: {
            '255,0,255': 0, // no collision
            '0,0,0': 1, // blocking
            '0,255,255': 2, // water top (swimming)
            '0,0,255': 3,  // water full (diving)
            '255,0,0': 4,  // danger (killing)
            '255,255,255': 5 // saving?
        }

    },

    convert: {

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

                var bytes = [];
                for(var y = 0; y < img.height / 8; y++) {
                    for(var x = 0; x < img.width / 8; x++) {

                        for(var py = 0; py < 8; py++) {

                            var high = 0,
                                low = 0;

                            for(var px = 0; px < 8; px++) {

                                var i = ((img.width * (y * 8 + py)) + x * 8 + px) << 2,
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
                                    return Promise.rejected('Color %s at %sx%s was not found in pallete:', p, x, y);
                                }

                            }

                            bytes.push(low, high);

                        }

                    }
                }

                if (r8x16) {
                    bytes = gb.rearrangeTiles16(bytes, img.width / 8, img.height / 8);
                }

                return Promise.fulfilled(bytes);

            }).then(function(data) {
                file = file.replace(/\.png$/, '.bin');
                console.log('[tileset] Saving tileset "%s"...', file);
                return gb.saveFile(file, data);

            }).then(function() {
                console.log('[tileset] Done!');

            }, function(err) {
                console.error('[tileset] Error:', err);
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
                console.error('[blocks] Error:', err);
            });

        },

        Map: function(file) {

            console.log('[map] Converting tiles JSON Map "%s"...', file);
            return gb.loadFile(file).then(function(map) {

                // tiled index starts at i
                var data = map.layers[0].data.map(function(i) {
                        return i - 1;
                    }),
                    rleBytes = [],
                    rleOffsets = [],
                    w = map.width,
                    h = map.height,
                    rx = w / 10,
                    ry = h / 8;

                // Generate rooms
                for(var y = 0; y < ry; y++) {
                    for(var x = 0; x < rx; x++) {

                        var roomBytes = [];
                        for(var i = 0; i < 8; i++) {

                            var offset = ((y * 8 + i) * w) + x * 10,
                                rowBytes = data.slice(offset, offset + 10);

                            roomBytes.push.apply(roomBytes, rowBytes);

                        }

                        // Push the data offset into the room index
                        rleOffsets.push((rleBytes.length >> 8), rleBytes.length & 0xff);

                        // RLE encode the room data
                        rleBytes.push.apply(
                            rleBytes,
                            gb.rleEncode(gb.rleMapValue, roomBytes, 3, (255 - gb.rleMapValue + 3))
                        );

                    }
                }

                var compressed = rleOffsets.concat(rleBytes);
                return Promise.fulfilled(compressed);

            }).then(function(data) {
                file = file.replace(/\.json$/, '.bin');
                console.log('[map] Saving rle encoded map data "%s" (%s bytes)...', file, data.length);
                return gb.saveFile(file ,data);

            }).then(function() {
                console.log('[map] Done!');

            }, function(err) {
                console.error('[map] Error:', err);
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
                console.error('[col] Error:', err);
            });

        }

    },


    // Helpers ----------------------------------------------------------------
    rleEncode: function(magicByte, data, minLength, maxLength) {

        var compressed = [];

        for(var i = 0; i < data.length; i++) {

            var matching = 0;
            for(var e = i; e < data.length; e++) {
                if (data[e] === data[i] && matching < maxLength) {
                    matching++;

                } else {
                    break;
                }
            }

            if (matching >= minLength) {

                compressed.push(magicByte + (matching - minLength), data[i]);
                i += matching;

            }

            // don't forget the tile which didn't match!
            compressed.push(data[i]);

        }

        return compressed;

    },

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
            file = path.join(gb.base, name);

        var buf = new Buffer(data);
        fs.writeFile(file, buf, {
            encoding: 'binary'

        }, function(err) {
            err ? d.reject(err) : d.fulfill();
        });

        return d.promise;

    }

};

gb.convert.Tileset('tiles.bg.png').then(function() {
    gb.convert.Tileset('tiles.ch.png', true).then(function() {

        gb.convert.BlockDef('blocks.def.png', 'tiles.bg.png').then(function() {

            gb.convert.Map('main.map.json').then(function() {
                gb.convert.Collision('tiles.col.png');

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

