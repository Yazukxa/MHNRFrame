local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local AssetRegistry = require(script.Parent.AssetRegistry)
local ClientNetwork = require(script.Parent.ClientNetwork)
local Environment = require(script.Parent.Environment)
local Registry = require(script.Parent.Registry)
local ServerNetwork = require(script.Parent.ServerNetwork)
local Signal = require(script.Parent.Signal)

local Loader = {}

local NOT_STARTED = "is not available until the framework has started. Call Framework.WaitForStart() first."
local REPLICA_ATTRIBUTE = "IsReplica"

local isServer = RunService:IsServer()
local frameworkModule = script.Parent.Parent

if isServer and frameworkModule:GetAttribute(REPLICA_ATTRIBUTE) then
	error(
		`{frameworkModule:GetFullName()} is the copy made for clients. On the server, require the original module instead.`,
		0
	)
end

local hasStartBeenCalled = false
local hasStarted = false
local started = Signal.new()

local SHARED_PATH = { "Common", "Shared" }
local ASSETS_FOLDER_NAME = "Assets"

local services = Registry.new({
	Name = "Services",
	FolderPath = { "Services" },
	UnavailableMessage = if isServer
		then `Framework.Services {NOT_STARTED}`
		else "Framework.Services only exists on the server. Use Framework.Server to reach a service from the client.",
})
local controllers = Registry.new({
	Name = "Controllers",
	FolderPath = { "Controllers" },
	UnavailableMessage = if isServer
		then "Framework.Controllers only exists on the client."
		else `Framework.Controllers {NOT_STARTED}`,
})
local modules = Registry.new({
	Name = "Modules",
	FolderPath = { "Modules" },
	UnavailableMessage = `Framework.Modules {NOT_STARTED}`,
})
local common = Registry.new({
	Name = "Common",
	FolderPath = { "Common" },
	ExcludedFolders = { "Shared" },
})
local shared = Registry.new({
	Name = "Shared",
	FolderPath = SHARED_PATH,
	ExcludedFolders = { ASSETS_FOLDER_NAME },
})
local packages = Registry.new({
	Name = "Packages",
	FolderPath = { "Packages" },
})

common:AddContainer(frameworkModule)
shared:AddContainer(frameworkModule)
packages:AddContainer(frameworkModule)

local function ensureFolder(parent: Instance, folderName: string): Instance
	local existingFolder = parent:FindFirstChild(folderName)
	if existingFolder then
		return existingFolder
	end
	local folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = parent
	return folder
end

local function getSharedRoot(root: Instance): Instance
	local sharedRoot = root
	for _, folderName in SHARED_PATH do
		sharedRoot = if isServer then ensureFolder(sharedRoot, folderName) else sharedRoot:WaitForChild(folderName)
	end
	return sharedRoot
end

local sharedRoot = getSharedRoot(frameworkModule)
local serverRoot = if isServer then frameworkModule:FindFirstChild("Server") else nil
local assets = if isServer
	then ensureFolder(sharedRoot, ASSETS_FOLDER_NAME)
	else sharedRoot:WaitForChild(ASSETS_FOLDER_NAME)
local serverAssets = if serverRoot then ensureFolder(serverRoot, ASSETS_FOLDER_NAME) else nil

if serverRoot then
	packages:AddContainer(serverRoot)
end
rawset(shared.Accessor, ASSETS_FOLDER_NAME, assets)
AssetRegistry.SetRoot(assets)

Loader.Services = services.Accessor :: any
Loader.Controllers = controllers.Accessor :: any
Loader.Modules = modules.Accessor :: any
Loader.Shared = shared.Accessor :: any
Loader.Common = common.Accessor :: any
Loader.Packages = packages.Accessor :: any
Loader.Assets = assets :: any
Loader.ServerAssets = serverAssets :: any

local function sortByDependencies(entries, bucketName: string)
	local entriesByName = {}
	for _, entry in entries do
		entriesByName[entry.Name] = entry
	end

	local sortedEntries = {}
	local visitStates = {}

	local function visit(entry, dependencyChain: string)
		if visitStates[entry.Name] == "Visited" then
			return
		end
		if visitStates[entry.Name] == "Visiting" then
			error(`Circular dependency in Framework.{bucketName}: {dependencyChain}`, 0)
		end
		visitStates[entry.Name] = "Visiting"

		local dependencies = if typeof(entry.Module) == "table" then entry.Module.Dependencies else nil
		if typeof(dependencies) == "table" then
			for _, dependencyName in dependencies do
				local dependency = entriesByName[dependencyName]
				if not dependency then
					error(`{entry.Name} depends on {dependencyName}, which is not in Framework.{bucketName}`, 0)
				end
				visit(dependency, `{dependencyChain} -> {dependencyName}`)
			end
		end

		visitStates[entry.Name] = "Visited"
		table.insert(sortedEntries, entry)
	end

	for _, entry in entries do
		visit(entry, entry.Name)
	end
	return sortedEntries
end

local function initialize(entries)
	for _, entry in entries do
		local module = entry.Module
		if typeof(module) == "table" and typeof(module.Init) == "function" then
			module.Init(module)
		end
	end
end

local function start(entries)
	for _, entry in entries do
		local module = entry.Module
		if typeof(module) == "table" and typeof(module.Start) == "function" then
			task.spawn(module.Start, module)
		end
	end
end

local function assertServerOnlyLocation()
	if not frameworkModule:IsDescendantOf(game) then
		return
	end
	if frameworkModule:IsDescendantOf(ServerScriptService) or frameworkModule:IsDescendantOf(ServerStorage) then
		return
	end
	error(
		`{frameworkModule:GetFullName()} must live in ServerScriptService or ServerStorage so its Server folder is never sent to players`,
		0
	)
end

local function cloneWithout(excludedInstances: { Instance }): Instance
	local archivableStates = {}
	for _, excludedInstance in excludedInstances do
		archivableStates[excludedInstance] = excludedInstance.Archivable
		excludedInstance.Archivable = false
	end
	local clone = frameworkModule:Clone()
	for excludedInstance, wasArchivable in archivableStates do
		excludedInstance.Archivable = wasArchivable
	end
	return clone
end

local function createReplica(): Instance
	local excludedInstances = { assets }
	if serverRoot then
		table.insert(excludedInstances, serverRoot)
	end
	local environment = Environment.GetFolder(frameworkModule)
	if environment then
		table.insert(excludedInstances, environment)
	end

	local replica = cloneWithout(excludedInstances)
	assets.Parent = getSharedRoot(replica)
	replica:SetAttribute(REPLICA_ATTRIBUTE, true)
	replica.Parent = ReplicatedStorage
	return replica
end

local function startServer()
	assertServerOnlyLocation()
	Environment.Distribute(frameworkModule)
	local replica = createReplica()

	local serverContainer = serverRoot or Instance.new("Folder")
	modules:AddContainer(serverContainer)
	services:AddContainer(serverContainer)

	modules:LoadAll()
	local loadedServices = sortByDependencies(services:LoadAll(), "Services")

	initialize(loadedServices)
	ServerNetwork.Publish(loadedServices, replica)
	start(loadedServices)
end

local function startClient()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	ClientNetwork.Build(frameworkModule)

	local clientRoot = frameworkModule:FindFirstChild("Client") or Instance.new("Folder")
	modules:AddContainer(clientRoot)
	controllers:AddContainer(clientRoot)

	modules:LoadAll()
	local loadedControllers = sortByDependencies(controllers:LoadAll(), "Controllers")

	initialize(loadedControllers)
	start(loadedControllers)
end

function Loader.Start()
	if hasStartBeenCalled then
		return
	end
	hasStartBeenCalled = true

	if isServer then
		startServer()
	else
		startClient()
	end

	hasStarted = true
	started:Fire()
end

function Loader.WaitForStart()
	if hasStarted then
		return
	end
	started:Wait()
end

return Loader
