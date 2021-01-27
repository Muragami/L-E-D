--[[
MIT License

Copyright (c) 2021 JasonP, simple visuals for LÖVE

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

assert(Class, "L-E-D.fxvisual must be included after L-E-D.core")
assert(fxColor, "L-E-D.fxvisual must be included after L-E-D.fxcolor")

fxShape = Class { __includes = { Entity } }

fxLED =  Class { __includes = { Entity }, bits = 4, width = 0, height = 0 }

--[[
	bits is bits per color channel, so actual color bits: 4x bits
		1 bit = 4 bit color (16 color) and uses four 8x8 pixel textures
		2 bits = 8 bit color (256 color) and uses four 32x32 pixel textures
		3 bits = 12 bit color (4096 colors) and uses four 128x128 pixel textures ~ 256MB
		4 bits = 16 bit color (65536 colors) and uses four 512x512 pixel textures ~ 4MB
		5 bits = 20 bit color (1 million colors) and uses four 2048x2048 textures ~ 64MB
		6 bits = 24 bit color (16 million colors) and uses four 8192x8192 textures ~ 1 GB!
	-- so really 1-5 bits is best!
]]
function fxLED:init(width,height,bits)
	if bits == nil then bits = 4 end
	self.bits = bits
	self.width = width
	self.height = height
	if Core.LEDtex == nil then
		-- create the LED texture (512x512 for a 4-bit channel color LED)
		local tsize = math.sqrt(math.pow(2,self.bits*4)) * 2
		self.imgSize = tsize
		-- we need 4 of these for the four possible rotations
		Core.LEDid = {}
		Core.LEDid[1] = love.image.newImageData(tsize,tsize)
		Core.LEDid[2] = love.image.newImageData(tsize,tsize)
		Core.LEDid[3] = love.image.newImageData(tsize,tsize)
		Core.LEDid[4] = love.image.newImageData(tsize,tsize)
		-- create standard LED images
		self:makeLEDs(1)
		self:makeLEDs(2)
		self:makeLEDs(3)
		self:makeLEDs(4)
		-- debug!
		--Core.LEDid[1] :encode( 'png', "LED-" .. bits .. "B-V1.png" )
		--Core.LEDid[2] :encode( 'png', "LED-" .. bits .. "B-V2.png" )
		--Core.LEDid[3] :encode( 'png', "LED-" .. bits .. "B-V3.png" )
		--Core.LEDid[4] :encode( 'png', "LED-" .. bits .. "B-V4.png" )
		-- we need 4 of these for the four possible rotations
		Core.LEDimg = {}
		Core.LEDimg[1] = love.graphics.newImage(Core.LEDid[1])
		Core.LEDimg[2] = love.graphics.newImage(Core.LEDid[2])
		Core.LEDimg[3] = love.graphics.newImage(Core.LEDid[3])
		Core.LEDimg[4] = love.graphics.newImage(Core.LEDid[4])
		--
	end
	self.screen = {}
	-- make the screen empty
	for c = 1,height*width,1 do
		self.screen[c*4] = 0
		self.screen[c*4+1] = 0
		self.screen[c*4+2] = 0
		self.screen[c*4+3] = 0
	end

end

function fxLED:makeLEDs(ver,process)
	-- make the LED iamges
	local delta = {}
	if ver == 1 then
		delta[1] = { [1] = 0, [2] = 0 }
		delta[2] = { [1] = 1, [2] = 0 }
		delta[3] = { [1] = 1, [2] = 1 }
		delta[4] = { [1] = 0, [2] = 1 }
	elseif ver == 2 then
		delta[1] = { [1] = 1, [2] = 0 }
		delta[2] = { [1] = 1, [2] = 1 }
		delta[3] = { [1] = 0, [2] = 1 }
		delta[4] = { [1] = 0, [2] = 0 }
	elseif ver == 3 then
		delta[1] = { [1] = 1, [2] = 1 }
		delta[2] = { [1] = 0, [2] = 1 }
		delta[3] = { [1] = 0, [2] = 0 }
		delta[4] = { [1] = 1, [2] = 0 }
	else
		delta[1] = { [1] = 0, [2] = 1 }
		delta[2] = { [1] = 0, [2] = 0 }
		delta[3] = { [1] = 1, [2] = 0 }
		delta[4] = { [1] = 1, [2] = 1 }
	end

	-- no processing, ok, make a dummy passback function!
	if process == nil then process = function(x) return x end end
	local imgData = Core.LEDid[ver]
	local sz = self.imgSize * 0.5
	local h, s, l, r, g, b, xl
	s = 1
	-- l is always 0
	for cy=1,sz,1 do
		l = (cy / sz) * 2
		if l > 1 then
			xl = l - 1
			l = 0.5
		else
			l = cy / sz
			xl = 0
		end
		for cx=1,sz,1 do
			h = cx / sz * 6
			-- calc
			local c = (1-math.abs(2*l-1))*s
			local x = (1-math.abs(h%2-1))*c
			local m,r,g,b = (l-.5*c), 0,0,0
			if h < 1     then r,g,b = c,x,0
			elseif h < 2 then r,g,b = x,c,0
			elseif h < 3 then r,g,b = 0,c,x
			elseif h < 4 then r,g,b = 0,x,c
			elseif h < 5 then r,g,b = x,0,c
			else              r,g,b = c,0,x
			end
			imgData:setPixel( (cx-1)*2 + delta[1][1], (cy-1)*2 + delta[1][2], process(r+m), 0, 0, 1 )
			imgData:setPixel( (cx-1)*2 + delta[2][1], (cy-1)*2 + delta[2][2], 0, process(g+m), 0, 1 )
			imgData:setPixel( (cx-1)*2 + delta[3][1], (cy-1)*2 + delta[3][2], 0, 0, process(b+m), 1 )
			local v = process(xl)
			imgData:setPixel( (cx-1)*2 + delta[4][1], (cy-1)*2 + delta[4][2], v, v, v, 1 )
		end
	end
end
