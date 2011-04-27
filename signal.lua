--[[
signal.lua
Copyright (c) 2011 Josh Tynjala
Released under the MIT license.

Based on as3-signals by Robert Penner
http://github.com/robertpenner/as3-signals
Copyright (c) 2009 Robert Penner
Released under the MIT license.
]]--
module(..., package.seeall)

local function indexOf(t, value, start)
	if start == nil then
		start = 1
	end
	for i,v in ipairs(t) do
		if i >= start and v == value then
			return i
		end
	end
	return nil
end

local listenerMT = {};

--this is used by the == comparison in indexOf
listenerMT.__eq = function (a, b)
	return a.func == b.func and a.scope == b.scope
end

local function newListener(func, scope)
	local listener =
	{
		func = func,
		scope = scope
	}
	setmetatable(listener, listenerMT)
	
	return listener
end

function new()
	local signal = {}
	local listeners = {}
	local oneTimeListeners = {}
	
	signal.numListeners = 0

	function signal:add(func, scope)
		if func == nil then
			error("Function passed to signal:add() must not non-nil.")
		end
		local listener = newListener(func, scope)
		table.insert(listeners, listener)
		self.numListeners = self.numListeners + 1
		return listener
	end
		
	function signal:addOnce(func, scope)
		local listener = self:add(listener)
		table.insert(oneTimeListeners, listener)
		return listener
	end
	
	function signal:dispatch(...)
		for i,listener in ipairs(listeners) do
			if listener.scope then
				listener.func(listener.scope, unpack(arg))
			else
				listener.func(unpack(arg))
			end
		end
		
		for i,listener in ipairs(oneTimeListeners) do
			self:remove(listener)
		end
	end
	
	function signal:remove(func, scope)
		local listener
		if type(func) == "function" then
			listener = newListener(func, scope)
		else
			--special case used by removeAll so that we don't need to create
			--a new instance of the listener
			listener = func
		end
		local index = indexOf(listeners, listener)
		if index ~= nil then
			table.remove(listeners, index)
			self.numListeners = self.numListeners - 1
			
			--check if it was a one-time listener
			index = indexOf(oneTimeListeners, listener)
			if index ~= nil then
				table.remove(oneTimeListeners, index)
			end
		end
		
	end
	
	function signal:removeAll()
		while #listeners > 0 do
			self:remove(listeners[1])
		end
	end
	
	return signal
end