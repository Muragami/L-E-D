--[[
MIT License

Copyright (c) 2021 JasonP, fancy colors for LÖVE

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

assert(Class, "L-E-D.fxcolor must be included after L-E-D.core")

fxColor = Class { __includes = { Entity } }

local function lerp(a, b, k) --smooth transitions
  if a == b then
    return a
  else
    if math.abs(a-b) < 0.005 then return b else return a * (1-k) + b * k end
  end
end

fxColorTable = {}
fxColorId = 1

local function fxColorUpdate(dt)
  for i, v in ipairs(fxColorTable) do
    v:update(dt)
  end
end

-- add our internal update routine to be called before love_update each frame
Core.InternalUpdate["fxColor"] = fxColorUpdate

function fxColor:init()
	-- put us in the color table
	fxColorTable[fxColorId] = self
	self.ID = fxColorId
	fxColorId = fxColorId + 1
	-- make sure we have an internal table for entities we color
	self.toColor = {}
end

function fxColor:free()
	fxColorTable[self.ID] = fxColorTable[fxColorId-1]
	fxColorId = fxColorId - 1
end

-- we allow colors to have effects that update
function fxColor:update(dt)
	-- do an effect if we have one
	if self.effect then self.effect(self,dt) end
	-- update RGBA
	if self.changed then
		self.RGBA = { HSL(unpack(self)) }
		self.changed = false
		-- Kif, I've made it with RGBA! inform the men!
		for k,v in pairs(self.toColor) do
			k:set_color(v,self.RGBA)
		end
	end
end

function fxColor:setHSLA(h,s,l,a)
	self[1] = h
	self[2] = s
	self[3] = l
	self[4] = a or 1.0
	self.changed = true
end

-- This code is based on https://en.wikipedia.org/wiki/HSL_and_HSV
function fxColor:setRGBA(r,g,b,a)
	local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local c = max - min
  if c == 0 then self[1] = 0
  elseif max == r then self[1] = math.fmod((g - b) / c,6)
  elseif max == g then self[1] = (b - r) / c + 2
  else self[1] = (r - g) / c + 4 end
  self[3] = (min + max) / 2
  if c == 0 then self[2] = 0 else self[2] = c / (1 - math.abs(2 * self[3] - 1)) end
	self[4] = a or 1
	self.changed = true
end

function fxColor:setHex(hex)
	if i == nil then i = 1 end
	local l = s:len()
	local r,g,b,a
	if l+i < 6 then return 0, 0, 0, 0 end
	r = tonumber(s:sub(i,2),16) / 255
	g = tonumber(s:sub(i+2,4),16) / 255
	b = tonumber(s:sub(i+4,6),16) / 255
	if l+i > 8 then
		-- read the a part!
		a = tonumber(s:sub(i+6,8),16) / 255
	else
		a = 1
	end
	self:setRGBA(r,g,b,a)
end

--by Taehl https://love2d.org/wiki/HSL_color
--where the magic happens
function fxColor:toRGBA()
	if s <= 0 then
		self.RGBA[1] = l
		self.RGBA[2] = l
		self.RGBA[3] = l
		return
	end
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
	self.RGBA[1] = r + m
	self.RGBA[2] = g + m
	self.RGBA[3] = b + m
end

function fxColor:getColor()
	return self.RGBA
end

function fxColor:getColors()
	return self.RGBA[1], self.RGBA[2], self.RGBA[3], self.RGBA[4]
end

function fxColor:toLove()
	love.graphics.setColor(self.RGBA[1], self.RGBA[2], self.RGBA[3], self.RGBA[4])
end

function fxColor:paint(thing,part)
	self.toColor[thing] = part
end

function fxColor:unpaint(thing,part)
	self.toColor[thing] = nil
end
