local Environment = {}

local FOLDER_NAME = "Environment"

local function getTargets(): { [string]: Instance? }
	return {
		StarterGui = game:GetService("StarterGui"),
		StarterPlayerScripts = game:GetService("StarterPlayer"):FindFirstChildOfClass("StarterPlayerScripts"),
	}
end

function Environment.GetFolder(frameworkModule: Instance): Instance?
	return frameworkModule:FindFirstChild(FOLDER_NAME)
end

function Environment.Distribute(frameworkModule: Instance)
	local environment = Environment.GetFolder(frameworkModule)
	if not environment then
		return
	end

	local movedInstances: { [Instance]: boolean } = {}
	for folderName, target in getTargets() do
		local source = environment:FindFirstChild(folderName)
		if not source or not target then
			continue
		end
		for _, child in source:GetChildren() do
			local existingChild = target:FindFirstChild(child.Name)
			if existingChild and not movedInstances[existingChild] then
				existingChild:Destroy()
			end
			child.Parent = target
			movedInstances[child] = true
		end
	end
end

return Environment
