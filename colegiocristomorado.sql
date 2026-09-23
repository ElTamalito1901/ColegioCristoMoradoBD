-- ============================================================
-- BASE DE DATOS: ColegioCristoMorado
-- ============================================================
--
-- IMPORTANTE:
-- Este script elimina las tablas del proyecto y las crea
-- nuevamente desde cero.
--
-- Debes estar conectado a la base de datos:
-- ColegioCristoMorado
-- ============================================================


-- ============================================================
-- 1. ELIMINAR TABLAS EXISTENTES
-- ============================================================

DROP TABLE IF EXISTS personal_permisos CASCADE;
DROP TABLE IF EXISTS personal CASCADE;
DROP TABLE IF EXISTS codigos_verificacion CASCADE;
DROP TABLE IF EXISTS mensaje_destinatarios CASCADE;
DROP TABLE IF EXISTS mensajes CASCADE;
DROP TABLE IF EXISTS comunicado_lecturas CASCADE;
DROP TABLE IF EXISTS comunicado_destinatarios CASCADE;
DROP TABLE IF EXISTS comunicados CASCADE;
DROP TABLE IF EXISTS estudiante_familiar CASCADE;
DROP TABLE IF EXISTS docentes CASCADE;
DROP TABLE IF EXISTS estudiantes CASCADE;
DROP TABLE IF EXISTS padres_familia CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;

CREATE DATABASE "colegiocristomorado";

-- ============================================================
-- 2. TABLA: usuarios
-- ============================================================

CREATE TABLE usuarios (
    id BIGSERIAL PRIMARY KEY,

    nombre VARCHAR(100) NOT NULL,

    -- Gmail personal: lo vincula y verifica el propio usuario (con código)
    correo VARCHAR(150) UNIQUE,

    correo_verificado BOOLEAN NOT NULL DEFAULT FALSE,

    password VARCHAR(255) NOT NULL,

    rol VARCHAR(50) NOT NULL DEFAULT 'USER',

    -- Usuario institucional: ALU/DOC/APO/DIR + DNI (admin: libre)
    usuario VARCHAR(100) UNIQUE NOT NULL,

    estado BOOLEAN NOT NULL DEFAULT TRUE,

    fecha_registro TIMESTAMP NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 3. USUARIOS DE PRUEBA
-- Usuario = PREFIJO + DNI:  ALU (alumno), DOC (docente),
-- APO (apoderado/padre), DIR (directiva). Admin: usuario libre.
-- ============================================================

INSERT INTO usuarios (nombre, correo, password, rol, usuario)
VALUES
    ('Administrador',       'admin123@gmail.com', 'admin', 'ADMIN',   'admin123'),
    ('Carlos Mendoza Ruiz', NULL,                 '1234',  'DOCENTE', 'DOC45678912'),
    ('Juan Pérez García',   NULL,                 '1234',  'ALUMNO',  'ALU87654321'),
    ('Juan Pérez Rojas',    NULL,                 '1234',  'PADRE',   'APO76543210');


-- ============================================================
-- 4. TABLA: estudiantes
-- ============================================================

CREATE TABLE estudiantes (
    id BIGSERIAL PRIMARY KEY,

    nombre_completo VARCHAR(150) NOT NULL,

    -- DNI | CE (carné de extranjería) | PASAPORTE | OTRO. El número va en "dni".
    tipo_documento VARCHAR(10) NOT NULL DEFAULT 'DNI'
        CHECK (tipo_documento IN ('DNI', 'CE', 'PASAPORTE', 'OTRO')),

    dni VARCHAR(15) UNIQUE NOT NULL,

    foto_url VARCHAR(500),

    fecha_nacimiento DATE,

    genero VARCHAR(20),

    nacionalidad VARCHAR(60),

    direccion VARCHAR(200),

    telefono VARCHAR(20),

    grado VARCHAR(10) NOT NULL,

    seccion VARCHAR(5) NOT NULL,

    anio_ingreso INT,

    estado VARCHAR(20) NOT NULL DEFAULT 'Activo',

    -- Cuenta de acceso del alumno (correo + contraseña en usuarios)
    usuario_id BIGINT UNIQUE
        REFERENCES usuarios(id)
        ON DELETE SET NULL,

    fecha_registro TIMESTAMP NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 5. DATOS DE EJEMPLO: estudiantes
-- ============================================================

INSERT INTO estudiantes (
    nombre_completo,
    dni,
    fecha_nacimiento,
    genero,
    nacionalidad,
    direccion,
    telefono,
    grado,
    seccion,
    anio_ingreso,
    estado
)
VALUES
(
    'Juan Pérez García',
    '87654321',
    '2014-04-12',
    'Masculino',
    'Peruana',
    'Av. Los Olivos 123, Comas',
    '987654321',
    '5°',
    'A',
    2022,
    'Activo'
),
(
    'María López Torres',
    '91234567',
    '2015-02-20',
    'Femenino',
    'Peruana',
    'Jr. Las Flores 456, Comas',
    '987654322',
    '4°',
    'B',
    2023,
    'Activo'
);


-- ============================================================
-- 5.1 CUENTAS DE ACCESO DE LOS ALUMNOS (ALU + DNI)
-- ============================================================

INSERT INTO usuarios (nombre, correo, password, rol, usuario)
VALUES ('María López Torres', NULL, '1234', 'ALUMNO', 'ALU91234567');

UPDATE estudiantes e
SET usuario_id = u.id
FROM usuarios u
WHERE u.usuario = 'ALU' || e.dni;


-- ============================================================
-- 6. TABLA: padres_familia
-- ============================================================

CREATE TABLE padres_familia (
    id BIGSERIAL PRIMARY KEY,

    nombre_completo VARCHAR(150) NOT NULL,

    -- DNI | CE (carné de extranjería) | PASAPORTE | OTRO. El número va en "dni".
    tipo_documento VARCHAR(10) NOT NULL DEFAULT 'DNI'
        CHECK (tipo_documento IN ('DNI', 'CE', 'PASAPORTE', 'OTRO')),

    dni VARCHAR(15) UNIQUE NOT NULL,

    -- Se muestra en el perfil del padre (no en la tabla de Usuarios > Padres)
    fecha_nacimiento DATE,

    telefono VARCHAR(20) NOT NULL,

    correo VARCHAR(150),                  -- correo de contacto (no es el de inicio de sesión)

    direccion VARCHAR(200),

    estado VARCHAR(20) NOT NULL DEFAULT 'Activo',

    -- Cuenta de acceso del apoderado (usuario APO + DNI)
    usuario_id BIGINT UNIQUE
        REFERENCES usuarios(id)
        ON DELETE SET NULL,

    fecha_registro TIMESTAMP NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 7. DATOS DE EJEMPLO: padres_familia
-- ============================================================

INSERT INTO padres_familia (
    nombre_completo,
    dni,
    telefono,
    correo,
    direccion,
    estado
)
VALUES
(
    'Juan Pérez Rojas',
    '76543210',
    '987654321',
    'juan.perez@correo.pe',
    'Av. Los Olivos 123, Comas',
    'Activo'
),
(
    'Ana García López',
    '65432109',
    '987654322',
    'ana.garcia@correo.pe',
    'Av. Los Olivos 123, Comas',
    'Activo'
);

-- Fecha de nacimiento de los padres (se ve en su perfil)
UPDATE padres_familia SET fecha_nacimiento = '1982-06-14' WHERE dni = '76543210';
UPDATE padres_familia SET fecha_nacimiento = '1985-09-02' WHERE dni = '65432109';

-- Cuentas de los apoderados (APO + DNI)
INSERT INTO usuarios (nombre, correo, password, rol, usuario)
VALUES ('Ana García López', NULL, '1234', 'PADRE', 'APO65432109');

UPDATE padres_familia p
SET usuario_id = u.id
FROM usuarios u
WHERE u.usuario = 'APO' || p.dni;


-- ============================================================
-- 8. TABLA: estudiante_familiar
-- Relación N a N entre estudiantes y padres
-- ============================================================

CREATE TABLE estudiante_familiar (
    id BIGSERIAL PRIMARY KEY,

    estudiante_id BIGINT NOT NULL
        REFERENCES estudiantes(id)
        ON DELETE CASCADE,

    padre_familia_id BIGINT NOT NULL
        REFERENCES padres_familia(id)
        ON DELETE CASCADE,

    parentesco VARCHAR(20) NOT NULL DEFAULT 'Apoderado',

    CONSTRAINT estudiante_familiar_unique
        UNIQUE (estudiante_id, padre_familia_id)
);


-- ============================================================
-- 9. RELACIÓN ESTUDIANTE - PADRE
-- Juan Pérez García -> Juan Pérez Rojas
-- ============================================================

INSERT INTO estudiante_familiar (
    estudiante_id,
    padre_familia_id,
    parentesco
)
SELECT
    e.id,
    p.id,
    'Padre'
FROM estudiantes e
CROSS JOIN padres_familia p
WHERE e.dni = '87654321'
  AND p.dni = '76543210';


-- ============================================================
-- 10. RELACIÓN ESTUDIANTE - MADRE
-- Juan Pérez García -> Ana García López
-- ============================================================

INSERT INTO estudiante_familiar (
    estudiante_id,
    padre_familia_id,
    parentesco
)
SELECT
    e.id,
    p.id,
    'Madre'
FROM estudiantes e
CROSS JOIN padres_familia p
WHERE e.dni = '87654321'
  AND p.dni = '65432109';


-- ============================================================
-- 11. TABLA: docentes
-- ============================================================

CREATE TABLE docentes (
    id BIGSERIAL PRIMARY KEY,

    nombre_completo VARCHAR(150) NOT NULL,

    -- DNI | CE (carné de extranjería) | PASAPORTE | OTRO. El número va en "dni".
    tipo_documento VARCHAR(10) NOT NULL DEFAULT 'DNI'
        CHECK (tipo_documento IN ('DNI', 'CE', 'PASAPORTE', 'OTRO')),

    dni VARCHAR(15) UNIQUE NOT NULL,

    foto_url VARCHAR(500),

    fecha_nacimiento DATE,

    genero VARCHAR(20),

    telefono VARCHAR(20),

    correo VARCHAR(150),

    direccion VARCHAR(200),

    especialidad VARCHAR(100),

    titulo_profesional VARCHAR(150),

    fecha_ingreso DATE,

    estado VARCHAR(20) NOT NULL DEFAULT 'Activo',

    usuario_id BIGINT UNIQUE
        REFERENCES usuarios(id),

    fecha_registro TIMESTAMP NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 12. DOCENTE DE PRUEBA
-- Vinculado al usuario: DOC45678912
-- ============================================================

INSERT INTO docentes (
    nombre_completo,
    dni,
    fecha_nacimiento,
    genero,
    telefono,
    correo,
    direccion,
    especialidad,
    titulo_profesional,
    fecha_ingreso,
    estado,
    usuario_id
)
SELECT
    'Carlos Mendoza Ruiz',
    '45678912',
    '1985-06-15',
    'Masculino',
    '987112233',
    'docente@demo.com',
    'Jr. La Cultura 200, Comas',
    'Matemática',
    'Licenciado en Educación Secundaria',
    '2020-03-01',
    'Activo',
    u.id
FROM usuarios u
WHERE u.usuario = 'DOC45678912';


-- ============================================================
-- 12.1 COMUNICADOS Y MENSAJES
-- ============================================================

-- Comunicado institucional (solo la administración los crea)
CREATE TABLE IF NOT EXISTS comunicados (
    id BIGSERIAL PRIMARY KEY,

    titulo VARCHAR(200) NOT NULL,

    contenido TEXT NOT NULL,              -- HTML simple del editor

    imagen TEXT,                          -- opcional (imagen en base64 o enlace)

    anuncio BOOLEAN NOT NULL DEFAULT FALSE, -- TRUE = se muestra en grande al entrar

    autor_id BIGINT
        REFERENCES usuarios(id)
        ON DELETE SET NULL,

    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),

    fecha_actualizacion TIMESTAMP
);

-- A qué grupos va dirigido cada comunicado
CREATE TABLE IF NOT EXISTS comunicado_destinatarios (
    comunicado_id BIGINT NOT NULL
        REFERENCES comunicados(id)
        ON DELETE CASCADE,

    grupo VARCHAR(30) NOT NULL
        CHECK (grupo IN ('TODOS', 'ADMINISTRATIVO', 'DOCENTES', 'ALUMNOS', 'PADRES')),

    PRIMARY KEY (comunicado_id, grupo)
);

-- Quién ya leyó cada comunicado (filtros Leídos / No leídos)
CREATE TABLE IF NOT EXISTS comunicado_lecturas (
    id BIGSERIAL PRIMARY KEY,

    comunicado_id BIGINT NOT NULL
        REFERENCES comunicados(id)
        ON DELETE CASCADE,

    usuario_id BIGINT NOT NULL
        REFERENCES usuarios(id)
        ON DELETE CASCADE,

    fecha_lectura TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT comunicado_lecturas_unique
        UNIQUE (comunicado_id, usuario_id)
);

-- Mensaje privado entre usuarios
CREATE TABLE IF NOT EXISTS mensajes (
    id BIGSERIAL PRIMARY KEY,

    remitente_id BIGINT
        REFERENCES usuarios(id)
        ON DELETE SET NULL,

    asunto VARCHAR(200) NOT NULL,

    contenido TEXT NOT NULL,

    fecha_envio TIMESTAMP NOT NULL DEFAULT NOW(),

    respuesta_a_id BIGINT
        REFERENCES mensajes(id)
        ON DELETE SET NULL,

    eliminado_remitente BOOLEAN NOT NULL DEFAULT FALSE
);

-- Destinatarios de cada mensaje (cada uno con su leído / eliminado)
CREATE TABLE IF NOT EXISTS mensaje_destinatarios (
    id BIGSERIAL PRIMARY KEY,

    mensaje_id BIGINT NOT NULL
        REFERENCES mensajes(id)
        ON DELETE CASCADE,

    destinatario_id BIGINT NOT NULL
        REFERENCES usuarios(id)
        ON DELETE CASCADE,

    leido BOOLEAN NOT NULL DEFAULT FALSE,

    fecha_lectura TIMESTAMP,

    eliminado BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT mensaje_destinatarios_unique
        UNIQUE (mensaje_id, destinatario_id)
);

CREATE INDEX IF NOT EXISTS idx_mensaje_destinatarios_destinatario ON mensaje_destinatarios (destinatario_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_remitente ON mensajes (remitente_id);
CREATE INDEX IF NOT EXISTS idx_comunicado_lecturas_usuario ON comunicado_lecturas (usuario_id);


-- ============================================================
-- 12.2 CÓDIGOS DE VERIFICACIÓN (Gmail)
-- Vincular Gmail, cambiar y recuperar contraseña. Solo se guarda el hash.
-- ============================================================

CREATE TABLE IF NOT EXISTS codigos_verificacion (
    id BIGSERIAL PRIMARY KEY,

    usuario_id BIGINT NOT NULL
        REFERENCES usuarios(id)
        ON DELETE CASCADE,

    tipo VARCHAR(30) NOT NULL
        CHECK (tipo IN ('VINCULAR_CORREO', 'CAMBIO_PASSWORD', 'RECUPERAR_PASSWORD')),

    correo VARCHAR(150) NOT NULL,

    codigo_hash VARCHAR(64) NOT NULL,

    expira_en TIMESTAMP NOT NULL,

    intentos INT NOT NULL DEFAULT 0,

    usado BOOLEAN NOT NULL DEFAULT FALSE,

    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_codigos_usuario_tipo ON codigos_verificacion (usuario_id, tipo);


-- ============================================================
-- 12.3 PERSONAL STAFF / DIRECTIVA (DIR + N.º de documento)
-- El administrador decide los permisos de cada uno.
-- ============================================================

-- Personal Staff / Directiva (usuario DIR + N.º de documento, rol DIRECTIVO)
CREATE TABLE IF NOT EXISTS personal (
    id BIGSERIAL PRIMARY KEY,

    tipo_documento VARCHAR(10) NOT NULL DEFAULT 'DNI'
        CHECK (tipo_documento IN ('DNI', 'CE', 'PASAPORTE', 'OTRO')),

    numero_documento VARCHAR(15) UNIQUE NOT NULL,

    nombres VARCHAR(100) NOT NULL,

    apellido_paterno VARCHAR(60) NOT NULL,

    apellido_materno VARCHAR(60),

    correo VARCHAR(150),              -- correo de contacto

    telefono VARCHAR(20),

    fecha_nacimiento DATE,

    cargo VARCHAR(100),               -- Director(a), Secretaria, Auxiliar...

    estado VARCHAR(20) NOT NULL DEFAULT 'Activo',

    usuario_id BIGINT UNIQUE
        REFERENCES usuarios(id)
        ON DELETE SET NULL,

    fecha_registro TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Permisos que el ADMINISTRADOR le da a cada miembro de la Directiva
CREATE TABLE IF NOT EXISTS personal_permisos (
    personal_id BIGINT NOT NULL
        REFERENCES personal(id)
        ON DELETE CASCADE,

    permiso VARCHAR(30) NOT NULL
        CHECK (permiso IN ('COMUNICADOS', 'REPORTES', 'ACADEMICO', 'USUARIOS', 'PERMISOS')),

    PRIMARY KEY (personal_id, permiso)
);

-- Cuentas de ejemplo (contraseña 1234)
INSERT INTO usuarios (nombre, correo, password, rol, usuario)
VALUES
    ('Víctor Flores Luca',          NULL, '1234', 'DIRECTIVO', 'DIR20262926'),
    ('Jane Mercado Solano',         NULL, '1234', 'DIRECTIVO', 'DIR42444633'),
    ('Bertha Arroyo Medina',        NULL, '1234', 'DIRECTIVO', 'DIR99557828');

INSERT INTO personal (tipo_documento, numero_documento, nombres, apellido_paterno, apellido_materno,
                      correo, telefono, cargo, usuario_id)
SELECT 'DNI', x.doc, x.nombres, x.paterno, x.materno, x.correo, x.telefono, x.cargo, u.id
FROM (VALUES
    ('20262926', 'Víctor', 'Flores',  'Luca',    'victorfloresluca@gmail.com', '987111222', 'Director(a)'),
    ('42444633', 'Jane',   'Mercado', 'Solano',  'janemercadosolano@gmail.com', '987333444', 'Secretaria'),
    ('99557828', 'Bertha', 'Arroyo',  'Medina',  'berthaarroyomedina@gmail.com', NULL,       'Administrativo-Limpieza')
) AS x(doc, nombres, paterno, materno, correo, telefono, cargo)
JOIN usuarios u ON u.usuario = 'DIR' || x.doc;

-- Director: todos (incluye Gestionar permisos); Secretaria: solo comunicados; Limpieza: ninguno
INSERT INTO personal_permisos (personal_id, permiso)
SELECT p.id, x.permiso FROM personal p
CROSS JOIN (VALUES ('COMUNICADOS'), ('REPORTES'), ('ACADEMICO'), ('USUARIOS'), ('PERMISOS')) AS x(permiso)
WHERE p.numero_documento = '20262926';

INSERT INTO personal_permisos (personal_id, permiso)
SELECT p.id, 'COMUNICADOS' FROM personal p WHERE p.numero_documento = '42444633';


-- Datos de ejemplo: un anuncio para todos y un comunicado para alumnos y padres
WITH c AS (
    INSERT INTO comunicados (titulo, contenido, anuncio, autor_id, fecha_creacion)
    SELECT 'Reunión de Padres de Familia',
           'Estimados padres, les invitamos a la próxima reunión para discutir el progreso académico del tercer bimestre. Su asistencia es vital. Se llevará a cabo en el auditorio principal.<br><br><b>Agenda:</b><ul><li>Presentación de las calificaciones bimestrales.</li><li>Estrategias de apoyo para los alumnos.</li><li>Preguntas y respuestas.</li></ul>',
           TRUE, u.id, NOW() - INTERVAL '1 hour'
    FROM usuarios u WHERE u.usuario = 'admin123'
    RETURNING id
)
INSERT INTO comunicado_destinatarios (comunicado_id, grupo) SELECT id, 'TODOS' FROM c;

WITH c AS (
    INSERT INTO comunicados (titulo, contenido, anuncio, autor_id, fecha_creacion)
    SELECT 'Inicio del tercer bimestre',
           'Les recordamos que el tercer bimestre inicia el lunes. Revisen sus horarios actualizados.',
           FALSE, u.id, NOW() - INTERVAL '1 day'
    FROM usuarios u WHERE u.usuario = 'admin123'
    RETURNING id
)
INSERT INTO comunicado_destinatarios (comunicado_id, grupo)
SELECT id, g FROM c CROSS JOIN (VALUES ('ALUMNOS'), ('PADRES')) AS grupos(g);

-- Mensajes de ejemplo: del docente a Juan, y de Juan al docente
WITH m AS (
    INSERT INTO mensajes (remitente_id, asunto, contenido, fecha_envio)
    SELECT id, 'Materiales para mañana', 'Recuerda traer regla y compás para la clase de geometría.', NOW() - INTERVAL '5 hours'
    FROM usuarios WHERE usuario = 'DOC45678912'
    RETURNING id
)
INSERT INTO mensaje_destinatarios (mensaje_id, destinatario_id)
SELECT m.id, u.id FROM m CROSS JOIN usuarios u WHERE u.usuario = 'ALU87654321';

WITH m AS (
    INSERT INTO mensajes (remitente_id, asunto, contenido, fecha_envio)
    SELECT id, 'Pregunta sobre la tarea de Historia', 'Profesor, tengo una duda sobre el trabajo de Historia. ¿Hasta cuándo es la entrega?', NOW() - INTERVAL '2 hours'
    FROM usuarios WHERE usuario = 'ALU87654321'
    RETURNING id
)
INSERT INTO mensaje_destinatarios (mensaje_id, destinatario_id)
SELECT m.id, u.id FROM m CROSS JOIN usuarios u WHERE u.usuario = 'DOC45678912';


-- ============================================================
-- 13. VERIFICAR USUARIOS
-- ============================================================

SELECT *
FROM usuarios
ORDER BY id;


-- ============================================================
-- 14. VERIFICAR ESTUDIANTES
-- ============================================================

SELECT *
FROM estudiantes
ORDER BY id;


-- ============================================================
-- 14.1 VERIFICAR ESTUDIANTE + CUENTA DE ACCESO
-- ============================================================

SELECT
    e.id AS estudiante_id,
    e.nombre_completo,
    e.dni,
    u.id AS usuario_id,
    u.correo,
    u.password,
    u.rol,
    u.estado AS usuario_estado
FROM estudiantes e
LEFT JOIN usuarios u
    ON u.id = e.usuario_id
ORDER BY e.id;


-- ============================================================
-- 15. VERIFICAR PADRES
-- ============================================================

SELECT *
FROM padres_familia
ORDER BY id;


-- ============================================================
-- 16. VERIFICAR DOCENTES
-- ============================================================

SELECT *
FROM docentes
ORDER BY id;


-- ============================================================
-- 17. VERIFICAR RELACIÓN ESTUDIANTE - PADRES
-- ============================================================

SELECT
    ef.id,
    e.nombre_completo AS estudiante,
    e.dni AS dni_estudiante,
    p.nombre_completo AS padre_familiar,
    p.dni AS dni_padre,
    p.telefono,
    p.correo,
    ef.parentesco
FROM estudiante_familiar ef
INNER JOIN estudiantes e
    ON e.id = ef.estudiante_id
INNER JOIN padres_familia p
    ON p.id = ef.padre_familia_id
ORDER BY ef.id;


-- ============================================================
-- 18. VERIFICAR DOCENTE + USUARIO
-- ============================================================

SELECT
    d.id AS docente_id,
    d.nombre_completo AS docente,
    d.dni,
    d.especialidad,
    d.titulo_profesional,
    d.estado,
    u.id AS usuario_id,
    u.usuario,
    u.correo,
    u.rol,
    u.estado AS usuario_estado
FROM docentes d
INNER JOIN usuarios u
    ON u.id = d.usuario_id
ORDER BY d.id;


-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================

SELECT * FROM usuarios