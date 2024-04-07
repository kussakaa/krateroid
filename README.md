# KRATEROID

## DESCRIPTION

Strategic 3d game with huge world and destructible terrain

![Главное меню](screenshot.png)

## TODO

* [ ] Drawer
  * [ ] UBO?
  * [X] Basic light
  * [ ] Shadows
  * [ ] Blur?
  * [ ] SSAO?
* [ ] Terrain
  * [X] Texturing 
  * [X] Materials 
  * [ ] Beautiful generation
  * [X] Many chunks
  * [ ] Block physics
* [ ] Explosions
* [ ] Actors
* [ ] Projectiles
* [ ] Vehicles
* [ ] Shapes
  * [X] Lines
  * [ ] Quads
  * [ ] Spheres
* [ ] GUI
  * [X] Texts
  * [X] Buttons
  * [X] Panels
  * [X] Menus
  * [X] Switchers
  * [X] Sliders
  * [ ] Text fields
  * [ ] Animations?
* [ ] Configs (JSON, TOML, INI, ZIGGY)?
* [ ] Network?
* [ ] Scripting (Lua, AngelScript)?

## BUILD

```bash
git clone https://github.com/kussakaa/krateroid.git
cd krateroid/
git clone https://github.com/zig-gamedev/zig-gamedev.git deps/zig-gamedev/
zig build run

```

## CREDITS
- Developers of [zig-gamedev](https://github.com/michal-z/zig-gamedev) for their cool library 
