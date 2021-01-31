--[[
MIT License

Copyright (c) 2021 JasonP, simple engine for LÖVE,
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

-- JSON support
require 'L-E-D.JSON'

-- UTILITY
function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

-- VECTOR (light)
local sqrt, cos, sin, atan2 = math.sqrt, math.cos, math.sin, math.atan2

local function str(x,y)
	return "("..tonumber(x)..","..tonumber(y)..")"
end

local function mul(s, x,y)
	return s*x, s*y
end

local function div(s, x,y)
	return x/s, y/s
end

local function add(x1,y1, x2,y2)
	return x1+x2, y1+y2
end

local function sub(x1,y1, x2,y2)
	return x1-x2, y1-y2
end

local function permul(x1,y1, x2,y2)
	return x1*x2, y1*y2
end

local function dot(x1,y1, x2,y2)
	return x1*x2 + y1*y2
end

local function det(x1,y1, x2,y2)
	return x1*y2 - y1*x2
end

local function eq(x1,y1, x2,y2)
	return x1 == x2 and y1 == y2
end

local function lt(x1,y1, x2,y2)
	return x1 < x2 or (x1 == x2 and y1 < y2)
end

local function le(x1,y1, x2,y2)
	return x1 <= x2 and y1 <= y2
end

local function len2(x,y)
	return x*x + y*y
end

local function len(x,y)
	return sqrt(x*x + y*y)
end

local function fromPolar(angle, radius)
	radius = radius or 1
	return cos(angle)*radius, sin(angle)*radius
end

local function randomDirection(len_min, len_max)
	len_min = len_min or 1
	len_max = len_max or len_min

	assert(len_max > 0, "len_max must be greater than zero")
	assert(len_max >= len_min, "len_max must be greater than or equal to len_min")

	return fromPolar(math.random()*2*math.pi,
	                 math.random() * (len_max-len_min) + len_min)
end

local function toPolar(x, y)
	return atan2(y,x), len(x,y)
end

local function dist2(x1,y1, x2,y2)
	return len2(x1-x2, y1-y2)
end

local function dist(x1,y1, x2,y2)
	return len(x1-x2, y1-y2)
end

local function normalize(x,y)
	local l = len(x,y)
	if l > 0 then
		return x/l, y/l
	end
	return x,y
end

local function rotate(phi, x,y)
	local c, s = cos(phi), sin(phi)
	return c*x - s*y, s*x + c*y
end

local function perpendicular(x,y)
	return -y, x
end

local function project(x,y, u,v)
	local s = (x*u + y*v) / (u*u + v*v)
	return s*u, s*v
end

local function mirror(x,y, u,v)
	local s = 2 * (x*u + y*v) / (u*u + v*v)
	return s*u - x, s*v - y
end

-- ref.: http://blog.signalsondisplay.com/?p=336
local function trim(maxLen, x, y)
	local s = maxLen * maxLen / len2(x, y)
	s = s > 1 and 1 or math.sqrt(s)
	return x * s, y * s
end

local function angleTo(x,y, u,v)
	if u and v then
		return atan2(y, x) - atan2(v, u)
	end
	return atan2(y, x)
end

-- the module
Vector =  {
	str = str,

	fromPolar       = fromPolar,
	toPolar         = toPolar,
	randomDirection = randomDirection,

	-- arithmetic
	mul    = mul,
	div    = div,
	idiv   = idiv,
	add    = add,
	sub    = sub,
	permul = permul,
	dot    = dot,
	det    = det,
	cross  = det,

	-- relation
	eq = eq,
	lt = lt,
	le = le,

	-- misc operations
	len2          = len2,
	len           = len,
	dist2         = dist2,
	dist          = dist,
	normalize     = normalize,
	rotate        = rotate,
	perpendicular = perpendicular,
	project       = project,
	mirror        = mirror,
	trim          = trim,
	angleTo       = angleTo,
}

-- CLASS
local function include_helper(to, from, seen)
	if from == nil then
		return to
	elseif type(from) ~= 'table' then
		return from
	elseif seen[from] then
		return seen[from]
	end

	seen[from] = to
	for k,v in pairs(from) do
		k = include_helper({}, k, seen) -- keys might also be tables
		if to[k] == nil then
			to[k] = include_helper({}, v, seen)
		end
	end
	return to
end

-- deeply copies `other' into `class'. keys in `other' that are already
-- defined in `class' are omitted
local function include(class, other)
	return include_helper(class, other, {})
end

-- returns a deep copy of `other'
local function clone(other)
	return setmetatable(include({}, other), getmetatable(other))
end

local function new(class)
	-- mixins
	class = class or {}  -- class can be nil
	local inc = class.__includes or {}
	if getmetatable(inc) then inc = {inc} end

	for _, other in ipairs(inc) do
		if type(other) == "string" then
			other = _G[other]
		end
		include(class, other)
	end

	-- class implementation
	class.__index = class
	class.init    = class.init    or class[1] or function() end
	class.include = class.include or include
	class.clone   = class.clone   or clone

	-- constructor call
	return setmetatable(class, { __call = function(c, ...)
		local o = setmetatable({}, c)
		o:init(...)
		return o
	end})
end

Class = setmetatable({new = new, include = include, clone = clone},
	{__call = function(_,...) return new(...) end})

-- some nice stuff
_INVALID = {}
_EMPTY = _INVALID

-- ENTITY
Entity = Class { type = "?", name = "?", order = 0, once = true, listening = true,
 		active = true, clck = 0.0, changed = true }
local AllNamedEntities = {}

function Entity:init(name)
	if name ~= nill then
		self:rename(name)
	end
end

-- this allows an entity to be an instance of another, calls made on self
-- that trigger __index get passed upward to the source table here
local function source_index(t,k)
	local src = rawget(t,'__source')
	if src then return src[k] else return nil end
end

function Entity:setSource(src) self.__source = src setmetatable(self, { __index = source_index }) end
function Entity:getSource() return self.__source end
function Entity:hasSource() return self.__source ~= nil end

function Entity:configFromTable(cfg)
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
	self:invalidate()
end

function Entity:integrate()
end

function Entity:disintegrate()
end

-- marking for changes
function Entity:validate() self.changed = false if self.made_valid then self:made_valid() end end
function Entity:invalidate() self.changed = true if self.made_invalid then self:made_invalid() end end
function Entity:isinvalid() return self.changed end

function Entity:toIntegrate()
	self.once = true
end

function Entity:toDisintegrate()
	self.once = true
	self:disintegrate()
end

function Entity:rename(name)
	AllNamedEntities[self.name] = nil
	self.name = name
	AllNamedEntities[self.name] = self
end

function Entity:listen(b)
	self.listening = b
end

function Entity:makeDummy(b)
	self.listening = false
	self.active = false
end

function Entity:signal(name,...)
	if name == "love_update" and self.once then
		self:integrate()
		self.once = false
	end
	if self.signal_accept and not self.signal_accept[name] then return end
	-- pass the signal to the function, if we are listening
	if self[name] and self.listening then
		if self.filter and string.starts(name,self.filter) then
			self[name](self,...)
		else
			self[name](self,...)
		end
	end
end

-- TODO: add Location
-- TODO: add Style

-- LIST
-- a list of classes, a type of collection, as is an Entity
List = Class { __includes = { Entity }, type = 'list', name = "?", ID = -1, top = 0, index = {},
		places = {}, ordered = false }
local ListID = 1
local AllLists = {}

-- create a new list, and add it to the master table of lists
function List:init(name)
	if name == nil then name = "?" end
	self:rename(name)
	self.ID = ListID
	ListID = ListID + 1
	AllLists[self.ID] = self
	AllLists[name] = self
end

-- clear the list
function List:clear()
	-- call on_clear if it is set for a contained class
	for i,v in ipairs(self.index) do
		if v.list_rem then v:list_rem(self) end
	end
	self.index = {}
	self.top = 0
end

-- add an entity to our list
function List:add(entity,name)
	self.top = self.top + 1
	self.index[self.top] = entity
	self.places[entity] = self.top
	if name then self.index[name] = entity end
	-- let the entity know it is being added to this list, if it wants that
	if entity.list_add then entity:list_add(self,name) end
end

-- add an entity to our list, before another one
function List:addBefore(entity,what,name)
	local where
	if type(what) == "string" then
		-- find by name
		where = self.index[what]
	else
		-- find by identity
		where = self.places[what]
	end
	-- insert the entity
	assert(where,"List:addBefore() doesn't have " .. tostring(what))
	table.insert(self.index,where,entity)
	if name then self.index[name] = entity end
	-- update places!
	self.top = self.top + 1
	for i=where,self.top,1 do
		self.places[self.index[i]] = i
	end
end

-- add an entity to our list, before another one
function List:addAfter(entity,what,name)
	local where
	if type(what) == "string" then
		-- find by name
		where = self.index[what]
	else
		-- find by identity
		where = self.places[what]
	end
	-- insert the entity
	assert(where,"List:addBefore() doesn't have " .. tostring(what))
	-- after the top, that's easy!
	if where == self.top then self:add(entity,name) return end
	-- less easy!
	where = where + 1
	table.insert(self.index,where,entity)
	if name then self.index[name] = entity end
	-- update places!
	self.top = self.top + 1
	for i=where,self.top,1 do
		self.places[self.index[i]] = i
	end
end

-- low level, remove an entity by id
function List:rem(id, name)
	local e = self.index[id]
	if e then
		-- let the entity know it is being removed from this list, if it wants that
		if e.list_rem then e:list_rem(self, name) end
		-- do the removal
		self.top = self.top - 1
		self.index[id] = self.index[self.top]
	end
end

-- remove an entity from our list
function List:remove(how,x)
	if how == 'name' then
		-- remove by it's name
		local e = self.index[x]
		if e then self:rem(self.places[e], name) end
	elseif how == 'class' then
		local e = self.places[x]
		if e then self:rem(e, name) end
		-- remove by class itself
		self:rem(self.places[x])
	elseif how == 'id' then
		-- remove by id number
		self:rem(x)
	else
		error("List:remove() called with bad method")
	end
end

-- pass signals to our contained classes
function List:signal(name,...)
	for _,v in ipairs(self.index) do
		if v.signal then v:signal(name,...) end
	end
end

-- pass an integrate() call to contents!
function List:integrate()
	for _,v in ipairs(self.index) do
		v:integrate()
	end
end

-- pass an integrate() call to contents!
function List:disintegrate()
	for _,v in ipairs(self.index) do
		v:disintegrate()
	end
end


-- TIMER
local _timer = {}
_timer.__index = _timer

local function _nothing_() end

local function updateTimerHandle(handle, dt)
		-- handle: {
		--   time = <number>,
		--   after = <function>,
		--   during = <function>,
		--   limit = <number>,
		--   count = <number>,
		-- }
		handle.time = handle.time + dt

		if type(handle.during) == "table" then
			handle.during:timer_during(dt, math.max(handle.limit - handle.time, 0))
		else
			handle.during(dt, math.max(handle.limit - handle.time, 0))
		end

		while handle.time >= handle.limit and handle.count > 0 do
			if type(handle.after) == table then
				if handle.after:timer_after() == false then
					handle.count = 0
					break
				end
			else
				if handle.after(handle.after) == false then
					handle.count = 0
					break
				end
			end
			handle.time = handle.time - handle.limit
			handle.count = handle.count - 1
		end
end

function _timer:update(dt)
	-- timers may create new timers, which leads to undefined behavior
	-- in pairs() - so we need to put them in a different table first
	local to_update = {}
	for handle in pairs(self.functions) do
		to_update[handle] = handle
	end

	for handle in pairs(to_update) do
		if self.functions[handle] then
			updateTimerHandle(handle, dt)
			if handle.count == 0 then
				self.functions[handle] = nil
			end
		end
	end
end

function _timer:during(delay, during, after)
	local handle = { time = 0, during = during, after = after or _nothing_, limit = delay, count = 1 }
	self.functions[handle] = true
	return handle
end

function _timer:after(delay, func)
	return self:during(delay, _nothing_, func)
end

function _timer:every(delay, after, count)
	local count = count or math.huge -- exploit below: math.huge - 1 = math.huge
	local handle = { time = 0, during = _nothing_, after = after, limit = delay, count = count }
	self.functions[handle] = true
	return handle
end

function _timer:cancel(handle)
	self.functions[handle] = nil
end

function _timer:clear()
	self.functions = {}
end

function _timer:script(f)
	local co = coroutine.wrap(f)
	co(function(t)
		self:after(t, co)
		coroutine.yield()
	end)
end

_timer.tween = setmetatable({
	-- helper functions
	out = function(f) -- 'rotates' a function
		return function(s, ...) return 1 - f(1-s, ...) end
	end,
	chain = function(f1, f2) -- concatenates two functions
		return function(s, ...) return (s < .5 and f1(2*s, ...) or 1 + f2(2*s-1, ...)) * .5 end
	end,

	-- useful tweening functions
	linear = function(s) return s end,
	quad   = function(s) return s*s end,
	cubic  = function(s) return s*s*s end,
	quart  = function(s) return s*s*s*s end,
	quint  = function(s) return s*s*s*s*s end,
	sine   = function(s) return 1-math.cos(s*math.pi/2) end,
	expo   = function(s) return 2^(10*(s-1)) end,
	circ   = function(s) return 1 - math.sqrt(1-s*s) end,

	back = function(s,bounciness)
		bounciness = bounciness or 1.70158
		return s*s*((bounciness+1)*s - bounciness)
	end,

	bounce = function(s) -- magic numbers ahead
		local a,b = 7.5625, 1/2.75
		return math.min(a*s^2, a*(s-1.5*b)^2 + .75, a*(s-2.25*b)^2 + .9375, a*(s-2.625*b)^2 + .984375)
	end,

	elastic = function(s, amp, period)
		amp, period = amp and math.max(1, amp) or 1, period or .3
		return (-amp * math.sin(2*math.pi/period * (s-1) - math.asin(1/amp))) * 2^(10*(s-1))
	end,
}, {

-- register new tween
__call = function(tween, self, len, subject, target, method, after, ...)
	-- recursively collects fields that are defined in both subject and target into a flat list
	local function tween_collect_payload(subject, target, out)
		for k,v in pairs(target) do
			local ref = subject[k]
			assert(type(v) == type(ref), 'Type mismatch in field "'..k..'".')
			if type(v) == 'table' then
				tween_collect_payload(ref, v, out)
			else
				local ok, delta = pcall(function() return (v-ref)*1 end)
				assert(ok, 'Field "'..k..'" does not support arithmetic operations')
				out[#out+1] = {subject, k, delta}
			end
		end
		return out
	end

	method = tween[method or 'linear'] -- see __index
	local payload, t, args = tween_collect_payload(subject, target, {}), 0, {...}

	local last_s = 0
	return self:during(len, function(dt)
		t = t + dt
		local s = method(math.min(1, t/len), unpack(args))
		local ds = s - last_s
		last_s = s
		for _, info in ipairs(payload) do
			local ref, key, delta = unpack(info)
			ref[key] = ref[key] + delta * ds
		end
	end, after)
end,

-- fetches function and generated compositions for method `key`
__index = function(tweens, key)
	if type(key) == 'function' then return key end

	assert(type(key) == 'string', 'Method must be function or string.')
	if rawget(tweens, key) then return rawget(tweens, key) end

	local function construct(pattern, f)
		local method = rawget(tweens, key:match(pattern))
		if method then return f(method) end
		return nil
	end

	local out, chain = rawget(tweens,'out'), rawget(tweens,'chain')
	return construct('^in%-([^-]+)$', function(...) return ... end)
	       or construct('^out%-([^-]+)$', out)
	       or construct('^in%-out%-([^-]+)$', function(f) return chain(f, out(f)) end)
	       or construct('^out%-in%-([^-]+)$', function(f) return chain(out(f), f) end)
	       or error('Unknown interpolation method: ' .. key)
end})

-- Timer instancing
function _timer.new()
	return setmetatable({functions = {}, tween = _timer.tween}, _timer)
end

-- default instance
local default = _timer.new()

-- module forwards calls to default instance
local module = {}
for k in pairs(_timer) do
	if k ~= "__index" then
		module[k] = function(...) return default[k](default, ...) end
	end
end
module.tween = setmetatable({}, {
	__index = _timer.tween,
	__newindex = function(k,v) _timer.tween[k] = v end,
	__call = function(t, ...) return default:tween(...) end,
})

Timer = setmetatable(module, {__call = _timer.new})

-- CORE
local Registry = { deferred = {} }
Registry.__index = function(self, key)
	return Registry[key] or (
		function()
			local t = {}
			rawset(self, key, t)
			return t
		end
	)()
end

-- places a signal entity/function at the end of the list
function Registry:add(s, f)
	self[s][f] = f
	table.insert(self[s],f) -- add to the end of the order normally
	return f
end

-- add before another entity/function
function Registry:addBefore(s, f, e)
	self[s][f] = f
	-- find e in the list
	for i,v in ipairs(self[s]) do
		if v == e then
			table.insert(self[s],f,i)
		end
	end
	return f
end

-- add before another entity/function
function Registry:addAfter(s, f, e)
	self[s][f] = f
	-- find e in the list
	for i,v in ipairs(self[s]) do
		if v == e then
			table.insert(self[s],f,i+1)
		end
	end
	return f
end

function Registry:emit(s, ...)
	for i,x in ipairs(self[s]) do
		if s == "love_update" then Core.HasUpdated = true
			elseif s == "love_draw" then Core.HasDrawn = true
		end
		if type(x) == "table" then x:signal(s,...) else x(s,...) end
	end
end

local function va_to_table(t, ...)
    if select('#', ...) < 2 then return end
    local function helper(x, ...)
        if select('#', ...) == 0 then
          table.insert(t,x)
        end
				table.insert(t,x)
        helper(...)
    end
    helper(...)
end

function Registry:emitDeferred(s, ...)
	local emit = {}
	emit.s = s
	va_to_table(emit,...)
	table.insert(self.deferred,emit)
end

function Registry:doDeferred()
	for _,v in ipairs(self.deferred) do
		self:emit(v.s, v[1], v[2], v[3], v[4], v[5], v[6])
	end
	self.deferred = {}
end

function Registry:remove(s, ...)
	local f = {...}
	for i = 1,select('#', ...) do
		self[s][f[i]] = nil
	end
end

function Registry:clear(...)
	local s = {...}
	for i = 1,select('#', ...) do
		self[s[i]] = {}
	end
end

function Registry:emitPattern(p, ...)
	for s in pairs(self) do
		if s:match(p) then self:emit(s, ...) end
	end
end

function Registry:registerPattern(p, f)
	for s in pairs(self) do
		if s:match(p) then self:register(s, f) end
	end
	return f
end

function Registry:removePattern(p, ...)
	for s in pairs(self) do
		if s:match(p) then self:remove(s, ...) end
	end
end

function Registry:clearPattern(p)
	for s in pairs(self) do
		if s:match(p) then self[s] = {} end
	end
end

	-- instancing
function Registry.new()
	return setmetatable({}, Registry)
end

	-- default instance
local default = Registry.new()

	-- module forwards calls to default instance
local module = {}
	for k in pairs(Registry) do
		if k ~= "__index" then
			module[k] = function(...) return default[k](default, ...) end
		end
end

Core = setmetatable(module, {})
-- setup love signals
Core.DefaultSignals = { "love_update", "love_draw", "love_errorhandler",
 		"love_threaderror", "love_quit", "love_lowmemory", "love_displayrotated", "post_update" }
Core.JoystickSignals = { "love_gamepadaxis", "love_gamepadpressed","love_gamepadreleased",
 		"love_joystickadded", "love_joystickaxis", "love_joystickhat",
		"love_joystickpressed", "love_joystickreleased", "love_joystickremoved" }
Core.WindowSignals = { "love_directorydropped", "love_filedropped", "love_focus",
		"love_mousefocus", "love_resize", "love_visible" }
Core.MouseKeyboardSignals = { "love_mousemoved", "love_mousepressed", "love_mousereleased", "love_wheelmoved",
		"love_keypressed", "love_keyreleased", "love_textedited", "love_textinput" }
-- do a little magic to put them all into an AllSignals reference
Core.AllSignals = {}
for _,v in ipairs(Core.DefaultSignals) do table.insert(Core.AllSignals, v) end
for _,v in ipairs(Core.JoystickSignals) do table.insert(Core.AllSignals, v) end
for _,v in ipairs(Core.WindowSignals) do table.insert(Core.AllSignals, v) end
for _,v in ipairs(Core.MouseKeyboardSignals) do table.insert(Core.AllSignals, v) end
Core.AllNamedEntities = AllNamedEntities
Core.AllLists = AllLists
Core.HasUpdated = false
Core.HasDrawn = false
Core.ClearScreen = true
Core.Quitting = false
Core.InternalUpdate = {}
Core.type = "L-E-D.Core"

-- add signals to a list or Entity
function Core.signalsTo(l,sigs)
	if sigs == nil then sigs = Core.DefaultSignals end
	for _,v in ipairs(sigs) do
		Core.add(v,l)
		if v == "love_update" then
			-- make sure this knows to integrate
			l:toIntegrate()
		end
	end
end

-- remove signals to a list or Entity
function Core.signalsFrom(l,sigs)
	if sigs == nil then sigs = Core.DefaultSignals end
	for _,v in ipairs(sigs) do
		Core.remove(v,l)
		if v == "love_update" then
			-- make sure this knows to integrate
			l:toDisintegrate()
		end
	end
end

function Core.findEntity(name)
	return Core.AllNamedEntities[name]
end

function Core.findList(name)
	if name == nil then name = "?" end
	return Core.AllLists[name]
end

-- RUN
function love.run()
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	return function()
		-- simple detection for a lack of uh, well game!
		Core.HasDrawn = false
		Core.HasUpdated = false

		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					-- all something to stop quitting by setting Core.Quitting to false
					Core.Quitting = true
					Core.emit("love_quit",a,b,c,d,e,f)
					if Core.Quitting then return a or 0 end
				end
				Core.emit("love_" .. name,a,b,c,d,e,f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end

		-- call internal updates
		for _,v in pairs(Core.InternalUpdate) do
			local t = type(v)
			if (t == 'table') then t:love_update(dt)
			elseif (t == 'function') then v(dt)
			end
		end
		-- update timers
		Timer.update(dt)
		-- update others
		Core.emit("love_update",dt)
		-- do any post update for internals
		Core.emit("post_update",dt)
		-- do any deferred signals
		Core.doDeferred()
		-- draw
		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			if Core.ClearScreen then love.graphics.clear(love.graphics.getBackgroundColor()) end
			Core.emit("love_draw")
			love.graphics.present()
		end
		-- quit if we have not updated or drawn anything
		if not Core.HasDrawn or not Core.HasUpdated then return 0 end
		-- be nice!
		if love.timer then love.timer.sleep(0.001) end
	end
end

-- Emitter, a class to emit timed or triggered signals
Emitter = Class { __includes = { Entity }, type = "Emitter" }

function Emitter:init(cfg)
	self:configFromTable(cfg)
end
