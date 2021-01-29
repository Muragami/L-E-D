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

fxLED =  Class { __includes = { Entity }, drawMode = "buffer", fuzzMode = "flip", bits = 4, width = 0, height = 0 }

-- install some shared fxLED stuff into Core, and fill that in if we use it!
Core.LEDimg = {}
Core.LEDid = {}

--[[
	bits is bits per color channel, so actual color bits: 4x bits
		1 bit = 4 bit color (16 color) and uses four 8x8 pixel textures
		2 bits = 8 bit color (256 color) and uses four 32x32 pixel textures
		3 bits = 12 bit color (4096 colors) and uses four 128x128 pixel textures ~ 256MB
		4 bits = 16 bit color (65536 colors) and uses four 512x512 pixel textures ~ 4MB
		!!! 5 bits = 20 bit color (1 million colors) and uses four 2048x2048 textures ~ 64MB
		!!! 6 bits = 24 bit color (16 million colors) and uses four 8192x8192 textures ~ 1 GB!
	-- so really 1-4 bits is best! I'm not sure a SpriteBatch can index millions of sprites!
]]
function fxLED:init(width,height,bits)
	if bits == nil then bits = 4 end
	self.bits = bits
	self.width = width
	self.height = height
	if Core.LEDimg[bits] == nil then
		-- create the LED texture (as described above)
		self.colors = math.pow(2,self.bits*4)
		self.map_width = math.sqrt(self.colors)
		local tsize = self.map_width * 2
		self.imgSize = tsize
		-- we need 4 of these for the four possible rotations
		Core.LEDid[bits] = {}
		Core.LEDid[bits][1] = love.image.newImageData(tsize,tsize)
		Core.LEDid[bits][2] = love.image.newImageData(tsize,tsize)
		Core.LEDid[bits][3] = love.image.newImageData(tsize,tsize)
		Core.LEDid[bits][4] = love.image.newImageData(tsize,tsize)
		-- create standard LED images
		self:_newLEDs(1)
		self:_newLEDs(2)
		self:_newLEDs(3)
		self:_newLEDs(4)
		-- TODO: debug!
		Core.LEDid[bits][1] :encode( 'png', "LED-" .. bits .. "B-V1.png" )
			-- we need 4 of these for the four possible rotations
		Core.LEDimg[bits] = {}
		Core.LEDimg[bits][1] = love.graphics.newImage(Core.LEDid[bits][1])
		Core.LEDimg[bits][1]:setFilter('nearest','nearest')
		Core.LEDimg[bits][2] = love.graphics.newImage(Core.LEDid[bits][2])
		Core.LEDimg[bits][2]:setFilter('nearest','nearest')
		Core.LEDimg[bits][3] = love.graphics.newImage(Core.LEDid[bits][3])
		Core.LEDimg[bits][3]:setFilter('nearest','nearest')
		Core.LEDimg[bits][4] = love.graphics.newImage(Core.LEDid[bits][4])
		Core.LEDimg[bits][4]:setFilter('nearest','nearest')
		--
	end
	-- quads for the various pixels
	local ledQuads = {}
	local sz, c = self.imgSize * 0.5, 0
	for cy=1,sz,1 do
		for cx=1,sz,1 do
			ledQuads[c] = love.graphics.newQuad((cx-1) * 2, (cy-1) * 2, 2, 2,
    									self.imgSize, self.imgSize)
			c = c + 1
		end
	end
	self.ledQuads = ledQuads
	-- the batch itself
	self.sBatch = love.graphics.newSpriteBatch(Core.LEDimg[self.bits][1], width*height, "stream")
	-- now the sprites!
	local sIndex = {}
	c = 0
	for cy=1,height,1 do
		for cx=1,width,1 do
			self.sBatch:setColor(0,0,0,1)
			sIndex[c] = self.sBatch:add( ledQuads[1], cx*2, cy*2)
			c = c + 1
		end
	end
	self.screen = {}
	self.screen_invalid = {}
	-- make the screen empty (we stores arrays of lines)
	for iy = 0,height-1,1 do
		self.screen[iy] = {}
		self.screen_invalid[iy] = true
		local ln = self.screen[iy]
		for ix = 0,width-1,1 do
			ln[ix*2] = 0				-- intensity (L'ish)
			ln[ix*2+1] = ledQuads[0]			-- the color itself
		end
	end
	self.sIndex = sIndex
	self.flipCount = 1
	self:makeFuzz("flip")
	self.fuzzModeList = { "none", "flip", "spin", "wiggle", "backflip", "trifecta", "wave", "buzz", "half" }
end

function fxLED:makeFuzz(m)
	if m == "flip" then
		self.fuzzIndex = { 1, 3 }
	elseif m == "none" then
		self.fuzzIndex = { 1 }
	elseif m == "spin" then
		self.fuzzIndex = { 1, 2, 3, 4 }
	elseif m == "wiggle" then
		self.fuzzIndex = { 1, 3, 3, 1, 3, 1, 3 }
	elseif m == "backflip" then
		self.fuzzIndex = { 1, 3, 4, 2 }
	elseif m == "trifecta" then
		self.fuzzIndex = { 1, 3, 2, 1, 3, 4 }
	elseif m == "wave" then
		self.fuzzIndex = { 1, 2, 3, 4, 3, 2, 1 }
	elseif m == "buzz" then
		self.fuzzIndex = { 1, 1, 3, false, 1, 1, 2 }
	elseif m == "half" then
		self.fuzzIndex = { 1, false }
	else
		error("fxLED:makeFuzz has no mode: " + m)
	end
	self.fuzzEnd = #self.fuzzIndex
	self.fuzzMode = m
	self.flipCount = 1
end

function fxLED:_newLEDs(ver,process)
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
	local imgData = Core.LEDid[self.bits][ver]
	local sz = self.imgSize * 0.5
	local h, s, l, r, g, b, xl
	l = 0.5
	-- l is always 0
	for cy=1,sz,1 do
		s = (cy / sz) * 2
		if s > 1 then
			xl = s - 1
			s = 1
		else
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

function fxLED:setHSLA(x,y,h,s,l,a)
	-- h turns into x in the map, s turns into y
	-- we use l for the strength of the LED (setColor)
	local mx = math.floor(h / 6 * self.map_width)
	local my = math.floor(s * self.map_width)
	local spot = my * self.map_width + mx
	-- are we direct?
	if self.drawMode == "direct" then
		-- inform the SpriteBatch directly
		self.sBatch:setColor(l,l,l,a)
		self.sBatch:set(self.sIndex[y*self.width+x],self.ledQuads[spot],x*2,y*2)
	elseif self.drawMode == "buffer" then
		-- cache this change and invalidate the line it's on
		local ln = self.screen[y]
		ln[x*2] = l
		ln[x*2+1] = self.ledQuads[spot]
		self.screen_invalid[y] = true
	else error("fxLED:setHSLA() unsupported draw mode: " .. self.drawMode)
	end
end

function fxLED:setPixel(x,y,l,spot)
	-- are we direct?
	if self.drawMode == "direct" then
		-- inform the SpriteBatch directly
		self.sBatch:setColor(l,l,l,a)
		self.sBatch:set(self.sIndex[y*self.width+x],self.ledQuads[spot],x*2,y*2)
	elseif self.drawMode == "buffer" then
		-- cache this change and invalidate the line it's on
		local ln = self.screen[y]
		ln[x*2] = l
		ln[x*2+1] = self.ledQuads[spot]
		self.screen_invalid[y] = true
	else error("fxLED:setHSLA() unsupported draw mode: " .. self.drawMode)
	end
end

function fxLED:getSpot(h,s,l)
	return math.floor(s * self.map_width) * self.map_width + math.floor(h / 6 * self.map_width)
end

function fxLED:setRGBA(x,y,r,g,b,a)
end

function fxLED:love_update()
	-- move screen to the spritebatch if we are buffering!
	if self.drawMode == 'buffer' then
		for iy=0,self.height-1,1 do
			if self.screen_invalid[iy] then
				-- update the screen, this line has changed!
				local ln = self.screen[iy]
				local off = iy*self.width
				for ix=0,self.width-1,1 do
					local l = ln[ix*2]
					self.sBatch:setColor(l,l,l,1)
					self.sBatch:set(self.sIndex[off+ix],ln[ix*2+1],ix*2,iy*2)
				end
				self.screen_invalid[iy] = false
			end
		end
	end
end

function fxLED:love_draw()
	-- draw the batch!
	if self.fuzzIndex[self.flipCount] then self.sBatch:setTexture(Core.LEDimg[self.bits][self.fuzzIndex[self.flipCount]]) end
	self.flipCount = self.flipCount + 1
	if self.flipCount > self.fuzzEnd then self.flipCount = 1 end
	if self.fuzzIndex[self.flipCount] then love.graphics.draw(self.sBatch) end
end
