local Workspace = game:GetService("Workspace")

local Framework = require(script:FindFirstAncestor("MainModule"))

local AnimationConfig = Framework.Common.AnimationConfig

local LEGACY_BLENDING_ATTRIBUTE = "RbxLegacyAnimationBlending"

local AnimationService = {}

function AnimationService:Init()
	Workspace:SetAttribute(LEGACY_BLENDING_ATTRIBUTE, AnimationConfig.LegacyBlending)
end

return AnimationService
