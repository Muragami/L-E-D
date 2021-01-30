# L-E-D
**Say L, E, D**

**Implemented: a bit = ??%, not ready for regular use yet!**

LÖVE Engine Design
-----
What started as some updates for [hump](https://github.com/vrld/hump), turned into a kind of fabric. At that point, I started recoding a bit and ended up here. This is a very simple, low-level engine that runs on top of [LÖVE](https://love2d.org). It implements a simple Observer Pattern, and has the following features:

  * **Entities, Lists, and Signals**: The fabric of the engine. In the replaced love.run() function, it sends signals to any registered Entities and Lists (of Entities). This is the core of humped, and all other features below run on top of that.
  * **fxcolor**: HSL color support with programmability, colors can alter over time, on events, etc.
  * **fxaudio**: fxAudio Entity to make routing of audio events simple.
  * **fxcamera**: fxCamera Entity to make handling of 2d camera's a snap.
  * **fxvisual**: Simple but robust visual entities: fxLED, fxShape, fxGroup.

## Changes from hump and LÖVE
hump
-----
  * **Signal is now Core**: The signal. class became Core. as it is the basis of humped.
  * **Signal is expanded**: The signal. class can call entities (passing the class to Core and then Core calls YourEntity:signal(name,...)) and supports stuff like filters and automatic routing.
  * **Gamestate is gone**: Using Lists and signals via Core, removes the need for Gamestate. A Gamestate is now just a list of Entities that listen for the signals 'love_update' and 'love_draw', etc.
  * **Timer is embedded**: Timer added to Core and supports built-ins like TimedSignals, etc.

LÖVE
-----
  * **Custom love.run**: love.run() has been replaced with a custom function that doesn't call handlers, but emits signals through Core so any listening Entities and Lists are called upon.
  * **love.load is gone**: Due to the change in design model, Entities have a once called function (before first love_update signal) called Entity:integrate() allowing them to load. A matching call to Entity:disintegrate() happens when they are removed from Integration (all Entities/Lists that listen to love_update are considered Integrated).

## Embedded code
  * JSON Encode/Decode in Pure LUA by [Jeffrey Friedl](http://regex.info/blog/lua/json) is licensed under a [Creative Commons Attribution 3.0 Unported License](http://creativecommons.org/licenses/by/3.0/deed.en_US).
  * Refactored code from [hump](https://github.com/vrld/hump).
