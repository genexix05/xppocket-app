# App Privacy (App Store Connect) — respuestas v1 (con ads + IAP)

Usa esto en **App Store Connect → App Privacy → Edit**.
Debe coincidir con el binario: Sign in with Apple opcional, cloud save Pro,
StoreKit, AdMob **personalizado si el usuario lo permite** (UMP en EEA/UK + aviso ATT).

## Pregunta inicial

| Pregunta | Respuesta |
|----------|-----------|
| ¿Recoges datos de esta app? | **Sí** |

## Tracking

| Pregunta | Respuesta |
|----------|-----------|
| ¿Usas los datos para trackear? | **Sí**: Device ID y Advertising Data (AdMob, solo con ATT permitido) |

El resto de tipos se declaran **sin** tracking.

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

### 5. AdMob (versión gratuita)

| Tipo | ¿Tracking? | Linked to user | Used for |
|------|-----------|----------------|----------|
| Identifiers → **Device ID** | **Yes** | **No** | Third-Party Advertising, Analytics |
| Usage Data → **Advertising Data** | **Yes** | **No** | Third-Party Advertising, Analytics |
| Usage Data → **Product Interaction** | **No** | **No** | Third-Party Advertising, Analytics |
| Location → **Coarse Location** (IP) | **No** | **No** | Third-Party Advertising |

### 6. Diagnostics (opcional)

Crash Data de Apple → tracking **No**.

## No declares

- Precise Location

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
| Ads | `AdsConfig.adRequest()`: UMP + ATT deciden la personalización |
| `PrivacyInfo.xcprivacy` | `NSPrivacyTracking` = true; Device ID y Advertising Data con tracking |
| Paywall | Privacy + Terms of Use |
| Connect App Privacy | Tracking = Sí (Device ID, Advertising Data) |
