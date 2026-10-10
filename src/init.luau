local RunService = game:GetService("RunService")

local Core = script.Core

local AssetRegistry = require(Core.AssetRegistry)
local ClientNetwork = require(Core.ClientNetwork)
local CoreTypes = require(Core.Types)
local Index = require(script.Index)
local Loader = require(Core.Loader)
local PlayerLifecycle = require(Core.PlayerLifecycle)
local RemoteProperty = require(Core.RemoteProperty)
local RemoteSignal = require(Core.RemoteSignal)
local Signal = require(Core.Signal)
local Trove = require(Core.Trove)

local isServer = RunService:IsServer()

local Framework = {
	IsServer = isServer,
	IsClient = not isServer,

	Signal = Signal,
	Trove = Trove,

	Services = Loader.Services :: Index.Services,
	Controllers = Loader.Controllers :: Index.Controllers,
	Modules = Loader.Modules :: Index.Modules,
	Shared = Loader.Shared :: Index.Shared,
	Common = Loader.Common :: Index.Common,
	Packages = Loader.Packages :: Index.Packages,
	Server = ClientNetwork.Accessor :: Index.Server,

	Assets = Loader.Assets :: Index.Assets,
	ServerAssets = Loader.ServerAssets :: Index.ServerAssets,
}

function Framework.Start()
	Loader.Start()
end

function Framework.WaitForStart()
	Loader.WaitForStart()
end

function Framework.GetAsset(categoryName: string, assetName: string): Instance
	return AssetRegistry.Find(categoryName, assetName)
end

function Framework.RemoteSignal(isUnreliable: boolean?): CoreTypes.RemoteSignal<...any>
	if not isServer then
		error("Framework.RemoteSignal can only be created on the server", 2)
	end
	return RemoteSignal.new(isUnreliable)
end

function Framework.RemoteProperty<Value>(initialValue: Value): CoreTypes.RemoteProperty<Value>
	if not isServer then
		error("Framework.RemoteProperty can only be created on the server", 2)
	end
	return RemoteProperty.new(initialValue)
end

function Framework.OnPlayerAdded(callback: (player: Player, trove: CoreTypes.Trove) -> ()): CoreTypes.Connection
	return PlayerLifecycle.OnPlayerAdded(callback)
end

function Framework.OnPlayerRemoving(callback: (player: Player) -> ()): CoreTypes.Connection
	return PlayerLifecycle.OnPlayerRemoving(callback)
end

function Framework.OnCharacterAdded(
	callback: (character: Model, player: Player, trove: CoreTypes.Trove) -> ()
): CoreTypes.Connection
	return PlayerLifecycle.OnCharacterAdded(callback)
end

function Framework.GetPlayerTrove(player: Player): CoreTypes.Trove?
	return PlayerLifecycle.GetPlayerTrove(player)
end

function Framework.GetCharacterTrove(character: Model): CoreTypes.Trove?
	return PlayerLifecycle.GetCharacterTrove(character)
end

return Framework
