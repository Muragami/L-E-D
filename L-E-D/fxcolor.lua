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

assert(Class, "humped.fxcolor must be included after humped.core")

fxColor = Class { __includes = { Entity } }

local function lerp(a, b, k) --smooth transitions
  if a == b then
    return a
  else
    if math.abs(a-b) < 0.005 then return b else return a * (1-k) + b * k end
  end
end

--by Taehl https://love2d.org/wiki/HSL_color
--where the magic happens
local function HSL(h, s, l, a)
  if s <= 0 then return l,l,l,a end
  h, s, l = h*6, s, l
  local c = (1-math.abs(2*l-1))*s
  local x = (1-math.abs(h%2-1))*c
  local m,r,g,b = (l-.5*c), 0,0,0
  if h < 1     then r,g,b = c,x,0
  elseif h < 2 then r,g,b = x,c,0
  elseif h < 3 then r,g,b = 0,c,x
  elseif h < 4 then r,g,b = 0,x,c
  elseif h < 5 then r,g,b = x,0,c
  else              r,g,b = c,0,x
  end return {r+m, g+m, b+m, a}
end

fxColorTable = {}
fxColorId = 1

local function fxColorUpdate(dt)
  for i, v in ipairs(lueColorTable) do
    v:update(dt)
  end
end

function fxColor:init()
	fxColorTable[fxColorId] = self
	self.ID = fxColorId
	fxColorId = fxColorId + 1
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
	end
end

function fxColor:setColorHSLA(h,s,l,a)
	self[1] = h
	self[2] = s
	self[3] = l
	self[4] = a or 1.0
	self.changed = true
end

-- This code is based on https://en.wikipedia.org/wiki/HSL_and_HSV
function fxColor:setColorRGBA(r,g,b,a)
  local max = Math.max(r, g, b)
  local min = Math.min(r, g, b)
  local d = max - min
  local h
  if d == 0 then h = 0
  elseif max == r then h = (g - b) / d % 6;
  elseif max == g then h = (b - r) / d + 2
  else h = (r - g) / d + 4;
  self[3] = (min + max) / 2;
  self[2] = d === 0 ? 0 : d / (1 - Math.abs(2 * l - 1));
  self[1] = h * 60
	self[4] = a or 1.0
	self.changed = true
end

function fxColor:getColor()
	if self.changed then self.RGBA = HSL(unpack(self)) self.changed = false end
	return self.RGBA
end

function fxColor:getColors()
	if self.changed then self.RGBA = HSL(unpack(self)) self.changed = false end
	return self.RGBA[1], self.RGBA[2], self.RGBA[3], self.RGBA[4]
end

function fxColor:toLove()
	if self.changed then self.RGBA = HSL(unpack(self)) self.changed = false end
	love.graphics.setColor(self.RGBA[1], self.RGBA[2], self.RGBA[3], self.RGBA[4])
end
