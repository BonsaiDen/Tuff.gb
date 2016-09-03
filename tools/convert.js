// Dependencies ---------------------------------------------------------------
var path = require('path'),
    Promise = require('bluebird'),
    lib = require('./lib');


// Setup Data Paths -----------------------------------------------------------
lib.IO.setSource(path.join(process.cwd(), process.argv[2]));
lib.IO.setDest(path.join(process.cwd(), process.argv[3]));


// Convert Tuff Data Files ----------------------------------------------------
Promise.all([
    lib.Tileset('tiles.bg.png'),
    lib.TiledImage('logoTree.bg.png'),
    lib.Tileset('title.bg.png'),
    lib.Tileset('animation.bg.png'),
    lib.TileRowMap('player.ch.png'),
    lib.EffectRowMap('effect.ch.png'),
    lib.TileRowMap('entities.ch.png'),
    lib.Tileset('title.ch.png', true),
    lib.Collision('tiles.col.png'),
    lib.Sounds('sounds.js'),
    lib.BlockDef('blocks.def.png', 'tiles.bg.png').then(function(defs) {
        return lib.Map('scroll.map.json', defs, 0xf0, 16, 12);
    })

]).then(function() {
    console.log('Complete!');

}).error(function(err) {
    console.error(err.toString().red);
    process.exit(1);
});

