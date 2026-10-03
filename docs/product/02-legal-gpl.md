# Legal y GPL

> **Aviso:** orientación para desarrolladores. No sustituye asesoramiento legal. Ante dudas de marca, copyright de juegos o fiscalidad de suscripciones, consulta a un profesional.

## Base: qué licencia cubre qué

| Componente | Licencia | Implicación |
|------------|----------|-------------|
| empo-app (launcher Swift) | **GPLv2+** | Código fuente publicado bajo GPL; aviso de copyright. |
| mkxp-z-apple-mobile (motor) | **GPLv2+** | Igual; tu rama postload también GPL si distribuyes binario. |
| mkxp-z upstream | **GPLv2+** | Parches sueltos pueden ir upstream; el fork iOS es derivado. |
| Deps (SDL, OpenSSL, etc.) | Varias (LGPL, zlib, …) | Ya listadas en app → **Open-source licenses**. |

Referencia proyecto: [README.md](../../README.md#license).

## Obligaciones al distribuir en App Store

Cuando subes un binario (TestFlight o producción), **recibes usuarios** bajo GPL. Mínimo práctico:

### 1. Código fuente correspondiente

- [ ] Repo **público** con el código exacto (o etiqueta/tag) de cada build subido.
- [ ] En app o App Store: enlace claro al repo («Código fuente» en Settings / descripción).
- [ ] Por versión: tag `v1.0.0` ↔ build number subido a Connect.

**Plantilla texto Settings (adaptar):**

> El código fuente de esta app está disponible bajo GNU GPL v2 o posterior en:  
> `TODO: https://github.com/tu-usuario/tu-app`

### 2. Licencia y avisos

- [ ] Mantener pantalla **Open-source licenses** ([LicensesView.swift](../../ios/Empo/src/Settings/LicensesView.swift)).
- [ ] No quitar copyright de Empo/mkxp-z de los headers que copies.
- [ ] README del repo: sección **Credits** (Ancurio, mkxp-z, mateo-m/Empo, etc.).

### 3. GPL y App Store

- Apple **no prohibe** apps GPL en la store.
- No puedes imponer restricciones adicionales sobre la parte GPL (p.ej. prohibir recompilar).
- **Sí puedes cobrar** por la app en la store (Apple cobra por distribución/conveniencia).
- La suscripción «Pro sin ads» sobre el **mismo binario GPL** es habitual si el binario Pro sigue siendo GPL y publicas su fuente. Lo que vendes es conveniencia/servicio (hosting, sync futuro), no el derecho exclusivo al motor.

Si algún día separas «servidor Pro» propietario del cliente GPL, el servidor puede ser distinto; el cliente que enlaza GPL sigue GPL.

## Contenido de juegos (usuarios)

La app **no distribuye** juegos RPG Maker. El usuario importa archivos propios.

### En app y metadata

- [ ] Disclaimer: el usuario debe tener derecho sobre los juegos que importa.
- [ ] No preinstalar fangames ni ROMs.
- [ ] Capturas App Store: solo juegos con permiso o assets genéricos/demo propio.

### Pokémon / IP de terceros

- Alto riesgo de rechazo o reclamación si marketing menciona Pokémon o muestra IP Nintendo.
- Describir: «compatible con juegos RPG Maker XP / Essentials» sin marcas registradas ajenas.

## Marca «Empo»

- Empo es proyecto de mateo-m; tu app debe usar **nombre distinto**.
- GPL permite fork; no permite pasar tu app por la oficial Empo.

## Privacidad (resumen)

Detalle en [06-privacidad.md](./06-privacidad.md). Obligatorio para App Store:

- [ ] Política de privacidad URL pública.
- [ ] App Privacy questionnaire en Connect (datos recogidos).
- [ ] Si añades ads: ATT, declaración de tracking según caso.

## Checklist pre–TestFlight

- [ ] Repo público creado y push del estado actual.
- [ ] README con licencia GPL y link a fuentes upstream.
- [ ] Enlace a fuente visible desde la app.
- [ ] Privacy policy URL (aunque sea página GitHub wiki mínima).
- [ ] Sin secretos/API keys en el repo (AdMob, etc. → xcconfig gitignored).

## Checklist pre–producción

- [ ] Tag git = versión App Store.
- [ ] Texto de suscripción cumple [App Store Review Guidelines 3.1](https://developer.apple.com/app-store/review/guidelines/#subscriptions) (precio, renovación, cancelación).
- [ ] Restaurar compras implementado (Fase D).

## Plantilla README legal (repo)

Copia al README de tu fork cuando renombres:

```markdown
## Licencia

Este proyecto es software libre bajo [GPL-2.0-or-later](LICENSE).

Deriva de [Empo](https://github.com/mateo-m/empo-app) y [mkxp-z-apple-mobile](https://github.com/mateo-m/mkxp-z-apple-mobile).

## Código fuente

Correspondiente a la versión publicada en App Store: tag `vX.Y.Z`.

## Juegos

Esta aplicación no incluye juegos. Los usuarios importan contenido bajo su propia responsabilidad.
```
