local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)
local Trove = require(script.Parent.Trove)
local Types = require(script.Parent.Types)

local PlayerLifecycle = {}

local isServer = RunService:IsServer()

local playerTroves: { [Player]: Types.Trove } = {}
local characterTroves: { [Model]: Types.Trove } = {}
local characterOwners: { [Model]: Player } = {}

local playerAdded: Types.Signal<Player, Types.Trove> = Signal.new()
local playerRemoving: Types.Signal<Player> = Signal.new()
local characterAdded: Types.Signal<Model, Player, Types.Trove> = Signal.new()

local function onCharacterRemoving(character: Model)
	local characterTrove = characterTroves[character]
	if not characterTrove then
		return
	end
	characterTroves[character] = nil
	characterOwners[character] = nil
	characterTrove:Clean()
end

local function onCharacterAdded(player: Player, character: Model)
	if characterTroves[character] then
		return
	end
	local characterTrove = Trove.new()
	characterTroves[character] = characterTrove
	characterOwners[character] = player
	characterAdded:Fire(character, player, characterTrove)
end

local function onPlayerAdded(player: Player)
	if playerTroves[player] then
		return
	end
	local playerTrove = Trove.new()
	playerTroves[player] = playerTrove
	playerAdded:Fire(player, playerTrove)

	if not isServer and player ~= Players.LocalPlayer then
		return
	end
	playerTrove:Connect(player.CharacterAdded, function(character: Model)
		onCharacterAdded(player, character)
	end)
	playerTrove:Connect(player.CharacterRemoving, onCharacterRemoving)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player: Player)
	local playerTrove = playerTroves[player]
	if not playerTrove then
		return
	end
	playerRemoving:Fire(player)

	for character, owner in characterOwners do
		if owner == player then
			onCharacterRemoving(character)
		end
	end
	playerTroves[player] = nil
	playerTrove:Clean()
end

function PlayerLifecycle.OnPlayerAdded(callback: (player: Player, trove: Types.Trove) -> ()): Types.Connection
	local existingPlayerTroves = table.clone(playerTroves)
	local connection = playerAdded:Connect(callback)
	for player, playerTrove in existingPlayerTroves do
		task.spawn(callback, player, playerTrove)
	end
	return connection
end

function PlayerLifecycle.OnPlayerRemoving(callback: (player: Player) -> ()): Types.Connection
	return playerRemoving:Connect(callback)
end

function PlayerLifecycle.OnCharacterAdded(
	callback: (character: Model, player: Player, trove: Types.Trove) -> ()
): Types.Connection
	local existingCharacterTroves = table.clone(characterTroves)
	local existingCharacterOwners = table.clone(characterOwners)
	local connection = characterAdded:Connect(callback)
	for character, characterTrove in existingCharacterTroves do
		task.spawn(callback, character, existingCharacterOwners[character], characterTrove)
	end
	return connection
end

function PlayerLifecycle.GetPlayerTrove(player: Player): Types.Trove?
	return playerTroves[player]
end

function PlayerLifecycle.GetCharacterTrove(character: Model): Types.Trove?
	return characterTroves[character]
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

return PlayerLifecycle
