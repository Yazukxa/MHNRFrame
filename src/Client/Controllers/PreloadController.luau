local ContentProvider = game:GetService("ContentProvider")

local Framework = require(script:FindFirstAncestor("MainModule"))
local Types = require(script:FindFirstAncestor("MainModule").Types)

local PreloadConfig = Framework.Common.PreloadConfig

local PreloadController = {
	LoadedCount = 0,
	TotalCount = 0,
	IsComplete = false,
	Progressed = Framework.Signal.new() :: Types.Signal<number, number>,
	Completed = Framework.Signal.new() :: Types.Signal<>,
}

local queue: { Instance } = {}
local queuedAssets: { [Instance]: boolean } = {}
local nextQueueIndex = 1
local hasStarted = false
local isProcessing = false

local function collectInstances(root: Instance?, className: string, assets: { Instance })
	if not root then
		return
	end
	for _, descendant in root:GetDescendants() do
		if descendant:IsA(className) then
			table.insert(assets, descendant)
		end
	end
end

local function processQueue()
	isProcessing = true
	while nextQueueIndex <= #queue do
		local lastIndex = math.min(nextQueueIndex + PreloadConfig.BatchSize - 1, #queue)
		local batch = table.move(queue, nextQueueIndex, lastIndex, 1, {})
		nextQueueIndex = lastIndex + 1

		ContentProvider:PreloadAsync(batch)
		PreloadController.LoadedCount += #batch
		PreloadController.Progressed:Fire(PreloadController.LoadedCount, PreloadController.TotalCount)
	end
	isProcessing = false

	PreloadController.IsComplete = true
	PreloadController.Completed:Fire()
end

function PreloadController:Queue(assets: { Instance })
	for _, asset in assets do
		if not queuedAssets[asset] then
			queuedAssets[asset] = true
			table.insert(queue, asset)
			self.TotalCount += 1
		end
	end

	if not hasStarted or isProcessing then
		return
	end
	if nextQueueIndex > #queue then
		return
	end
	self.IsComplete = false
	task.spawn(processQueue)
end

function PreloadController:WaitUntilComplete()
	if self.IsComplete then
		return
	end
	self.Completed:Wait()
end

function PreloadController:Start()
	local assets = {}
	if PreloadConfig.Animations then
		collectInstances(Framework.Assets:FindFirstChild("Animations"), "Animation", assets)
	end
	if PreloadConfig.Sounds then
		collectInstances(Framework.Assets:FindFirstChild("Sounds"), "Sound", assets)
		collectInstances(Framework.Assets:FindFirstChild("VFX"), "Sound", assets)
	end

	hasStarted = true
	self:Queue(assets)
	if isProcessing then
		return
	end
	self.IsComplete = true
	self.Completed:Fire()
end

return PreloadController
