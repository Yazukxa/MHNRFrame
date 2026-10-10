local Types = require(script.Parent.Types)

local Trove = {}
Trove.__index = Trove

local TABLE_CLEANUP_METHODS = { "Destroy", "Disconnect", "Clean" }

local function resolveCleanupMethod(object: any, cleanupMethod: string?): string?
	local objectType = typeof(object)
	if objectType == "function" or objectType == "thread" then
		return nil
	end
	if cleanupMethod then
		return cleanupMethod
	end
	if objectType == "Instance" then
		return "Destroy"
	end
	if objectType == "RBXScriptConnection" then
		return "Disconnect"
	end
	if objectType == "table" then
		for _, methodName in TABLE_CLEANUP_METHODS do
			if typeof(object[methodName]) == "function" then
				return methodName
			end
		end
	end
	error(`Trove cannot clean up a {objectType} without a cleanup method name`, 3)
end

local function cleanUp(object: any, cleanupMethod: string?)
	local objectType = typeof(object)
	if objectType == "function" then
		object()
		return
	end
	if objectType == "thread" then
		if object == coroutine.running() then
			task.defer(pcall, task.cancel, object)
			return
		end
		pcall(task.cancel, object)
		return
	end
	object[cleanupMethod](object)
end

function Trove.new(): Types.Trove
	local self = setmetatable({
		Entries = {},
	}, Trove)
	return self :: any
end

function Trove.Add(self, object, cleanupMethod)
	table.insert(self.Entries, {
		Object = object,
		CleanupMethod = resolveCleanupMethod(object, cleanupMethod),
	})
	return object
end

function Trove.Connect(self, signal, callback)
	return self:Add(signal:Connect(callback))
end

function Trove.Extend(self)
	return self:Add(Trove.new())
end

function Trove.Remove(self, object)
	for index, entry in self.Entries do
		if entry.Object == object then
			table.remove(self.Entries, index)
			cleanUp(entry.Object, entry.CleanupMethod)
			return true
		end
	end
	return false
end

function Trove.AttachToInstance(self, instance)
	self:Connect(instance.Destroying, function()
		self:Clean()
	end)
end

function Trove.Clean(self)
	local entries = self.Entries
	self.Entries = {}
	for index = #entries, 1, -1 do
		local entry = entries[index]
		cleanUp(entry.Object, entry.CleanupMethod)
	end
end

function Trove.Destroy(self)
	self:Clean()
end

return Trove
