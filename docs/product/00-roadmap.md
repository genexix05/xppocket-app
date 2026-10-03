# Roadmap hacia App Store

## Objetivo

Publicar **una app distinta de Empo** (nombre, look, bundle ID) basada en este código GPL, con modelo freemium opcional (ads + suscripción Pro sin anuncios).

## Fases

### Fase A — Fundamentos (sin App Store)

**Meta:** decisiones escritas + repo listo para rebrand.

- [ ] Rellenar [01-identidad-rebrand.md](./01-identidad-rebrand.md) (nombre, bundle ID, paleta).
- [ ] Crear repo público GPL para **tu** app (fork de empo-app con historial claro).
- [ ] Leer y marcar checklist en [02-legal-gpl.md](./02-legal-gpl.md).
- [ ] Cuenta Apple Developer (99 USD/año) — puede esperar a Fase C, pero reserva el bundle ID pronto.

**Salida:** `docs/product/01` completo al 100 %, repo URL definida.

---

### Fase B — Rebrand visual v1

**Meta:** nadie confunde la app con Empo en capturas de pantalla.

- [ ] `ios/Empo/project.yml` — `PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER`, display name.
- [ ] `ios/Empo/src/Design/Theme.swift` — paleta nueva.
- [ ] `Assets.xcassets` — AppIcon + logo (sustituir `EmpoMark`).
- [ ] Splash + [DisclaimerView.swift](../../ios/Empo/src/App/DisclaimerView.swift) — copy propio.
- [ ] [SettingsView.swift](../../ios/Empo/src/Settings/SettingsView.swift) — URLs privacy/about propias.
- [ ] Pasada strings user-facing — ver [05-inventario-codigo.md](./05-inventario-codigo.md).
- [ ] `xcodegen` + build dispositivo/simulador.

**Salida:** TestFlight **interno** (solo tú / beta cerrada).

---

### Fase C — App Store (sin monetización)

**Meta:** primera versión gratuita en producción.

- [ ] Política de privacidad publicada (URL estable).
- [ ] [03-app-store.md](./03-app-store.md) — metadata, capturas, clasificación por edades.
- [ ] [06-privacidad.md](./06-privacidad.md) — `PrivacyInfo.xcprivacy` coherente con lo declarado.
- [ ] Archive Release + Upload + review.

**Salida:** App live v1.0.0 (gratis, sin ads).

---

### Fase D — Monetización

**Meta:** Pro ~2–3 €/mes sin ads + tier gratis con anuncios.

- [ ] StoreKit 2 — producto suscripción en App Store Connect.
- [ ] Paywall + restaurar compras.
- [ ] AdMob (u otro) solo fuera del canvas de juego.
- [ ] Actualizar privacidad + App Privacy labels.
- [ ] Submit update 1.1.0.

**Salida:** IAP + ads en review aprobados.

---

## Qué NO hacer en v1

- No mezclar rebrand + StoreKit + ads en un solo PR.
- No usar capturas/metadata con IP de Nintendo/Pokémon.
- No ocultar el origen GPL ni eliminar pantalla de licencias.
- No publicar sin URL de código fuente accesible.

## Hitos opcionales (motor)

Independientes del App Store pero relevantes para tu fork:

- [ ] Merge postload `asset-cache-and-text-encoding` en tu `dev` del motor.
- [ ] PR o mantenimiento en `genexix05/mkxp-z-apple-mobile`.
- [ ] Pin del submódulo en empo-app cuando estabilices el motor.
