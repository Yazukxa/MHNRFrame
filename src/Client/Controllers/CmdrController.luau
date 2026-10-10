local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = require(script:FindFirstAncestor("MainModule"))

local AdminConfig = Framework.Common.AdminConfig
local AdminUtil = Framework.Shared.AdminUtil

local CLIENT_MODULE_NAME = "CmdrClient"
local NO_PERMISSION_MESSAGE = "You do not have permission to run commands."

local CmdrController = {}

local function onBeforeRun(context: any): string?
	if AdminUtil.IsAdmin(context.Executor) then
		return nil
	end
	return NO_PERMISSION_MESSAGE
end

function CmdrController:Start()
	if not AdminUtil.IsAdmin(Players.LocalPlayer) then
		return
	end

	local Cmdr = require(ReplicatedStorage:WaitForChild(CLIENT_MODULE_NAME)) :: any
	Cmdr.Registry:RegisterHook("BeforeRun", onBeforeRun)
	Cmdr:SetActivationKeys(AdminConfig.ActivationKeys)
end

return CmdrController
