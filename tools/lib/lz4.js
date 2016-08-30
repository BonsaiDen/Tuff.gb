// LZ4 alike data compression -------------------------------------------------
var maxRepeatCount = 65,
    minRepeatLength = 2,
    maxLiteralLength = 64,
    maxCopyLength = 35,
    minCopyLength = 3,
    maxCopyOffset = 255;


// Data Analyzers -------------------------------------------------------------
function findSingleRepeat(buf, from, to) {

    var s = buf[from],
        len = 0;

    for(var i = from; i < to; i++) {
        if (buf[i] === s) {
            len++;

            if (len === maxRepeatCount) {
                break;
            }

        } else {
            break;
        }
    }

    return len < minRepeatLength ? -1 : len;

}

function findDualRepeat(buf, from, to) {

    var s = buf[from],
        t = buf[from + 1],
        len = 0;

    for(var i = from; i < to; i += 2) {
        if (buf[i] === s && buf[i + 1] === t) {
            len++;
            if (len === maxRepeatCount) {
                break;
            }

        } else {
            break;
        }
    }

    return len < minRepeatLength ? -1 : len;

}

function findSubCopy(buf, from, length) {

    for(var at = from - length; at >= Math.max(from - maxCopyOffset, 0) ; at--) {

        // Check for maximum copy length
        var match = true;
        for(var i = 0; i < length; i++) {
            if (buf[from + i] !== buf[at + i]) {
                match = false;
                break;
            }
        }

        if (match) {
            return from - at - length;
        }

    }

    return -1;

}

function findCopy(buf, from) {

    findCopy.value.length = -1;

    for(var length = minCopyLength; length < Math.min(maxCopyLength, buf.length - from + 1); length++) {

        var at = findSubCopy(buf, from, length, 0);
        if (at !== -1) {
            findCopy.value.offset = at;
            findCopy.value.length = length;

        } else {
            break;
        }

    }

    return findCopy.value;

}

findCopy.value = {
    length: -1,
    offset: 0
};



// Encoder --------------------------------------------------------------------
var copyEncodeLength = 2,
    singleEncodeLength = 2,
    dualEncodeLength = 3;


function encode(data, addEndMarker) {

    var literalCount = 0,
        index = 0,
        output = [];

    while(index < data.length) {

        var singleRepeat = findSingleRepeat(data, index, index + maxRepeatCount),
            dualRepeat = findDualRepeat(data, index, index + maxRepeatCount * 2),
            copy = findCopy(data, index);

        var savedSingle = singleRepeat * 1 - singleEncodeLength,
            savedDual = dualRepeat * 2 - dualEncodeLength,
            savedCopy = copy.length - copyEncodeLength;

        if (savedSingle > 0 || savedDual > 0 || savedCopy > 0 || literalCount === maxLiteralLength) {
            if (literalCount > 0) {

                // 01 0000000
                //   1-64 literals
                output.push(((literalCount - 1) & 0x3f) | 0x40);
                output.push.apply(output, data.slice(index - literalCount, index));

                literalCount = 0;

            }
        }

        // Single Repeat
        if (savedSingle > 0 && savedSingle >= savedDual && savedSingle >= savedCopy) {

            if (singleRepeat > maxRepeatCount) {
                throw new Error('Single Repeat Count out of Range: ' + singleRepeat);
            }

            // 00 1 0 0000
            // repeat the zero byte 2-33 times
            if (data[index] === 0 && (singleRepeat - minRepeatLength) < 16) {
                output.push(0x20 | ((singleRepeat - minRepeatLength) & 0x0f));

            // 10 000000
            // repeat the next byte 2-65 times
            } else {
                output.push(0x80 | ((singleRepeat - minRepeatLength) & 0x3f));
                output.push(data[index]);
            }

            index += singleRepeat;

        // Dual Repeat
        } else if (savedDual > 0 && savedDual >= savedSingle && savedDual >= savedCopy) {

            if (dualRepeat > maxRepeatCount) {
                throw new Error('Dual Repeat Count out of Range: ' + dualRepeat);
            }

            // 11 000000
            // repeat the next 2 bytes 2-65 times
            output.push(0xc0 | ((dualRepeat - minRepeatLength) & 0x3f));
            output.push(data[index]);
            output.push(data[index + 1]);

            index += dualRepeat * 2;

        // Copy
        } else if (savedCopy > 0 && savedCopy) {

            if (copy.length > maxCopyLength) {
                throw new Error('Copy Length out of Range: ' + copy.length);
            }

            if (copy.offset + copy.length > maxCopyOffset) {
                throw new Error('Copy Offset out of Range: ' + (copy.offset + copy.length));
            }

            // 00 0 00000 00000000
            // copy 3-35 bytes from offset 1-256 (+length)
            output.push(((copy.length - minCopyLength) & 0x1f));
            output.push(copy.offset & 0xff);

            index += copy.length;

        } else {
            literalCount++;
            index++;
        }

    }

    if (literalCount > 0) {
        // 01 0000000
        //   1-64 literals
        output.push(((literalCount - 1) & 0x3f) | 0x40);
        output.push.apply(output, data.slice(index - literalCount, index));
    }

    //console.log('Compressed %s bytes to %s%% (%s bytes)', data.length, 100 / data.length * output.length, output.length);

    if (addEndMarker === true) {
        output.push(0x30);
    }

    return output;

}


// Decoder --------------------------------------------------------------------
function decode(data) {

    // TODO Currently doesn't work, must be updated to match encoder
    var output = [],
        index = 0;

    while(index < data.length) {

        var type = data[index],
            i = 0,
            offset = 0,
            length = 0;

        // Literal Data
        if ((type & 0x80) === 0x80) {
            length = (type & 0x7f) + 1;
            output.push.apply(output, data.slice(index + 1, index + 1 + length));
            index += length + 1;

        // Repeat
        } else if ((type & 0x40) === 0x40) {

            length = (type & 0x1f) + minRepeatLength;

            // Dual
            if ((type & 0x20) === 0x20) {

                for(i = 0; i < length; i++) {
                    output.push(data[index + 1], data[index + 2]);
                }
                index += 3;

            // Single
            } else {
                for(i = 0; i < length; i++) {
                    output.push(data[index + 1]);
                }
                index += 2;
            }

        // Copy
        } else {
            length = (type & 0x3f) + minCopyLength;
            offset = data[index + 1];

            var origin = output.length;
            for(i = 0; i < length; i++) {
                output.push(output[(origin - offset - length) + i]);
            }
            index += 2;
        }

    }

    return output;

}


// Exports --------------------------------------------------------------------
exports.encode = encode;
exports.decode = decode;

