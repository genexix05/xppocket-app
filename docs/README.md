# Empo documentation

This folder is the source of the [Empo documentation site](https://empo.mateo.sh/).
Each `.md` and `.mdx` file here becomes a page. Run `bun run docs:dev` from the repository root
to read it in a browser, or read the files below on GitHub.

Start with the [project README](../README.md) for what Empo is and how to build it.

## Product launch (fork / App Store)

Internal checklists for rebranding this fork, GPL compliance, App Store submission, and monetization:

| Doc | What it covers |
| --- | -------------- |
| [`product/README.md`](product/README.md) | Hub: status table and reading order |
| [`product/00-roadmap.md`](product/00-roadmap.md) | Phases A–D toward App Store |
| [`product/01-identidad-rebrand.md`](product/01-identidad-rebrand.md) | Name, bundle ID, visual identity |
| [`product/02-legal-gpl.md`](product/02-legal-gpl.md) | GPL obligations, games, trademarks |
| [`product/03-app-store.md`](product/03-app-store.md) | Connect, metadata, review |
| [`product/04-monetizacion.md`](product/04-monetizacion.md) | Pro subscription + ads (post-v1) |
| [`product/05-inventario-codigo.md`](product/05-inventario-codigo.md) | Files to change for rebrand |
| [`product/06-privacidad.md`](product/06-privacidad.md) | Privacy policy, ATT, PrivacyInfo |

## For players

| Doc                                          | What it covers                                                     |
| -------------------------------------------- | ------------------------------------------------------------------ |
| [`requirements.mdx`](requirements.mdx)       | Devices, iOS version, sideloading tools, and the supported engines. |
| [`install.mdx`](install.mdx)                 | How to sideload the app and get update notifications.              |
| [`importing-games.mdx`](importing-games.mdx) | The accepted file types, and what happens to an installed game.    |
| [`playing.mdx`](playing.mdx)                 | The library, the touch controls, controllers, and game settings.   |
| [`saves.mdx`](saves.mdx)                     | Where saves live, what updates and deletes do, moving saves.       |
| [`troubleshooting.mdx`](troubleshooting.mdx) | Frequent problems and their fixes.                                 |
| [`faq.mdx`](faq.mdx)                         | Short answers before you install.                                  |
| `community.mdx`                              | Generated from [`SUPPORT.md`](../SUPPORT.md) by `tools/root-pages.ts` at build time. Not checked in. |
| `privacy.mdx`                                | Generated from [`PRIVACY.md`](../PRIVACY.md) by `tools/root-pages.ts` at build time. Not checked in. |
| `terms.mdx`                                  | Generated from [`TERMS.md`](../TERMS.md) by `tools/root-pages.ts` at build time. Not checked in. |
| `changelog.mdx`                              | Generated from [`CHANGELOG.md`](../CHANGELOG.md) by `tools/changelog-page.ts` at build time. Not checked in. |

## For game developers

Reference docs for shipping or adapting an RPG Maker game for Empo:

| Doc                                        | What it covers                                                                               |
| ------------------------------------------ | -------------------------------------------------------------------------------------------- |
| [`controls-format.md`](controls-format.md) | The `empo/controls.json` touch-controls manifest: format, validation codes, controller maps. |
| [`config-format.md`](config-format.md)     | The JSON5 language that both the app and the engine parse, and its quirks.                   |
| [`patches-format.md`](https://github.com/mateo-m/mkxp-z-apple-mobile/blob/dev/docs/patches-format.md) (engine repo) | The `patches.json` script-patching system: format, matching semantics, when patches apply. |
| [`schemas/`](schemas/)                     | JSON Schemas (e.g. `empo-controls.v1.schema.json`).                                          |
| [`examples/`](examples/)                   | Worked examples (e.g. a complete `controls.json`).                                           |

## For contributors

Explanations of the trickier architecture, in rough reading order:

| Doc                                                  | What it covers                                                                     |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------- |
| [`how-it-works.mdx`](how-it-works.mdx)               | The architecture in one page, with links to each detailed note.                     |
| [`sdl-ruby-workarounds.md`](https://github.com/mateo-m/mkxp-z-apple-mobile/blob/dev/docs/sdl-ruby-workarounds.md) (engine repo) | Why SDL, the GL context, OpenAL, and the Ruby VM persist for the process lifetime. |

The detailed notes (the game cores, the Ruby interpreters, one game per session, pause and
resume, the import pipeline, and the visual rules) live next to the Swift, in
[`ios/Empo/docs/`](../ios/Empo/docs/).

`media/` holds the README screenshots and demo assets. The site configuration lives in
[`blume.config.ts`](../blume.config.ts), and site-wide static files live in [`public/`](../public).
