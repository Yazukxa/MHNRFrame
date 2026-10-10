local Players = game:GetService("Players")

local Framework = require(script:FindFirstAncestor("MainModule"))
local Types = require(script:FindFirstAncestor("MainModule").Types)

local ProfileStore = Framework.Packages.ProfileStore
local DataConfig = Framework.Common.DataConfig
local PlayerDataTemplate = Framework.Common.PlayerDataTemplate

local LOAD_FAILED_MESSAGE = "Your data could not be loaded. Please rejoin."
local SESSION_ENDED_MESSAGE = "Your data was opened on another server. Please rejoin."
local PATH_SEPARATOR = "."

local DataService = {
	Client = {
		Data = Framework.RemoteProperty(nil),
		Changed = Framework.RemoteSignal(),
	},
	Loaded = Framework.Signal.new() :: Types.Signal<Player, Types.PlayerData>,
	Changed = Framework.Signal.new() :: Types.Signal<Player, { string | number }, any>,
}

local playerStore = ProfileStore.New(DataConfig.StoreName, PlayerDataTemplate)
local profiles: { [Player]: any } = {}

local function toKeys(path: Types.DataPath): { string | number }
	local keys = if typeof(path) == "string" then string.split(path, PATH_SEPARATOR) else path
	if #keys == 0 or keys[1] == "" then
		error("A data path cannot be empty", 3)
	end
	return keys
end

local function onPlayerAdded(player: Player)
	local profile = playerStore:StartSessionAsync(DataConfig.KeyPrefix .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if not profile then
		player:Kick(LOAD_FAILED_MESSAGE)
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick(SESSION_ENDED_MESSAGE)
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	profiles[player] = profile
	DataService.Client.Data:SetFor(player, profile.Data)
	DataService.Loaded:Fire(player, profile.Data)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile then
		profile:EndSession()
	end
end

function DataService:GetProfile(player: Player): any
	return profiles[player]
end

function DataService:GetData(player: Player): Types.PlayerData?
	local profile = profiles[player]
	if not profile then
		return nil
	end
	return profile.Data
end

function DataService:WaitForData(player: Player): Types.PlayerData?
	local data = self:GetData(player)
	while not data and player.Parent == Players do
		task.wait()
		data = self:GetData(player)
	end
	return data
end

function DataService:Get(player: Player, path: Types.DataPath): any
	local value: any = self:GetData(player)
	for _, key in toKeys(path) do
		if typeof(value) ~= "table" then
			return nil
		end
		value = value[key]
	end
	return value
end

function DataService:Set(player: Player, path: Types.DataPath, value: any): boolean
	local keys = toKeys(path)
	local parent: any = self:GetData(player)
	if not parent then
		return false
	end

	for index = 1, #keys - 1 do
		parent = parent[keys[index]]
		if typeof(parent) ~= "table" then
			error(`"{table.concat(keys, PATH_SEPARATOR)}" is not a path in {player.Name}'s data`, 2)
		end
	end
	parent[keys[#keys]] = value

	self.Client.Changed:Fire(player, keys, value)
	self.Changed:Fire(player, keys, value)
	return true
end

function DataService:Update(player: Player, path: Types.DataPath, callback: (value: any) -> any): any
	if not self:GetData(player) then
		return nil
	end
	local value = callback(self:Get(player, path))
	self:Set(player, path, value)
	return value
end

function DataService:Increment(player: Player, path: Types.DataPath, amount: number): number?
	if not self:GetData(player) then
		return nil
	end
	local value = self:Get(player, path)
	if typeof(value) ~= "number" then
		error(`"{table.concat(toKeys(path), PATH_SEPARATOR)}" is not a number in {player.Name}'s data`, 2)
	end
	self:Set(player, path, value + amount)
	return value + amount
end

function DataService:Sync(player: Player)
	local data = self:GetData(player)
	if data then
		self.Client.Data:SetFor(player, data)
	end
end

function DataService:Start()
	Framework.OnPlayerAdded(onPlayerAdded)
	Framework.OnPlayerRemoving(onPlayerRemoving)
end

return DataService
