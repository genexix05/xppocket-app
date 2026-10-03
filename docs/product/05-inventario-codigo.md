# Inventario de código para rebrand

Mapa de archivos a tocar al salir de «Empo». Actualizado 2026-08-23.

## Punto único de configuración

| Archivo | Qué cambia |
|---------|------------|
| [ios/Empo/project.yml](../../ios/Empo/project.yml) | Nombre proyecto, bundle ID, versión, `PRODUCT_NAME` |
| [ios/Empo/Signing.xcconfig](../../ios/Empo/Signing.xcconfig) | Team ID (gitignored) |
| [ios/Empo/src/App/AppInfo.swift](../../ios/Empo/src/App/AppInfo.swift) | Lee nombre del plist — no hardcodea «Empo» |

Tras editar `project.yml`:

```sh
xcodegen generate --spec ios/Empo/project.yml --project ios/Empo
```

## Identidad visual

| Archivo | Notas |
|---------|-------|
| [Theme.swift](../../ios/Empo/src/Design/Theme.swift) | `Color.brand`, `surface`, spacing, radius |
| [RootView.swift](../../ios/Empo/src/App/RootView.swift) | `.fontDesign(.rounded)`, `.tint(.brand)` |
| [SplashIcons.swift](../../ios/Empo/src/Design/SplashIcons.swift) | Logo animado splash |
| [DisclaimerView.swift](../../ios/Empo/src/App/DisclaimerView.swift) | Primer arranque |
| [Assets.xcassets/AppIcon.appiconset/](../../ios/Empo/Assets.xcassets/AppIcon.appiconset/) | Icono |
| [Assets.xcassets/EmpoMark.imageset/](../../ios/Empo/Assets.xcassets/EmpoMark.imageset/) | Renombrar/reemplazar |

## UI principal

| Archivo | Prioridad |
|---------|-----------|
| [GameLibraryView.swift](../../ios/Empo/src/Library/GameLibraryView.swift) | Alta — muchos strings «Empo» |
| [SettingsView.swift](../../ios/Empo/src/Settings/SettingsView.swift) | Alta — URLs mateo-m |
| [GameCard.swift](../../ios/Empo/src/Library/GameCard.swift) | Media |
| [GameLoadingView.swift](../../ios/Empo/src/Library/GameLoadingView.swift) | Media |
| [LicensesView.swift](../../ios/Empo/src/Settings/LicensesView.swift) | Mantener; actualizar deps |

## Strings «Empo» en Swift (~40 archivos)

Buscar y clasificar:

```sh
rg 'Empo' ios/Empo/src --glob '*.swift' -l
```

### Categorías

1. **User-facing** — cambiar a `AppInfo.name` o copy nuevo.
2. **Rutas / carpetas** — `EmpoState/`, `Duplicate Games` — ver [DataDirectory.swift](../../ios/Empo/src/App/DataDirectory.swift); cambio de nombre puede migrar datos (planificar).
3. **Identificadores internos** — `EmpoActionCatalog`, `EmpoSceneDelegate` — opcional renombrar en v2 (no visible al usuario).

### Archivos con más referencias user-facing

- `GameLibraryView.swift` — mensajes borrado/migración
- `GameContainer.swift` — rutas sandbox
- `GameSettings.swift` / `GameSettingsView.swift`
- `GameImportValidator.swift` — errores importación
- `PlayerRuntimeState.swift` — logs/debug

## Motor (submódulo)

| Qué | Acción |
|-----|--------|
| `mkxp-z-apple-mobile` | Tu rama postload; no rebrandea UI app |
| Postloads `$empo` en Ruby | Interno motor; no visible en App Store |

## Legal / metadata embebida

| Archivo | Acción |
|---------|--------|
| [SettingsView.swift](../../ios/Empo/src/Settings/SettingsView.swift) | Cambiar URLs privacy + GitHub |
| [PrivacyInfo.xcprivacy](../../ios/Empo/PrivacyInfo.xcprivacy) | Actualizar al añadir ads/IAP |
| [Info.plist](../../ios/Empo/Info.plist) | Generado vía project.yml |

## Docs upstream (opcional renombrar después)

- `docs/schemas/empo-controls.v1.schema.json` — formato controles; breaking change si renombras.
- `docs/*.mdx` — wiki jugadores; baja prioridad si no publicas misma wiki.

## Checklist grep final

```sh
# User-facing en launcher
rg 'Empo' ios/Empo/src --glob '*.swift'

# URLs upstream
rg 'mateo-m' ios/Empo/src

# Brand color (verificar sustitución)
rg '\.brand|Color\.brand' ios/Empo/src
```

- [ ] Cero URLs mateo-m en settings/about.
- [ ] Strings visibles usan nombre nuevo o `AppInfo.name`.
- [ ] Decisión documentada si mantienes carpeta `EmpoState` en disco (compat saves).
