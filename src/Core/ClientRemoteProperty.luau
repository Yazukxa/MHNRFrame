local Signal = require(script.Parent.Signal)
local Types = require(script.Parent.Types)

local ClientRemoteProperty = {}
ClientRemoteProperty.__index = ClientRemoteProperty

function ClientRemoteProperty.new(remote: RemoteEvent): Types.ClientRemoteProperty<any>
	local self = setmetatable({
		Changed = Signal.new(),
		Value = nil,
		IsReady = false,
	}, ClientRemoteProperty)

	remote.OnClientEvent:Connect(function(value)
		self.Value = value
		self.IsReady = true
		self.Changed:Fire(value)
	end)
	remote:FireServer()

	return self :: any
end

function ClientRemoteProperty.Get(self)
	if not self.IsReady then
		self.Changed:Wait()
	end
	return self.Value
end

function ClientRemoteProperty.Observe(self, callback)
	if self.IsReady then
		task.spawn(callback, self.Value)
	end
	return self.Changed:Connect(callback)
end

return ClientRemoteProperty
