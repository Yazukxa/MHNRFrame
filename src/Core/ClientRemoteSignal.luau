local Types = require(script.Parent.Types)

local ClientRemoteSignal = {}
ClientRemoteSignal.__index = ClientRemoteSignal

function ClientRemoteSignal.new(remote: RemoteEvent | UnreliableRemoteEvent): Types.ClientRemoteSignal<...any>
	local self = setmetatable({
		Remote = remote,
	}, ClientRemoteSignal)
	return self :: any
end

function ClientRemoteSignal.Connect(self, callback)
	return self.Remote.OnClientEvent:Connect(callback)
end

function ClientRemoteSignal.Once(self, callback)
	return self.Remote.OnClientEvent:Once(callback)
end

function ClientRemoteSignal.Wait(self)
	return self.Remote.OnClientEvent:Wait()
end

function ClientRemoteSignal.Fire(self, ...)
	self.Remote:FireServer(...)
end

return ClientRemoteSignal
