--[[
MIT License

Copyright (c) 2021 JasonP, simple camera for LÖVE
adapted from hump by Matthias Richter Copyright (c) 2010-2013

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

assert(Class, "L-E-D.fxcamera must be included after L-E-D.core")

fxCamera = Class { __includes = { Entity } }

local cos, sin = math.cos, math.sin

local function _smooth_none()
	return function(dx,dy) return dx,dy end
end

local function _smooth_linear(speed)
	assert(type(speed) == "number", "Invalid parameter: speed = "..tostring(speed))
	return function(dx,dy, s)
		-- normalize direction
		local d = math.sqrt(dx*dx+dy*dy)
		local dts = math.min((s or speed) * love.timer.getDelta(), d) -- prevent overshooting the goal
		if d > 0 then
			dx,dy = dx/d, dy/d
		end

		return dx*dts, dy*dts
	end
end

local function _smooth_damped(stiffness)
	assert(type(stiffness) == "number", "Invalid parameter: stiffness = "..tostring(stiffness))
	return function(dx,dy, s)
		local dts = love.timer.getDelta() * (s or stiffness)
		return dx*dts, dy*dts
	end
end

fxCameraSmooth = { none = _smooth_none, linear = _smooth_linear, damped = _smooth_damped }

function fxCamera:init(x, y, zoom, rot, smoother)
	x,y  = x or love.graphics.getWidth()/2, y or love.graphics.getHeight()/2
	zoom = zoom or 1
	rot  = rot or 0
	smoother = smoother or _smooth_none() -- for locking, see below
	self:screen() -- the whole screen, by default
end

function fxCamera:screen(x, y, w, h)
	self.sx,self.sy = x or 0, y or 0
	self.sw,self.sh = w or love.graphics.getWidth(), h or love.graphics.getHeight()
end

function fxCamera:lookAt(x, y)
	self.x, self.y = x, y
end

function fxCamera:move(dx, dy)
	self.x, self.y = self.x + dx, self.y + dy
end

function fxCamera:position()
	return self.x, self.y
end

function fxCamera:rotate(phi)
	self.rot = self.rot + phi
end

function fxCamera:rotateTo(phi)
	self.rot = phi
end

function fxCamera:zoom(mul)
	self.scale = self.scale * mul
end

function fxCamera:zoomTo(zoom)
	self.scale = zoom
end

function fxCamera:enter()
	x,y = x or 0, y or 0
	w,h = w or love.graphics.getWidth(), h or love.graphics.getHeight()

	self._sx,self._sy,self._sw,self._sh = love.graphics.getScissor()
	if not noclip then
		love.graphics.setScissor(x,y,w,h)
	end

	local cx,cy = x+w/2, y+h/2
	love.graphics.push()
	love.graphics.translate(cx, cy)
	love.graphics.scale(self.scale)
	love.graphics.rotate(self.rot)
	love.graphics.translate(-self.x, -self.y)
end

function fxCamera:exit()
	love.graphics.pop()
	love.graphics.setScissor(self._sx,self._sy,self._sw,self._sh)
end

-- world coordinates to camera coordinates
function fxCamera:cameraCoords(x,y)
	-- x,y = ((x,y) - (self.x, self.y)):rotated(self.rot) * self.scale + center
	local c,s = cos(self.rot), sin(self.rot)
	x,y = x - self.x, y - self.y
	x,y = c*x - s*y, s*x + c*y
	return x*self.scale + self.sw/2 + self.sx, y*self.scale + self.sh/2 + self.sy
end

-- camera coordinates to world coordinates
function fxCamera:worldCoords(x,y)
	-- x,y = (((x,y) - center) / self.scale):rotated(-self.rot) + (self.x,self.y)
	local c,s = cos(-self.rot), sin(-self.rot)
	x,y = (x - self.sw/2 - self.sx) / self.scale, (y - self.sh/2 - self.sy) / self.scale
	x,y = c*x - s*y, s*x + c*y
	return x+self.x, y+self.y
end

function fxCamera:mousePosition()
	local mx,my = love.mouse.getPosition()
	return self:worldCoords(mx,my)
end

-- camera scrolling utilities
function fxCamera:lockX(x, smoother, ...)
	local dx, dy = (smoother or self.smoother)(x - self.x, self.y, ...)
	self.x = self.x + dx
	return self
end

function fxCamera:lockY(y, smoother, ...)
	local dx, dy = (smoother or self.smoother)(self.x, y - self.y, ...)
	self.y = self.y + dy
	return self
end

function fxCamera:lockPosition(x,y, smoother, ...)
	return self:move((smoother or self.smoother)(x - self.x, y - self.y, ...))
end

function fxCamera:lockWindow(x, y, x_min, x_max, y_min, y_max, smoother, ...)
	-- figure out displacement in camera coordinates
	x,y = self:cameraCoords(x,y)
	local dx, dy = 0,0
	if x < x_min then
		dx = x - x_min
	elseif x > x_max then
		dx = x - x_max
	end
	if y < y_min then
		dy = y - y_min
	elseif y > y_max then
		dy = y - y_max
	end

	-- transform displacement to movement in world coordinates
	local c,s = cos(-self.rot), sin(-self.rot)
	dx,dy = (c*dx - s*dy) / self.scale, (s*dx + c*dy) / self.scale

	-- move
	self:move((smoother or self.smoother)(dx,dy,...))
end

fxView = Class { __includes = { List }, camera = fxCamera() }
