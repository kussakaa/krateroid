# KRATEROID

## DESCRIPTION

Strategic 3d game with huge world and destructible landscape

![Главное меню](screenshot.png)

## PLANNED

* [ ] Drawer
  * [ ] UBO?
  * [x] Basic light
  * [ ] Shadows
  * [ ] Blur?
  * [ ] SSAO?
* [ ] World 
  * [] Chunk
    * [x] Mesh render
	* [ ] Texturing
	* [ ] Materials
  * [ ] Beautiful Generation
  * [ ] Entities
* [ ] GUI
  * [x] Text
  * [x] Button
  * [x] Panel
  * [x] Menu
  * [x] Switcher
  * [x] Slider
  * [ ] Text field
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
