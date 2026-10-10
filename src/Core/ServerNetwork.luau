local RemoteProperty = require(script.Parent.RemoteProperty)
local RemoteSignal = require(script.Parent.RemoteSignal)

local ServerNetwork = {}

local function createServiceFolder(serviceName: string, service: any): Folder?
	if typeof(service) ~= "table" then
		return nil
	end
	local clientTable = service.Client
	if typeof(clientTable) ~= "table" then
		return nil
	end
	clientTable.Server = service

	local serviceFolder = Instance.new("Folder")
	serviceFolder.Name = serviceName

	for memberName, member in clientTable do
		if typeof(memberName) ~= "string" then
			continue
		end
		if typeof(member) == "function" then
			local remoteFunction = Instance.new("RemoteFunction")
			remoteFunction.Name = memberName
			remoteFunction.OnServerInvoke = function(player: Player, ...)
				return member(clientTable, player, ...)
			end
			remoteFunction.Parent = serviceFolder
		elseif RemoteSignal.Is(member) or RemoteProperty.Is(member) then
			member.Remote.Name = memberName
			member.Remote.Parent = serviceFolder
		end
	end

	return serviceFolder
end

function ServerNetwork.Publish(services: { { Name: string, Module: any } }, frameworkModule: Instance)
	local remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"

	for _, entry in services do
		local serviceFolder = createServiceFolder(entry.Name, entry.Module)
		if serviceFolder then
			serviceFolder.Parent = remotesFolder
		end
	end

	remotesFolder.Parent = frameworkModule
	remotesFolder:SetAttribute("IsReady", true)
end

return ServerNetwork
