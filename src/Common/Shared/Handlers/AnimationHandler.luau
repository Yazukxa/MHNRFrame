local RunService = game:GetService("RunService")

local Framework = require(script:FindFirstAncestor("MainModule"))
local Types = require(script:FindFirstAncestor("MainModule").Types)

local AnimationHandler = {}

local ASSET_CATEGORY = "Animations"
local ANIMATOR_TIMEOUT = 5

local tracksByCharacter: { [Model]: { [string]: AnimationTrack } } = {}
local ancestryConnections: { [Model]: RBXScriptConnection } = {}

local function forgetCharacter(character: Model)
	tracksByCharacter[character] = nil
	local ancestryConnection = ancestryConnections[character]
	if not ancestryConnection then
		return
	end
	ancestryConnection:Disconnect()
	ancestryConnections[character] = nil
end

local function getCharacterTracks(character: Model): { [string]: AnimationTrack }
	local existingTracks = tracksByCharacter[character]
	if existingTracks then
		return existingTracks
	end

	local tracks = {}
	tracksByCharacter[character] = tracks
	ancestryConnections[character] = character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(game) then
			forgetCharacter(character)
		end
	end)
	return tracks
end

local function getAnimator(character: Model): Animator?
	local controller: Instance? = character:FindFirstChildOfClass("Humanoid")
		or character:FindFirstChildOfClass("AnimationController")
	if not controller then
		return nil
	end

	local existingAnimator = controller:FindFirstChildOfClass("Animator")
	if existingAnimator then
		return existingAnimator
	end
	if RunService:IsClient() then
		return controller:WaitForChild("Animator", ANIMATOR_TIMEOUT) :: Animator?
	end

	local animator = Instance.new("Animator")
	animator.Parent = controller
	return animator
end

function AnimationHandler.GetAnimation(source: Types.AnimationSource): Animation
	if typeof(source) == "Instance" then
		return source
	end

	local animation = Framework.GetAsset(ASSET_CATEGORY, source)
	if not animation:IsA("Animation") then
		error(`{animation:GetFullName()} is a {animation.ClassName}, not an Animation`, 3)
	end
	return animation
end

function AnimationHandler.GetTrack(character: Model, source: Types.AnimationSource): AnimationTrack?
	local animation = AnimationHandler.GetAnimation(source)
	local tracks = getCharacterTracks(character)
	local existingTrack = tracks[animation.AnimationId]
	if existingTrack then
		return existingTrack
	end

	local animator = getAnimator(character)
	if not animator then
		return nil
	end
	local track = animator:LoadAnimation(animation)
	tracks[animation.AnimationId] = track
	return track
end

function AnimationHandler.Play(
	character: Model,
	source: Types.AnimationSource,
	options: Types.AnimationOptions?
): AnimationTrack?
	local track = AnimationHandler.GetTrack(character, source)
	if not track then
		return nil
	end

	local playOptions: Types.AnimationOptions = options or {}
	if playOptions.Priority then
		track.Priority = playOptions.Priority
	end
	if playOptions.Looped ~= nil then
		track.Looped = playOptions.Looped
	end
	track:Play(playOptions.FadeTime, playOptions.Weight, playOptions.Speed)
	return track
end

function AnimationHandler.Stop(character: Model, source: Types.AnimationSource, fadeTime: number?)
	local tracks = tracksByCharacter[character]
	if not tracks then
		return
	end
	local track = tracks[AnimationHandler.GetAnimation(source).AnimationId]
	if track then
		track:Stop(fadeTime)
	end
end

function AnimationHandler.StopAll(character: Model, fadeTime: number?)
	local tracks = tracksByCharacter[character]
	if not tracks then
		return
	end
	for _, track in tracks do
		track:Stop(fadeTime)
	end
end

function AnimationHandler.IsPlaying(character: Model, source: Types.AnimationSource): boolean
	local tracks = tracksByCharacter[character]
	if not tracks then
		return false
	end
	local track = tracks[AnimationHandler.GetAnimation(source).AnimationId]
	return track ~= nil and track.IsPlaying
end

function AnimationHandler.Preload(character: Model, sources: { Types.AnimationSource })
	for _, source in sources do
		AnimationHandler.GetTrack(character, source)
	end
end

return AnimationHandler
