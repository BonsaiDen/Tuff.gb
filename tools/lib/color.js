// RGB to GBC 12bit color conversion ------------------------------------------
var Color = {

    // Convert a RGB color into its closest approximated 15 bit color value
    rgbToGameboy: function(r, g, b) {
        var approx = Color.approximateColor(r, g, b);
        return Color.getBGRBytes.apply(null, approx);
    },

    // Convert a RGB color into a 15 bit GameBoy Color
    rgbToBGR: function(r, g, b) {

        var r1 = Math.floor(r / 8) & 31,
            g1 = Math.floor(g / 8) & 31,
            b1 = Math.floor(b / 8) & 31;

        return (b1 << 10) | (g1 << 5) | r1;

    },

    // Convert a 15 bit GameBoy Color back into full RGB
    bgrToRGB: function(i) {

        var r2 = i       & 0x1F,
            g2 = i >>  5 & 0x1F,
            b2 = i >> 10 & 0x1F,
            r3 = ((r2 * 13 + g2 * 2 + b2) >> 1) ,
            g3 = (g2 * 3 + b2) << 1,
            b3 = (r2 * 3 + g2 * 2 + b2 * 11) >> 1;

        return [r3, g3, b3];

    },

    getBGRBytes: function(r, g, b) {

        var i = Color.rgbToBGR(r, g, b);
        return [i & 0xff, i >> 8].map(function(i) {
            return '$' + i.toString(16);

        }).join(', ');

    },

    getBGRDiff: function(r, g, b, tr, tg, tb) {

        var i = Color.rgbToBGR(r, g, b),
            out = Color.bgrToRGB(i);

        return (Math.abs(out[0] - tr) + Math.abs(out[1] - tg) + Math.abs(out[2] - tb));

    },

    // Base on a RGB input color it will return the closest matching RGB color
    // that can be displayed on the Gameboy Color
    approximateColor: function (tr, tg, tb) {

        var maxDiff = 256,
            fr = 0,
            fg = 0,
            fb = 0;

        function search(rs, re, gs, ge, bs, be, res) {

            for(var r = rs; r < re; r += res) {
                for(var g = gs; g < ge; g += res) {
                    for(var b = bs; b < be; b += res) {

                        var d = Color.getBGRDiff(r, g, b, tr, tg, tb);
                        if (d < maxDiff) {
                            fr = r;
                            fg = g;
                            fb = b;
                            maxDiff = d;
                        }

                    }
                }
            }

        }

        var lastDiff = 0,
            res = 4,
            rs = 0,
            re = 256,
            gs = 0,
            ge = 256,
            bs = 0,
            be = 256;

        while(res >= 1) {

            lastDiff = maxDiff;
            search(rs, re, gs, ge, bs, be, res);

            rs = Math.max(fr - (maxDiff ), 0);
            re = Math.min(fr + (maxDiff ), 256);

            gs = Math.max(fg - (maxDiff ), 0);
            ge = Math.min(fg + (maxDiff ), 256);

            bs = Math.max(fb - (maxDiff ), 0);
            be = Math.min(fb + (maxDiff ), 256);

            res /= 2;

        }

        //console.log(tr, tg, tb, '-> diff', maxDiff, '->', fr, fg, fb, 'in', Date.now() - start, 'ms');
        return [fr, fg, fb];

    }

};

// Exports --------------------------------------------------------------------
module.exports = Color;

