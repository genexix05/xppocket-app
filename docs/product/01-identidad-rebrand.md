# Identidad y rebrand

Rellena esta hoja **antes** de tocar colores en código. Copia la sección «Decisiones» a un commit cuando esté cerrada.

## Decisiones

| Campo | Valor | Notas |
|-------|-------|-------|
| **Nombre en icono** (`CFBundleDisplayName`) | `XP Pocket` | Corto; no se trunca en home screen |
| **Nombre App Store** (≤ 30 chars) | `XP Pocket - RPG Maker Player` | 28 chars; ASO / búsqueda |
| **Subtítulo App Store** (≤ 30 chars) | `RGSS XP, VX & mkxp games` | 24 chars; segunda línea keywords |
| **Nombre corto / slug** | `xp-pocket` | Repo, carpetas, SKU |
| **Tagline (in-app / web)** | `RPG Maker en tu iPhone` | |
| **Bundle ID** | `app.xppocket.player` | Único en Apple; no cambia tras publicar |
| **SKU App Store Connect** | `xp-pocket-ios` | Solo interno Apple; no visible al usuario |
| **Team ID Apple** | `TODO:` | developer.apple.com → Membership → 10 chars |
| **Repo código (GPL)** | `TODO:` | GitHub/GitLab público |
| **Dominio / web** | `xppocket.app` o `essentialsrpgplayer.app` | Privacy + landing; no tiene que = nombre icono |
| **Email soporte** | `TODO:` | Obligatorio en App Store Connect |

### Tres capas de nombre (referencia)

| Capa | Valor | Dónde |
|------|-------|-------|
| Icono | XP Pocket | `PRODUCT_NAME` / display name en `project.yml` |
| App Store título | XP Pocket: RPG Maker Player | App Store Connect al crear la ficha |
| Subtítulo Store | RGSS XP, VX & mkxp games | App Store Connect |

Alternativas App Store (misma marca, ≤ 30 chars):

- `XP Pocket - RPG Maker XP` (24)
- `XP Pocket: RM XP & mkxp` (23)

**No usar:** `XP Pocket - RPG Maker Game Player` (~33 chars, no cabe).

### Descripción Store (borrador)

> Play RPG Maker XP, VX, and VX Ace games on iPhone and iPad. Import your own game folders or archives. Powered by mkxp-z. No games included — you provide the files you have rights to use.

Mencionar Essentials/fan games solo en descripción larga, no «Pokémon» en título.

## Identidad visual

| Token | Empo actual | XP Pocket (TODO) |
|-------|-------------|------------------|
| Primario / brand (oscuro) | `#FA8F29` | Beige `#EDE0CC` |
| Primario / brand (claro) | warm dark / peach | Navy `#1F2E4F` |
| Tipografía global | `.rounded` ([RootView](../../ios/Empo/src/App/RootView.swift)) | `rounded` / `default` |
| Estilo general | Naranja cálido, biblioteca tipo Apple Music | `TODO:` referencia |

### Referencias visuales

- `TODO:` captura / Figma / app de referencia

## Diferenciación respecto a Empo

Checklist «no parecer clone» (Guideline Apple 4.3):

- [x] Icono claramente distinto (forma + color).
- [x] Paleta no-naranja (o naranja muy diferente en saturación/hue).
- [x] Splash y disclaimer con copy propio (no «Here be dragons») — **splash/disclaimer eliminados**; arranque directo a biblioteca.
- [x] Sin logo `EmpoMark` ni tipografía idéntica en marketing.
- [x] Bundle ID `app.xppocket.player` ≠ `sh.mateo.empo`.

Competencia a evitar confundir en Store: **RPG Pocket** (MV/MZ), **RPGPlayer**, Empo, JoiPlay.

### Copy primer arranque (implementado)

| Pantalla | Texto |
|----------|-------|
| Splash tagline | `RPG Maker on your iPhone` |
| Disclaimer título | `Welcome to XP Pocket` |
| Disclaimer subtítulo | `RGSS XP, VX & mkxp on iPhone` |
| CTA | `Continue` |

Cuerpo: importar juegos propios, sin juegos incluidos, compatibilidad variable, guardar a menudo, enlace GitHub issues.

Fuente: [DisclaimerView.swift](../../ios/Empo/src/App/DisclaimerView.swift) (`OnboardingCopy`).

## Checklist de implementación

### Configuración Xcode

- [x] `ios/Empo/project.yml` — `PRODUCT_NAME: XP Pocket`, `bundleIdPrefix: app.xppocket`, `PRODUCT_BUNDLE_IDENTIFIER: app.xppocket.player`
- [ ] `ios/Empo/Signing.xcconfig` — `DEVELOPMENT_TEAM`, confirmar bundle ID
- [x] Regenerar: `xcodegen generate --spec ios/Empo/project.yml --project ios/Empo`

### Diseño en código

- [x] `ios/Empo/src/Design/Theme.swift` — `Color.brand`, `surface`, semánticos
- [ ] `ios/Empo/src/Design/SplashIcons.swift` — icono splash (splash eliminado; asset pack conservado)
- [x] `Assets.xcassets/AppIcon.appiconset/` — todos los tamaños
- [x] Renombrar o reemplazar `EmpoMark.imageset` → `PocketMark`

### Copy / strings

- [x] Primer arranque — splash/disclaimer eliminados; arranque directo a biblioteca
- [x] `SettingsView.swift` — About, privacy, source code, report issue, website
- [x] `AppInfo.swift` — nombre del plist + URLs públicas + `builtInLayoutName`
- [x] Mensajes user-facing «Empo» — sustituidos por `AppInfo.name` / «Built-in default»
- [x] Carpeta visible `EmpoState/` → `PlayerData/` (migración al arrancar)
- [x] Reportes de error — `POST /v1/feedback` + «Send feedback» (sin GitHub issues)

### Legal visible en app

- [x] Settings → Open-source licenses
- [x] Settings → Credits (mkxp-z, Empo upstream, Smallbits)
- [ ] Enlace código fuente GPL definitivo (`AppInfo.sourceCodeURL` → repo público cuando exista; hoy `xppocket.app`)

## Verificación

- [x] Buscar `Empo` en `ios/Empo/src` — solo identificadores internos (`EmpoActionCatalog`, upstream en Credits/Licenses, logs)
- [x] Cero URLs `mateo-m` en settings/about
- [ ] Captura biblioteca + settings + splash (claro / oscuro)
- [ ] App Store Connect: registrar Bundle ID `app.xppocket.player`
- [ ] TestFlight: nombre icono «XP Pocket» y ficha «XP Pocket: RPG Maker Player»
