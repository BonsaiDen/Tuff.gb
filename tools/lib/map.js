// Dependencies ---------------------------------------------------------------
var lz4 = require('./lz4');


// Tiled Map parsing ----------------------------------------------------------
var Map = {

    parseRoom: function(
        data, entityData, effectData,
        x, y, w, h,
        roomOffsets, mapBytes, blockDefinitions, animationOffset
    ) {

        var tileBytes = [],
            entityBytes = [],
            effectBytes = [],
            entities,
            effects,
            animations,
            tiles,
            header = 0,
            i;

        for(i = 0; i < 8; i++) {
            var offset = ((y * 8 + i) * w) + x * 10;
            tileBytes.push.apply(tileBytes, data.slice(offset, offset + 10));
            entityBytes.push.apply(entityBytes, entityData.slice(offset, offset + 10));
            effectBytes.push.apply(effectBytes, effectData.slice(offset, offset + 10));
        }

        // Record mapped tile blocks
        var tileBlocks = [false, false, false, false, false, false, false];
        tileBytes.forEach(function(t) {
            tileBlocks[Math.floor(t / 64)] = true;
        });

        var tileBlocksUsed = tileBlocks.filter(function(t) {
            return t === true;

        }).length;

        if (tileBlocksUsed > 4) {
            throw new TypeError('Room ' + x + 'x' + y + ' uses more than the maximum of 4 mapped tile blocks.');
        }

        // Setup block mapping
        var tileBlockMapping = [],
            blockMappingByte = 0;

        for(i = 0; i < 8; i++) {
            if (tileBlocks[i]) {
                tileBlockMapping.push(i);
                blockMappingByte |= (1 << i);
            }
        }

        entities = Map.parseEntities(entityBytes, x, y);
        effects = Map.parseEffects(effectBytes, x, y);
        animations = Map.parseAnimations(tileBytes, blockDefinitions, animationOffset);

        // Convert tile bytes into mapping space of current screen
        var customTileMapping = [1, 3, 7, 15].indexOf(blockMappingByte) === -1;
        tileBytes = tileBytes.map(function(t) {
            var originBlock = Math.floor(t / 64),
                targetBlock = tileBlockMapping.indexOf(originBlock);

            return (t - originBlock * 64) + targetBlock * 64;
        });

        // Compress tile data
        tiles = lz4.encode(tileBytes, false);

        var roomBytes = [];
        if (animations.used) {
            header |= 1; // 0000_000x
        }

        if (customTileMapping) {
            header |= 2; // 0000_00x0
        }

        if (effects.used) {
            header |= (effects.count << 2); // 000x_xx00
        }

        if (entities.used) {
            header |= (entities.count << 5); // xxx0_0000
        }

        // Write Room Header Byte
        roomBytes.push(header);

        // Write Animation Attribute Byte
        if (animations.used) {
            roomBytes.push(parseInt(animations.data.join(''), 2));
        }

        if (customTileMapping) {
            roomBytes.push(blockMappingByte);
        }

        // Write Effect Bytes
        if (effects.used) {
            roomBytes.push.apply(roomBytes, effects.data.slice(0, effects.count * 2));
        }

        // Write Entity Bytes
        if (entities.used) {
            roomBytes.push.apply(roomBytes, entities.data.slice(0, entities.count * 2));
        }

        roomBytes.push.apply(roomBytes, tiles);
        mapBytes.push(roomBytes.length);
        mapBytes.push.apply(mapBytes, roomBytes);

    },

    parseAnimations: function(tileBytes, blockDefinitions, animationOffset) {

        // Check which animations are used on this screen
        var animations = [
                0, 0, 0, 0, 0, 0, 0, 0
            ],
            animationCount = 0;

        tileBytes.forEach(function(b) {
            blockDefinitions.slice(b * 4, b * 4 + 4).forEach(function(t) {

                if (t >= animationOffset) {
                    t -= animationOffset;
                    t /= 2;
                    animationCount++;
                    animations[7 - Math.floor(t)] = 1;
                }

            });

        });

        return {
            data: animations,
            used: animationCount !== 0
        };

    },

    parseEntities: function(entityBytes, x, y) {

        // Find Entities
        var entities = [
                0, 0,
                0, 0,
                0, 0,
                0, 0
            ],
            entityIndex = -1,
            entityCount = 0;

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
                entityCount++;

            } else if (value < 256 && value > 0) {
                throw new TypeError('Invalid entity ' + value + ' in map room ' + x + 'x' + y);
            }

        });

        return {
            data: entities,
            count: entityCount,
            used: entityIndex !== -1
        };

    },

    parseEffects: function(effectBytes, x, y) {

        // Find Effects
        var effects = [
                0, 0,
                0, 0,
                0, 0,
                0, 0
            ],
            effectIndex = -1,
            effectCount = 0;

        effectBytes.map(function(value, index) {

            if (value > 352) {

                if (effectIndex === 7) {
                    throw new TypeError('More than 4 effects in map room ' + x + 'x' + y);
                }

                var ey = Math.floor(index / 10),
                    ex = index - ey * 10,
                    type = value - 352,
                    // 8x8 offsets
                    xOffset = 0,
                    yOffset = 0;

                effects[++effectIndex] = (type & 0x3f) | (yOffset << 6) | (xOffset << 7);
                effects[++effectIndex] = ((ey & 0x0f) << 4) | (ex & 0x0f);
                effectCount++;

            } else if (value < 352 && value > 0) {
                throw new TypeError('Invalid effect ' + value + ' in map room ' + x + 'x' + y);
            }

        });

        return {
            data: effects,
            count: effectCount,
            used: effectIndex !== -1
        };

    }

};


// Exports --------------------------------------------------------------------
module.exports = Map;

