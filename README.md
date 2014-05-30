# Tuff

Another port of a very old game of mine, this time for the original black and white Gameboy!

In case you're trying to get started with your own DMG game, you might find a lot of the code very helpful, the core runtime is mostly separated from the game code and there are many useful routines and a whole lot of comments for you to check out.


## Screens

![](http://dl.dropboxusercontent.com/u/2332843/tuff/screen1.png) . ![](http://dl.dropboxusercontent.com/u/2332843/tuff/screen2.png) 

![](http://dl.dropboxusercontent.com/u/2332843/tuff/screen3.png) . ![](http://dl.dropboxusercontent.com/u/2332843/tuff/screen4.png)


## How to compile

1. Install [rgbgs](https://github.com/bentley/rgbds), it is the assembler that is being used
2. Get [Node.js](https://nodejs.org), it is used for graphics conversion and other tooling
3. Make sure you got `make` installed 
4. Run `make`

You'll find the assembled ROM under `build/main.gb`, it should play in a GameBoy Emulator of your choice.


## Emulators for Development

I found that [Gambatte](https://github.com/sinamas/gambatte) and [bgb](http://bgb.bircd.org/) are by far the best emulators for developing 
as they have a big focus on accuracy. Especially *bgb*, as it comes with a great, 
built-in debugger, vram viewer and other goodies. 

For the web, [GameBoy Online](https://github.com/grantgalitz/GameBoy-Online) is by far the best of the available JavaScript based 
emulators out there.

For video recording [mednafen](http://mednafen.sourceforge.net/) will be the emulator of choice, you can record a 
uncompressed gameplay video along with audio like so:

    mednafen -qtrecord "game_raw.mov" -qtrecord.vcodec png -qtrecord.h_double_threshold 144 -qtrecord.w_double_threshold 160 game.gb

This will record a uncompressed 160x144 video of the game.

Getting the video YouTube ready can quickly be done with `ffmpeg`:

    ffmpeg -i game_raw.mov -vf scale=480:432 -sws_flags neighbor -acodec libmp3lame -ac 1 -ab 64000 -ar 22050 -vcodec mpeg4 -flags +mv4+gmc -mbd bits -trellis 2 -b 8000k game.avi

> This will scale it up, convert the audio to mp3 and the video to mpeg4, you can tweak the bitrate, but it will normally average out at around 3000kb/s (of course, this depends on the graphics of the game).


# License

Tuff, a Gameboy Game
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

