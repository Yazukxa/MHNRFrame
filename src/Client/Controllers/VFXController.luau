local Workspace = game:GetService("Workspace")

local Framework = require(script:FindFirstAncestor("MainModule"))
local Types = require(script:FindFirstAncestor("MainModule").Types)

local VFXService = Framework.Server.VFXService

local VFXController = {}

local ASSET_CATEGORY = "VFX"
local EFFECTS_FOLDER_NAME = "Effects"
local CLEANUP_PADDING = 0.25

local effectsFolder: Folder = nil :: any

local function getAnchorPart(target: any): BasePart?
	if typeof(target) ~= "Instance" then
		return nil
	end
	if target:IsA("BasePart") then
		return target
	end
	if target:IsA("Attachment") then
		return target:FindFirstAncestorWhichIsA("BasePart")
	end
	if target:IsA("Model") then
		local humanoid = target:FindFirstChildOfClass("Humanoid")
		local rootPart = if humanoid then humanoid.RootPart else nil
		return rootPart or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function getTargetCFrame(target: any, anchorPart: BasePart?): CFrame
	if typeof(target) == "CFrame" then
		return target
	end
	if typeof(target) == "Vector3" then
		return CFrame.new(target)
	end
	if target:IsA("Attachment") then
		return target.WorldCFrame
	end
	if anchorPart then
		return anchorPart.CFrame
	end
	return target:GetPivot()
end

local function getParts(effect: Instance): { BasePart }
	local parts = {}
	if effect:IsA("BasePart") then
		table.insert(parts, effect)
	end
	for _, descendant in effect:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	return parts
end

local function weldToAnchor(part: BasePart, anchorPart: BasePart)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = anchorPart
	weldConstraint.Part1 = part
	weldConstraint.Parent = part
end

local function destroyWithAnchor(effect: Instance, anchorPart: BasePart)
	local trove = Framework.Trove.new()
	trove:AttachToInstance(effect)
	trove:Connect(anchorPart.Destroying, function()
		effect:Destroy()
	end)
end

local function place(effect: Instance, worldCFrame: CFrame, anchorPart: BasePart?)
	if effect:IsA("Attachment") then
		effect.Parent = anchorPart or Workspace.Terrain
		effect.WorldCFrame = worldCFrame
		return
	end
	if not effect:IsA("PVInstance") then
		error(`VFX "{effect.Name}" must be an Attachment, a BasePart or a Model, not a {effect.ClassName}`, 3)
	end

	effect:PivotTo(worldCFrame)
	for _, part in getParts(effect) do
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.Anchored = anchorPart == nil
		if anchorPart then
			weldToAnchor(part, anchorPart)
		end
	end
	effect.Parent = effectsFolder

	if anchorPart then
		destroyWithAnchor(effect, anchorPart)
	end
end

local function emit(effect: Instance): number
	local particleLifetime = 0
	for _, descendant in effect:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			local emitDelay = descendant:GetAttribute("EmitDelay") or 0
			local emitCount = descendant:GetAttribute("EmitCount")
			if emitCount then
				task.delay(emitDelay, descendant.Emit, descendant, emitCount)
			end
			particleLifetime = math.max(particleLifetime, emitDelay + descendant.Lifetime.Max)
		elseif descendant:IsA("Sound") then
			descendant:Play()
		end
	end
	return particleLifetime
end

local function waitForSounds(effect: Instance)
	for _, descendant in effect:GetDescendants() do
		if descendant:IsA("Sound") and descendant.IsPlaying and not descendant.Looped then
			descendant.Ended:Wait()
		end
	end
end

local function finish(effect: Instance, particleLifetime: number)
	if not effect.Parent then
		return
	end
	for _, descendant in effect:GetDescendants() do
		if
			descendant:IsA("ParticleEmitter")
			or descendant:IsA("Beam")
			or descendant:IsA("Trail")
			or descendant:IsA("Light")
		then
			descendant.Enabled = false
		end
	end

	task.wait(particleLifetime + CLEANUP_PADDING)
	waitForSounds(effect)
	effect:Destroy()
end

local function onPlayed(effectName: string, target: Types.VFXTarget?, options: Types.VFXOptions?)
	if target == nil then
		return
	end
	VFXController:Play(effectName, target, options)
end

function VFXController:Play(effectName: string, target: Types.VFXTarget, options: Types.VFXOptions?): Instance
	local effectOptions: Types.VFXOptions = options or {}
	local effect = Framework.GetAsset(ASSET_CATEGORY, effectName):Clone()

	local anchorPart = if effectOptions.Follow == false then nil else getAnchorPart(target)
	local worldCFrame = getTargetCFrame(target, getAnchorPart(target)) * (effectOptions.Offset or CFrame.identity)
	place(effect, worldCFrame, anchorPart)

	local holdTime = effectOptions.Duration or effect:GetAttribute("Duration") or 0
	task.delay(holdTime, finish, effect, emit(effect))
	return effect
end

function VFXController:Init()
	effectsFolder = Instance.new("Folder")
	effectsFolder.Name = EFFECTS_FOLDER_NAME
	effectsFolder.Parent = Workspace
end

function VFXController:Start()
	VFXService.Played:Connect(onPlayed)
end

return VFXController
