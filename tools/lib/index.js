/*jshint evil: true*/

// Dependencies ---------------------------------------------------------------
var Promise = require('bluebird'),
    Palette = require('./palette'),
    Sound = require('./sound'),
    IO = require('./io'),
    Tile = require('./tile'),
    LZ4 = require('./lz4'),
    Map = require('./map');


// High Level Conversion Methods ----------------------------------------------
module.exports = {

    IO: IO,

    TileRowMap: function(file) {

        console.log('[tilerowmap] Converting tilerowmap "%s"...', file);

        return IO.load(file).then(function(img) {
            return Tile.rowMapFromImage(Palette.Sprite, 4, img, file);

        }).then(function(data) {
            return IO.saveAs('bin', file, data);

        }).then(function() {
            console.log('[tilerowmap] Done!');

        }).error(function(err) {
            console.error(('[tilerowmap] Error: ' + err).red);
        });

    },

    EffectRowMap: function(file) {

        console.log('[tilerowmap] Converting effectrowmap "%s"...', file);

        return IO.load(file).then(function(img) {
            return Tile.effectRowMapFromImage(Palette.Sprite, 4, img, file);

        }).then(function(data) {
            return IO.saveAs('bin', file, data);

        }).then(function() {
            console.log('[tilerowmap] Done!');

        }).error(function(err) {
            console.error(('[tilerowmap] Error: ' + err).red);
        });

    },


    Tileset: function(file, r8x16) {

        console.log('[tileset] Converting tileset "%s"...', file);

        var palette = (/\.bg\.png$/).test(file) ? Palette.Background : Palette.Sprite;
        return IO.load(file).then(function(img) {
            return Tile.tilesFromImage(palette, r8x16, img);

        }).then(function(bytes) {
            return LZ4.encode(bytes, true);

        }).then(function(data) {
            return IO.saveAs('bin', file, data);

        }).then(function() {
            console.log('[tileset] Done!');

        }).error(function(err) {
            console.error(('[tileset] Error: ' + err).red);
        });

    },

    TiledImage: function(file) {

        console.log('[tiledimage] Converting tiled image "%s"...', file);

        var palette = (/\.bg\.png$/).test(file) ? Palette.Background : Palette.Sprite;

        return IO.load(file).then(function(img) {

            var tiles = [],
                tileCount = 0,
                index = {},
                blocks = [];

            for(var y = 0; y < img.height / 8; y++) {
                for(var x = 0; x < img.width / 8; x++) {

                    var tile = Tile.tileFromImageBlock(img, palette, x, y),
                        hash = tile.join(',');

                    if (!index.hasOwnProperty(hash)) {
                        index[hash] = tileCount++;
                        tiles.push.apply(tiles, tile);
                    }

                    blocks.push(index[hash] - 128);

                }
            }

            return Promise.all([
                LZ4.encode(tiles, true),
                LZ4.encode(blocks, true)
            ]);

        }).then(function(bytes) {
            return bytes[0].concat(bytes[1]);

        }).then(function(data) {
            return IO.saveAs('bin', file, data);

        }).then(function() {
            console.log('[tiledimage] Done!');

        }).error(function(err) {
            console.error(('[tiledimage] Error: ' + err).red);
        });

    },

    BlockDef: function(file, tileset) {

        console.log('[blocks] Parsing 16x16 block defs "%s" using tileset "%s"...', file, tileset);

        var defs = null;
        return Promise.props({
            blocks: IO.load(file),
            tiles: IO.load(tileset)

        }).then(function(result) {
            return Tile.blockDefsFromImage(Palette.Background, result.blocks, result.tiles);

        }).then(function(data) {
            defs = data;
            return IO.saveAs('bin', file, data);

        }).then(function() {
            console.log('[blocks] Done!');
            return defs.map(function(e) {
                return e + 128;
            });

        }).error(function(err) {
            console.error(('[blocks] Error: ' + err).red);
        });

    },

    BlockMap: function(file, tileset) {

        console.log('[blocks] Parsing 16x16 block map "%s" using tileset "%s"...', file, tileset);

        return Promise.props({
            blocks: IO.load(file),
            tiles: IO.load(tileset)

        }).then(function(result) {
            return Tile.blockDefsFromImage(Palette.Background, result.blocks, result.tiles, true);

        }).error(function(err) {
            console.error(('[blocks] Error: ' + err).red);
        });

    },

    Map: function(file, blockDefinitions, animationOffset) {

        console.log('[map] Converting tiles JSON Map "%s"...', file);
        return IO.load(file).then(function(map) {

            // tiled index starts at i
            var data = map.layers[0].data.map(function(i) {
                    return i - 1;
                    //return ((i - 1) + 256) % 256;
                }),
                entityData = map.layers[1].data,
                effectData = map.layers[2].data,
                mapBytes = [],
                roomOffsets = [],
                w = map.width,
                h = map.height,
                rx = w / 10,
                ry = h / 8;

            // Generate rooms
            for(var y = 0; y < ry; y++) {
                for(var x = 0; x < rx; x++) {
                    Map.parseRoom(
                        data, entityData, effectData,
                        x, y, w, h,
                        roomOffsets, mapBytes,
                        blockDefinitions, animationOffset
                    );
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
            return Tile.hashImageBlocks(Palette.Collision, false, img).index.map(function(key) {
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

        console.log('[snd] Converting sound effect definitions data "%s"...', file);

        return IO.load(file).then(function(effectList) {
            return Sound.fromEffectList(effectList);

        }).then(function(library) {
            return library.serialize();

        }).then(function(data) {
            return IO.saveAs('gb.s', file, data);

        }).then(function() {
            console.log('[snd] Done!');

        }).error(function(err) {
            console.error(('[snd] Error: ' + err).red);
        });

    },

    rgbToBGR: function(r, g, b) {

        var r1 = Math.floor(r / 8) & 31,
            g1 = Math.floor(g / 8) & 31,
            b1 = Math.floor(b / 8) & 31;

        var i = (b1 << 10) | (g1 << 5) | r1;


        //var r2 = i       & 0x1F,
        //    g2 = i >>  5 & 0x1F,
        //    b2 = i >> 10 & 0x1F;
            //r3 = ((r2 * 13 + g2 * 2 + b2) >> 1) ,
            //g3 = (g2 * 3 + b2) << 1,
            //b3 = (r2 * 3 + g2 * 2 + b2 * 11) >> 1;

        return [i & 0xff, i >> 8].map(function(i) {
            return '$' + i.toString(16);

        }).join(', ');

    }

};

