local Framework = require(script:FindFirstAncestor("MainModule"))
local Types = require(script:FindFirstAncestor("MainModule").Types)

local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new<Context>(
	states: { [string]: Types.State<Context> },
	context: Context
): Types.StateMachine<Context>
	local self = setmetatable({
		Current = nil,
		Context = context,
		Changed = Framework.Signal.new(),
		States = states,
	}, StateMachine)
	return self :: any
end

function StateMachine.Transition(self, stateName: string)
	if stateName == self.Current then
		return
	end
	local nextState = self.States[stateName]
	if not nextState then
		error(`State "{stateName}" does not exist`, 2)
	end

	local previousStateName = self.Current
	local previousState = if previousStateName then self.States[previousStateName] else nil
	if previousState and previousState.Exit then
		previousState.Exit(self.Context, stateName)
	end

	self.Current = stateName
	if nextState.Enter then
		nextState.Enter(self.Context, previousStateName)
	end
	self.Changed:Fire(stateName, previousStateName)
end

function StateMachine.Destroy(self)
	local currentState = if self.Current then self.States[self.Current] else nil
	self.Current = nil
	if currentState and currentState.Exit then
		currentState.Exit(self.Context, nil)
	end
	self.Changed:Destroy()
end

return StateMachine
