# REDLINE: Road Rash (English Edition)

An English-language translation of [REDLINE / 公路狂徒](https://github.com/vorojar/redline-road-rash), a 3D motorcycle racing and combat game made with Godot 4. This is an unofficial community translation; the original game and its assets remain credited to their respective creators.

## Play in a browser

The browser edition requires WebGL 2 and WebAssembly. The first launch downloads the game files; later visits can reuse the browser cache.

## Run from source

1. Install Godot 4.7.2 Standard.
2. Open `project.godot` in Godot.
3. Run the main scene, `game/main.tscn`.

To export the web build, use `scripts/export_web.sh` on macOS/Linux, or open the project in Godot and export with the Web preset. To preview an existing export, serve the export folder over HTTP rather than opening the files directly.

## Controls

| Action | Keyboard |
| --- | --- |
| Throttle / brake / steer | W, A, S, D or arrow keys |
| Punch / kick / weapon attack | J / K / L |
| Block / dodge / disarm | U / I / O |
| Charge and release boost | Hold / release Shift |
| Cruise control / pause | C / Esc |
| Start race / attack | Enter / Space |

The mobile version uses landscape touch controls. Settings let you change input mode, graphics quality, sound, music, and other assists.

## What changed

- Translated the game menus, HUD, tutorial, race events, results, settings, track and stage names, and bike descriptions into English.
- Translated the browser launch page, loading/error messages, and credits page.
- Updated project and package names for the English edition.

## Attribution and licensing

This repository is an unofficial translation of the project by [vorojar](https://github.com/vorojar/redline-road-rash). See [the original project](https://github.com/vorojar/redline-road-rash) and [credits page](web/credits.html) for game and asset attribution.

The upstream repository does not include a license for its game code. This repository therefore does not add a license or claim new redistribution rights over the original code or assets. Third-party assets keep their original licenses; see `assets/licenses/` and `web/credits.html`.
