local CoreTypes = require(script.Parent.Core.Types)

export type Connection = CoreTypes.Connection
export type Signal<T...> = CoreTypes.Signal<T...>
export type Trove = CoreTypes.Trove
export type RemoteSignal<T...> = CoreTypes.RemoteSignal<T...>
export type RemoteProperty<Value> = CoreTypes.RemoteProperty<Value>
export type ClientRemoteSignal<T...> = CoreTypes.ClientRemoteSignal<T...>
export type ClientRemoteProperty<Value> = CoreTypes.ClientRemoteProperty<Value>

export type State<Context> = {
	Enter: ((context: Context, previousStateName: string?) -> ())?,
	Exit: ((context: Context, nextStateName: string?) -> ())?,
}

export type StateMachine<Context> = {
	Current: string?,
	Context: Context,
	Changed: Signal<string, string?>,
	Transition: (self: StateMachine<Context>, stateName: string) -> (),
	Destroy: (self: StateMachine<Context>) -> (),
}

export type StateMachineClass = {
	new: <Context>(states: { [string]: State<Context> }, context: Context) -> StateMachine<Context>,
}

export type AnimationSource = string | Animation

export type AnimationOptions = {
	FadeTime: number?,
	Weight: number?,
	Speed: number?,
	Priority: Enum.AnimationPriority?,
	Looped: boolean?,
}

export type AnimationHandler = {
	GetAnimation: (source: AnimationSource) -> Animation,
	GetTrack: (character: Model, source: AnimationSource) -> AnimationTrack?,
	Play: (character: Model, source: AnimationSource, options: AnimationOptions?) -> AnimationTrack?,
	Stop: (character: Model, source: AnimationSource, fadeTime: number?) -> (),
	StopAll: (character: Model, fadeTime: number?) -> (),
	IsPlaying: (character: Model, source: AnimationSource) -> boolean,
	Preload: (character: Model, sources: { AnimationSource }) -> (),
}

export type SoundSource = string | Sound

export type SoundOptions = {
	Volume: number?,
	PlaybackSpeed: number?,
	Looped: boolean?,
	TimePosition: number?,
}

export type SoundHandler = {
	GetSound: (source: SoundSource) -> Sound,
	Play: (source: SoundSource, parent: Instance?, options: SoundOptions?) -> Sound,
	PlayAt: (source: SoundSource, position: Vector3, options: SoundOptions?) -> Sound,
}

export type VFXTarget = CFrame | Vector3 | BasePart | Attachment | Model

export type VFXOptions = {
	Offset: CFrame?,
	Duration: number?,
	Follow: boolean?,
}

export type VFXService = {
	Play: (self: VFXService, effectName: string, target: VFXTarget, options: VFXOptions?) -> (),
	PlayFor: (
		self: VFXService,
		players: { Player },
		effectName: string,
		target: VFXTarget,
		options: VFXOptions?
	) -> (),
	PlayExcept: (
		self: VFXService,
		ignoredPlayer: Player,
		effectName: string,
		target: VFXTarget,
		options: VFXOptions?
	) -> (),
}

export type VFXController = {
	Play: (self: VFXController, effectName: string, target: VFXTarget, options: VFXOptions?) -> Instance,
}

export type PlayerData = typeof(require(script.Parent.Common.Data.PlayerDataTemplate))

export type DataPath = string | { string | number }

export type DataService = {
	Loaded: Signal<Player, PlayerData>,
	Changed: Signal<Player, { string | number }, any>,
	GetProfile: (self: DataService, player: Player) -> any,
	GetData: (self: DataService, player: Player) -> PlayerData?,
	WaitForData: (self: DataService, player: Player) -> PlayerData?,
	Get: (self: DataService, player: Player, path: DataPath) -> any,
	Set: (self: DataService, player: Player, path: DataPath, value: any) -> boolean,
	Update: (self: DataService, player: Player, path: DataPath, callback: (value: any) -> any) -> any,
	Increment: (self: DataService, player: Player, path: DataPath, amount: number) -> number?,
	Sync: (self: DataService, player: Player) -> (),
}

export type DataController = {
	IsLoaded: boolean,
	Loaded: Signal<PlayerData>,
	Changed: Signal<{ string | number }, any>,
	GetData: (self: DataController) -> PlayerData,
	Get: (self: DataController, path: DataPath) -> any,
	Observe: (self: DataController, path: DataPath, callback: (value: any) -> ()) -> Connection,
}

export type PreloadController = {
	LoadedCount: number,
	TotalCount: number,
	IsComplete: boolean,
	Progressed: Signal<number, number>,
	Completed: Signal<>,
	Queue: (self: PreloadController, assets: { Instance }) -> (),
	WaitUntilComplete: (self: PreloadController) -> (),
}

return {}
