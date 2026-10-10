local Framework = require(script:FindFirstAncestor("MainModule"))
local Types = require(script:FindFirstAncestor("MainModule").Types)

local DataService = Framework.Server.DataService

local PATH_SEPARATOR = "."

local DataController = {
	IsLoaded = false,
	Loaded = Framework.Signal.new() :: Types.Signal<Types.PlayerData>,
	Changed = Framework.Signal.new() :: Types.Signal<{ string | number }, any>,
}

local data: any = nil

local function toKeys(path: Types.DataPath): { string | number }
	local keys = if typeof(path) == "string" then string.split(path, PATH_SEPARATOR) else path
	if #keys == 0 or keys[1] == "" then
		error("A data path cannot be empty", 3)
	end
	return keys
end

local function doPathsOverlap(firstKeys: { string | number }, secondKeys: { string | number }): boolean
	for index = 1, math.min(#firstKeys, #secondKeys) do
		if firstKeys[index] ~= secondKeys[index] then
			return false
		end
	end
	return true
end

local function onDataReceived(receivedData: Types.PlayerData?)
	if receivedData == nil then
		return
	end
	data = receivedData

	local wasLoaded = DataController.IsLoaded
	DataController.IsLoaded = true
	if not wasLoaded then
		DataController.Loaded:Fire(receivedData)
	end
	DataController.Changed:Fire({}, receivedData)
end

local function onChanged(keys: { string | number }, value: any)
	if not data then
		return
	end

	local parent = data
	for index = 1, #keys - 1 do
		parent = parent[keys[index]]
		if typeof(parent) ~= "table" then
			return
		end
	end
	parent[keys[#keys]] = value
	DataController.Changed:Fire(keys, value)
end

function DataController:GetData(): Types.PlayerData
	if not data then
		self.Loaded:Wait()
	end
	return data
end

function DataController:Get(path: Types.DataPath): any
	local value = data
	for _, key in toKeys(path) do
		if typeof(value) ~= "table" then
			return nil
		end
		value = value[key]
	end
	return value
end

function DataController:Observe(path: Types.DataPath, callback: (value: any) -> ()): Types.Connection
	local observedKeys = toKeys(path)
	if data then
		task.spawn(callback, self:Get(observedKeys))
	end
	return self.Changed:Connect(function(changedKeys)
		if doPathsOverlap(changedKeys, observedKeys) then
			callback(self:Get(observedKeys))
		end
	end)
end

function DataController:Start()
	DataService.Changed:Connect(onChanged)
	DataService.Data:Observe(onDataReceived)
end

return DataController
