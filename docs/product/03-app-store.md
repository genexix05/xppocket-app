# App Store Connect y review

## Prerrequisitos

- [ ] [Apple Developer Program](https://developer.apple.com/programs/) activo.
- [ ] Identidad rellenada en [01-identidad-rebrand.md](./01-identidad-rebrand.md).
- [ ] [02-legal-gpl.md](./02-legal-gpl.md) — repo público + privacy URL.
- [ ] Build Release firmado con team real (no solo simulador).

## App Store Connect — crear app

| Campo | Valor |
|-------|-------|
| Plataforma | iOS |
| Nombre | `TODO:` (nombre comercial) |
| Idioma principal | Español o English |
| Bundle ID | el de [01-identidad-rebrand.md](./01-identidad-rebrand.md) |
| SKU | `TODO:` |
| Acceso | Completo |

- [ ] App creada en Connect.
- [ ] Certificado + Provisioning Profile (Xcode Automatic Signing suele bastar).

## Requisitos técnicos Empo

| Requisito | Valor actual |
|-----------|--------------|
| iOS mínimo | **26.0** (`project.yml`) |
| Dispositivos | iPhone + iPad (`TARGETED_DEVICE_FAMILY`) |
| Arquitectura | arm64 |

Implica audiencia limitada al ecosistema iOS 26+ al lanzar; coherente con upstream.

## Metadata App Store

### Textos

- [x] **Nombre** (30 chars) — `XP Pocket - RPG Maker Player`
- [x] **Subtítulo** (30 chars) — `RGSS XP, VX & mkxp games`
- [ ] **Descripción** — pegar borrador de [01-identidad-rebrand.md](./01-identidad-rebrand.md).
- [ ] **Palabras clave** — `RPG Maker,RGSS,mkxp,VX Ace,XP,fan game,import`
- [ ] **URL soporte** — `https://xppocket.app`
- [ ] **URL marketing** — `https://xppocket.app` (opcional)
- [ ] **URL política privacidad** — `https://xppocket.app/privacy`
- [x] **Age Rating** — hecho
- [ ] **App Privacy** — seguir [07-app-privacy-connect.md](./07-app-privacy-connect.md)

### Capturas

Tamaños según [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/).

- [ ] iPhone 6.7" (obligatorio si soportas iPhone).
- [ ] iPad 12.9" si soportas iPad.
- [ ] UI **rebrandeada**; sin IP de terceros.

### Clasificación por edades

- [ ] Cuestionario completado (violencia, UGC — usuarios importan juegos → puede afectar).
- [ ] Sin apuestas ni contenido adulto en la app en sí.

## Build y upload

```sh
# Desde repo root, con Signing.xcconfig configurado
xcodegen generate --spec ios/Empo/project.yml --project ios/Empo
# Xcode: Product → Archive → Distribute App → App Store Connect
```

- [ ] `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` incrementados en `project.yml`.
- [ ] Archive subido y procesado (sin errores de símbolos/bitcode).
- [ ] Build seleccionado en la versión de Connect.

## Fases de script en Xcode (saber qué valida)

El target Empo ejecuta antes de compilar:

1. Hydrate native deps / ANGLE / engine prebuilt.
2. Verify native deps (fingerprint binding si tocaste motor).
3. Assemble Assets.bundle (incluye Postload/).

Si cambias `script-bootstrap.cpp`, rebuild binding local antes de Archive — ver [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Review — riesgos conocidos

| Riesgo | Mitigación |
|--------|------------|
| **4.3 Spam** (clone) | Rebrand fuerte; descripción honesta. |
| **2.5.1** Software requirements | Motor ya evita `exit()`; no cambiar. |
| **5.2 IP** | No promocionar Pokémon; UGC disclaimer. |
| **3.1.1 IAP** | Si hay suscripción: restaurar compras, términos claros. |
| **Guideline ads** | No ads sobre gameplay; declarar en privacy. |

### Notas para el revisor (campo «Notes»)

Plantilla:

```
This app is an RPG Maker game player. It does not include any games.
Users import their own game files. The app runs user-provided RGSS scripts
in a sandbox. Source code is available under GPL at: TODO URL
```

## TestFlight

- [ ] Internal testing — build smoke test.
- [ ] External testing — opcional antes de producción.
- [ ] Recoger crashes (Organizer / Xcode).

## Lanzamiento

- [ ] Precio: Gratis (v1 sin IAP).
- [ ] Disponibilidad: países `TODO:`.
- [ ] Submit for Review.
- [ ] Monitorizar Resolution Center (rechazos → corregir → resubmit).

## Post-lanzamiento

- [ ] Tag git `v1.0.0` = build en producción.
- [ ] Actualizar [README producto](./README.md) estado ✅.
- [ ] Canal soporte (email / GitHub Issues).
