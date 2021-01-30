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

-- example me this, batman
Game = List("TheGame")

-- this tells the system to send all signals to Game
Core.signalsTo(Game,Core.AllSignals)

-- actually do something
Startup = Entity()

function Startup:integrate()
	self.OurLED = fxLED(640,360,4)
	self.OurLED.drawMode = "buffer"
	self.OurLED:makeFuzz(self.OurLED.fuzzModeList[1])
	self.fuzzID = 1
	self.rng = love.math.newRandomGenerator()
	self.clk = 0
end

function Startup:love_update(dt)
	-- set 256 random pixels on the LED screen
	self.clk = self.clk + dt
	local h,s = math.fmod(self.clk,6),0.6
	local lines = 16
	for i=1,lines,1 do
		local half = (self.OurLED.height-lines)/2
		local y = math.floor(math.sin(self.clk)*half)+half+i
		local spot = self.OurLED:getSpot(h,s,1)
		for c=0,639,1 do
			self.OurLED:setPixel(c,y,1,spot)
		end
	end
	self.OurLED:love_update(dt)
end

function Startup:love_keypressed(key, scancode, isrepeat)
	if key == 'space' then
		self.fuzzID = self.fuzzID + 1
		if self.fuzzID > #(self.OurLED.fuzzModeList) then self.fuzzID = 1 end
		self.OurLED:makeFuzz(self.OurLED.fuzzModeList[self.fuzzID])
	end
end

function Startup:love_draw()
	self.OurLED:love_draw()
	love.graphics.setColor(0,0,0,0.67)
	love.graphics.rectangle('fill', 0, 0, 1280, 20)
	love.graphics.setColor(1,1,1,1)
	love.graphics.print("FPS: " .. love.timer.getFPS() .. " fuzz is: " .. self.OurLED.fuzzMode)
end

Game:add(Startup,"Startup")
