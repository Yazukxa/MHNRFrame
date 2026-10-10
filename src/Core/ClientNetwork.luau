local RunService = game:GetService("RunService")

local ClientRemoteProperty = require(script.Parent.ClientRemoteProperty)
local ClientRemoteSignal = require(script.Parent.ClientRemoteSignal)

local ClientNetwork = {}

local isReady = false

ClientNetwork.Accessor = setmetatable({}, {
	__index = function(_, serviceName)
		if RunService:IsServer() then
			error("Framework.Server only exists on the client. Use Framework.Services on the server.", 2)
		end
		if not isReady then
			error(
				"Framework.Server is not available until Framework.Start has run. Call Framework.WaitForStart() first.",
				2
			)
		end
		error(`Framework.Server.{serviceName} does not exist. Give the service a Client table to expose it.`, 2)
	end,
}) :: any

local function createServiceProxy(serviceFolder: Instance, properties: { any })
	local serviceProxy = {}

	for _, remote in serviceFolder:GetChildren() do
		if remote:IsA("RemoteFunction") then
			serviceProxy[remote.Name] = function(_, ...)
				return remote:InvokeServer(...)
			end
		elseif remote:GetAttribute("IsProperty") then
			local property = ClientRemoteProperty.new(remote :: RemoteEvent)
			serviceProxy[remote.Name] = property
			table.insert(properties, property)
		elseif remote:IsA("BaseRemoteEvent") then
			serviceProxy[remote.Name] = ClientRemoteSignal.new(remote :: RemoteEvent)
		end
	end

	return serviceProxy
end

function ClientNetwork.Build(frameworkModule: Instance)
	local remotesFolder = frameworkModule:WaitForChild("Remotes")
	if not remotesFolder:GetAttribute("IsReady") then
		remotesFolder:GetAttributeChangedSignal("IsReady"):Wait()
	end

	local properties = {}
	for _, serviceFolder in remotesFolder:GetChildren() do
		rawset(ClientNetwork.Accessor, serviceFolder.Name, createServiceProxy(serviceFolder, properties))
	end
	for _, property in properties do
		property:Get()
	end

	isReady = true
end

return ClientNetwork
