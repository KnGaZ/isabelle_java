# Isabella Bacalar — reconstrucción en Java

Sistema de gestión del **Hotel Isabella (Bacalar)** reescrito en el stack propio:
**Spring MVC + Thymeleaf + MySQL**, empaquetado como **WAR para WildFly** (junto a `sail.war`).

Este repo corresponde al arranque del traspaso: **Fase 1 (cimientos)** + **Fase 2 (esquema de datos)**.

---

## Qué incluye esta entrega

- Proyecto Maven que compila a `target/isabella.war` (Spring Boot 2.7.18, Java 11).
- Arranque como WAR en WildFly (`ServletInitializer`) o como JAR standalone.
- Conexión a MySQL configurada + página **/salud** que verifica la conectividad.
- **Sistema de diseño clonado 1:1** (sección 3 del traspaso): paleta "laguna Bacalar",
  tipografías Bricolage Grotesque / Instrument Sans / Space Mono, tarjetas, chips,
  toasts, header con la marca y **bottom nav filtrado por rol**.
- **Esquema MySQL completo** (`db/schema.sql`): todas las tablas, ENUMs,
  columnas generadas (`amount_mxn`, `difference`) y las 4 vistas (`v_cash_balance`,
  `v_daily_totals`, `v_daily_by_caja`, `v_daily_by_area`).
- **Semillas de catálogos** (`db/seed.sql`): roles, cajas, áreas, canales, socios,
  cuentas y las 19 habitaciones (i1–i20 **sin i13**).

> Arranca **sin datos de operación**, tal como pide la sección 14. La caja se empieza a capturar ~15/sep.

---

## Requisitos

- JDK 11
- Maven 3.6+
- MySQL 5.7 (o 8.x) en el VPS

---

## 1) Preparar MySQL

Crear una base **nueva** (no reutilizar `sail`) y su usuario:

```sql
CREATE DATABASE isabella CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'isabella'@'localhost' IDENTIFIED BY 'PON_UNA_CLAVE_FUERTE';
GRANT ALL PRIVILEGES ON isabella.* TO 'isabella'@'localhost';
FLUSH PRIVILEGES;
```

Cargar esquema y catálogos:

```bash
mysql -u isabella -p isabella < src/main/resources/db/schema.sql
mysql -u isabella -p isabella < src/main/resources/db/seed.sql
```

Luego pon la clave real en `src/main/resources/application.properties`
(`spring.datasource.password`).

> **Respaldos:** montar un respaldo diario propio para la base `isabella` desde el día 1
> (es la caja del hotel). No mezclar con `/root/respaldos_sail/`.

---

## 2) Compilar

```bash
mvn clean package -DskipTests
# genera target/isabella.war
```

---

## 3) Desplegar en WildFly

```bash
cp target/isabella.war /opt/wildfly/standalone/deployments/
# el deployment scanner crea isabella.war.deployed cuando termina
```

La app queda en `http://TU_HOST:8080/isabella/`
(contexto `/isabella` por el nombre del WAR; se puede montar detrás de Nginx/Apache
y el dominio `app.isabellabacalar.com` cuando toque HTTPS).

Verifica:
- `…/isabella/`        → inicio con el look clonado.
- `…/isabella/salud`   → debe decir **OK** y mostrar la versión de MySQL.

### Alternativa: JAR standalone
Cambia el scope de `spring-boot-starter-tomcat` a `compile` en el `pom.xml` y corre:
```bash
mvn spring-boot:run          # dev, puerto 8080
# o en prod: java -jar target/isabella.war  (con server.port=8083)
```

---

## Decisiones tomadas (revisar y confirmar)

1. **IDs = BIGINT AUTO_INCREMENT.** Arranque limpio sin migración → es lo más simple.
   (El documento permitía CHAR(36) UUID; se descartó por no aportar aquí.)
2. **`folio` es la PK de `cash_movements`** (el número de recibo). MySQL solo permite
   una columna AUTO_INCREMENT por tabla, así que el folio *es* la identidad de la fila.
3. **Interactividad (pantallas 2, 3, 7, 9):** se resolverá con **JS ligero del lado
   cliente** (fetch a endpoints REST del propio Spring que devuelven JSON), con opción
   de Alpine.js/htmx para toggles y cálculos en vivo. Thymeleaf server-side para el resto.
   Se define pantalla por pantalla al entrar a cada fase.
4. **Columna `fecha`** se llama `date` en la BD (respetando el esquema original),
   siempre entre backticks en el DDL.

Si prefieres otra opción en cualquiera de estos puntos, se ajusta antes de seguir.

---

## Roadmap (plan por fases, sección 13)

- [x] **Fase 1 — Cimientos:** proyecto Spring (WAR), conexión MySQL, Thymeleaf,
      layout base con paleta/fuentes (header + bottom nav), deploy verificable.
- [x] **Fase 2 — Datos:** esquema MySQL (tablas + enums + generated columns + vistas)
      y seeds de catálogos.
- [ ] **Fase 3 — Auth:** Spring Security (login por email + BCrypt, sesión, roles),
      pantalla de login, navegación filtrada por el usuario autenticado, admin de usuarios.
- [ ] **Fase 4 — Núcleo de dinero:** Captura (con transferencia), Gastos, Arqueo,
      Dashboard (Operativo + Dirección). Reglas de la sección 5.
- [ ] **Fase 5 — Reservas + Housekeeping.**
- [ ] **Fase 6 — Admin** (usuarios con contraseña/correo, cuentas, catálogos) +
      bitácora + Movimientos.
- [ ] **Fase 7 — WhatsApp** (empezar con `wa.me`), respaldos automáticos, HTTPS, dominio.

**Meta:** listo para captura en vivo ~15 de septiembre, base limpia.
```
