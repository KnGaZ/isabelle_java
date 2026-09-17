-- =================================================================
--  Isabella Bacalar — Semillas de catalogos  (Fase 2)
--  Arranque SIN datos de operacion: solo estructura + catalogos.
--  (Seccion 14: la operacion se carga desde ~15/sep.)
--
--  Idempotente: usa INSERT ... ON DUPLICATE KEY para poder re-ejecutar.
-- =================================================================

SET NAMES utf8mb4;

-- ---- Roles ----
INSERT INTO roles (code, name) VALUES
  ('ADMIN',     'Administrador'),
  ('GERENCIA',  'Gerencia'),
  ('SOCIO',     'Socio'),
  ('RECEPCION', 'Recepcion'),
  ('CAMARISTA', 'Camarista')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- ---- Cajas ----
INSERT INTO cajas (code, name, emoji, active) VALUES
  ('CAJA_HOTEL', 'Caja Hotel', '🏨', 1),
  ('RESTAURANTE','Restaurante','🍽️', 1),
  ('PONTON',     'Ponton',     '⛵', 1),
  ('JET_SKI',    'Jet Ski',    '🌊', 1),
  ('BORREGOS',   'Borregos',   '🐏', 1)
ON DUPLICATE KEY UPDATE name = VALUES(name), emoji = VALUES(emoji), active = VALUES(active);

-- ---- Areas ----
INSERT INTO areas (code, name, active) VALUES
  ('HOSPEDAJE',    'Hospedaje',    1),
  ('TOURS',        'Tours',        1),
  ('BUFFET',       'Buffet',       1),
  ('RESTAURANTE',  'Restaurante',  1),
  ('DAYPASS',      'Daypass',      1),
  ('COMISIONES',   'Comisiones',   1),
  ('MANTENIMIENTO','Mantenimiento',1),
  ('RECEPCION',    'Recepcion',    1),
  ('RH',           'RH',           1),
  ('HOTEL',        'Hotel',        1),
  ('COMIDA_STAFF', 'Comida Staff', 1),
  ('AMA_LLAVES',   'Ama de Llaves',1)
ON DUPLICATE KEY UPDATE name = VALUES(name), active = VALUES(active);

-- ---- Canales (reservas) ----
INSERT INTO channels (code, name, active) VALUES
  ('BOOKING', 'Booking', 1),
  ('EXPEDIA', 'Expedia', 1),
  ('DIRECTO', 'Directo', 1),
  ('MHC',     'MHC',     1),
  ('OTRO',    'Otro',    1),
  ('WALK_IN', 'Walk-in', 1),
  ('GOOGLE',  'Google',  1),
  ('AIRBNB',  'Airbnb',  1)
ON DUPLICATE KEY UPDATE name = VALUES(name), active = VALUES(active);

-- ---- Socios (25% c/u) ----
INSERT INTO partners (name, active, share_pct) VALUES
  ('Isabel',  1, 25.00),
  ('Eyder',   1, 25.00),
  ('Roberto', 1, 25.00),
  ('Jonatan', 1, 25.00)
ON DUPLICATE KEY UPDATE share_pct = VALUES(share_pct), active = VALUES(active);

-- ---- Cuentas (ajustar kind/partner segun corresponda) ----
INSERT INTO accounts (name, kind, active) VALUES
  ('Caribe',    'BANCO', 1),
  ('D. Robert', 'OTRO',  1)
ON DUPLICATE KEY UPDATE kind = VALUES(kind), active = VALUES(active);

-- ---- Habitaciones: i1..i20 SIN i13 (19 en total) ----
INSERT INTO rooms (code, name, active) VALUES
  ('i1','Habitacion i1',1),  ('i2','Habitacion i2',1),  ('i3','Habitacion i3',1),
  ('i4','Habitacion i4',1),  ('i5','Habitacion i5',1),  ('i6','Habitacion i6',1),
  ('i7','Habitacion i7',1),  ('i8','Habitacion i8',1),  ('i9','Habitacion i9',1),
  ('i10','Habitacion i10',1),('i11','Habitacion i11',1),('i12','Habitacion i12',1),
  ('i14','Habitacion i14',1),('i15','Habitacion i15',1),('i16','Habitacion i16',1),
  ('i17','Habitacion i17',1),('i18','Habitacion i18',1),('i19','Habitacion i19',1),
  ('i20','Habitacion i20',1)
ON DUPLICATE KEY UPDATE name = VALUES(name), active = VALUES(active);

-- =================================================================
--  BOOTSTRAP DE ACCESO (para la Fase 3 - Auth)
--  Descomenta para crear un ADMIN inicial y poder entrar al sistema.
--  El hash es BCrypt de la contrasena temporal:  Isabella2025!
--  CAMBIALA en cuanto entres (Admin > Usuarios > cambiar contrasena).
-- -----------------------------------------------------------------
-- INSERT INTO users (full_name, email, role_id, password_hash, active)
-- SELECT 'Vane', 'vane@isabellabacalar.com', r.id,
--        '$2b$10$0ieiiARsmEwRbosBGfizYOLlpVlVhYjnOmAf39Qx98MzKI5P8ZBjO', 1
-- FROM roles r WHERE r.code = 'ADMIN'
-- ON DUPLICATE KEY UPDATE full_name = VALUES(full_name);
