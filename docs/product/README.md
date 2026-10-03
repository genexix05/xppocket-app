# Lanzamiento del producto (fork Empo)

Documentación interna para convertir este fork en **una app propia** publicable en App Store: rebrand, legal GPL, review de Apple y monetización.

> **No es documentación de usuario.** La wiki pública de jugadores sigue en [`docs/`](../README.md) (install, playing, etc.).

## Estado rápido

Actualiza esta tabla cuando cierres fases:

| Fase | Doc | Estado |
|------|-----|--------|
| Decisiones de identidad | [01-identidad-rebrand.md](./01-identidad-rebrand.md) | 🟡 XP Pocket (falta repo público, email Team) |
| Cumplimiento GPL / legal | [02-legal-gpl.md](./02-legal-gpl.md) | ⬜ Pendiente (repo público) |
| Privacidad | [06-privacidad.md](./06-privacidad.md) + [07-app-privacy-connect.md](./07-app-privacy-connect.md) | 🟡 Texto listo; falta URL pública + Connect |
| App Store Connect + review | [03-app-store.md](./03-app-store.md) | 🟡 App creada + Age Rating + TestFlight; falta metadata/submit |
| Rebrand en código | [05-inventario-codigo.md](./05-inventario-codigo.md) | 🟡 Mayormente hecho (TestFlight OK) |
| Monetización (Pro + ads) | [04-monetizacion.md](./04-monetizacion.md) | ⬜ Post-v1 |
| Operaciones (build, API, App Store) | [08-operaciones.md](./08-operaciones.md) | 🟡 Referencia viva |

Leyenda: ⬜ Pendiente · 🟡 En curso · ✅ Hecho

## Orden recomendado

1. **[00-roadmap.md](./00-roadmap.md)** — visión por fases (no saltar pasos).
2. **[01-identidad-rebrand.md](./01-identidad-rebrand.md)** — nombre, colores, bundle ID (bloquea casi todo lo demás).
3. **[02-legal-gpl.md](./02-legal-gpl.md)** — obligaciones GPL antes de subir binarios.
4. Rebrand mínimo en código (Theme + icono + `project.yml`) → TestFlight interno.
5. **[06-privacidad.md](./06-privacidad.md)** + **[03-app-store.md](./03-app-store.md)** — metadata y review.
6. **[04-monetizacion.md](./04-monetizacion.md)** — cuando el build rebranded esté estable.
7. **[08-operaciones.md](./08-operaciones.md)** — compilar, IPA, App Store, reiniciar API/web.

## Cómo usar estos docs

- Cada archivo tiene **checklists** con `- [ ]`. Márcalos en git (`- [x]`) cuando completes tareas.
- Los campos `TODO:` son decisiones tuyas; rellénalos en el doc o en un issue.
- **Legal:** esto es orientación técnica, no asesoramiento jurídico. Para dudas fiscales/contratos, consulta a un profesional en tu jurisdicción (España/UE).

## Relación con el upstream

| Repo | Rol |
|------|-----|
| [mateo-m/empo-app](https://github.com/mateo-m/empo-app) | Launcher SwiftUI (GPL) |
| [mateo-m/mkxp-z-apple-mobile](https://github.com/mateo-m/mkxp-z-apple-mobile) | Motor iOS (GPL) |
| Tu fork (`genexix05/…`) | Motor + postloads propios |
| Este workspace | App + docs de producto |

Mantén un remote `upstream` apuntando a mateo-m para cherry-pick de fixes del motor/launcher cuando convenga.

## Notas de sesión

Espacio libre para decisiones tomadas en chat (fecha + una línea):

```
2026-08-23 — Build simulador OK con rama postload/asset-cache-and-text-encoding.
2026-08-23 — Marca: XP Pocket (icono) / XP Pocket: RPG Maker Player (App Store).
              Bundle ID app.xppocket.player · SKU xp-pocket-ios.
2026-08-24 — TestFlight interno OK. Privacy live en https://xppocket.app/privacy.
              Guía App Privacy Connect: docs/product/07-app-privacy-connect.md.
```
