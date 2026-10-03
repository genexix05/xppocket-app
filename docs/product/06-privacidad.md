# Privacidad, ATT y App Privacy

## Estado actual (sin ads ni IAP)

Archivo: [ios/Empo/PrivacyInfo.xcprivacy](../../ios/Empo/PrivacyInfo.xcprivacy)

- `NSPrivacyTracking`: **false**
- Datos recogidos declarados: **ninguno**
- APIs requeridas: UserDefaults (`CA92.1`), file timestamps (`C617.1`)

Settings enlaza a wiki upstream — **cambiar** en rebrand:

- [SettingsView.swift](../../ios/Empo/src/Settings/SettingsView.swift) → `https://github.com/mateo-m/empo-app/wiki/privacy-policy`

## Política de privacidad (publicada)

| Campo | Valor |
|-------|-------|
| URL pública | `https://xppocket.app/privacy` |
| Fuente | [server/xppocket-web/html/privacy.html](../../server/xppocket-web/html/privacy.html) |
| Idiomas | ES + EN en la misma página |

Contenido cubre: on-device, Sign in with Apple opcional, cloud save Pro, layouts API, sin ads/analytics.

- [x] Borrador escrito.
- [x] URL accesible sin login (`https://xppocket.app/privacy`).
- [x] Enlace en app (Settings → `AppInfo.privacyURL`).
- [ ] Misma URL en App Store Connect (App Information).

## App Store Connect — App Privacy

Responder según **realidad del binario** subido.

### v0.1 / TestFlight actual (cuenta opcional + cloud save)

Guía campo a campo: [07-app-privacy-connect.md](./07-app-privacy-connect.md).

- [ ] Declarar Email + User ID + User Content (saves) — App Functionality, no tracking.
- [ ] Diagnostics solo si usas crash reports de Apple.
- [ ] No location / purchases / ads (hasta Fase D).

Revisar tras cada release.

### v1.1 (con AdMob + suscripción)

Añadir declaración según [Google / Apple labels](https://developer.apple.com/app-store/app-privacy-details/):

- [ ] Identifiers (advertising ID si ATT aceptado).
- [ ] Purchases (StoreKit).
- [ ] Usage data / diagnostics si el SDK lo exige.

Actualizar `PrivacyInfo.xcprivacy`:

- [ ] `NSPrivacyTracking` → true si usas tracking cross-app.
- [ ] `NSPrivacyCollectedDataTypes` — rellenar tipos.
- [ ] `NSUserTrackingUsageDescription` en Info.plist si ATT.

## ATT (Tracking)

Solo si muestras prompt de seguimiento:

```xml
<!-- Info.plist / project.yml INFOPLIST_KEY -->
<key>NSUserTrackingUsageDescription</key>
<string>Usamos identificadores para mostrar anuncios más relevantes. Puedes usar la app sin aceptar.</string>
```

- [ ] Decidir: ads personalizados vs no personalizados.
- [ ] Implementar `ATTrackingManager.requestTrackingAuthorization` antes del primer ad personalizado.

## Checklist pre-submit

- [ ] Privacy URL live.
- [ ] Texto app = cuestionario Connect = `PrivacyInfo.xcprivacy`.
- [ ] Sin SDK ocultos que recojan datos no declarados.
- [ ] Logs diagnóstico (Settings) — aclarar en policy si exportan archivos locales.

## Plantilla URL GitHub wiki

Si no tienes web propia:

```
https://github.com/TU_USUARIO/TU_REPO/wiki/Privacy-Policy
```

Crea página wiki con el borrador de arriba.
