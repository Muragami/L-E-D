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

fxColor = Class { __includes = { Entity }, type = "fxColor" }

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

function fxColor:init(h, s, l, a)
	-- put us in the color table
	fxColorTable[fxColorId] = self
	self.ID = fxColorId
	fxColorId = fxColorId + 1
	-- make sure we have an internal table for entities we color
	self.toColor = {}
	self[1] = h or 0.0
	self[2] = s or 1.0
	self[3] = l or 1.0
	self[4] = a or 1.0
	self.RGBA = {}
	self.changed = true
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
		self:toRGBA()
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
	local h, s, l = self[1], self[2], self[3]
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

local svg_color = {
	['black'] = { 0, 0, 0 },
	['dimgrey'] = { 0, 0, 41 },
	['dimgray'] = { 0, 0, 41 },
	['grey'] = { 0, 0, 50 },
	['gray'] = { 0, 0, 50 },
	['darkgray'] = { 0, 0, 66 },
	['darkgrey'] = { 0, 0, 66 },
	['silver'] = { 0, 0, 75 },
	['lightgrey'] = { 0, 0, 83 },
	['lightgray'] = { 0, 0, 83 },
	['gainsboro'] = { 0, 0, 86 },
	['whitesmoke'] = { 0, 0, 96 },
	['white'] = { 0, 0, 100 },
	['rosybrown'] = { 0, 25, 65 },
	['indianred'] = { 0, 53, 58 },
	['brown'] = { 0, 59, 41 },
	['firebrick'] = { 0, 68, 42 },
	['lightcoral'] = { 0, 79, 72 },
	['maroon'] = { 0, 100, 25 },
	['darkred'] = { 0, 100, 27 },
	['red'] = { 0, 100, 50 },
	['snow'] = { 0, 100, 99 },
	['salmon'] = { 6, 93, 71 },
	['mistyrose'] = { 6, 100, 94 },
	['tomato'] = { 9, 100, 64 },
	['darksalmon'] = { 15, 72, 70 },
	['orangered'] = { 16, 100, 50 },
	['coral'] = { 16, 100, 66 },
	['lightsalmon'] = { 17, 100, 74 },
	['sienna'] = { 19, 56, 40 },
	['chocolate'] = { 25, 75, 47 },
	['saddlebrown'] = { 25, 76, 31 },
	['seashell'] = { 25, 100, 97 },
	['sandybrown'] = { 28, 87, 67 },
	['peachpuff'] = { 28, 100, 86 },
	['peru'] = { 30, 59, 53 },
	['linen'] = { 30, 67, 94 },
	['darkorange'] = { 33, 100, 50 },
	['bisque'] = { 33, 100, 88 },
	['tan'] = { 34, 44, 69 },
	['burlywood'] = { 34, 57, 70 },
	['antiquewhite'] = { 34, 78, 91 },
	['navajowhite'] = { 36, 100, 84 },
	['blanchedalmond'] = { 36, 100, 90 },
	['papayawhip'] = { 37, 100, 92 },
	['moccasin'] = { 38, 100, 85 },
	['wheat'] = { 39, 77, 83 },
	['oldlace'] = { 39, 85, 95 },
	['orange'] = { 39, 100, 50 },
	['floralwhite'] = { 40, 100, 97 },
	['goldenrod'] = { 43, 74, 49 },
	['darkgoldenrod'] = { 43, 89, 38 },
	['cornsilk'] = { 48, 100, 93 },
	['gold'] = { 51, 100, 50 },
	['khaki'] = { 54, 77, 75 },
	['lemonchiffon'] = { 54, 100, 90 },
	['palegoldenrod'] = { 55, 67, 80 },
	['darkkhaki'] = { 56, 38, 58 },
	['beige'] = { 60, 56, 91 },
	['lightgoldenrodyellow'] = { 60, 80, 90 },
	['olive'] = { 60, 100, 25 },
	['yellow'] = { 60, 100, 50 },
	['lightyellow'] = { 60, 100, 94 },
	['ivory'] = { 60, 100, 97 },
	['olivedrab'] = { 80, 60, 35 },
	['yellowgreen'] = { 80, 61, 50 },
	['darkolivegreen'] = { 82, 39, 30 },
	['greenyellow'] = { 84, 100, 59 },
	['lawngreen'] = { 90, 100, 49 },
	['chartreuse'] = { 90, 100, 50 },
	['darkseagreen'] = { 120, 25, 65 },
	['forestgreen'] = { 120, 61, 34 },
	['limegreen'] = { 120, 61, 50 },
	['lightgreen'] = { 120, 73, 75 },
	['palegreen'] = { 120, 93, 79 },
	['darkgreen'] = { 120, 100, 20 },
	['green'] = { 120, 100, 25 },
	['lime'] = { 120, 100, 50 },
	['honeydew'] = { 120, 100, 97 },
	['seagreen'] = { 146, 50, 36 },
	['mediumseagreen'] = { 147, 50, 47 },
	['springgreen'] = { 150, 100, 50 },
	['mintcream'] = { 150, 100, 98 },
	['mediumspringgreen'] = { 157, 100, 49 },
	['mediumaquamarine'] = { 160, 51, 60 },
	['aquamarine'] = { 160, 100, 75 },
	['turquoise'] = { 174, 72, 56 },
	['lightseagreen'] = { 177, 70, 41 },
	['mediumturquoise'] = { 178, 60, 55 },
	['darkslategray'] = { 180, 25, 25 },
	['darkslategrey'] = { 180, 25, 25 },
	['paleturquoise'] = { 180, 65, 81 },
	['teal'] = { 180, 100, 25 },
	['darkcyan'] = { 180, 100, 27 },
	['cyan'] = { 180, 100, 50 },
	['aqua'] = { 180, 100, 50 },
	['lightcyan'] = { 180, 100, 94 },
	['azure'] = { 180, 100, 97 },
	['darkturquoise'] = { 181, 100, 41 },
	['cadetblue'] = { 182, 25, 50 },
	['powderblue'] = { 187, 52, 80 },
	['lightblue'] = { 195, 53, 79 },
	['deepskyblue'] = { 195, 100, 50 },
	['skyblue'] = { 197, 71, 73 },
	['lightskyblue'] = { 203, 92, 75 },
	['steelblue'] = { 207, 44, 49 },
	['aliceblue'] = { 208, 100, 97 },
	['slategray'] = { 210, 13, 50 },
	['slategrey'] = { 210, 13, 50 },
	['lightslategrey'] = { 210, 14, 53 },
	['lightslategray'] = { 210, 14, 53 },
	['dodgerblue'] = { 210, 100, 56 },
	['lightsteelblue'] = { 214, 41, 78 },
	['cornflowerblue'] = { 219, 79, 66 },
	['royalblue'] = { 225, 73, 57 },
	['midnightblue'] = { 240, 64, 27 },
	['lavender'] = { 240, 67, 94 },
	['navy'] = { 240, 100, 25 },
	['darkblue'] = { 240, 100, 27 },
	['mediumblue'] = { 240, 100, 40 },
	['blue'] = { 240, 100, 50 },
	['ghostwhite'] = { 240, 100, 99 },
	['darkslateblue'] = { 248, 39, 39 },
	['slateblue'] = { 248, 53, 58 },
	['mediumslateblue'] = { 249, 80, 67 },
	['mediumpurple'] = { 260, 60, 65 },
	['blueviolet'] = { 271, 76, 53 },
	['indigo'] = { 275, 100, 25 },
	['darkorchid'] = { 280, 61, 50 },
	['darkviolet'] = { 282, 100, 41 },
	['mediumorchid'] = { 288, 59, 58 },
	['thistle'] = { 300, 24, 80 },
	['plum'] = { 300, 47, 75 },
	['violet'] = { 300, 76, 72 },
	['purple'] = { 300, 100, 25 },
	['darkmagenta'] = { 300, 100, 27 },
	['fuchsia'] = { 300, 100, 50 },
	['magenta'] = { 300, 100, 50 },
	['orchid'] = { 302, 59, 65 },
	['mediumvioletred'] = { 322, 81, 43 },
	['deeppink'] = { 328, 100, 54 },
	['hotpink'] = { 330, 100, 71 },
	['palevioletred'] = { 340, 60, 65 },
	['lavenderblush'] = { 340, 100, 97 },
	['crimson'] = { 348, 83, 47 },
	['pink'] = { 350, 100, 88 },
	['lightpink'] = { 351, 100, 86 } }

fxColorPalette = Class { __includes = { List }, type = "fxColorPalette" }

function fxColorPalette:init(name,cfg)
	self:rename(name)
end

function fxColorPalette:addStd(name)
	if svg_color[name] then
		local tab = svg_color[name]
		local h, s, l = tab[1], tab[2], tab[3]
		self:add(fxColor(h,s,l),name)
	end
end

function fxColorPalette:addAllStd()
	for k,v in pairs(svg_color) do
		local h, s, l = v[1], v[2], v[3]
		self:add(fxColor(h,s,l),k)
	end
end

function fxColorPalette:duplicate(color)
	if type(color) == "string" then
		-- it's a string into this palette
		local e = index[name]
		return e:clone()
	else
		-- its' a color object
		return color:clone()
	end
end
