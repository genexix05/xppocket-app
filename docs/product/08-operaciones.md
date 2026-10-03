# Operaciones — build, despliegue y App Store

Guía práctica para el día a día: compilar la app, generar un `.ipa`, subir a TestFlight/App Store, y operar la API y la web.

> **Audiencia:** tú (mantenedor). No es documentación de usuario.

## Referencias rápidas

| Recurso | URL / ruta |
|---------|------------|
| App (bundle ID producción) | `app.xppocket.player` |
| App (bundle ID dev / personal team) | `app.xppocket.player.dev` |
| Esquema Xcode | `XPPocket` |
| Versión en código | `ios/Empo/project.yml` → `MARKETING_VERSION` + `CURRENT_PROJECT_VERSION` |
| Landing + privacy | `https://xppocket.app` |
| API | `https://api.xppocket.app` |
| Servidor Docker | `192.168.0.48` (usuario `genexix05`) |
| API en servidor | `~/docker/xppocket-api` → puerto **8787** |
| Web en servidor | puerto **8081** (contenedor `xppocket-web`) |
| Datos API persistentes | `/mnt/nextcloud-data/genexix05/xppocket-api/data` |

Docs relacionados:

- [03-app-store.md](./03-app-store.md) — metadata, review, capturas
- [07-app-privacy-connect.md](./07-app-privacy-connect.md) — App Privacy en Connect
- [server/xppocket-api/README.md](../../server/xppocket-api/README.md) — endpoints API
- [CONTRIBUTING.md](../../CONTRIBUTING.md) — build desde cero, motor, deps nativas

---

## 1. Prerrequisitos en el Mac

```bash
# Herramientas de build
brew install bun xcodegen gh autoconf automake libtool cmake pkg-config git-cliff

# Clonar (con submódulo del motor)
git clone --recursive git@github.com:TU_ORG/empo-app.git
cd empo-app
bun install
```

| Requisito | Detalle |
|-----------|---------|
| Xcode | **26+** (SDK iOS 26). Xcode → Settings → Platforms si falta el SDK. |
| Cuenta Apple | Developer Program para Archive / App Store. Apple ID gratis basta para dispositivo con bundle `.dev`. |
| iOS mínimo soportado | **26.0** (`project.yml`) |

### Firma local (dispositivo / Archive)

```bash
cp ios/Empo/Signing.xcconfig.example ios/Empo/Signing.xcconfig
```

Edita `Signing.xcconfig`:

```xcconfig
DEVELOPMENT_TEAM = TU_TEAM_ID_10_CHARS
// Opcional si tu team no puede registrar el bundle de producción:
// PRODUCT_BUNDLE_IDENTIFIER = app.xppocket.player.dev
```

El archivo está en `.gitignore`; no se commitea.

---

## 2. Generar el proyecto Xcode

Siempre que cambies `project.yml` o clones el repo:

```bash
xcodegen generate --spec ios/Empo/project.yml --project ios/Empo
open ios/Empo/XPPocket.xcodeproj
```

---

## 3. Compilar en Xcode

### Simulador (desarrollo diario)

1. Abre `ios/Empo/XPPocket.xcodeproj`.
2. Esquema **XPPocket**, destino **iPhone Simulator** (iOS 26+).
3. **Product → Run** (⌘R).

La primera compilación descarga/hidrata deps nativas (ANGLE, OpenSSL, motor prebuilt). Puede tardar varios minutos.

**Línea de comandos (Debug simulador):**

```bash
xcodegen generate --spec ios/Empo/project.yml --project ios/Empo

xcodebuild \
  -project ios/Empo/XPPocket.xcodeproj \
  -scheme XPPocket \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build
```

**Instalar en simulador ya arrancado:**

```bash
SIM=$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)
xcrun simctl install "$SIM" "ios/Empo/build/Debug-iphonesimulator/XP Pocket.app"
xcrun simctl launch "$SIM" app.xppocket.player.dev
```

### Dispositivo físico

1. Conecta el iPhone/iPad (iOS 26+).
2. Confirma `Signing.xcconfig` con tu `DEVELOPMENT_TEAM`.
3. Destino → tu dispositivo → **Run**.

Si falla el provisioning: Xcode → target **XPPocket** → **Signing & Capabilities** → *Automatically manage signing*.

### Release en Xcode (sin Archive)

```bash
xcodebuild \
  -project ios/Empo/XPPocket.xcodeproj \
  -scheme XPPocket \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  build
```

Salida típica: `ios/Empo/build/Release-iphoneos/XP Pocket.app`.

---

## 4. Compilar el .ipa

Hay **tres caminos** según el objetivo:

| Objetivo | Método |
|----------|--------|
| **App Store / TestFlight** | Xcode Archive → Upload (sección 5) |
| **Release sideload (GitHub / AltStore)** | Tag `v*.*.*` → CI, o `scripts/release.sh` |
| **IPA local de emergencia** | `RELEASE_LOCAL_BUILD=1 scripts/release.sh patch` |

### 4a. IPA firmado para App Store (recomendado)

Ver sección 5 (Archive). Connect recibe el binario; no necesitas empaquetar `.ipa` a mano.

### 4b. IPA unsigned (CI / sideload)

**Automático (recomendado):**

```bash
# Bump + tag + push; GitHub Actions construye y publica el .ipa
scripts/release.sh patch    # o minor | major | 1.2.3

# Alternativa sin terminal: GitHub → Actions → Release → Run workflow (mode=cut)
```

El workflow genera `Empo-<version>-unsigned.ipa`, lo adjunta al GitHub Release y actualiza `altstore-source.json`.

**Dry-run (probar build sin publicar):**

GitHub → Actions → Release → Run workflow → mode **dry-run**, ref `main`.

**Build local (si CI no está disponible):**

```bash
RELEASE_LOCAL_BUILD=1 scripts/release.sh patch
# Salida: build/ipa/Empo-<version>-unsigned.ipa
```

**Manual (equivalente simplificado):**

```bash
xcodegen generate --spec ios/Empo/project.yml --project ios/Empo

xcodebuild \
  -project ios/Empo/XPPocket.xcodeproj \
  -scheme XPPocket \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  CODE_SIGNING_ALLOWED=NO \
  CONFIGURATION_BUILD_DIR="$PWD/build/Release-iphoneos" \
  build

codesign --force --sign - \
  --generate-entitlement-der \
  --entitlements ios/Empo/XPPocket.entitlements \
  "build/Release-iphoneos/XP Pocket.app"

mkdir -p build/ipa/Payload
cp -R "build/Release-iphoneos/XP Pocket.app" build/ipa/Payload/
(cd build/ipa && zip -qr "XPPocket-unsigned.ipa" Payload)
```

### 4c. Incrementar versión antes de subir

Edita `ios/Empo/project.yml`:

```yaml
MARKETING_VERSION: 1.0.1      # visible en App Store (semver)
CURRENT_PROJECT_VERSION: 42   # build number (entero, debe subir cada upload)
```

O deja que `scripts/release.sh` lo haga automáticamente al cortar un release.

Regenera el proyecto tras editar:

```bash
xcodegen generate --spec ios/Empo/project.yml --project ios/Empo
```

---

## 5. Subir a App Store Connect

### 5a. Archive desde Xcode

1. Destino: **Any iOS Device (arm64)** (no simulador).
2. **Product → Archive**.
3. En Organizer → **Distribute App**:
   - **App Store Connect** → Upload
   - Opciones por defecto (bitcode off, symbols on)
4. Espera procesamiento en [App Store Connect](https://appstoreconnect.apple.com) (5–30 min).

Checklist previo: [03-app-store.md](./03-app-store.md) (capturas, privacy URL, App Privacy, notas al revisor).

### 5b. TestFlight

1. Connect → tu app → **TestFlight**.
2. Cuando el build aparezca como *Ready to Test*:
   - **Internal testing**: testers del team (inmediato).
   - **External testing**: requiere Beta App Review (primera vez).
3. Instala **TestFlight** en el dispositivo → acepta invitación.

### 5c. Enviar a review (producción)

1. Connect → **App Store** → **+ Version** (ej. 1.0.0).
2. Rellena metadata, capturas, clasificación, App Privacy.
3. Selecciona el build procesado.
4. **Submit for Review**.

Tras aprobación: elige liberación manual o automática.

### 5d. Si el upload falla

| Error típico | Qué hacer |
|--------------|-----------|
| Invalid bundle / missing compliance | Connect → build → Export compliance / encryption |
| Provisioning | Revisa certificados; Automatic Signing en Xcode |
| Símbolos / dSYM | Organizer → incluir symbols al distribuir |
| Versión duplicada | Sube `CURRENT_PROJECT_VERSION` en `project.yml` |

---

## 6. API (`api.xppocket.app`)

Código: `server/xppocket-api/`.

### 6a. Desarrollo local

```bash
cd server/xppocket-api
cp .env.example .env
# Edita XPPOCKET_ADMIN_KEY y XPPOCKET_JWT_SECRET (valores largos aleatorios)

docker compose up -d --build
curl http://127.0.0.1:8787/health
curl http://127.0.0.1:8787/v1/layouts
open http://127.0.0.1:8787/docs
```

### 6b. Desplegar cambios en el servidor

Desde el Mac:

```bash
rsync -avz --delete \
  --exclude data --exclude .env \
  server/xppocket-api/ genexix05@192.168.0.48:~/docker/xppocket-api/

ssh genexix05@192.168.0.48 \
  'cd ~/docker/xppocket-api && docker compose down && docker compose build --no-cache && docker compose up -d'

curl https://api.xppocket.app/health
```

> **Importante:** `--exclude .env` preserva secretos del servidor. No sobrescribas `.env` salvo que quieras cambiar configuración a propósito.

### 6c. Reiniciar la API (sin rebuild)

```bash
ssh genexix05@192.168.0.48 'cd ~/docker/xppocket-api && docker compose restart'
```

### 6d. Reiniciar con rebuild (cambio de código)

```bash
ssh genexix05@192.168.0.48 \
  'cd ~/docker/xppocket-api && docker compose down && docker compose up -d --build'
```

### 6e. Logs y estado

```bash
# Logs en vivo
ssh genexix05@192.168.0.48 'docker logs -f xppocket-api'

# Estado del contenedor
ssh genexix05@192.168.0.48 'docker ps --filter name=xppocket-api'

# Health check
curl -s https://api.xppocket.app/health | jq
```

### 6f. Datos persistentes

Dentro del contenedor, volumen `/data`:

| Ruta | Contenido |
|------|-----------|
| `xppocket.db` | SQLite (cuentas, layouts, saves) |
| `packs/` | ZIPs de layouts |
| `saves/` | Cloud saves por cuenta |
| `feedback/` | Reportes enviados desde la app (`POST /v1/feedback`) |

En el host (según despliegue actual):

```bash
ssh genexix05@192.168.0.48 \
  'ls -la /mnt/nextcloud-data/genexix05/xppocket-api/data/feedback/'
```

### 6g. Operaciones habituales

**Conceder Pro a una cuenta (testing):**

```bash
# Listar cuentas
curl -s -H "X-Admin-Key: TU_CLAVE" \
  https://api.xppocket.app/v1/admin/accounts | jq

# 30 días de Pro
curl -X POST -H "X-Admin-Key: TU_CLAVE" \
  "https://api.xppocket.app/v1/admin/accounts/UUID/grant-pro?days=30"
```

**Subir un layout:**

```bash
curl -X POST "https://api.xppocket.app/v1/layouts" \
  -H "X-Admin-Key: TU_CLAVE" \
  -F "id=mi-layout" \
  -F "name=Mi layout" \
  -F "author=Tu nombre" \
  -F "pack=@mi-layout.zip"
```

Variables de entorno: ver tabla en [server/xppocket-api/README.md](../../server/xppocket-api/README.md).

---

## 7. Web (`xppocket.app`)

Código: `server/xppocket-web/`. HTML estático generado + nginx en Docker.

### 7a. Regenerar HTML (idiomas ES/EN/PT/FR/DE)

```bash
cd server/xppocket-web
python3 build-site.py
# Salida: html/, html/en/, html/pt/, ...
```

Edita textos en `build-site.py` o plantillas según cómo esté organizado el generador, luego vuelve a ejecutar el script.

### 7b. Probar en local

```bash
cd server/xppocket-web
docker compose up -d --build
open http://127.0.0.1:8081
```

### 7c. Desplegar en el servidor

Mismo patrón que la API (ajusta ruta remota si difiere):

```bash
rsync -avz --delete \
  server/xppocket-web/ genexix05@192.168.0.48:~/docker/xppocket-web/

ssh genexix05@192.168.0.48 \
  'cd ~/docker/xppocket-web && docker compose down && docker compose up -d --build'

curl -I https://xppocket.app
```

### 7d. Reiniciar solo la web

```bash
ssh genexix05@192.168.0.48 'cd ~/docker/xppocket-web && docker compose restart'
```

---

## 8. Flujo recomendado: de cambio a producción

```text
1. Desarrollo en simulador / dispositivo (Xcode Run)
2. Commit + push a main
3. (Opcional) Desplegar API/web si tocaste server/
4. Bump versión:
     - App Store: editar project.yml O scripts/release.sh
     - Sideload release: scripts/release.sh patch
5. Archive → Upload → TestFlight → smoke test
6. Completar metadata Connect → Submit for Review
7. Tras aprobación: tag git vX.Y.Z = build en producción
```

---

## 9. Diagnóstico rápido

### App no compila

```bash
# Regenerar proyecto
xcodegen generate --spec ios/Empo/project.yml --project ios/Empo

# Verificar deps nativas (simulador / device)
PLATFORM_NAME=iphonesimulator scripts/verify-native-deps.sh
PLATFORM_NAME=iphoneos scripts/verify-native-deps.sh

# Re-hidratar deps
tools/fetch-angle.sh
tools/fetch-native-deps.sh
tools/fetch-engine-prebuilt.sh
```

Si editaste código del binding del motor (`mkxp-z-apple-mobile/binding/`):

```bash
cd ios/Dependencies
make -f iphonesimulator.make mkxp-merged   # o iphoneos.make
```

### App: logs de sesión

Ajustes → activar debug logs → reproducir → Ajustes → **Send feedback**, o desde la ficha del juego → Export logs.

En disco (app Archivos): `Documents/Games/<título>/Logs/`.

### API caída

```bash
curl -v https://api.xppocket.app/health
ssh genexix05@192.168.0.48 'docker ps -a | grep xppocket'
ssh genexix05@192.168.0.48 'docker logs --tail 100 xppocket-api'
```

---

## 10. Checklist pre-release App Store

- [ ] `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` actualizados
- [ ] Build Release probado en dispositivo real
- [ ] Privacy live en `https://xppocket.app/privacy`
- [ ] App Privacy en Connect alineado con [07-app-privacy-connect.md](./07-app-privacy-connect.md)
- [ ] Capturas con UI **XP Pocket** (no Empo)
- [ ] Notas al revisor redactadas ([03-app-store.md](./03-app-store.md))
- [ ] API desplegada si hay cambios de backend (auth, cloud save, feedback)
- [ ] TestFlight interno OK

---

## Notas de sesión

Espacio para anotar comandos/host específicos que cambien:

```text
2026-08-24 — TestFlight interno OK. Web en xppocket.app, API en api.xppocket.app.
              Servidor Docker: 192.168.0.48 (genexix05).
```
