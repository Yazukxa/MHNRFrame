export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Wait: (self: Signal<T...>) -> T...,
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
	Destroy: (self: Signal<T...>) -> (),
}

export type Trove = {
	Add: <Object>(self: Trove, object: Object, cleanupMethod: string?) -> Object,
	Connect: (self: Trove, signal: any, callback: (...any) -> ()) -> any,
	Extend: (self: Trove) -> Trove,
	Remove: (self: Trove, object: any) -> boolean,
	AttachToInstance: (self: Trove, instance: Instance) -> (),
	Clean: (self: Trove) -> (),
	Destroy: (self: Trove) -> (),
}

export type RemoteSignal<T...> = {
	Connect: (self: RemoteSignal<T...>, callback: (player: Player, T...) -> ()) -> RBXScriptConnection,
	Fire: (self: RemoteSignal<T...>, player: Player, T...) -> (),
	FireAll: (self: RemoteSignal<T...>, T...) -> (),
	FireExcept: (self: RemoteSignal<T...>, ignoredPlayer: Player, T...) -> (),
	FireList: (self: RemoteSignal<T...>, players: { Player }, T...) -> (),
}

export type RemoteProperty<Value> = {
	Get: (self: RemoteProperty<Value>) -> Value,
	Set: (self: RemoteProperty<Value>, value: Value) -> (),
	GetFor: (self: RemoteProperty<Value>, player: Player) -> Value,
	SetFor: (self: RemoteProperty<Value>, player: Player, value: Value) -> (),
	ClearFor: (self: RemoteProperty<Value>, player: Player) -> (),
}

export type ClientRemoteSignal<T...> = {
	Connect: (self: ClientRemoteSignal<T...>, callback: (T...) -> ()) -> RBXScriptConnection,
	Once: (self: ClientRemoteSignal<T...>, callback: (T...) -> ()) -> RBXScriptConnection,
	Wait: (self: ClientRemoteSignal<T...>) -> T...,
	Fire: (self: ClientRemoteSignal<T...>, T...) -> (),
}

export type ClientRemoteProperty<Value> = {
	Changed: Signal<Value>,
	Get: (self: ClientRemoteProperty<Value>) -> Value,
	Observe: (self: ClientRemoteProperty<Value>, callback: (value: Value) -> ()) -> Connection,
}

return {}
