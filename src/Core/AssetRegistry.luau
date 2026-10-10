local AssetRegistry = {}

local PATH_SEPARATOR = "/"

local assetsRoot: Instance = nil :: any
local indexes: { [string]: { [string]: { Instance } } } = {}

local function addAssetsToIndex(index: { [string]: { Instance } }, container: Instance)
	for _, child in container:GetChildren() do
		if child:IsA("Folder") then
			addAssetsToIndex(index, child)
			continue
		end
		local matches = index[child.Name]
		if matches then
			table.insert(matches, child)
		else
			index[child.Name] = { child }
		end
	end
end

local function getPath(asset: Instance, category: Instance): string
	local segments = { asset.Name }
	local parent = asset.Parent
	while parent and parent ~= category do
		table.insert(segments, 1, parent.Name)
		parent = parent.Parent
	end
	return table.concat(segments, PATH_SEPARATOR)
end

local function findByPath(category: Instance, assetPath: string): Instance?
	local current: Instance? = category
	for _, segment in string.split(assetPath, PATH_SEPARATOR) do
		if not current then
			return nil
		end
		current = current:FindFirstChild(segment)
	end
	return current
end

local function findByName(category: Instance, assetName: string): { Instance }?
	local index = indexes[category.Name]
	local matches = if index then index[assetName] else nil
	if matches and matches[1]:IsDescendantOf(category) then
		return matches
	end

	local rebuiltIndex = {}
	addAssetsToIndex(rebuiltIndex, category)
	indexes[category.Name] = rebuiltIndex
	return rebuiltIndex[assetName]
end

function AssetRegistry.SetRoot(root: Instance)
	assetsRoot = root
end

function AssetRegistry.Find(categoryName: string, assetName: string): Instance
	local category = assetsRoot:FindFirstChild(categoryName)
	if not category then
		error(`Assets.{categoryName} does not exist`, 3)
	end

	if string.find(assetName, PATH_SEPARATOR, 1, true) then
		local asset = findByPath(category, assetName)
		if not asset then
			error(`"{assetName}" does not exist in Assets.{categoryName}`, 3)
		end
		return asset
	end

	local matches = findByName(category, assetName)
	if not matches then
		error(`"{assetName}" does not exist in Assets.{categoryName}`, 3)
	end
	if #matches > 1 then
		error(
			`"{assetName}" exists {#matches} times in Assets.{categoryName}. Use its path instead, such as "{getPath(
				matches[1],
				category
			)}"`,
			3
		)
	end
	return matches[1]
end

return AssetRegistry
