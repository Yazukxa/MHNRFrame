local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MODULE_NAME = "MainModule"

local Framework = require(ReplicatedStorage:WaitForChild(MODULE_NAME))

Framework.Start()
