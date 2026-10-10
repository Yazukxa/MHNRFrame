local Framework = require(script:FindFirstAncestor("MainModule"))

local Cmdr = Framework.Packages.Cmdr
local AdminUtil = Framework.Shared.AdminUtil

local COMMANDS_FOLDER_NAME = "Commands"
local NO_PERMISSION_MESSAGE = "You do not have permission to run commands."

local CmdrService = {}

local function onBeforeRun(context: any): string?
	if AdminUtil.IsAdmin(context.Executor) then
		return nil
	end
	return NO_PERMISSION_MESSAGE
end

function CmdrService:Init()
	Cmdr.Registry:RegisterHook("BeforeRun", onBeforeRun)
	Cmdr.Registry:RegisterDefaultCommands()

	local serverRoot = script:FindFirstAncestor("Server")
	local commandsFolder = if serverRoot then serverRoot:FindFirstChild(COMMANDS_FOLDER_NAME) else nil
	if commandsFolder then
		Cmdr.Registry:RegisterCommandsIn(commandsFolder)
	end
end

return CmdrService
