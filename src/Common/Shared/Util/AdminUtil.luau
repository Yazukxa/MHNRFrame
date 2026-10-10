local AdminConfig = require(script.Parent.Parent.Parent.Config.AdminConfig)

local AdminUtil = {}

function AdminUtil.IsAdmin(player: Player): boolean
	return table.find(AdminConfig.Admins, player.UserId) ~= nil
end

return AdminUtil
