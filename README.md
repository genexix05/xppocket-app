<p align="center"><img src="ios/Empo/Assets.xcassets/AppIcon.appiconset/xppocket-1024.png" alt="XP Pocket icon" width="160" /></p>

# <p align="center">XP Pocket</p>

> <p align="center">Play RPG Maker and PSDK games on iPhone and iPad.</p>

<p align="center">
  <a href="#license"><img alt="License" src="https://img.shields.io/badge/license-GPLv2%2B-blue.svg" /></a>
  <a href="#availability"><img alt="Platform" src="https://img.shields.io/badge/platform-iOS%2026%2B-lightgrey.svg" /></a>
  <a href="#languages"><img alt="Languages" src="https://img.shields.io/badge/languages-EN%20%7C%20ES%20%7C%20FR%20%7C%20DE-informational.svg" /></a>
</p>

<p align="center"><a href="https://apps.apple.com/es/app/xp-pocket-rpg-maker-player/id6804504844">App Store</a> · <a href="https://xppocket.app">Website</a></p>

XP Pocket is a game launcher for iPhone and iPad. It runs RPG Maker XP, VX, VX Ace, MV, and MZ games, Pokemon Essentials games, and PSDK games. RPG Maker games run on [mkxp-z-apple-mobile](https://github.com/genexix05/mkxp-z-apple-mobile), an iOS fork of the [mkxp-z](https://github.com/mkxp-z/mkxp-z) engine. PSDK games run on [psdk-apple-mobile](https://github.com/mateo-m/psdk-apple-mobile), an iOS build of LiteRGSS2 and SFML with one Ruby for each PSDK release type. RPG Maker MV and MZ games bring their own JavaScript engine, and run in a web view.

## Demo

|                  Cinematic                  |                Battle                 |                  Overworld                  |
| :-----------------------------------------: | :-----------------------------------: | :-----------------------------------------: |
| ![Cinematic](docs/media/demo-cinematic.png) | ![Battle](docs/media/demo-battle.png) | ![Overworld](docs/media/demo-overworld.png) |

## Table of contents

- [Highlights](#highlights)
- [Languages](#languages)
- [Availability](#availability)
- [How it works](#how-it-works)
- [Importing games](#importing-games)
- [Support](#support)
- [Contributing](#contributing)
- [License](#license)
- [Credits](#credits)

## Highlights

- Plays games made for RGSS1 (XP), RGSS2 (VX), RGSS3 (VX Ace), modern mkxp-z forks, PSDK, and RPG Maker MV and MZ.
- **Seven Ruby versions in one app.** XP Pocket includes Ruby 1.8, 1.9, and 3.1 for RPG Maker games, and Ruby 2.5, 3.0, 3.2, and 3.3 for PSDK games. Each game runs on the version it was written for. Newer Pokemon Essentials games that ship a `ruby300.dll` run on Ruby 3.1, and XP Pocket rewrites their older syntax as needed. See [`ios/Empo/docs/multi-ruby.md`](ios/Empo/docs/multi-ruby.md).
- Imports games from folders or archives (`.zip`, `.7z`, `.rar`, JoiPlay's `.jgp`, self-extractable `.exe`).
- On-screen D-pad and action buttons you can move and resize. Layouts can differ per game and per screen orientation. Share and install layouts with the community.
- Pause and resume from the library.
- Library with sort, search, grid/list views, and bulk delete.
- Optional XP Pocket Pro subscription: no ads, cloud save, cheat menu, fast forward, and premium layouts.

## Languages

The app is available in English, Spanish, French, and German. Strings live in
[`ios/Empo/src/Localizable.xcstrings`](ios/Empo/src/Localizable.xcstrings) and permission prompts in
[`ios/Empo/src/InfoPlist.xcstrings`](ios/Empo/src/InfoPlist.xcstrings). The text inside the games themselves
is not translated.

## Availability

[XP Pocket - RPG Maker Player](https://apps.apple.com/es/app/xp-pocket-rpg-maker-player/id6804504844) is on the App Store. Playing is free and needs no account. The free version shows ads, and XP Pocket Pro removes them.

Sign in with Apple is optional and only needed for cloud save.

### Limitations

- **One game per session.** After you exit a Ruby game (RPG Maker XP, VX, VX Ace or PSDK), close XP Pocket from the app switcher and reopen it to start a different one. MV and MZ games do not have this limit. This limit stays until Ruby can clear its state reliably. See [`ios/Empo/docs/multi-session.md`](ios/Empo/docs/multi-session.md).
- **Ogg and Theora movies only.** The engine skips MP4 and other formats without a message.
- **Windows-only code.** Some games call Windows functions that the engine's `win32_wrap.rb` does not copy. Those games can fail to load some files.

## How it works

```text
cores/                 One folder per core: its release pin, bridge, and framework build
ios/Empo/              The app (SwiftUI + UIKit for touch controls)
ios/Dependencies/      The downloaded core releases and ANGLE
server/                The XP Pocket API, web site, and tunnel setup
docs/                  Notes on the harder parts
```

The [`docs/`](docs/README.md) folder covers how to install and play, what game developers can
ship with a game, and how the harder parts of the app work. To read it in a browser locally, run:

```sh
bun install
bun run docs:dev
```

## Importing games

XP Pocket accepts these input shapes:

- A folder with a standard RPG Maker `Game.exe` and `Data/` layout.
- A PSDK game folder with `Game.rb` and `Game.yarb`.
- A `.zip`, `.7z`, or `.rar` archive with the same content.
- A `.jgp` (JoiPlay Game Package) manifest that points at game files.

Share them from another app, or use the Files picker from the library's import button. XP Pocket identifies the engine and its version, picks the correct game core and Ruby interpreter, and extracts artwork from `Game.exe` if present. XP Pocket writes everything to its sandbox, so the original imported folder stays unchanged.

## Support

Questions and bug reports are welcome at [xppocket.app](https://xppocket.app) and in the
[issue tracker](https://github.com/genexix05/xppocket-app/issues). For a game that crashes or renders wrong, open an issue with the game title, the game version, the XP Pocket version (**Settings → About**), and what went wrong.

## Contributing

Issues, ideas, and PRs are welcome. Game compatibility reports help the most.

For build requirements, build steps, and PR guidelines, see [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

[GPLv2+](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html), the same license as upstream [mkxp-z](https://github.com/mkxp-z/mkxp-z) and the project XP Pocket builds on. The app shows the full dependency and font license set at **Settings → Open-source licenses**.

## Credits

- [mateo-m](https://github.com/mateo-m) for the original app that XP Pocket builds on, and for the iOS engine builds.
- [Ancurio](https://github.com/Ancurio) for the original [mkxp](https://github.com/Ancurio/mkxp) engine.
- The [mkxp-z contributors](https://github.com/mkxp-z/mkxp-z/graphs/contributors) for keeping it alive on desktop.
- [JoiPlay](https://github.com/joiplay) for the [Ruby 1.8 cross-compilation work](https://github.com/joiplay/ruby) and the multi-Ruby dispatch model their RPG Maker plugin uses.
- [white-axe](https://github.com/white-axe) for [PR #304](https://github.com/mkxp-z/mkxp-z/pull/304), the Ruby 3.1 syntax-transform patches that mkxp-z-apple-mobile applies to its 3.1 build.
- [MGC](https://www.save-point.org/thread-3151.html) for the original H-Mode7 RPG Maker XP plugin. The [native port](https://github.com/mateo-m/hmode7-apple-mobile) re-implements it on mkxp-z's `Bitmap` and `Table` APIs.
- [Splendide Imaginarius](https://github.com/Splendide-Imaginarius) for the `win32_wrap.rb` extensions that keep Windows-only RPG Maker games loading on non-Windows targets.
