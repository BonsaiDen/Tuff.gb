// Dependencies ---------------------------------------------------------------
var lz4 = require('./lz4');


// Tile Data Parsing and Conversion -------------------------------------------
var Tiles = {

    /** Convert a image into 8x8 tiles in Gameboy Format. */
    tilesFromImage: function(palette, r8x16, img) {

        var bytes = [];
        for(var y = 0; y < img.height / 8; y++) {
            for(var x = 0; x < img.width / 8; x++) {
                bytes.push.apply(bytes, Tiles.tileFromImageBlock(img, palette, x, y));
            }
        }


        // This will re-order the tiles so that it's easier to use them for
        // sprites when using 8x16 sprites on the GameBoy
        if (r8x16) {
            bytes = Tiles.toTileOrder16(bytes, img.width / 8, img.height / 8);
        }

        return bytes;

    },

    /** Encode a image of 16x16px tiles into a mapping of rows along with a index header. */
    rowMapFromImage: function(palette, columns, img) {

        var rowOffsets = [],
            rowBytes = [];

        // Split img into rows
        var bytesPerRow = 16 * 16 * 4 * columns, // 16x16 pixel, 4 channels (RGBA)
            rowCount = img.height / 16;

        for(var y = 0; y < rowCount; y++) {

            var subImage = {
                width: img.width,
                height: 16,
                data: img.data.slice(y * bytesPerRow, y * bytesPerRow + bytesPerRow)
            };

            var tileBytes = Tiles.tilesFromImage(palette, true, subImage),
                rowOffset = ((rowCount * 2) - ((y + 1) * 2)) + rowBytes.length;

            rowOffsets.push((rowOffset >> 8), rowOffset & 0xff);
            rowBytes.push.apply(rowBytes, lz4.encode(tileBytes, true));

        }

        return rowOffsets.concat(rowBytes);

    },

    /** Encode a image of 8x16px tiles into a mapping of rows along with a index header. */
    effectRowMapFromImage: function(palette, columns, img) {

        var rowOffsets = [],
            rowBytes = [];

        // Split img into rows
        var bytesPerRow = 8 * 16 * 4 * columns, // 8x16 pixel, 4 channels (RGBA)
            rowCount = img.height / 16;

        for(var y = 0; y < rowCount; y++) {

            var subImage = {
                width: img.width,
                height: 16,
                data: img.data.slice(y * bytesPerRow, y * bytesPerRow + bytesPerRow)
            };

            var tileBytes = Tiles.tilesFromImage(palette, true, subImage),
                rowOffset = ((rowCount * 2) - ((y + 1) * 2)) + rowBytes.length;

            rowOffsets.push((rowOffset >> 8), rowOffset & 0xff);
            rowBytes.push.apply(rowBytes, lz4.encode(tileBytes, true));

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
    blockDefsFromImage: function(palette, blocks, tiles, map) {

        var offsets = [[], [], [], []],
            tileMap = Tiles.hashImageBlocks(palette, true, tiles),
            blockMap = Tiles.hashImageBlocks(palette, false, blocks),
            mapped = {},
            mappedReverse = {},
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

                if (map) {
                    if (!mappedReverse.hasOwnProperty(bytes.join(','))) {
                        mappedReverse[bytes.join(',')] = blockIndex;
                    }
                    mapped[blockIndex] = bytes.join(',');
                }

                // save as direct indeces into the vram map
                // this saves 16 cycles per tile load
                offsets[0].push(bytes[0] - 128);
                offsets[1].push(bytes[1] - 128);
                offsets[2].push(bytes[2] - 128);
                offsets[3].push(bytes[3] - 128);

                blockIndex++;

            }
        }

        if (map) {
            return {
                map: mapped,
                reverse: mappedReverse
            };

        } else {

            var merged = [],
                l = offsets[0].length;

            for(var e = 0; e < l; e++) {
                merged.push(
                    offsets[0][e],
                    offsets[1][e],
                    offsets[2][e],
                    offsets[3][e]
                );
            }

            return merged;

        }

    }


};


// Exports --------------------------------------------------------------------
module.exports = Tiles;

