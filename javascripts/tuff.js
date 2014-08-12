
var cout = console.log.bind(console);

function loadViaXHR () {

    var xhr = new XMLHttpRequest();
    xhr.open("GET", "roms/game.gb");
    xhr.responseType = "blob";
    xhr.onload = function () {
        startGame(new Blob([this.response], {
            type: "text/plain"
        }));
    };

    xhr.send();

}

function startGame(blob) {
    var binaryHandle = new FileReader();
    binaryHandle.onload = function () {
        if (this.readyState === 2) {
            start(document.getElementById('screen'), this.result);
        }
    };
    binaryHandle.readAsBinaryString(blob);
};

window.onload = function() {

    loadViaXHR();

    var keyZones = [
        ["right", [39, 68]],
        ["left", [37, 65]],
        ["up", [38, 87]],
        ["down", [40, 83]],
        ["a", [88, 77]],
        ["b", [90, 78, 89]],
        ["select", [16]],
        ["start", [13]]
    ];

    var pressed = {};
    function keyDown(event) {
        var keyCode = event.keyCode;
        var keyMapLength = keyZones.length;
        if (pressed[keyCode]) {
            return;

        } else {
            pressed[keyCode] = true;
        }

        for (var keyMapIndex = 0; keyMapIndex < keyMapLength; ++keyMapIndex) {
            var keyCheck = keyZones[keyMapIndex];
            var keysMapped = keyCheck[1];
            var keysTotal = keysMapped.length;
            for (var index = 0; index < keysTotal; ++index) {
                if (keysMapped[index] === keyCode) {
                    GameBoyKeyDown(keyCheck[0]);
                    try {
                        event.preventDefault();
                    }
                    catch (error) { }
                }
            }
        }
    }

    function keyUp(event) {
        var keyCode = event.keyCode;
        var keyMapLength = keyZones.length;
        if (!pressed[keyCode]) {
            return;

        } else {
            pressed[keyCode] = false;
        }
        for (var keyMapIndex = 0; keyMapIndex < keyMapLength; ++keyMapIndex) {
            var keyCheck = keyZones[keyMapIndex];
            var keysMapped = keyCheck[1];
            var keysTotal = keysMapped.length;
            for (var index = 0; index < keysTotal; ++index) {
                if (keysMapped[index] === keyCode) {
                    GameBoyKeyUp(keyCheck[0]);
                    try {
                        event.preventDefault();
                    }
                    catch (error) { }
                }
            }
        }
    }

    window.addEventListener('keydown', keyDown);
    window.addEventListener('keyup', keyUp);
    window.addEventListener('blur', function() {
        pressed = {};
    });

};

