// Tuff GameBoy palette defintions --------------------------------------------
module.exports = {

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
        '255,0,0': 4,  // hazard lava
        '255,128,0': 6,  // hazard spikes
        '255,255,0': 7,  // hazard electric
        '0,255,0': 5 // breakable
    }

};

