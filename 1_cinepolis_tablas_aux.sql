-- Tabla para auditoría de reservas
CREATE TABLE audit_reservas (
    audit_id NUMBER PRIMARY KEY,
    accion VARCHAR2(10) NOT NULL,
    reserva_id NUMBER NOT NULL,
    cliente_id NUMBER,
    funcion_id NUMBER,
    asientos_reservados NUMBER,
    total_pago NUMBER,
    usuario VARCHAR2(30) NOT NULL,
    fecha_auditoria DATE NOT NULL,
    valores_anteriores VARCHAR2(500)
);

-- Tabla para estadísticas de ocupación
CREATE TABLE estadisticas_ocupacion (
    estadistica_id NUMBER PRIMARY KEY,
    sala_id NUMBER NOT NULL,
    fecha DATE NOT NULL,
    asientos_ocupados NUMBER DEFAULT 0,
    porcentaje_ocupacion NUMBER(5,2) DEFAULT 0,
    ingresos_generados NUMBER DEFAULT 0,
    ultima_actualizacion DATE DEFAULT SYSDATE,
    CONSTRAINT fk_est_sala FOREIGN KEY (sala_id) REFERENCES Salas(sala_id)
);

-- Tabla para log de errores
CREATE TABLE error_log (
    error_id NUMBER PRIMARY KEY,
    error_message VARCHAR2(4000) NOT NULL,
    error_date DATE DEFAULT SYSDATE,
    contexto VARCHAR2(500)
);

-- Índices para optimización
CREATE INDEX idx_audit_fecha ON audit_reservas(fecha_auditoria);
CREATE INDEX idx_estadisticas_fecha ON estadisticas_ocupacion(fecha, sala_id);
CREATE INDEX idx_reserva_funcion ON Reserva(funcion_id);
CREATE INDEX idx_funciones_fecha ON Funciones(fecha, sala_id);
