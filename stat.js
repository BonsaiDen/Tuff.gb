var fs = require('fs');

require('colors');

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

                    if (section.start < bank.start) {
                        bank.start = section.start;
                    }

                    bank.used += section.size;
                    bank.end = section.end;
                    bank.size = bank.used + bank.free;

                    bank.sections.push(section);

                }

            }

        }

    } else {

        var sectionName = line.split('(')[0].replace(':', '').trim();
        if (sectionName) {

            bank = {
                name: sectionName,
                empty: false,
                free: 0,
                used: 0,
                size: -1,
                start: 100000,
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

function ljust(val, length) {
    val = val.toString();
    return new Array(length - val.length + 1).join(' ') + val;
}

function rjust(val, length) {
    val = val.toString();
    return val + new Array(length - val.length + 1).join(' ');
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

    console.log('  %s @ %s (%s of %s bytes used) (%s free)'.cyan, rjust(bank.name, 7), toHex(bank.start), ljust(bank.used, 5), ljust(bank.size, 5), ljust(bank.free - 1, 5));
    console.log('');

    // Sections
    var prev = null;
    bank.sections.forEach(function(section) {

        if (prev) {
            var unused = section.start - (prev.end + 1);
            if (unused > 0) {
                console.log('    - %s-%s ........ (%s bytes free)'.grey, toHex(prev.end + 1), toHex(prev.end + unused), ljust(unused, 5));
            }

        } else if (section.start > bank.start) {
            console.log('    - %s-%s ........ (%s bytes free)'.grey, toHex(bank.start), toHex(section.start - 1), ljust(section.start - 1, 5));
        }

        console.log('    - %s-%s ######## (%s bytes)', toHex(section.start), toHex(section.end), ljust(section.size, 5));
        prev = section;

    });

    var left = (bank.end - 1) - (prev.end + 1);
    if (left > 0) {
        console.log('    - %s-%s ........ (%s bytes free)'.grey, toHex(prev.end + 1), toHex(bank.end - 1), ljust(left, 5));
    }

    console.log('\n');

});

