# MHNRFrame

One `MainModule` that holds the whole game. Pure Luau, no dependencies, no `--!strict`.

Full documentation: [yazukxa.github.io/MHNRFrame](https://yazukxa.github.io/MHNRFrame/)

`MainModule` sits in **ServerScriptService** next to `Loader`, the one script that starts it:

```lua
local Framework = require(script.Parent.MainModule)

Framework.Start()
```

Nothing else to wire up. The module does nothing until that runs.

## Layout

```
ServerScriptService
├── Loader                     starts the module
└── MainModule                 the framework, and the thing every script requires
    ├── Core                   framework internals, leave alone
    ├── Types                  global types for the whole game
    ├── Index                  what each Framework.X.Y is, for autocomplete
    ├── Common                 everything both sides use
    │   ├── Config             AdminConfig, AnimationConfig, DataConfig, PreloadConfig
    │   ├── Data               PlayerDataTemplate
    │   ├── Enums
    │   └── Shared
    │       ├── Assets         instances every player gets
    │       │   ├── Animations
    │       │   ├── VFX
    │       │   ├── Sounds
    │       │   ├── Models
    │       │   └── UI
    │       ├── Handlers       AnimationHandler, SoundHandler
    │       ├── Classes        StateMachine
    │       └── Util           AdminUtil
    ├── Packages               third-party libraries
    ├── Environment            things that belong in Roblox's own containers
    │   ├── StarterGui
    │   └── StarterPlayerScripts   ClientLoader, boots the client
    ├── Client
    │   ├── Controllers        CmdrController, DataController, PreloadController, VFXController
    │   └── Modules            client-only helpers
    │       └── UI
    └── Server
        ├── Assets             instances only the server gets
        ├── Commands           your own Cmdr commands
        ├── Packages           server-only libraries: Cmdr, ProfileStore
        ├── Services           AnimationService, CmdrService, DataService, VFXService
        └── Modules            server-only helpers and classes
```

When the server starts, the framework copies itself into `ReplicatedStorage.MainModule` **without the `Server` folder**. That copy is what clients run. Anything under `Server` never leaves the server; everything else is visible to players, so keep secrets under `Server`.

At the same moment, everything in `Environment/StarterGui` and `Environment/StarterPlayerScripts` is moved into the real StarterGui and StarterPlayerScripts.

`Assets` is moved into that copy rather than duplicated, so always reach it through `Framework.Assets`, never by path.

Subfolders are fine anywhere. Folders are searched, so `Common/Config/AnimationConfig` is still `Framework.Common.AnimationConfig`. Names must be unique inside a bucket. A ModuleScript's own children are private to it and are not picked up.

`Shared` sits inside `Common` but is its own bucket: modules under `Common/Shared` are `Framework.Shared.Name`, everything else under `Common` is `Framework.Common.Name`. Modules inside `Assets` are never picked up.

## The one line

Every module starts with this, wherever it sits:

```lua
local Framework = require(script:FindFirstAncestor("MainModule"))
```

`require(script.Parent.Parent.Parent)` works too if you prefer counting parents. Types through the first form are confirmed in VS Code (luau-lsp). If Studio's own editor does not autocomplete through it, use the parents form there.

A server Script outside the MainModule:

```lua
local Framework = require(game.ServerScriptService.MainModule)
Framework.WaitForStart()
```

A LocalScript outside the MainModule:

```lua
local Framework = require(game.ReplicatedStorage:WaitForChild("MainModule"))
Framework.WaitForStart()
```

`WaitForStart` returns once every `Start` has been kicked off. `Framework.IsServer` and `Framework.IsClient` tell a shared module which side it is on.

## Reaching things

| Access | Side | Loaded |
| --- | --- | --- |
| `Framework.Services.Name` | server | at boot |
| `Framework.Controllers.Name` | client | at boot |
| `Framework.Modules.Name` | each side has its own | at boot |
| `Framework.Shared.Name` | both | first use |
| `Framework.Common.Name` | both | first use |
| `Framework.Packages.Name` | both, plus `Server/Packages` on the server | first use |
| `Framework.Server.Name` | client | at boot, the network view of a service |
| `Framework.Assets` | both | the `Common/Shared/Assets` folder, also `Framework.Shared.Assets` |
| `Framework.GetAsset(category, name)` | both | one asset, found by name or path |
| `Framework.ServerAssets` | server | the `Server/Assets` folder, `nil` on the client |

Inside a function these are always safe. At the top of a file they also work, with one exception: a module that is still waiting on something at the top of its own file cannot be handed over half-loaded, and the error names it. Modules load before Services and Controllers, and those load alphabetically, so this only bites when one controller grabs a later, slower controller at the top of its file. Read it inside `Init` or `Start` instead.

Asking for a module name that does not exist is an error, not `nil`.

## Environment

`Environment` holds whatever has to end up in one of Roblox's own containers. It has two folders, and their names say where the contents go:

- `Environment/StarterGui` goes to StarterGui: ScreenGuis and anything else every player's PlayerGui should get.
- `Environment/StarterPlayerScripts` goes to StarterPlayerScripts: LocalScripts that run once per player. The client loader lives here.

The move happens the instant the server starts, before any player has joined. If something with the same name is already in the real container, the one from `Environment` replaces it, so a custom `PlayerModule` here wins over Roblox's default one.

Like assets, these are made in Studio and Rojo leaves them alone. Two things to know:

- A ScreenGui only shows in the Studio viewport while it sits in the real StarterGui. Drag it there to edit it, drag it back when you are done.
- A script in here is not inside the MainModule once the game is running, so it reaches the framework the way an outside script does: `require(game.ReplicatedStorage:WaitForChild("MainModule"))`, then `Framework.WaitForStart()`.

## Admin commands

Cmdr is installed. Press **F2** in game to open the console.

Only the user ids in `Common/Config/AdminConfig` can use it. For everyone else the console never opens, and the server refuses every command they send regardless.

```lua
return {
	ActivationKeys = { Enum.KeyCode.F2 },
	Admins = {
		157330543, -- blair
		89656671, -- Mitiosss
		115173677, -- wacky
	},
}
```

`Framework.Shared.AdminUtil.IsAdmin(player)` answers the same question anywhere else in the game.

All of Cmdr's built-in commands are registered: `kick`, `ban`, `kill`, `teleport`, `respawn`, `announce` and the rest. Type `help` in the console for the list.

Your own commands go in `Server/Commands`, two modules each, the way Cmdr expects: `Name` describes the command and `NameServer` does the work. The description is sent to clients; the `Server` half is not.

## Assets

Assets are made in Studio, not in files. Rojo leaves everything inside the asset folders alone, so anything you or the team drop in there stays.

Animations, sounds and effects are found by name in their folder, so nothing needs registering:

```lua
AnimationHandler.Play(character, "Punch")
SoundHandler.Play("Hit")
VFXService:Play("HitSpark", character)
```

Folders inside a category are only for organising. If the same name exists twice, give the path instead, and the error tells you which:

```lua
AnimationHandler.Play(character, "Sword/Idle")
AnimationHandler.Play(character, "Fist/Idle")
```

For anything else, `Framework.GetAsset` does the same lookup in any category, and `Framework.Assets` is the folder itself:

```lua
local sword = Framework.GetAsset("Models", "Sword"):Clone()
local hud = Framework.Assets.UI.Hud
local dummy = Framework.ServerAssets.Dummy:Clone()
```

A missing name is an error that says what it looked for and where.

### VFX templates

Put a template in `Common/Shared/Assets/VFX`. It can be an **Attachment**, a **BasePart** or a **Model**.

| Attribute | On | Meaning |
| --- | --- | --- |
| `EmitCount` | ParticleEmitter | burst this many particles when played |
| `EmitDelay` | ParticleEmitter | wait this long before the burst |
| `Duration` | the template | how long emitters, beams, trails and lights that are switched on stay on |

Sounds inside a template play with it. The effect cleans itself up once its particles and sounds have finished.

## Animation

`AnimationService` sets the Workspace attribute `RbxLegacyAnimationBlending` when the server initialises. `Common/Config/AnimationConfig` holds the switch, on by default:

```lua
return {
	LegacyBlending = true,
}
```

`AnimationHandler` plays animations on any character, on either side. It takes the name of an `Animation` in `Assets/Animations`, or the `Animation` itself, and keeps one track per animation per character.

```lua
local AnimationHandler = Framework.Shared.AnimationHandler

local track = AnimationHandler.Play(character, "Punch")
AnimationHandler.Play(character, "Idle", { Looped = true, FadeTime = 0 })
AnimationHandler.Stop(character, "Punch")
AnimationHandler.StopAll(character)
AnimationHandler.IsPlaying(character, "Punch")
AnimationHandler.GetTrack(character, "Punch")
AnimationHandler.Preload(character, { "Punch", "Kick" })
```

Options: `FadeTime`, `Weight`, `Speed`, `Priority`, `Looped`.

`Preload` loads tracks onto one character ahead of time. An Animator holds 256 tracks at most, so preload what that character uses, not everything.

## Sound

```lua
local SoundHandler = Framework.Shared.SoundHandler

SoundHandler.Play("Click")
SoundHandler.Play("Hit", character.PrimaryPart, { Volume = 0.5 })
SoundHandler.PlayAt("Explosion", position)
```

It takes the name of a `Sound` in `Assets/Sounds`, or the `Sound` itself. No parent means it plays for the listener with no position. A sound that is not looped removes itself when it ends. Options: `Volume`, `PlaybackSpeed`, `Looped`, `TimePosition`.

## VFX

On the server, for everyone:

```lua
local VFXService = Framework.Services.VFXService

VFXService:Play("HitSpark", character)
VFXService:Play("Explosion", CFrame.new(0, 5, 0))
VFXService:PlayFor({ player }, "LevelUp", character)
VFXService:PlayExcept(attacker, "Slash", character, { Offset = CFrame.new(0, 0, -2) })
```

On the client, for that player only:

```lua
local effect = Framework.Controllers.VFXController:Play("Slash", character)
```

The target is a `CFrame`, a `Vector3`, a part, an attachment or a model. Given an instance the effect follows it; pass `Follow = false` to leave it where it started. A character is followed at its root part. Options: `Offset`, `Duration`, `Follow`.

Send a character, not a `Player`. An effect aimed at something the client has not streamed in is skipped.

## Preloading

`PreloadController` loads these in the background as soon as the client starts:

- every `Animation` in `Assets/Animations`
- every `Sound` in `Assets/Sounds` and inside `Assets/VFX`

```lua
local PreloadController = Framework.Controllers.PreloadController

PreloadController.Progressed:Connect(function(loadedCount: number, totalCount: number) end)
PreloadController:WaitUntilComplete()
PreloadController:Queue({ instance, instance })
```

`Common/Config/PreloadConfig` switches animations and sounds on or off and sets the batch size.

## StateMachine

`Framework.Shared.StateMachine` works for anything on either side:

```lua
local StateMachine = Framework.Shared.StateMachine

local machine = StateMachine.new({
	Closed = {},
	Open = {
		Enter = function(door: Model, previousStateName: string?) end,
		Exit = function(door: Model, nextStateName: string?) end,
	},
}, door)

machine:Transition("Open")
machine.Current
machine.Changed:Connect(function(stateName: string, previousStateName: string?) end)
machine:Destroy()
```

The second argument is handed to every `Enter` and `Exit`. Both are optional. Moving to the state it is already in does nothing, a state name that does not exist is an error, and `Destroy` exits the current state.

## Player data

`DataService` saves player data with ProfileStore: one session per player, locked to the server they are on, saved automatically and again when they leave or the server shuts down.

**The table goes in `Common/Data/PlayerDataTemplate`.** It is empty right now. Whatever you put there is what a new player starts with, and anything you add later is filled in for existing players when they join. `Types.PlayerData` follows that table by itself, so its keys autocomplete everywhere.

Only plain values: numbers, strings, booleans and tables of those. No Instances, Vector3, CFrame or Color3, and no list with gaps.

On the server:

```lua
local DataService = Framework.Services.DataService

local data = DataService:GetData(player)
local data = DataService:WaitForData(player)

DataService:Get(player, "Stats.Level")
DataService:Set(player, "Stats.Level", 5)
DataService:Increment(player, "Coins", 25)
DataService:Update(player, "Inventory", function(inventory)
	table.insert(inventory, "Sword")
	return inventory
end)

DataService.Loaded:Connect(function(player: Player, data: Types.PlayerData) end)
DataService.Changed:Connect(function(player: Player, keys: { string | number }, value: any) end)
```

`GetData` is `nil` until the player's data has loaded and after they leave. `WaitForData` waits for it and gives `nil` if the player leaves first. `Set`, `Update` and `Increment` do nothing for a player with no data and say so: `false`, `nil`, `nil`.

Change data through `Set`, `Update` or `Increment`. They tell the client. If you edit the table directly, call `DataService:Sync(player)` afterwards to resend everything.

A path is `"Stats.Level"`, or a list of keys when one of them is a number or contains a dot: `{ "Inventory", 1 }`.

On the client, each player has a live copy of their own data and nobody else's:

```lua
local DataController = Framework.Controllers.DataController

local data = DataController:GetData()
DataController:Get("Stats.Level")
DataController:Observe("Coins", function(coins: number) end)
DataController.Changed:Connect(function(keys: { string | number }, value: any) end)
```

`GetData` waits until the data has arrived. `Observe` runs straight away with the current value, then again whenever that value, something inside it, or something it sits inside changes. The client copy is read-only: changing it does nothing on the server.

`Common/Config/DataConfig` has the DataStore name and key prefix. Changing either after launch points every player at a fresh, empty save.

In Studio, data only saves if **Enable Studio Access to API Services** is on for the place. With it off, ProfileStore keeps everything in memory for that play session and prints one line saying so.

`DataService:GetProfile(player)` is the raw ProfileStore profile for anything not covered here.

## Other data and config

Other data modules go in `Common/Data`, settings in `Common/Config`, enum tables in `Common/Enums`. Add a module to `Index` to get autocomplete on its names.

## Writing a service

`Server/Services/VFXService` is a complete one to copy from. The shape:

```lua
local Framework = require(script:FindFirstAncestor("MainModule"))

local Service = {
	Dependencies = { "OtherService" },
	Client = {
		Changed = Framework.RemoteSignal(),
		Value = Framework.RemoteProperty(0),
	},
}

function Service:Init() end

function Service:Start() end

function Service.Client:Request(player: Player, value: any): boolean
	if typeof(value) ~= "number" then
		return false
	end
	return self.Server:Handle(player, value)
end

return Service
```

A service is a plain table. Its name is the ModuleScript's name. `Init`, `Start`, `Dependencies` and `Client` are all optional. Controllers are the same thing on the client, without `Client`; `Client/Controllers/VFXController` is a complete one.

## Boot order

1. `Modules` are required.
2. `Services` (server) or `Controllers` (client) are required, alphabetically.
3. `Init` runs on each, one at a time. Anything named in `Dependencies` goes first.
4. The server publishes every `Client` table. The client waits for that before step 1.
5. `Start` runs on each, all at once.

`Init` and `Start` only run on Services and Controllers. Modules are never called, so a class in `Modules` or `Shared` can have its own `Start` or `Init` methods.

A broken `Init` stops the boot. A broken `Start` only stops that one service.

## Client and server

Whatever a service puts in `Client` is what the client sees under `Framework.Server.ServiceName`.

| In the `Client` table | Server side | Client side |
| --- | --- | --- |
| a function | `function Service.Client:Name(player, ...)` | `Service:Name(...)`, waits for the result |
| `Framework.RemoteSignal()` | `:Fire(player, ...)` `:FireAll(...)` `:FireExcept(player, ...)` `:FireList(players, ...)` `:Connect(function(player, ...))` | `:Fire(...)` `:Connect(function(...))` `:Once` `:Wait` |
| `Framework.RemoteProperty(value)` | `:Set(value)` `:SetFor(player, value)` `:Get()` `:GetFor(player)` `:ClearFor(player)` | `:Get()` `:Observe(function(value))` `.Changed` |

`Framework.RemoteSignal(true)` makes an unreliable signal for things sent every frame.

`self.Server` inside a `Client` method is the service itself.

Arguments from the client are whatever the client decided to send. Type them `any` and check them before use.

`Set` replaces the value for everyone and drops per-player values. `SetFor` gives one player their own value.

## Global types

Two files, both at the top of the MainModule.

**`Types`** is where every shared type lives. Any script can use them:

```lua
local Types = require(script:FindFirstAncestor("MainModule").Types)

local options: Types.VFXOptions = { Duration = 2 }
```

Already in there: `Signal<T...>`, `Connection`, `Trove`, `RemoteSignal<T...>`, `RemoteProperty<T>`, `ClientRemoteSignal<T...>`, `ClientRemoteProperty<T>`, `PlayerData`, `DataPath`, `DataService`, `DataController`, `State<Context>`, `StateMachine<Context>`, `AnimationSource`, `AnimationOptions`, `AnimationHandler`, `SoundSource`, `SoundOptions`, `SoundHandler`, `VFXTarget`, `VFXOptions`, `VFXService`, `VFXController`, `PreloadController`.

**`Index`** says what each `Framework.X.Y` is. Names listed there get autocomplete and checking; everything else stays loose and never errors.

```lua
export type Services = {
	VFXService: Types.VFXService,
	[string]: any,
}

export type Common = {
	AnimationConfig: typeof(require(script.Parent.Common.Config.AnimationConfig)),
	[string]: any,
}
```

Two ways to list something:

- `typeof(require(...))` for a module that does not require the framework. That is the data and config in `Common`. Those modules may still require `Types`.
- A type written in `Types` for a module that does require the framework, which is every service, controller and handler. Using `typeof(require(...))` on those sends the type checker in a circle and it gives up.

Without `--!strict`, a value you do not annotate is loose in the checker even when autocomplete shows its type.

## Classes and instance variables

Classes are ordinary Luau. Put them in `Common/Shared/Classes` or `Modules`, declare the instance type in `Types`, and every script sees the fields.

```lua
export type Enemy = {
	Health: number,
	Model: Model,
	TakeDamage: (self: Enemy, amount: number) -> (),
}
```

```lua
local Types = require(script:FindFirstAncestor("MainModule").Types)

local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(model: Model): Types.Enemy
	local self = setmetatable({
		Health = 100,
		Model = model,
	}, Enemy)
	return self :: any
end

function Enemy:TakeDamage(amount: number)
	self.Health -= amount
end

return Enemy
```

Instance references at the top of a file are fine too. Anything loaded at boot may wait while it loads:

```lua
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = PlayerGui:WaitForChild("Hud") :: ScreenGui
local CoinsLabel = ScreenGui:WaitForChild("Coins") :: TextLabel
```

## Players and characters

```lua
Framework.OnPlayerAdded(function(player: Player, trove: Types.Trove) end)
Framework.OnPlayerRemoving(function(player: Player) end)
Framework.OnCharacterAdded(function(character: Model, player: Player, trove: Types.Trove) end)
Framework.GetPlayerTrove(player)
Framework.GetCharacterTrove(character)
```

Players and characters that already exist are passed in straight away. The player trove is cleaned when the player leaves, the character trove when the character is removed.

On the client `OnPlayerAdded` covers everyone, `OnCharacterAdded` covers only your own character.

## Signal and Trove

```lua
local changed: Types.Signal<number> = Framework.Signal.new()
local connection = changed:Connect(function(value: number) end)
changed:Once(function(value: number) end)
changed:Fire(5)
local value = changed:Wait()
connection:Disconnect()
changed:DisconnectAll()
```

```lua
local trove = Framework.Trove.new()
trove:Add(instance)
trove:Add(function() end)
trove:Add(object, "MethodName")
trove:Connect(signal, callback)
local child = trove:Extend()
trove:AttachToInstance(instance)
trove:Remove(object)
trove:Clean()
```

A trove cleans up Instances, connections, functions, threads, and any table with `Destroy`, `Disconnect` or `Clean`.

## Getting it into a place

- **Rojo**: `rojo serve`, then Connect in the Studio plugin. The Rojo version in `aftman.toml` has to match the plugin.
- **File**: `rojo build model.project.json --output MHNRFrame.rbxm`, then drag the file into ServerScriptService. It is a folder holding `Loader` and `MainModule` together. It has the code and the empty asset folders, not the assets made in Studio.
- **Asset id**: publish the MainModule as a model, then change the loader's first line to `require(assetId)`.

The MainModule must sit in ServerScriptService or ServerStorage. Anywhere else it refuses to start, because its `Server` folder would be sent to players. `Loader` expects the MainModule right beside it; if you keep the module somewhere else, point the loader's `require` at it. Calling `Start` twice is harmless.

Start it as the server boots, not later. The client loader reaches players through StarterPlayerScripts, which a player only copies when they join.

Rojo owns the scripts while it is connected: edit the files in `src` and `loader`, not the copies in Studio. Do not move or rename the `src` folder while `rojo serve` is running, it crashes the server and you have to reconnect.

## Checking the code

```
rojo sourcemap default.project.json --output sourcemap.json
luau-lsp analyze --sourcemap=sourcemap.json --defs=globalTypes.d.luau --flag:LuauSolverV2=false --ignore="**/Packages/**" src loader
selene src loader
```

`globalTypes.d.luau` is the Roblox API definition file from the luau-lsp repository. It is not committed.

## Third-party code

Both are unmodified copies in `Server/Packages`. Everything else in `src` is written for this project.

- **ProfileStore** by loleris (MAD STUDIO), from github.com/MadStudioRoblox/ProfileStore at commit `45c9847`. Apache-2.0.
- **Cmdr** v1.13.1 by evaera, from github.com/evaera/Cmdr at commit `abd8564`. MIT.

Both licences ask that their text travels with the code. That only matters if the MainModule is ever handed out or published as a model; the texts are in each project's repository.

Cmdr is written with newer Luau syntax than the pinned tools understand, which is one reason `Packages` is skipped by the type check and lint. An editor may underline its files; that is the editor being behind, not a problem in the game.
