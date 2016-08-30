// Dependencies ---------------------------------------------------------------
var path = require('path'),
    Promise = require('bluebird'),
    fs = Promise.promisifyAll(require('fs')),
    PNG = require('pngjs').PNG;


// General IO Wrapper ---------------------------------------------------------
var io = {

    _source: null,
    _dest: null,

    setSource: function(path) {
        io._source = path;
    },

    setDest: function(path) {
        io._dest = path;
    },

    load: function(name) {

        var file = path.join(io._source, name);
        if ((/\.png$/).test(file)) {
            return io.loadImage(file, name);

        } else if ((/\.json$/).test(file)) {
            return io.loadJSON(file);

        } else if ((/\.js$/).test(file)) {
            return Promise.fulfilled(require(file));
        }

    },

    save: function(name, data) {
        return fs.writeFile(path.join(io._dest, name), new Buffer(data));
    },

    saveAs: function(ext, name, data) {
        return io.save(name.replace(/\.[^\.]{0,4}$/, '.' + ext), data);
    },

    loadImage: function(file) {

        var deffered = Promise.pending();
        fs.createReadStream(file).pipe(new PNG({
            filterType: 4

        })).on('parsed', function() {

            if (this.height % 8 !== 0 || this.width % 8 !== 0) {
                deffered.reject(new Error('[image] Error: Image size is not a multiple of 8x8px!'));

            } else {

                console.log(
                    '[image] Loaded image "' + file + '" with %sx%s pixels (%sx%s tiles, %s bytes as tileset)',
                    this.width,
                    this.height,
                    this.width / 8,
                    this.height / 8,
                    this.width * this.height / 4
                );

                deffered.fulfill(this);

            }

        });

        return deffered.promise;

    },

    loadJSON: function(file) {
        return fs.readFileAsync(file).then(JSON.parse);
    }

};


// Exports --------------------------------------------------------------------
module.exports = io;

