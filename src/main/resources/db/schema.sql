-- =================================================================
--  Isabella Bacalar — Esquema MySQL 5.7  (Fase 2)
--  Conversion del esquema Postgres original (seccion 4 del traspaso).
--
--  Decisiones tomadas:
--   - IDs: BIGINT AUTO_INCREMENT (arranque limpio, sin migracion de datos).
--   - Enums de Postgres -> ENUM de MySQL.
--   - Columnas generadas STORED (amount_mxn, difference): soportadas en 5.7.
--   - RLS de Postgres -> se implementa en Spring Security + capa de servicio.
--   - cash_movements: 'folio' es la PK auto_increment (el numero de recibo).
--
--  Motor InnoDB + utf8mb4 en todas las tablas.
-- =================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================== CATALOGOS ===========================

CREATE TABLE IF NOT EXISTS roles (
  id    BIGINT AUTO_INCREMENT PRIMARY KEY,
  code  VARCHAR(20)  NOT NULL UNIQUE,
  name  VARCHAR(60)  NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS partners (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(120) NOT NULL,
  active     TINYINT(1)   NOT NULL DEFAULT 1,
  share_pct  DECIMAL(5,2) NOT NULL DEFAULT 25.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS accounts (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(120) NOT NULL,
  kind       VARCHAR(40)  NULL,           -- p.ej. BANCO, SOCIO, EFECTIVO
  active     TINYINT(1)   NOT NULL DEFAULT 1,
  partner_id BIGINT       NULL,
  CONSTRAINT fk_accounts_partner FOREIGN KEY (partner_id) REFERENCES partners(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS cajas (
  id     BIGINT AUTO_INCREMENT PRIMARY KEY,
  code   VARCHAR(30) NOT NULL UNIQUE,
  name   VARCHAR(60) NOT NULL,
  emoji  VARCHAR(8)  NULL,
  active TINYINT(1)  NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS areas (
  id     BIGINT AUTO_INCREMENT PRIMARY KEY,
  code   VARCHAR(40) NOT NULL UNIQUE,
  name   VARCHAR(80) NOT NULL,
  active TINYINT(1)  NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS channels (
  id     BIGINT AUTO_INCREMENT PRIMARY KEY,
  code   VARCHAR(30) NOT NULL UNIQUE,
  name   VARCHAR(60) NOT NULL,
  active TINYINT(1)  NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS suppliers (
  id     BIGINT AUTO_INCREMENT PRIMARY KEY,
  name   VARCHAR(160) NOT NULL,
  notes  VARCHAR(255) NULL,
  active TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS room_types (
  id     BIGINT AUTO_INCREMENT PRIMARY KEY,
  code   VARCHAR(30) NOT NULL UNIQUE,
  name   VARCHAR(80) NOT NULL,
  active TINYINT(1)  NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================== USUARIOS ============================

CREATE TABLE IF NOT EXISTS users (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  full_name     VARCHAR(160) NOT NULL,
  phone         VARCHAR(40)  NULL,
  email         VARCHAR(160) NULL UNIQUE,   -- camaristas pueden no tener login
  role_id       BIGINT       NOT NULL,
  password_hash VARCHAR(100) NULL,          -- BCrypt; null si no tiene acceso
  active        TINYINT(1)   NOT NULL DEFAULT 1,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ====================== HABITACIONES / RESERVAS ==================

CREATE TABLE IF NOT EXISTS rooms (
  id        BIGINT AUTO_INCREMENT PRIMARY KEY,
  code      VARCHAR(10)   NOT NULL UNIQUE,  -- i1..i20 (sin i13)
  name      VARCHAR(80)   NULL,
  base_rate DECIMAL(12,2) NULL,
  active    TINYINT(1)    NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS guests (
  id        BIGINT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(160) NOT NULL,
  phone     VARCHAR(40)  NULL,
  email     VARCHAR(160) NULL,
  country   VARCHAR(60)  NULL,
  notes     VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS reservations (
  id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
  room_id            BIGINT NOT NULL,
  guest_id           BIGINT NULL,
  channel_id         BIGINT NULL,
  check_in           DATE   NOT NULL,
  check_out          DATE   NOT NULL,
  pax                INT    NOT NULL DEFAULT 1,
  status             ENUM('CONFIRMADA','EN_CASA','SALIDA','CANCELADA','NO_SHOW')
                       NOT NULL DEFAULT 'CONFIRMADA',
  breakfast_included TINYINT(1) NOT NULL DEFAULT 0,
  special_requests   VARCHAR(255) NULL,
  notes              VARCHAR(255) NULL,
  source             ENUM('MANUAL','BEDS24') NOT NULL DEFAULT 'MANUAL',
  source_ref         VARCHAR(120) NULL,
  rate_per_night     DECIMAL(12,2) NULL,
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_res_room    FOREIGN KEY (room_id)    REFERENCES rooms(id),
  CONSTRAINT fk_res_guest   FOREIGN KEY (guest_id)   REFERENCES guests(id),
  CONSTRAINT fk_res_channel FOREIGN KEY (channel_id) REFERENCES channels(id),
  INDEX idx_res_dates (check_in, check_out),
  INDEX idx_res_room  (room_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS housekeeping (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  room_id     BIGINT NOT NULL,
  `date`      DATE   NOT NULL,
  status      ENUM('LIMPIEZA','REFRESCADA','LISTA','PENDIENTE','SALIDA','LLEGADA','SALIDA_LLEGADA')
                NOT NULL DEFAULT 'PENDIENTE',
  assigned_to BIGINT NULL,
  notes       VARCHAR(255) NULL,
  CONSTRAINT fk_hk_room     FOREIGN KEY (room_id)     REFERENCES rooms(id),
  CONSTRAINT fk_hk_assigned FOREIGN KEY (assigned_to) REFERENCES users(id),
  UNIQUE KEY uq_hk_room_date (room_id, `date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS maintenance_tickets (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  room_id     BIGINT NULL,
  title       VARCHAR(160) NOT NULL,
  description VARCHAR(500) NULL,
  status      VARCHAR(30)  NOT NULL DEFAULT 'ABIERTO',
  reported_by BIGINT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_mt_room     FOREIGN KEY (room_id)     REFERENCES rooms(id),
  CONSTRAINT fk_mt_reporter FOREIGN KEY (reported_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================= DINERO ============================

CREATE TABLE IF NOT EXISTS cash_movements (
  folio          BIGINT AUTO_INCREMENT PRIMARY KEY,   -- numero de recibo
  `date`         DATE   NOT NULL,
  user_id        BIGINT NULL,
  type           ENUM('INGRESO','EGRESO')             NOT NULL,
  caja_id        BIGINT NOT NULL,
  area_id        BIGINT NULL,
  concept        VARCHAR(200) NULL,
  amount         DECIMAL(12,2) NOT NULL,
  currency       ENUM('MXN','USD')                    NOT NULL DEFAULT 'MXN',
  tender         ENUM('EFECTIVO','TARJETA','TRANSFERENCIA') NOT NULL DEFAULT 'EFECTIVO',
  reservation_id BIGINT NULL,
  exchange_rate  DECIMAL(10,4) NOT NULL DEFAULT 1.0000,
  -- Columna generada: consolida USD a MXN (regla 3, seccion 5).
  amount_mxn     DECIMAL(16,2) AS (amount * exchange_rate) STORED,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cm_user FOREIGN KEY (user_id)        REFERENCES users(id),
  CONSTRAINT fk_cm_caja FOREIGN KEY (caja_id)        REFERENCES cajas(id),
  CONSTRAINT fk_cm_area FOREIGN KEY (area_id)        REFERENCES areas(id),
  CONSTRAINT fk_cm_res  FOREIGN KEY (reservation_id) REFERENCES reservations(id),
  INDEX idx_cm_date   (`date`),
  INDEX idx_cm_caja   (caja_id),
  INDEX idx_cm_area   (area_id),
  INDEX idx_cm_tender (type, tender)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS cash_counts (
  id             BIGINT AUTO_INCREMENT PRIMARY KEY,
  `date`         DATE   NOT NULL,
  caja_id        BIGINT NOT NULL,
  currency       ENUM('MXN','USD') NOT NULL DEFAULT 'MXN',
  counted_amount DECIMAL(14,2) NOT NULL,
  system_amount  DECIMAL(14,2) NOT NULL,
  -- Columna generada: diferencia = contado - sistema (regla 4, seccion 5).
  difference     DECIMAL(14,2) AS (counted_amount - system_amount) STORED,
  user_id        BIGINT NULL,
  notes          VARCHAR(255) NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cc_caja FOREIGN KEY (caja_id) REFERENCES cajas(id),
  CONSTRAINT fk_cc_user FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_cc_date (`date`),
  INDEX idx_cc_caja (caja_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS purchases (
  id               BIGINT AUTO_INCREMENT PRIMARY KEY,
  `date`           DATE   NOT NULL,
  concept          VARCHAR(200) NOT NULL,
  amount           DECIMAL(12,2) NOT NULL,
  area_id          BIGINT NULL,
  supplier_id      BIGINT NULL,
  account_id       BIGINT NULL,
  payment_method   ENUM('DEBITO','TRANSFERENCIA','EFECTIVO','CREDITO') NOT NULL,
  responsible_id   BIGINT NULL,
  status           ENUM('PAGADO','PENDIENTE','POR_REEMBOLSAR') NOT NULL DEFAULT 'PAGADO',
  invoice_folio    VARCHAR(60) NULL,
  -- Enlace opcional para no doble-contar cuando se paga en efectivo de caja.
  cash_movement_id BIGINT NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pur_area     FOREIGN KEY (area_id)          REFERENCES areas(id),
  CONSTRAINT fk_pur_supplier FOREIGN KEY (supplier_id)      REFERENCES suppliers(id),
  CONSTRAINT fk_pur_account  FOREIGN KEY (account_id)       REFERENCES accounts(id),
  CONSTRAINT fk_pur_resp     FOREIGN KEY (responsible_id)   REFERENCES users(id),
  CONSTRAINT fk_pur_cm       FOREIGN KEY (cash_movement_id) REFERENCES cash_movements(folio),
  INDEX idx_pur_date (`date`),
  INDEX idx_pur_area (area_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS commissions (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  `date`     DATE   NOT NULL,
  concept    VARCHAR(200) NULL,
  amount     DECIMAL(12,2) NOT NULL,
  area_id    BIGINT NULL,
  status     VARCHAR(30) NOT NULL DEFAULT 'PENDIENTE',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_com_area FOREIGN KEY (area_id) REFERENCES areas(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS partner_transactions (
  id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
  partner_id          BIGINT NOT NULL,
  type                ENUM('APORTACION','PAGO_POR_SOCIO','RETIRO','DISTRIBUCION') NOT NULL,
  amount              DECIMAL(14,2) NOT NULL,
  `date`              DATE   NOT NULL,
  related_purchase_id BIGINT NULL,
  notes               VARCHAR(255) NULL,
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pt_partner  FOREIGN KEY (partner_id)          REFERENCES partners(id),
  CONSTRAINT fk_pt_purchase FOREIGN KEY (related_purchase_id) REFERENCES purchases(id),
  INDEX idx_pt_partner (partner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS exchange_rates (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  `date`     DATE   NOT NULL,
  rate       DECIMAL(10,4) NOT NULL,        -- USD -> MXN
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_rate_date (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================= SISTEMA ===========================

CREATE TABLE IF NOT EXISTS audit_log (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id    BIGINT NULL,
  action     VARCHAR(60)  NOT NULL,   -- CREAR, EDITAR, BORRAR, CAMBIAR_CLAVE...
  entity     VARCHAR(60)  NOT NULL,   -- users, cajas, purchases...
  entity_id  VARCHAR(60)  NULL,
  diff       JSON         NULL,       -- MySQL 5.7 soporta JSON
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_audit_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS message_templates (
  id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  code    VARCHAR(60)  NOT NULL UNIQUE,
  name    VARCHAR(120) NOT NULL,
  body    TEXT         NOT NULL,
  channel VARCHAR(30)  NOT NULL DEFAULT 'WHATSAPP',
  active  TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS notifications (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  to_addr    VARCHAR(120) NULL,
  body       TEXT         NULL,
  status     VARCHAR(30)  NOT NULL DEFAULT 'PENDIENTE',
  provider   VARCHAR(30)  NULL,
  ref        VARCHAR(120) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================= VISTAS ============================
-- (En MySQL no existe security_invoker; se omite.)

-- Saldo por caja/moneda = SUMA con signo de amount_mxn, SOLO EFECTIVO.
-- (Regla 2, seccion 5: tarjeta y transferencia NO son efectivo fisico.)
CREATE OR REPLACE VIEW v_cash_balance AS
SELECT caja_id,
       currency,
       SUM(CASE WHEN type = 'INGRESO' THEN amount_mxn ELSE -amount_mxn END) AS balance_mxn
FROM   cash_movements
WHERE  tender = 'EFECTIVO'
GROUP BY caja_id, currency;

-- Totales diarios (todas las formas de pago).
CREATE OR REPLACE VIEW v_daily_totals AS
SELECT `date`,
       SUM(CASE WHEN type = 'INGRESO' THEN amount_mxn ELSE 0 END) AS ingresos,
       SUM(CASE WHEN type = 'EGRESO'  THEN amount_mxn ELSE 0 END) AS egresos
FROM   cash_movements
GROUP BY `date`;

-- Totales diarios por caja.
CREATE OR REPLACE VIEW v_daily_by_caja AS
SELECT `date`,
       caja_id,
       SUM(CASE WHEN type = 'INGRESO' THEN amount_mxn ELSE 0 END) AS ingresos,
       SUM(CASE WHEN type = 'EGRESO'  THEN amount_mxn ELSE 0 END) AS egresos
FROM   cash_movements
GROUP BY `date`, caja_id;

-- Totales diarios por area.
CREATE OR REPLACE VIEW v_daily_by_area AS
SELECT `date`,
       area_id,
       SUM(CASE WHEN type = 'INGRESO' THEN amount_mxn ELSE 0 END) AS ingresos,
       SUM(CASE WHEN type = 'EGRESO'  THEN amount_mxn ELSE 0 END) AS egresos
FROM   cash_movements
WHERE  area_id IS NOT NULL
GROUP BY `date`, area_id;

SET FOREIGN_KEY_CHECKS = 1;
