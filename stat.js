var fs = require('fs');

var lines = fs.readFileSync(process.argv[2]).toString().split('\n');
var banks = [],
    bank = null,
    section = null;

for(var i = 0, l = lines.length; i < l; i++) {

    var line = lines[i],
        prefix = line.match(/^\s+/);

    if (prefix) {

        line = line.trim();

        if (bank) {

            if (line !== 'EMPTY') {

                var slack = line.match(/SLACK\: \$([0-9A-F]{4,4}) bytes/);
                if (slack) {
                    bank.free += parseInt(slack[1], 16);
                    bank.size = bank.used + bank.free;
                }

                var s = line.match(/SECTION\: \$([0-9A-F]{4,4})-\$([0-9A-F]{4,4}) \(\$([0-9A-F]{4,4}) bytes\)/);
                if (s) {

                    section = {
                        start: parseInt(s[1], 16),
                        end: parseInt(s[2], 16),
                        size: parseInt(s[3], 16)
                    };

                    if (!bank.sections.length) {

                        if (banks.length === 1) {
                            bank.start = 0;

                        } else {
                            bank.start = section.start;
                        }

                    }

                    bank.used += section.size;
                    bank.end = section.end;
                    bank.size = bank.used + bank.free;

                    bank.sections.push(section);

                }

            }

        }

    } else {

        var sectionName = line.split('(')[0].trim().slice(0, -1);
        if (sectionName) {

            bank = {
                name: sectionName,
                empty: false,
                free: 0,
                used: 0,
                size: -1,
                start: 0,
                end: -1,
                sections: []
            };

            banks.push(bank);
            section = null;

        }

    }

}

function toHex(val) {
    val = val.toString(16);
    return '$' + (new Array(5 - val.length).join('0')) + val;
}


console.log('');

banks.filter(function(b) {
    return b.size !== -1;

}).map(function(bank) {

    // Bank
    bank.sections.sort(function(a, b) {
        return a.start - b.start;
    });

    bank.end = bank.start + bank.size;

    console.log('  %s @ %s (%s of %s bytes used) (%s free)', bank.name, toHex(bank.start), bank.used, bank.size, bank.free - 1);
    console.log('');

    // Sections
    var prev = null;
    bank.sections.forEach(function(section) {

        if (prev) {
            var unused = section.start - (prev.end + 1);
            if (unused > 0) {
                console.log('    - %s-%s [unused] (%s bytes free)', toHex(prev.end + 1), toHex(prev.end + unused), unused);
            }

        } else if (section.start > bank.start) {
            console.log('    - %s-%s [unused] (%s bytes free)', toHex(bank.start), toHex(section.start - 1), section.start - 1);
        }

        console.log('    - %s-%s -------- (%s bytes)', toHex(section.start), toHex(section.end), section.size);
        prev = section;

    });

    var left = (bank.end - 1) - (prev.end + 1);
    if (left > 0) {
        console.log('    - %s-%s [unused] (%s bytes free)', toHex(prev.end - 1), toHex(bank.end - 1), left);
    }

    console.log('\n');

});

