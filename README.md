# Tuff

Tuff is an original game for Nintendo's black and white GameBoy, based on a mix of Jump'n'Run and *Metroidvania* style game elements.

Below are some older screenshots of the game to give you an impression of what it looks like, there's also a more recent [Video](http://www.youtube.com/watch?v=Xdtt6Rsvwag).

### Screenshots

![](http://dl.dropboxusercontent.com/u/2332843/tuff/screen1.png) . ![](http://dl.dropboxusercontent.com/u/2332843/tuff/screen2.png) 

![](http://dl.dropboxusercontent.com/u/2332843/tuff/screen3.png) . ![](http://dl.dropboxusercontent.com/u/2332843/tuff/screen4.png)


## Development

The game, while mostly being developed on Emulators, also works on custom build flash ROM Game Paks.

There are many interesting bits and pieces under `src/core`, especially if you're interested in starting your own GameBoy development.

Coding is all done in VIM while graphics, sprites and sounds are converted via custom Node.js based conversion tools. The game's world is edited via [Tiled](http://www.mapeditor.org/) and also converted into a custom binary format.

Most of the game assets also get compressed with a custom LZ-Type compression routine.


### How to compile

1. You'll need `make`, [Node.js](https://nodejs.org) and [gbasm](https://github.com/BonsaiDen/gbasm)
2. Clone the repository and `cd` into its directory
3. Run `npm install .` to setup the dependencies
4. Run `make` to assemble the ROM under `build/game.gb`


### Emulator Tips for Development

[Gambatte](https://github.com/sinamas/gambatte) and [bgb](http://bgb.bircd.org/) are by far the best emulators for developing.
They both have a big focus on accuracy and *bgb* also comes with a huge number of built-in debugging tools.

On the web [GameBoy Online](https://github.com/grantgalitz/GameBoy-Online) is probably the best of the available JavaScript based emulators out there.

### Recording Gameplay Videos

For video recording [mednafen](http://mednafen.sourceforge.net/) turns out to be the simpelst solution:

    mednafen -qtrecord "game_raw.mov" -qtrecord.vcodec png -qtrecord.h_double_threshold 144 -qtrecord.w_double_threshold 160 game.gb

This will record a uncompressed 160x144 video of the game.

Getting the video YouTube ready can quickly be done with `ffmpeg`:

    ffmpeg -i game_raw.mov -vf scale=480:432 -sws_flags neighbor -acodec libmp3lame -ac 1 -ab 64000 -ar 22050 -vcodec mpeg4 -flags +mv4+gmc -mbd bits -trellis 2 -b 8000k game.avi

> This will scale it up, convert the audio to mp3 and the video to mpeg4, you can tweak the bitrate, but it will normally average out at around 3000kb/s for Tuff.


## Copyright and License

*Tuff* including all graphics, characters, ideas, sounds and maps are Copyright (c) 2014 Ivo Wetzel. All rights reserved.


The assembly code along with all conversion tools is licensed under MIT.

Copyright (C) 2014 Ivo Wetzel

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

