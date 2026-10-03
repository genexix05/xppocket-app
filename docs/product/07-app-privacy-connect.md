# App Privacy (App Store Connect) — respuestas v1 (con ads + IAP)

Usa esto en **App Store Connect → App Privacy → Edit**.
Debe coincidir con el binario: Sign in with Apple opcional, cloud save Pro,
StoreKit, AdMob **no personalizado** (`npa=1`, sin ATT).

## Pregunta inicial

| Pregunta | Respuesta |
|----------|-----------|
| ¿Recoges datos de esta app? | **Sí** |

## Tracking

| Pregunta | Respuesta |
|----------|-----------|
| ¿Usas los datos para trackear? | **No** en todos los tipos |

No declares Advertising Data ni Coarse Location como usados para **tracking**.
Si Connect ya los tiene marcados así, **edítalos o elimínalos** — eso fue el rechazo 5.1.2(i).

## Datos a declarar

### 1. Contact Info → Email Address

| Campo | Valor |
|-------|--------|
| ¿Tracking? | **No** |
| Linked to user | **Yes** |
| Used for | **App Functionality** (Sign in with Apple) |

### 2. Identifiers → User ID

| Campo | Valor |
|-------|--------|
| ¿Tracking? | **No** |
| Linked to user | **Yes** |
| Used for | **App Functionality** (`api.xppocket.app`) |

### 3. Purchases

| Campo | Valor |
|-------|--------|
| ¿Tracking? | **No** |
| Linked to user | **Yes** si hay cuenta; si no, según Connect |
| Used for | **App Functionality** / **Purchase History** (suscripción Pro) |

### 4. User Content (cloud saves)

| Campo | Valor |
|-------|--------|
| ¿Tracking? | **No** |
| Linked to user | **Yes** |
| Used for | **App Functionality** |

### 5. Advertising Data (solo si Connect lo exige por AdMob)

Si debes declarar datos de publicidad **sin** tracking:

| Campo | Valor |
|-------|--------|
| ¿Tracking? | **No** |
| Linked to user | **No** |
| Used for | **Third-Party Advertising** |

No declares **Coarse Location** salvo que realmente la uses (esta app no).

### 6. Diagnostics (opcional)

Crash Data de Apple → tracking **No**.

## No declares (v1)

- Location (coarse / precise)
- Tracking = **Yes** en cualquier categoría
- ATT / `NSUserTrackingUsageDescription` (no hace falta con ads `npa=1`)

## Privacy Policy URL

```
https://xppocket.app/privacy
```

## Terms of Use (EULA) — metadata App Store

Obligatorio con suscripciones auto-renovables (3.1.2(c)):

- En **App Description** o campo **EULA**: `https://xppocket.app/terms`
- En la app: ya hay enlace en el paywall Pro

Ejemplo para la descripción (añadir al final):

```
Terms of Use: https://xppocket.app/terms
Privacy Policy: https://xppocket.app/privacy
```

## Coherencia

| Sitio | Estado |
|-------|--------|
| Ads | `AdsConfig.nonPersonalizedRequest()` (`npa=1`) |
| `PrivacyInfo.xcprivacy` | `NSPrivacyTracking` = false |
| Paywall | Privacy + Terms of Use |
| Connect App Privacy | Tracking = No; sin Location |
