local Framework = require(script:FindFirstAncestor("MainModule"))
local Types = require(script:FindFirstAncestor("MainModule").Types)

local VFXService = {
	Client = {
		Played = Framework.RemoteSignal(),
	},
}

local ASSET_CATEGORY = "VFX"

function VFXService:Play(effectName: string, target: Types.VFXTarget, options: Types.VFXOptions?)
	Framework.GetAsset(ASSET_CATEGORY, effectName)
	self.Client.Played:FireAll(effectName, target, options)
end

function VFXService:PlayFor(
	players: { Player },
	effectName: string,
	target: Types.VFXTarget,
	options: Types.VFXOptions?
)
	Framework.GetAsset(ASSET_CATEGORY, effectName)
	self.Client.Played:FireList(players, effectName, target, options)
end

function VFXService:PlayExcept(
	ignoredPlayer: Player,
	effectName: string,
	target: Types.VFXTarget,
	options: Types.VFXOptions?
)
	Framework.GetAsset(ASSET_CATEGORY, effectName)
	self.Client.Played:FireExcept(ignoredPlayer, effectName, target, options)
end

return VFXService
