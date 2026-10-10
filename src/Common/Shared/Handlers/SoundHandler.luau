local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Framework = require(script:FindFirstAncestor("MainModule"))
local Types = require(script:FindFirstAncestor("MainModule").Types)

local SoundHandler = {}

local ASSET_CATEGORY = "Sounds"

function SoundHandler.GetSound(source: Types.SoundSource): Sound
	if typeof(source) == "Instance" then
		return source
	end

	local sound = Framework.GetAsset(ASSET_CATEGORY, source)
	if not sound:IsA("Sound") then
		error(`{sound:GetFullName()} is a {sound.ClassName}, not a Sound`, 3)
	end
	return sound
end

function SoundHandler.Play(source: Types.SoundSource, parent: Instance?, options: Types.SoundOptions?): Sound
	local soundOptions: Types.SoundOptions = options or {}
	local sound = SoundHandler.GetSound(source):Clone()
	if soundOptions.Volume then
		sound.Volume = soundOptions.Volume
	end
	if soundOptions.PlaybackSpeed then
		sound.PlaybackSpeed = soundOptions.PlaybackSpeed
	end
	if soundOptions.Looped ~= nil then
		sound.Looped = soundOptions.Looped
	end
	if soundOptions.TimePosition then
		sound.TimePosition = soundOptions.TimePosition
	end

	sound.Parent = parent or SoundService
	sound:Play()
	if not sound.Looped then
		sound.Ended:Once(function()
			sound:Destroy()
		end)
	end
	return sound
end

function SoundHandler.PlayAt(source: Types.SoundSource, position: Vector3, options: Types.SoundOptions?): Sound
	local attachment = Instance.new("Attachment")
	attachment.Parent = Workspace.Terrain
	attachment.WorldPosition = position

	local sound = SoundHandler.Play(source, attachment, options)
	sound.Destroying:Once(function()
		attachment:Destroy()
	end)
	return sound
end

return SoundHandler
