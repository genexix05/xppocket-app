# Monetización

Modelo freemium para XP Pocket: **jugar gratis siempre**, ingresos por **banner + interstitials** (free) y **suscripción Pro** (sin anuncios + features ya implementadas).

> StoreKit, AdMob y paywall al arranque están implementados en código; falta configurar producto IAP en Connect e IDs AdMob de producción.

## Modelo

| Tier | Precio | Incluye |
|------|--------|---------|
| **Free** | 0 € | App completa para jugar + banner en biblioteca + interstitials en momentos acordados |
| **Pro** | ~2,99 €/mes (Connect) | **Sin anuncios** + cloud save + cheats + fast forward + layouts premium |

**Regla Apple:** no bloquear jugar en free. Pro vende comodidad y extras, no el derecho a abrir un juego. El paywall de arranque debe tener **Cerrar / Ahora no** siempre visible.

### Valor Pro (ya en código / API)

- [x] Cloud save (`CloudSaveManager` + API)
- [x] Cheats, fast forward, layouts premium (gated por `AccountSession.hasPro`)
- [ ] StoreKit → activar `pro_until` en API tras compra verificada
- [ ] Sin anuncios (banner AdMob + interstitials desactivados al instante)

---

## Promo Pro al arranque (decidido)

Cada vez que el usuario **abre la app** (cold start → biblioteca), mostrar un **sheet de promoción Pro** antes de usar la app con normalidad. No es un anuncio AdMob: es paywall propio con beneficios y botón de suscripción.

### Cuándo mostrar

| Condición | ¿Mostrar sheet? |
|-----------|-----------------|
| Usuario **sin Pro** | **Sí**, al llegar a biblioteca tras launch |
| Usuario **con Pro** (`hasPro`) | **No** |
| Resume desde background (app ya en memoria) | **No** (solo cold start / fin de proceso) |
| Usuario en partida / carga / import | **No** — solo cuando `AppState.phase == .library` |

### Contenido del sheet

Reutilizar y ampliar `ProUpsellSheet` ([AccountSettingsSection.swift](../../ios/Empo/src/Account/AccountSettingsSection.swift)):

- Título: **XP Pocket Pro**
- Lista de beneficios (cloud save, cheats, fast forward, layouts premium, **sin anuncios**)
- Precio localizado desde StoreKit (cuando exista)
- Botón principal: **Suscribirse**
- Botón secundario: **Ahora no** / **Continuar gratis** — cierra el sheet y deja usar la app
- Enlace **Restaurar compras** (obligatorio StoreKit)
- Enlaces Términos + Privacidad

### Regla: sesión obligatoria antes de suscribirse

**No se puede iniciar la compra StoreKit sin cuenta.**

Flujo:

```text
1. Sheet Pro al arranque
2. Usuario pulsa «Suscribirse»
   ├─ Si NO hay sesión → Sign in with Apple (mismo flujo que Ajustes → Account)
   │                     → tras éxito, refrescar entitlements y mostrar compra
   └─ Si hay sesión    → StoreKit purchase → verify API → hasPro
3. Usuario pulsa «Ahora no» → sheet se cierra → biblioteca (free, con banner AdMob si aplica)
```

- Jugar **no** requiere cuenta; solo **comprar Pro**.
- La suscripción queda ligada a la cuenta (`pro_until` en API), no al dispositivo suelto.
- Si Sign in falla o el usuario cancela: volver al sheet Pro o cerrar según contexto; no bloquear la app.

### Implementación (referencia)

| Pieza | Dónde |
|-------|--------|
| Presentar sheet en launch | `RootView` o `GameLibraryView` — `.task` / `onAppear` tras `AccountSession.refreshOnLaunch()` |
| Flag “ya mostrado esta sesión” | `@State` en memoria (no UserDefaults: debe salir **cada** cold start) |
| Compra + sign-in | `PaywallView` / extender `ProUpsellSheet` + `AccountSignInControls` |
| Ocultar si Pro | `if !session.hasPro { showLaunchProSheet = true }` |

Checklist:

- [ ] Sheet al cold start para usuarios free.
- [ ] Botón suscribir deshabilitado o sustituido por «Iniciar sesión para suscribirte» si `!isSignedIn`.
- [ ] Tras Sign in with Apple, retomar flujo de compra sin pedir login otra vez.
- [ ] «Ahora no» siempre visible; biblioteca usable detrás.
- [ ] No mostrar si `hasPro`.

---

## Anuncios — política acordada

### Banner fijo (free)

| Ubicación | Formato | Estado |
|-----------|---------|--------|
| **`GameLibraryView`** — parte inferior | Banner AdMob fijo | ✅ Decidido |
| `SettingsView` | — | No banner (solo biblioteca) |
| `PlayerView` / canvas RGSS | — | **Nunca** |
| Durante carga del motor | — | **Nunca** encima del juego |

Implementación prevista:

- Banner anclado abajo en la biblioteca; el grid/lista de juegos deja padding inferior para no quedar tapado.
- Oculto si `AccountSession.hasPro` o mientras no hay consentimiento / SDK listo.
- Safe area respetada (home indicator).

### Interstitials (free)

Vídeo/imagen a pantalla completa con skip (~5 s típico en AdMob; duración real depende del creativo). **Nunca** mientras el juego RGSS está en primer plano.

| Momento | ¿Mostrar? | Notas |
|---------|-----------|-------|
| **Tras importar un juego** | **Sí** | Mejor momento: acción poco frecuente, usuario ya espera |
| **Al cargar un juego** | **Sí, con límite** | Cooldown global (p. ej. máx. 1 cada 10–15 min) o cada N-ésima carga (p. ej. 1 de cada 3) |
| **Al volver a biblioteca** (fin de sesión) | **Sí, con límite** | Mismo cooldown; no en cada pausa ligera in-game |
| **Pausa / menú dentro del juego** | **No** | Demasiado frecuente en RPG; mata retención |
| **Error al cargar / crash** | **No** | |
| **Primera apertura de la app** | **No** (interstitial AdMob; el **sheet Pro** sí se muestra — ver arriba) | |

**Cooldown global sugerido (v1):**

- Mínimo **10 minutos** entre interstitials, cualquiera sea el trigger.
- Máximo **1 interstitial por sesión de app** tras import (import siempre puede mostrar uno si pasó el cooldown).
- Pro: **0** interstitials siempre.

### Hooks de código (referencia)

| Evento | Archivo / flujo |
|--------|------------------|
| Import OK | `ImportPipeline` → callback al terminar |
| Antes de jugar | `GameLoadingView` / transición a `.playing` (tras cooldown) |
| Fin de sesión | Volver a biblioteca / `PauseManager` (no botón pausa RGSS) |
| Banner | `GameLibraryView` — `safeAreaInset(edge: .bottom)` o overlay |

### `AdCoordinator` (a implementar)

Responsabilidades centralizadas:

- [ ] Precargar interstitial + mostrar banner solo si `!hasPro`.
- [ ] `canShowInterstitial(reason:)` — Pro, cooldown, “ya hay anuncio en pantalla”, sin juego activo.
- [ ] Registrar timestamp del último interstitial (`UserDefaults` o memoria).
- [ ] `onDismiss` → continuar acción (abrir juego, volver a biblioteca, etc.).
- [ ] IDs en `Ads.xcconfig` gitignored (App ID + banner unit + interstitial unit).

---

## StoreKit 2

### App Store Connect

- [ ] Acuerdo **Paid Applications** firmado.
- [ ] Producto auto-renovable: `app.xppocket.player.pro.monthly` (confirmar ID final en Connect).
- [ ] Grupo de suscripciones.
- [ ] Precio ~2,99 €/mes (tier ES).
- [ ] Localización ES/EN del nombre de la suscripción.

### Código (a implementar)

```
ios/Empo/src/Monetization/
  SubscriptionManager.swift   // Product.products, Transaction.updates
  AdCoordinator.swift         // banner + interstitial + cooldowns
  LaunchProSheet.swift          // promo al arranque (extiende ProUpsellSheet)
  PaywallView.swift             // compra + restaurar + gate Sign in with Apple
```

Checklist:

- [ ] Cargar productos al launch.
- [ ] Comprar + `Transaction.updates`.
- [ ] **Restaurar compras** (obligatorio).
- [ ] Precio localizado desde StoreKit (no hardcodear «2,99 €»).
- [ ] POST verificación a API → `pro_until` en cuenta (requiere `isSignedIn`).
- [ ] Tras Pro activo: ocultar sheet de arranque, banner AdMob e interstitials.
- [ ] Paywall al arranque: Sign in with Apple **antes** de `Product.purchase()`.

### API (servidor)

- [ ] `POST /v1/subscription/verify` — JWS / transacción StoreKit 2.
- [ ] (Recomendado) App Store Server Notifications — renovaciones y cancelaciones.

### Texto legal suscripción (UE)

En paywall o web (`xppocket.app/terms`):

- Precio, periodo, renovación automática.
- Cancelar en Ajustes → Apple ID → Suscripciones.
- Enlace política privacidad.

---

## AdMob / privacidad

### Integración

- [ ] Cuenta [AdMob](https://admob.google.com/).
- [ ] Google Mobile Ads SDK (SPM).
- [ ] `Ads.xcconfig` gitignored: `GADApplicationIdentifier`, banner unit, interstitial unit.
- [ ] Actualizar [06-privacidad.md](./06-privacidad.md), `PrivacyInfo.xcprivacy`, App Privacy Connect.

### ATT (App Tracking Transparency)

- Interstitials + banner personalizados → casi seguro `NSUserTrackingUsageDescription` + prompt ATT.
- Alternativa v1: solicitar ads **no personalizados** donde el SDK lo permita → menos fricción (confirmar en doc Google).

---

## Impuestos / UE

- [ ] Revisar fiscalidad suscripciones Apple en España (Connect gestiona mucho del IVA).
- [ ] Guardar facturas Apple / AdMob.

---

## Orden de implementación

1. **StoreKit 2** + verify en API → Pro real en TestFlight sandbox.
2. **Launch Pro sheet** (arranque, sesión obligatoria para comprar).
3. **Banner** fijo en `GameLibraryView` (free only).
4. **Interstitial** import → luego carga/fin sesión con cooldown.
5. Privacy + terms + App Privacy Connect actualizados.
6. Submit (v1.0 con monetización o update 1.1).

## Estado código actual

- [x] `SubscriptionManager` (StoreKit 2) + `POST /v1/subscription/verify`
- [x] `ProPaywallView` — sheet al arranque + Ajustes; Sign in with Apple antes de comprar
- [x] `AdCoordinator` + banner biblioteca + interstitials (import / carga / fin sesión)
- [ ] Producto `app.xppocket.player.pro.monthly` en App Store Connect
- [ ] IDs AdMob de producción (ahora: IDs de test de Google en `project.yml`)
- `grant-pro` admin sigue disponible para testing sin compra
