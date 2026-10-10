local Types = require(script.Parent.Types)

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

local freeRunnerThread: thread? = nil

local function runCallback(callback, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	callback(...)
	freeRunnerThread = acquiredRunnerThread
end

local function runCallbacksForever()
	while true do
		runCallback(coroutine.yield())
	end
end

local function createRunnerThread(): thread
	local runnerThread = coroutine.create(runCallbacksForever)
	coroutine.resume(runnerThread)
	return runnerThread
end

local function getWritableConnections(signal)
	if signal.FiringDepth > 0 then
		signal.Connections = table.clone(signal.Connections)
	end
	return signal.Connections
end

function Connection.Disconnect(self)
	if not self.Connected then
		return
	end
	self.Connected = false

	local connections = getWritableConnections(self.Signal)
	local index = table.find(connections, self)
	if index then
		table.remove(connections, index)
	end
end

function Signal.new<T...>(): Types.Signal<T...>
	local self = setmetatable({
		Connections = {},
		FiringDepth = 0,
	}, Signal)
	return self :: any
end

function Signal.Connect(self, callback)
	local connection = setmetatable({
		Connected = true,
		Signal = self,
		Callback = callback,
	}, Connection)
	table.insert(getWritableConnections(self), connection)
	return connection
end

function Signal.Once(self, callback)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

function Signal.Wait(self)
	local waitingThread = coroutine.running()
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(waitingThread, ...)
	end)
	return coroutine.yield()
end

function Signal.Fire(self, ...)
	local connections = self.Connections
	self.FiringDepth += 1
	for _, connection in connections do
		if connection.Connected then
			local runnerThread = freeRunnerThread or createRunnerThread()
			freeRunnerThread = runnerThread
			task.spawn(runnerThread, connection.Callback, ...)
		end
	end
	self.FiringDepth -= 1
end

function Signal.DisconnectAll(self)
	for _, connection in self.Connections do
		connection.Connected = false
	end
	self.Connections = {}
end

function Signal.Destroy(self)
	self:DisconnectAll()
end

return Signal
