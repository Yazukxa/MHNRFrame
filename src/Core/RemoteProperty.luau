local Players = game:GetService("Players")

local Types = require(script.Parent.Types)

local RemoteProperty = {}
RemoteProperty.__index = RemoteProperty

local properties = {}

function RemoteProperty.new<Value>(initialValue: Value): Types.RemoteProperty<Value>
	local remote = Instance.new("RemoteEvent")
	remote:SetAttribute("IsProperty", true)

	local self = setmetatable({
		Remote = remote,
		Value = initialValue,
		PlayerValues = {},
	}, RemoteProperty)

	remote.OnServerEvent:Connect(function(player: Player)
		remote:FireClient(player, self:GetFor(player))
	end)

	table.insert(properties, self)
	return self :: any
end

function RemoteProperty.Is(value: any): boolean
	return typeof(value) == "table" and getmetatable(value) == RemoteProperty
end

function RemoteProperty.Get(self)
	return self.Value
end

function RemoteProperty.Set(self, value)
	self.Value = value
	table.clear(self.PlayerValues)
	self.Remote:FireAllClients(value)
end

function RemoteProperty.GetFor(self, player)
	local playerValue = self.PlayerValues[player]
	if playerValue ~= nil then
		return playerValue
	end
	return self.Value
end

function RemoteProperty.SetFor(self, player, value)
	self.PlayerValues[player] = value
	self.Remote:FireClient(player, self:GetFor(player))
end

function RemoteProperty.ClearFor(self, player)
	self:SetFor(player, nil)
end

Players.PlayerRemoving:Connect(function(player: Player)
	for _, property in properties do
		property.PlayerValues[player] = nil
	end
end)

return RemoteProperty
