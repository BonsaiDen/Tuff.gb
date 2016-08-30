// Sound Effect Library Parsing and Serialization -----------------------------
function Library() {
    this.effects = [];
    this.songs = [];
    this.patterns = [];
    this.instruments = [];
    this.samples = [];
}

// Statics --------------------------------------------------------------------
Library.fromEffectList = function(effectList) {

    var library = new Library();

    effectList.forEach(function(entry) {

        var note = 0;
        if (entry.frequency) {
            note = findNearestNoteForFrequency(entry.frequency);
        }

        var instrument = {
            name: entry.id,
            channel: entry.channel - 1,
            envelope: (entry.envInitVol || 0),
            envelopeStep: (entry.envStepDir ? entry.envStepTime : -entry.envStepTime) || 0,
            length: (entry.endless ? (entry.channel === 3 ? 256 : 64) : entry.soundLength) || 0,
            dutyCycle: entry.dutyCycle || 0,
            sweepTime: entry.sweepTime || 0,
            sweepShift: (entry.sweepDir ? entry.sweepShifts : -entry.sweepShifts) || 0,
            dividingRatioFrequency: entry.freqRatio || 0,
            polynomialCounterShift: entry.shiftFreq || 0,
            polynomialCounterStep: entry.polyStep || 0,
            outputLevel: entry.outputLevel || 0,
            sample: library.samples.length
        };

        if (entry.sample) {
            library.samples.push(entry.sample);
        }

        var pattern = {
            name: entry.id,
            length: 1,
            rows: [
                [note, library.instruments.length]
            ]
        };

        library.instruments.push(instrument);

        library.effects.push({
            name: entry.id, // Auto calculate from specified sound length later on
            tempo: 15, // ~250ms at 60fps
            pattern: library.patterns.length,
            loop: !!entry.looping
        });

        library.patterns.push(pattern);

    });

    return library;

};


// Serialization Template -----------------------------------------------------
var template = [
    '; Songs -----------------------------------------------------------------------',
    'SoundSongs:',
    '',
    '; Sound Effects ---------------------------------------------------------------',
    '{{effects}}',
    '',
    'SoundEffectTable:',
    '{{effectTable}}',
    '',
    '; Instruments -----------------------------------------------------------------',
    'SoundInstrumentTable:',
    '{{instruments}}',
    '',
    '; Patterns --------------------------------------------------------------------',
    'SoundPatternTable:',
    '{{patternTable}}',
    '',
    '{{patterns}}',
    '',
    '; Samples ---------------------------------------------------------------------',
    'SoundSampleTable:',
    '',
    '{{samples}}'

].join('\n');


// Methods --------------------------------------------------------------------
Library.prototype = {

    serialize: function() {

        // Samples
        var samples = deduplicate(this.samples.map(function(s) {
            return serializeSample(s);
        }));

        // Serialize instruments
        var instruments = deduplicate(this.instruments.map(function(i) {
            return serializeInstrument(i, samples);
        }));

        // Serialize Patterns
        var patterns = deduplicate(this.patterns.map(function(p) {
            return serializePattern(p, instruments);
        }));

        // Effects
        var effects = this.effects.map(function(p) {
            return serializeEffect(p, patterns);
        });


        // Instrument Templates
        template = template.replace('{{instruments}}', instruments.filter(function(i) {
            return i[2];

        }).map(function(i, index) {
            return 'sound_instrument_' + i[0] + '_' + index + ':\n  DB ' + i.slice(4) + '\n';

        }).join('\n'));


        // Pattern Templates
        template = template.replace('{{patternTable}}', patterns.filter(function(p) {
            return p[2];

        }).map(function(p, index) {
            return '  DW sound_pattern_' + p[0] + '_' + index;

        }).join('\n'));

        template = template.replace('{{patterns}}', patterns.filter(function(p) {
            return p[2];

        }).map(function(p, index) {
            return 'sound_pattern_' + p[0] + '_' + index + ':\n' + p[4].map(function(row) {
                return '  DB ' + row.join(', ');

            }).join('\n') + '\n  DB $FF\n';

        }).join('\n'));


        // Effect Templates
        var effectNames = effects.map(function(e) {
            return ('sound_effect_' + e[0]).toUpperCase();
        });

        var maxLength = Math.ceil(Math.max.apply(Math, effectNames.map(function(name) {
            return name.length;

        })) / 4) * 4;

        template = template.replace('{{effects}}', effectNames.map(function(e, index) {
            return e + new Array(maxLength - e.length + 1).join(' ') + '    EQU ' + index;

        }).join('\n'));

        template = template.replace('{{effectTable}}', effects.map(function(e) {
            return '  DB ' + e[1] + ', ' + e[2];

        }).join('\n'));

        template = template.replace('{{samples}}', samples.filter(function(s) {
            return s[2];

        }).map(function(s, index) {
            return 'sound_sample_' + index + ':\n' + chunk(chunk(s[4], 2).map(function(row) {
                return (row[0] << 4) | row[1];

            }), 8).map(function(row) {
                return '  DB ' + row.join(', ');

            }).join('\n') + '\n';

        }).join('\n'));

        return template;

    }

};


// Exports --------------------------------------------------------------------
module.exports = Library;


// Frequency Helpers ----------------------------------------------------------
var Frequencies = [
    0x002c, 0x009c, 0x0106, 0x016b, 0x01c9, 0x0223, 0x0277, 0x02c6, 0x0312, 0x0356, 0x039b, 0x03da,
    0x0416, 0x044e, 0x0483, 0x04b5, 0x04e5, 0x0511, 0x053b, 0x0563, 0x0589, 0x05ac, 0x05ce, 0x05ed,
    0x0600, 0x0627, 0x0642, 0x065b, 0x0672, 0x0689, 0x069e, 0x06b2, 0x06c4, 0x06d6, 0x06e7, 0x06f7,
    0x0706, 0x0714, 0x0721, 0x072d, 0x0739, 0x0744, 0x074f, 0x0759, 0x0762, 0x076b, 0x0773, 0x077b,
    0x0783, 0x078a, 0x0790, 0x0797, 0x079d, 0x07a2, 0x07a7, 0x07ac, 0x07b1, 0x07b6, 0x07ba, 0x07be,
    0x07c1, 0x07c4, 0x07c8, 0x07cb, 0x07ce, 0x07d1, 0x07d4, 0x07d6, 0x07d9, 0x07db, 0x07dd, 0x07df
];

function findNearestNoteForFrequency(frequency) {

    var dist = 10000,
        note = 0;

    for(var i = 0, l = Frequencies.length; i < l; i++) {

        var f = Frequencies[i],
            d = Math.abs(f - frequency);

        if (d < dist) {
            note = i;
            dist = d;
        }

    }

    return note;

}


// Serialization Helpers ------------------------------------------------------
function resolveOriginal(data, target) {

    var original;
    do {
        original = data[target];
        target = original[1] === -1 ? target : original[1];

    } while(!original[2]);

    return data[target][3];

}

function serializeSample(sample) {
    return [
        'Sample Name',
        -1,
        true,
        0,
        sample
    ];
}

function serializeInstrument(instrument, samples) {

    if (instrument.channel === 0) {
        return [
            instrument.name.toLowerCase(),
            -1, // first instrument if this is a duplicate
            true,
            0,
            (instrument.length === 64 ? 0x0 : 0x40) | 0, // Continuos / Channel
            instrument.sweepTime << 4 | ((instrument.sweepShift >= 0 ? 1 : 0) << 3) | Math.abs(instrument.sweepShift),
            instrument.dutyCycle << 6 | (instrument.length === 64 ? 0 : instrument.length),
            instrument.envelope << 4 | ((instrument.envelopeStep >= 0 ? 1 : 0) << 3) | Math.abs(instrument.envelopeStep),
        ];

    } else if (instrument.channel === 1) {
        return [
            instrument.name.toLowerCase(),
            -1, // first instrument if this is a duplicate
            true,
            0,
            (instrument.length === 64 ? 0x0 : 0x40) | 1, // Continuos / Channel
            instrument.dutyCycle << 6 | (instrument.length === 64 ? 0 : instrument.length),
            instrument.envelope << 4 | ((instrument.envelopeStep >= 0 ? 1 : 0) << 3) | Math.abs(instrument.envelopeStep),
            0xff // not used
        ];

    } else if (instrument.channel === 2) {
        return [
            instrument.name.toLowerCase(),
            -1, // first matching instrument if this is a duplicate
            true,
            0,
            (instrument.length === 256 ? 0x0 : 0x40) | 2, // Continuos / Channel
            instrument.length === 256 ? 0 : instrument.length,
            (instrument.outputLevel + 1) << 5,
            resolveOriginal(samples, instrument.sample) // sample reference
        ];

    } else if (instrument.channel === 3) {
        return [
            instrument.name.toLowerCase(),
            -1, // first matching instrument if this is a duplicate
            true,
            0,
            (instrument.length === 64 ? 0x00 : 0x40) | 3, // Continuos / Channel
            (instrument.length === 64 ? 0 : instrument.length),
            instrument.envelope << 4 | ((instrument.envelopeStep >= 0 ? 1 : 0) << 3) | Math.abs(instrument.envelopeStep),
            (instrument.polynomialCounterShift << 4) | (instrument.polynomialCounterStep << 3) | instrument.dividingRatioFrequency,
        ];
    }

}

function serializePattern(pattern, instruments) {
    var last = pattern.rows.length - 1;
    return [
        pattern.name.toLowerCase(),
        -1, // first matching pattern if this is a duplicate
        true,
        0,
        pattern.rows.map(function(row, index) {

            // Handle duplicates of instruments
            var target = resolveOriginal(instruments, row[1]);
            if (last === index) {
                return [row[0], target];

            } else {
                return [row[0], target];
            }

        })
    ];
}

function serializeEffect(effect, patterns) {
    return [
        effect.name.toLowerCase(),
        effect.tempo | (effect.loop && 0x80),
        resolveOriginal(patterns, effect.pattern)
    ];
}

function chunk(data, length) {

    var chunks = [];
    while(data.length > 0) {
        chunks.push(data.splice(0, length));
    }

    return chunks;

}

function deduplicate(values) {

    // De-duplicate values
    var i, j, l, current, original;
    for(i = 0, l = values.length; i < l; i++) {
        for(j = 0; j < i; j++) {

            if (i !== j) {

                current = values[i];
                original = values[j];

                // Detect duplicates and let them reference the original instrument
                if (current.slice(4).join(',') === original.slice(4).join(',')) {
                    current[1] = j;
                    current[2] = false;
                    break;
                }

            }

        }
    }

    var offset = 0;
    for(i = 0, l = values.length; i < l; i++) {
        if (values[i][2] === true) {
            values[i][3] = offset++;
        }
    }

    return values;

}

