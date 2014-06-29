# Tuff

Tuff is an original game for Nintendo's black and white GameBoy.

It's a mix of Jump'n'Run and *Metroidvania* elements and will also contain elements from *Knytt* as you do not have any attacks but will focus on exploring the world.

Thing is, it *will* be, because as of right now it's still somwhere in mids of development. And since I'm by no means a designer and are mostly on to the technogical "challenge", expect game mechanics and optimization to come first, everything else (including the actual game world) will be lagging behind for quite some time.

Below are some older screens of the game to give you an impression of what it looks like, there's also a more recent [Video](http://www.youtube.com/watch?v=Xdtt6Rsvwag).


## Screenshots

![](http://dl.dropboxusercontent.com/u/2332843/tuff/screen1.png) . ![](http://dl.dropboxusercontent.com/u/2332843/tuff/screen2.png) 

![](http://dl.dropboxusercontent.com/u/2332843/tuff/screen3.png) . ![](http://dl.dropboxusercontent.com/u/2332843/tuff/screen4.png)


# Development

The Game is mostly being developed on Emulators, although I actually build a number of custom GamePaks by replacing the original masked ROM with a reprogrammable Flash Chip, so it does actually run on the [real hardware](http://www.youtube.com/watch?v=yXNEeld8Lq8).

In case you're trying to get started with your own GameBoy title, you might find the stuff under `src/core` the most helpful. The core runtime is mostly separated from the game code (except where stated in the source) and there are many useful routines and a whole lot of documentation for you to check out.

As for IDEs, there are none. Coding is all done in VIM, graphics and sprites are converted from PNG graphics via some custom Node.js conversion tools. The game world is built with [Tiled](http://www.mapeditor.org/) and then converted into a custom game specific format.

Most of the game assets also get compressed with a custom LZ-Type compression routine.


## How to compile

1. Make sure you got `make` installed (If you're on Ubuntu, just run `sudo apt-get install build-essential`)
2. Install [rgbgs](https://github.com/bentley/rgbds), it is the assembler that is being used for the project
3. Get [Node.js](https://nodejs.org), it is used for graphics conversion and other tooling
4. Run `make`

You'll find the assembled ROM under `build/game.gb`, it should play in a GameBoy Emulator of your choice.


## Emulator Tips for Development

I found that [Gambatte](https://github.com/sinamas/gambatte) and [bgb](http://bgb.bircd.org/) are by far the best emulators for developing 
since they focus on accuracy. Especially *bgb*, which also comes with a ton of built-in debugging tools.

For the web [GameBoy Online](https://github.com/grantgalitz/GameBoy-Online) is by far the best of the available JavaScript based emulators out there.

## Recording Gameplay Videos

For video recording [mednafen](http://mednafen.sourceforge.net/) will be the emulator of choice, you can record a 
uncompressed gameplay video along with audio like so:

    mednafen -qtrecord "game_raw.mov" -qtrecord.vcodec png -qtrecord.h_double_threshold 144 -qtrecord.w_double_threshold 160 game.gb

This will record a uncompressed 160x144 video of the game.

Getting the video YouTube ready can quickly be done with `ffmpeg`:

    ffmpeg -i game_raw.mov -vf scale=480:432 -sws_flags neighbor -acodec libmp3lame -ac 1 -ab 64000 -ar 22050 -vcodec mpeg4 -flags +mv4+gmc -mbd bits -trellis 2 -b 8000k game.avi

> This will scale it up, convert the audio to mp3 and the video to mpeg4, you can tweak the bitrate, but it will normally average out at around 3000kb/s (of course, this depends on the graphics of the game).


## Copyright

"Tuff" including all Graphics, Ideas, Sound and Maps are Copyright (c) 2014 Ivo Wetzel


## License

The assembly code along with all conversion tools is licensed under MIT:

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

