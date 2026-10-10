local Types = require(script.Parent.Types)

export type Services = {
	DataService: Types.DataService,
	VFXService: Types.VFXService,
	[string]: any,
}

export type Controllers = {
	DataController: Types.DataController,
	PreloadController: Types.PreloadController,
	VFXController: Types.VFXController,
	[string]: any,
}

export type Modules = {
	[string]: any,
}

export type Assets = {
	Animations: any,
	VFX: any,
	Sounds: any,
	Models: any,
	UI: any,
	[string]: any,
}

export type Shared = {
	Assets: Assets,
	AdminUtil: typeof(require(script.Parent.Common.Shared.Util.AdminUtil)),
	AnimationHandler: Types.AnimationHandler,
	SoundHandler: Types.SoundHandler,
	StateMachine: Types.StateMachineClass,
	[string]: any,
}

export type Common = {
	AdminConfig: typeof(require(script.Parent.Common.Config.AdminConfig)),
	AnimationConfig: typeof(require(script.Parent.Common.Config.AnimationConfig)),
	DataConfig: typeof(require(script.Parent.Common.Config.DataConfig)),
	PreloadConfig: typeof(require(script.Parent.Common.Config.PreloadConfig)),
	PlayerDataTemplate: Types.PlayerData,
	[string]: any,
}

export type Packages = {
	Cmdr: any,
	ProfileStore: any,
	[string]: any,
}

export type Server = {
	DataService: {
		Data: Types.ClientRemoteProperty<Types.PlayerData?>,
		Changed: Types.ClientRemoteSignal<{ string | number }, any>,
	},
	VFXService: {
		Played: Types.ClientRemoteSignal<string, Types.VFXTarget, Types.VFXOptions?>,
	},
	[string]: any,
}

export type ServerAssets = {
	[string]: any,
}

return {}
