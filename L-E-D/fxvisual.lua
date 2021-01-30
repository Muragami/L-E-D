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

fxShape = Class { __includes = { Entity }, stroke = false, fill = true }

-- simple shapes that we pass into loved directly, if you are using these
-- then your shape will be turned into a mesh
local SimpleShapes = { triangle = true, rectangle = true, points = true,
 				polygon = true, line = true, ellipse = true, arc = true }

local wid, sz = false, false

--triangle
local function draw_triangleline(self)
	if not self.visible then return end
	if self.style then
		wid = love.graphics.getWidth()
		love.graphics.setWidth(self.style.width)
	end
	love.graphics.triangle("line",self.vertex[1],self.vertex[2],self.vertex[3],self.vertex[4],
									self.vertex[5],self.vertex[6])
	if self.style then
		love.graphics.setWidth(wid)
	end
end
local function draw_trianglefill(self)
	if not self.visible then return end
	love.graphics.triangle("fill",self.vertex[1],self.vertex[2],self.vertex[3],self.vertex[4],
									self.vertex[5],self.vertex[6])
end

--rectangle
local function draw_rectangleline(self)
	if not self.visible then return end
	if self.style then
		wid = love.graphics.getWidth()
		love.graphics.setWidth(self.style.width)
	end
	love.graphics.rectangle("line",self.vertex[1],self.vertex[2],self.width,self.height)
	if self.style then
		love.graphics.setWidth(wid)
	end
end
local function draw_rectanglefill(self)
	if not self.visible then return end
	love.graphics.rectangle("fill",self.vertex[1],self.vertex[2],self.width,self.height)
end

-- points
local function draw_pointsfill(self)
	if not self.visible then return end
	if self.style then
		sz = love.graphics.getPointSize()
		love.graphics.setPointSize(self.style.size)
	end
	love.graphics.points("fill",self.vertex)
	if self.style then
		love.graphics.setPointSize(sz)
	end
end

--polygon
local function draw_polygonline(self)
	if not self.visible then return end
	if self.style then
		wid = love.graphics.getLineWidth()
		love.graphics.setLineWidth(self.style.width)
	end
	love.graphics.polygon("line",self.vertex)
	if self.style then
		love.graphics.setLineWidth(wid)
	end
end
local function draw_polygonfill(self)
	if not self.visible then return end
	love.graphics.polygon("fill",self.vertex)
end

--line
local function draw_lineline(self)
	if not self.visible then return end
	if self.style then
		wid = love.graphics.getLineWidth()
		love.graphics.setLineWidth(self.style.width)
	end
	love.graphics.line("line",self.vertex)
	if self.style then
		love.graphics.setLineWidth(wid)
	end
end

--ellipse
local function draw_ellipseline(self)
	if not self.visible then return end
	if self.style then
		wid = love.graphics.getLineWidth()
		love.graphics.setLineWidth(self.style.width)
	end
	love.graphics.ellipse("line",self.vertex[1], self.vertex[2], self.width, self.height)
	if self.style then
		love.graphics.setLineWidth(wid)
	end
end
local function draw_ellipsefill(self)
	love.graphics.ellipse("fill",self.vertex[1], self.vertex[2], self.width, self.height)
end

-- arc
local function draw_arcline(self)
	if self.style then
		wid = love.graphics.getLineWidth()
		love.graphics.setLineWidth(self.style.width)
	end
	love.graphics.arc("line",self.vertex[1], self.vertex[2], self.radius, self.start, self.stop, self.segments)
	if self.style then
		love.graphics.setLineWidth(wid)
	end
end
local function draw_arcfill(self)
	love.graphics.arc("fill",self.vertex[1], self.vertex[2], self.radius, self.start, self.stop, self.segments)
end

--entity
local function draw_entity(self)
	self.draw_entity:love_draw()
end

-- mesh
local function draw_mesh(self)
	love.graphics.draw(self.the_mesh,self.sx, self.sy)
end

local DrawFunc = { triangleline = draw_triangleline, trianglefill =  draw_trianglefill,
				rectanglefill = draw_rectanglefill, rectangleline = draw_rectangleline,
			 	pointsfill = draw_pointsfill, polygonfill = draw_polygonfill,
				polygonline = draw_polygonline, lineline = draw_lineline, ellipseline = draw_ellipseline,
			 	ellipsefill = draw_ellipsefill, arcline = draw_arcline, arcfill = draw_arcfill }

function fxShape:init(cfg)
	local opts
	if cfg then
		if type(cfg) == "string" then
			-- decode the JSON data
			opts = JSON:decode(cfg)
		else
			-- it's a table with data
			opts = cfg
		end
	end
	-- get the config!
	for k,v in pairs(opts) do
		self[k] = v
	end
	if self.vertex and not self.sx then self.sx = self.vertex[1] end
	if self.vertex and not self.sy then self.sy = self.vertex[2] end
	-- are we simple?
	self.simple = SimpleShapes[opts.form] or false
	if self.simple then
		-- whatever we are, assign the proper draw function
		self.love_draw = DrawFunc[self.form .. self.mode]
	else
		-- well what have we here? let's take a closer look
		if self.form == "draw" then
			-- fully custom drawn shape, so let's configure that
			local code = self.draw
			if type(code) == "string" then
				self.love_draw = loadstring(code)
				-- Lua code to compile
			elseif type(code) == "table" then
				-- entity to call love_draw on
				self.draw_entity = code
				self.love_draw = draw_entity
			elseif type(code) == "function" then
				-- a function to assign
				self.love_draw = code
			end
		elseif self.form == "build" then
			-- ok we are making a mesh!
			local code = self.build
			if type(code) == "string" then
				self.the_mesh = (loadstring(code))(self)
				-- Lua code to compile
			elseif type(code) == "table" then
				-- entity to call love_draw on
				self.the_mesh = code:build()
			elseif type(code) == "function" then
				-- a function to assign
				self.the_mesh = code(self)
			end
			self.love_draw = draw_mesh
		else
			-- just drawing a mesh
			self.the_mesh = love.graphics.newMesh( self.vertex, self.mode, self.usage )
			self.love_draw = draw_mesh
		end
	end
	self.visible = true
	-- if this is for offscreen use, don't draw it when called upon
	if self.offscreen then self.draw_offscreen = self.love_draw self.love_draw = nil end
end

fxLED =  Class { __includes = { Entity }, drawMode = "buffer", fuzzMode = "flip", bits = 4, width = 0, height = 0 }

-- install some shared fxLED stuff into Core, and fill that in if we use it!
Core.LEDimg = {}
Core.LEDid = {}
Core.LEDq = {}

function Core.ledsNew(bits,ver,process)
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
	local imgData = Core.LEDid[bits][ver]
	local sz = Core.LEDid[bits].imgSize * 0.5
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

function Core.ledsSetup(bits)
	-- we need 4 of these for the four possible rotations
	Core.LEDid[bits] = {}
	local LEDid = Core.LEDid[bits]
	LEDid.colors = math.pow(2,bits*4)
	LEDid.map_width = math.sqrt(LEDid.colors)
	local tsize = LEDid.map_width * 2
	LEDid.imgSize = tsize
	LEDid[1] = love.image.newImageData(tsize,tsize)
	LEDid[2] = love.image.newImageData(tsize,tsize)
	LEDid[3] = love.image.newImageData(tsize,tsize)
	LEDid[4] = love.image.newImageData(tsize,tsize)
	-- create standard LED images
	Core.ledsNew(bits,1)
	Core.ledsNew(bits,2)
	Core.ledsNew(bits,3)
	Core.ledsNew(bits,4)
		-- we need 4 of these for the four possible rotations
	Core.LEDimg[bits] = {}
	Core.LEDimg[bits][1] = love.graphics.newImage(LEDid[1])
	Core.LEDimg[bits][1]:setFilter('nearest','nearest')
	Core.LEDimg[bits][2] = love.graphics.newImage(LEDid[2])
	Core.LEDimg[bits][2]:setFilter('nearest','nearest')
	Core.LEDimg[bits][3] = love.graphics.newImage(LEDid[3])
	Core.LEDimg[bits][3]:setFilter('nearest','nearest')
	Core.LEDimg[bits][4] = love.graphics.newImage(LEDid[4])
	Core.LEDimg[bits][4]:setFilter('nearest','nearest')
	-- quads for the various pixels
	Core.LEDq[bits] = {}
	local ledQuads = Core.LEDq[bits]
	local sz, c = tsize * 0.5, 0
	for cy=1,sz,1 do
		for cx=1,sz,1 do
			ledQuads[c] = love.graphics.newQuad((cx-1) * 2, (cy-1) * 2, 2, 2,
											tsize, tsize)
			c = c + 1
		end
	end
end

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
	-- do we have a setup for that many bits? if not, do that
	if Core.LEDimg[bits] == nil then Core.ledsSetup(bits) end
	self.map_width = Core.LEDid[bits].map_width
	self.ledImg = Core.LEDimg[self.bits]
	self.ledQuads = Core.LEDq[self.bits]
	-- the batch itself
	self.sBatch = love.graphics.newSpriteBatch(Core.LEDimg[self.bits][1], width*height, "stream")
	local ledQuads = self.ledQuads
	for cy=1,height,1 do
		for cx=1,width,1 do
			self.sBatch:setColor(0,0,0,1)
			self.sBatch:add( ledQuads[1], cx*2, cy*2)
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
		self.sBatch:set(y*self.width+x,self.ledQuads[spot],x*2,y*2)
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
		self.sBatch:set(y*self.width+x,self.ledQuads[spot],x*2,y*2)
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
	-- TODO
end

function fxLED:post_update()
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
					self.sBatch:set(off+ix,ln[ix*2+1],ix*2,iy*2)
				end
				self.screen_invalid[iy] = false
			end
		end
	end
end

function fxLED:love_draw()
	-- draw the batch!
	if self.fuzzIndex[self.flipCount] then self.sBatch:setTexture(self.ledImg[self.fuzzIndex[self.flipCount]]) end
	self.flipCount = self.flipCount + 1
	if self.flipCount > self.fuzzEnd then self.flipCount = 1 end
	if self.fuzzIndex[self.flipCount] then love.graphics.draw(self.sBatch) end
end
