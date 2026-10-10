local Players = game:GetService("Players")

local Types = require(script.Parent.Types)

local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal

function RemoteSignal.new(isUnreliable: boolean?): Types.RemoteSignal<...any>
	local self = setmetatable({
		Remote = Instance.new(if isUnreliable then "UnreliableRemoteEvent" else "RemoteEvent"),
	}, RemoteSignal)
	return self :: any
end

function RemoteSignal.Is(value: any): boolean
	return typeof(value) == "table" and getmetatable(value) == RemoteSignal
end

function RemoteSignal.Connect(self, callback)
	return self.Remote.OnServerEvent:Connect(callback)
end

function RemoteSignal.Fire(self, player, ...)
	self.Remote:FireClient(player, ...)
end

function RemoteSignal.FireAll(self, ...)
	self.Remote:FireAllClients(...)
end

function RemoteSignal.FireExcept(self, ignoredPlayer, ...)
	for _, player in Players:GetPlayers() do
		if player ~= ignoredPlayer then
			self.Remote:FireClient(player, ...)
		end
	end
end

function RemoteSignal.FireList(self, players, ...)
	for _, player in players do
		self.Remote:FireClient(player, ...)
	end
end

return RemoteSignal
