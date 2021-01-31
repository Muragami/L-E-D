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

-- this tells the system to send all signals to Game
Core.signalsTo(Game,Core.AllSignals)

-- maybe we will use some colors?
Colors = fxColorPalette()
Colors:addAllStd()		-- all standard svg color names, why not?
Game:add(Colors)			-- put it into the game list, so it gets post_update signals

-- actually do something, we will do an opening sequence
Intro = Entity()

function Intro:integrate()
end

function Intro:love_update(dt)
end

function Intro:love_keypressed(key, scancode, isrepeat)
end


Game:add(Intro,"Intro")
