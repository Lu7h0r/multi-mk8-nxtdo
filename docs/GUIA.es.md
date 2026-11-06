# Guía rápida (español)

Con esto tienes en la misma Switch **CTGP Deluxe** para jugar local y **Mario Kart 8 Deluxe** actualizado para jugar online en Nextendo.

**Qué necesitas:**
- Switch con CFW (Atmosphère).
- Tu propio volcado de MK8D: el juego base y la actualización **3.0.3**.
- Tus `prod.keys` (sacadas con Lockpick_RCM).
- CTGP-DX descargado de ctgpdx.com.
- Un PC Mac o Linux con unos 50 GB libres.

**Pasos:**
1. **Lockpick_RCM** → *Dump from EmuNAND* → copia `prod.keys` al PC.
2. **nxdumptool** → MK8D → activa *remove titlekey crypto* → vuelca el **base** y la **actualización 3.0.3**. Hazlo **antes** de actualizar el juego.
3. En el PC: `./scripts/setup-tools.sh` (solo la primera vez).
4. `./scripts/build.sh --base BASE.nsp --update UPD_303.nsp --ctgp CARPETA_CTGP --keys prod.keys`, que tarda unos 30 minutos.
5. Instala `out/CTGP-Deluxe_0100C7A5D0DE0000.nsp` con **DBI**. Aparece como juego aparte.
6. Actualiza el MK8D original a **4.0.1** con DBI, porque la actualización del eShop falla en CFW.
7. Borra el CTGP de `atmosphere/contents/0100152000022000` para que el original quede limpio para el online.
8. Online en Nextendo: vincula tu **Discord** (si no, sale el error 2306-0807).

**Importante:** no compartas el NSP que generes. Cada persona arma el suyo con sus propios archivos.

¿Problemas? Mira la tabla de errores en el README o la [wiki de Nextendo](https://wiki.nextendo.network/errors).
