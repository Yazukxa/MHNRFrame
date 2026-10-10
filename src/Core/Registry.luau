local Registry = {}
Registry.__index = Registry

export type Options = {
	Name: string,
	FolderPath: { string },
	ExcludedFolders: { string }?,
	UnavailableMessage: string?,
}

local function addModulesToIndex(
	index: { [string]: ModuleScript },
	container: Instance,
	bucketName: string,
	excludedFolders: { string }?
)
	for _, child in container:GetChildren() do
		if child:IsA("ModuleScript") then
			local existingModuleScript = index[child.Name]
			if existingModuleScript then
				error(
					`Framework.{bucketName} has two modules named {child.Name}: {existingModuleScript:GetFullName()} and {child:GetFullName()}`,
					0
				)
			end
			index[child.Name] = child
		elseif child:IsA("Folder") and not (excludedFolders and table.find(excludedFolders, child.Name)) then
			addModulesToIndex(index, child, bucketName, nil)
		end
	end
end

local function requireWithoutYielding(moduleScript: ModuleScript): any
	local hasFinished = false
	local wasSuccessful, result
	task.spawn(function()
		wasSuccessful, result = pcall(require, moduleScript)
		hasFinished = true
	end)

	if not hasFinished then
		error(
			`{moduleScript:GetFullName()} is still loading because it waits on something at the top of its file. Read it inside a function instead of at the top of another module.`,
			3
		)
	end
	if not wasSuccessful then
		error(result, 3)
	end
	return result
end

function Registry.new(options: Options)
	local self = setmetatable({
		Name = options.Name,
		FolderPath = options.FolderPath,
		ExcludedFolders = options.ExcludedFolders,
		UnavailableMessage = options.UnavailableMessage,
		Containers = {},
		Index = nil,
		Accessor = nil,
	}, Registry)

	self.Accessor = setmetatable({}, {
		__index = function(accessor, moduleName)
			local moduleScript = self:FindModuleScript(moduleName)
			if not moduleScript then
				error(`Framework.{options.Name}.{moduleName} does not exist`, 2)
			end
			local module = requireWithoutYielding(moduleScript)
			rawset(accessor, moduleName, module)
			return module
		end,
	})

	return self
end

function Registry.AddContainer(self, container: Instance)
	table.insert(self.Containers, container)
	self.Index = nil
end

function Registry.RebuildIndex(self)
	local index = {}
	for _, container in self.Containers do
		local root: Instance? = container
		for _, folderName in self.FolderPath do
			if not root then
				break
			end
			root = root:FindFirstChild(folderName)
		end
		if root then
			addModulesToIndex(index, root, self.Name, self.ExcludedFolders)
		end
	end
	self.Index = index
end

function Registry.FindModuleScript(self, moduleName: string): ModuleScript?
	if #self.Containers == 0 then
		error(self.UnavailableMessage, 3)
	end
	if not self.Index or not self.Index[moduleName] then
		self:RebuildIndex()
	end
	return self.Index[moduleName]
end

function Registry.LoadAll(self)
	self:RebuildIndex()

	local moduleNames = {}
	for moduleName in self.Index do
		table.insert(moduleNames, moduleName)
	end
	table.sort(moduleNames)

	local entries = {}
	for _, moduleName in moduleNames do
		local module = rawget(self.Accessor, moduleName)
		if module == nil then
			module = require(self.Index[moduleName])
			rawset(self.Accessor, moduleName, module)
		end
		table.insert(entries, {
			Name = moduleName,
			Module = module,
		})
	end
	return entries
end

return Registry
