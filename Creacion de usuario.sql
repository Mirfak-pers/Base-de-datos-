-- =============================================================================
-- 1. INSTALACIÓN DE USUARIO Y PERMISOS
-- =============================================================================
-- Descripcion: Creación del usuario para el proyecto y asignación de privilegios.
-- Autor/a: [Tu Nombre Completo]
-- =============================================================================

-- (Este script debe ser ejecutado por un usuario con privilegios de DBA, como SYSTEM)

-- Creación de un nuevo tablespace (opcional pero recomendado)
CREATE TABLESPACE cinepolis_ts
DATAFILE 'cinepolis_ts.dbf'
SIZE 50M
AUTOEXTEND ON;

-- Creación del usuario del proyecto
CREATE USER cinepolis_user IDENTIFIED BY tu_contraseña_segura
DEFAULT TABLESPACE cinepolis_ts
QUOTA UNLIMITED ON cinepolis_ts;

-- Concesión de permisos necesarios para el desarrollo
GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE TRIGGER,
 CREATE PROCEDURE, CREATE SEQUENCE TO cinepolis_user;

-- Permiso para visualizar salidas en la consola
GRANT EXECUTE ON DBMS_OUTPUT TO cinepolis_user;

-- Conexión como el nuevo usuario para verificar
CONNECT cinepolis_user/tu_contraseña_segura;

-- Fin del script de instalación de usuario y permisos