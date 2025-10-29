-- Trigger para auditoría de reservas
CREATE OR REPLACE TRIGGER trg_audit_reservas
    AFTER INSERT OR UPDATE OR DELETE ON Reserva
    FOR EACH ROW
DECLARE
    v_accion VARCHAR2(10);
    v_usuario VARCHAR2(30);
    v_fecha DATE;
    -- Variables para manejar la inserción en error_log
    v_error_id NUMBER;
    v_error_msg VARCHAR2(4000);
    v_error_date DATE;
BEGIN
    v_usuario := USER;
    v_fecha := SYSDATE;

    IF INSERTING THEN
        v_accion := 'INSERT';
        INSERT INTO audit_reservas (audit_id, accion, reserva_id, cliente_id,
                                  funcion_id, asientos_reservados, total_pago,
                                  usuario, fecha_auditoria)
        VALUES ((SELECT NVL(MAX(audit_id), 0) + 1 FROM audit_reservas),
                v_accion, :NEW.reserva_id, :NEW.cliente_id, :NEW.funcion_id,
                :NEW.asientos_reservados, :NEW.total_pago, v_usuario, v_fecha);

    ELSIF UPDATING THEN
        v_accion := 'UPDATE';
        INSERT INTO audit_reservas (audit_id, accion, reserva_id, cliente_id,
                                  funcion_id, asientos_reservados, total_pago,
                                  usuario, fecha_auditoria, valores_anteriores)
        VALUES ((SELECT NVL(MAX(audit_id), 0) + 1 FROM audit_reservas),
                v_accion, :NEW.reserva_id, :NEW.cliente_id, :NEW.funcion_id,
                :NEW.asientos_reservados, :NEW.total_pago, v_usuario, v_fecha,
                'Asientos anteriores: ' || :OLD.asientos_reservados ||
                ', Pago anterior: ' || :OLD.total_pago);

    ELSIF DELETING THEN
        v_accion := 'DELETE';
        INSERT INTO audit_reservas (audit_id, accion, reserva_id, cliente_id,
                                  funcion_id, asientos_reservados, total_pago,
                                  usuario, fecha_auditoria)
        VALUES ((SELECT NVL(MAX(audit_id), 0) + 1 FROM audit_reservas),
                v_accion, :OLD.reserva_id, :OLD.cliente_id, :OLD.funcion_id,
                :OLD.asientos_reservados, :OLD.total_pago, v_usuario, v_fecha);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't prevent the main operation
        -- Calcular valores primero en variables usando SELECT INTO
        BEGIN
            SELECT NVL(MAX(error_id), 0) + 1 INTO v_error_id FROM error_log;
        EXCEPTION
            WHEN OTHERS THEN
                v_error_id := 1; -- Valor por defecto si falla la consulta
        END;

        v_error_msg := 'Error en trigger audit_reservas: ' || SQLERRM;
        v_error_date := SYSDATE;

        -- Luego usar las variables en INSERT
        INSERT INTO error_log (error_id, error_message, error_date)
        VALUES (v_error_id, v_error_msg, v_error_date);
END trg_audit_reservas;
/
-- Trigger para validar capacidad de sala antes de insertar reserva
CREATE OR REPLACE TRIGGER trg_validar_capacidad_reserva
    BEFORE INSERT ON Reserva
    FOR EACH ROW
DECLARE
    v_capacidad_sala NUMBER;
    v_asientos_ocupados NUMBER;
    v_asientos_disponibles NUMBER;
    
    capacidad_excedida EXCEPTION;
    funcion_inexistente EXCEPTION;
BEGIN
    -- Obtener capacidad de la sala para esta función
    BEGIN
        SELECT s.capacidad INTO v_capacidad_sala
        FROM Salas s
        JOIN Funciones f ON s.sala_id = f.sala_id
        WHERE f.funcion_id = :NEW.funcion_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE funcion_inexistente;
    END;
    
    -- Calcular asientos ya ocupados
    SELECT NVL(SUM(asientos_reservados), 0) INTO v_asientos_ocupados
    FROM Reserva
    WHERE funcion_id = :NEW.funcion_id;
    
    -- Verificar disponibilidad
    v_asientos_disponibles := v_capacidad_sala - v_asientos_ocupados;
    
    IF :NEW.asientos_reservados > v_asientos_disponibles THEN
        RAISE capacidad_excedida;
    END IF;
    
    -- Auto-calcular total si no se proporciona
    IF :NEW.total_pago IS NULL OR :NEW.total_pago = 0 THEN
        :NEW.total_pago := :NEW.asientos_reservados * 4000; -- Precio base
    END IF;
    
    -- Auto-asignar fecha de reserva si no se proporciona
    IF :NEW.fecha_reserva IS NULL THEN
        :NEW.fecha_reserva := SYSDATE;
    END IF;
    
EXCEPTION
    WHEN capacidad_excedida THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: No hay suficientes asientos disponibles. ' ||
                               'Disponibles: ' || v_asientos_disponibles || 
                               ', Solicitados: ' || :NEW.asientos_reservados);
    WHEN funcion_inexistente THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error: La función especificada no existe');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20999, 'Error inesperado: ' || SQLERRM);
END trg_validar_capacidad_reserva;
/

-- Trigger para actualizar estadísticas de ocupación
CREATE OR REPLACE TRIGGER trg_actualizar_estadisticas
    AFTER INSERT OR UPDATE OR DELETE ON Reserva
    FOR EACH ROW
DECLARE
    v_funcion_id NUMBER;
    v_sala_id NUMBER;
    v_fecha DATE;
    -- Variables para manejar errores en EXCEPTION
    v_error_id NUMBER;
    v_error_msg VARCHAR2(4000);
    v_error_date DATE;
    v_contexto VARCHAR2(500);
BEGIN
    -- Determinar función afectada
    IF INSERTING OR UPDATING THEN
        v_funcion_id := :NEW.funcion_id;
    ELSE
        v_funcion_id := :OLD.funcion_id;
    END IF;
    
    -- Obtener información de la función
    SELECT f.sala_id, f.fecha INTO v_sala_id, v_fecha
    FROM Funciones f
    WHERE f.funcion_id = v_funcion_id;
    
    -- Actualizar tabla de estadísticas (crear si no existe)
    MERGE INTO estadisticas_ocupacion eo
    USING (
        SELECT v_sala_id as sala_id, v_fecha as fecha,
               NVL(SUM(r.asientos_reservados), 0) as total_ocupados,
               NVL(SUM(r.total_pago), 0) as ingresos_totales,
               s.capacidad
        FROM Salas s
        LEFT JOIN Funciones f ON s.sala_id = f.sala_id AND f.fecha = v_fecha
        LEFT JOIN Reserva r ON f.funcion_id = r.funcion_id
        WHERE s.sala_id = v_sala_id
        GROUP BY s.sala_id, s.capacidad
    ) src ON (eo.sala_id = src.sala_id AND eo.fecha = src.fecha)
    WHEN MATCHED THEN
        UPDATE SET 
            asientos_ocupados = src.total_ocupados,
            porcentaje_ocupacion = ROUND((src.total_ocupados / src.capacidad) * 100, 2),
            ingresos_generados = src.ingresos_totales,
            ultima_actualizacion = SYSDATE
    WHEN NOT MATCHED THEN
        INSERT (estadistica_id, sala_id, fecha, asientos_ocupados, 
                porcentaje_ocupacion, ingresos_generados, ultima_actualizacion)
        VALUES ((SELECT NVL(MAX(estadistica_id), 0) + 1 FROM estadisticas_ocupacion),
                src.sala_id, src.fecha, src.total_ocupados,
                ROUND((src.total_ocupados / src.capacidad) * 100, 2),
                src.ingresos_totales, SYSDATE);
                
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't prevent the main operation
        -- Calcular valores primero en variables usando SELECT INTO
        BEGIN
            SELECT NVL(MAX(error_id), 0) + 1 INTO v_error_id FROM error_log;
        EXCEPTION
            WHEN OTHERS THEN
                v_error_id := 1; -- Valor por defecto si falla la consulta
        END;
        
        v_error_msg := 'Error en trigger estadísticas: ' || SQLERRM;
        v_error_date := SYSDATE;
        v_contexto := 'Función ID: ' || NVL(TO_CHAR(v_funcion_id), 'NULL');

        -- Luego usar las variables en INSERT
        INSERT INTO error_log (error_id, error_message, error_date, contexto)
        VALUES (v_error_id, v_error_msg, v_error_date, v_contexto);
END trg_actualizar_estadisticas;
/
