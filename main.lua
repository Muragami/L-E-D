--[[
Jason A. Petrasko - muragami@wishray.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

-- grab the humped up core! (always before any other humped module!)
require 'L-E-D.core'
require 'L-E-D.fxcolor'
require 'L-E-D.fxcamera'
require 'L-E-D.fxvisual'

-- example me this, batman, let's just make a single List, call it Game
Game = List("TheGame")
-- make the game prune contained dead entities automagically
Game.prune_on_update = true
-- die if we are done, and an empty nest
Game.die_empty = true
-- this tells the system to send all signals to Game
Core:signalsTo(Game,Core.AllSignals)

-- maybe we will use some colors?
Colors = fxColorPalette("GameColors")
Colors:addAllStd()		-- all standard svg color names, why not?
Game:add(Colors)			-- put it into the game list, so it gets post_update signals

-- actually do something, we will do an opening sequence
Intro = Entity("Intro")

-- called once before the first time an entity will call love_update
function Intro:integrate()
	-- listen for intro_end
	Core:add("intro_end",self)
	-- also doom us, because we are going to die in 10 seconds
	self:Doom(3)
	print("integrate")
end

-- called once each frame, before the screen is drawn
function Intro:love_update(dt)
	Entity.love_update(self,dt)	-- let entity do tracking
	if not self.done then print("love_update") self.done = true end
end

-- what to do if a key is pressed!
function Intro:love_keypressed(key, scancode, isrepeat)
	Core:emit("intro_end")
	print("key_pressed")
end

-- signal that we are done with the intro
function Intro:intro_end(key, scancode, isrepeat)
	Core:run('start.lua')
	print("intro_end")
end

function Intro:kill()
	Entity.kill(self)
	print("intro killed")
	Game:remove(Colors)
	Game:remove(self)
end

function Intro:core_error(s)
	print("error:")
	print(s)
	print('')
end

-- add Intro to the game (making it real!)
Game:add(Intro)
