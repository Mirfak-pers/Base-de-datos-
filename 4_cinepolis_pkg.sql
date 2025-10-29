-- Especificación del Paquete
CREATE OR REPLACE PACKAGE pkg_cinepolis_management IS
    
    -- Tipos públicos
    TYPE reserva_rec IS RECORD (
        cliente_nombre VARCHAR2(100),
        pelicula_titulo VARCHAR2(100),
        asientos NUMBER,
        total NUMBER
    );
    
    TYPE reservas_table IS TABLE OF reserva_rec INDEX BY PLS_INTEGER;
    
    -- Procedimientos públicos
    PROCEDURE generar_reporte_diario(p_fecha IN DATE);
    PROCEDURE asignar_empleado_sala(p_empleado_id IN NUMBER, p_sala_id IN NUMBER);
    
    -- Funciones públicas
    FUNCTION obtener_ingresos_periodo(p_fecha_inicio DATE, p_fecha_fin DATE) RETURN NUMBER;
    FUNCTION validar_horario_funcion(p_sala_id NUMBER, p_fecha DATE, p_hora_inicio NUMBER) RETURN BOOLEAN;
    
END pkg_cinepolis_management;
/

-- Cuerpo del Paquete
CREATE OR REPLACE PACKAGE BODY pkg_cinepolis_management IS
    
    PROCEDURE generar_reporte_diario(p_fecha IN DATE) IS
        CURSOR c_resumen IS
            SELECT s.numero_sala, COUNT(r.reserva_id) as total_reservas,
                   SUM(r.asientos_reservados) as asientos_vendidos,
                   SUM(r.total_pago) as ingresos
            FROM Salas s
            LEFT JOIN Funciones f ON s.sala_id = f.sala_id AND f.fecha = p_fecha
            LEFT JOIN Reserva r ON f.funcion_id = r.funcion_id
            GROUP BY s.numero_sala
            ORDER BY s.numero_sala;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('REPORTE DIARIO - ' || TO_CHAR(p_fecha, 'DD/MM/YYYY'));
        DBMS_OUTPUT.PUT_LINE('================================================');
        
        FOR rec IN c_resumen LOOP
            DBMS_OUTPUT.PUT_LINE('Sala ' || rec.numero_sala || 
                               ': ' || rec.total_reservas || ' reservas, ' ||
                               rec.asientos_vendidos || ' asientos, $' || rec.ingresos);
        END LOOP;
    END generar_reporte_diario;
    
    FUNCTION obtener_ingresos_periodo(p_fecha_inicio DATE, p_fecha_fin DATE) RETURN NUMBER IS
        v_total NUMBER := 0;
    BEGIN
        SELECT NVL(SUM(r.total_pago), 0) INTO v_total
        FROM Reserva r
        JOIN Funciones f ON r.funcion_id = f.funcion_id
        WHERE f.fecha BETWEEN p_fecha_inicio AND p_fecha_fin;
        
        RETURN v_total;
    END obtener_ingresos_periodo;
    
    FUNCTION validar_horario_funcion(p_sala_id NUMBER, p_fecha DATE, p_hora_inicio NUMBER) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM Funciones
        WHERE sala_id = p_sala_id
        AND fecha = p_fecha
        AND (p_hora_inicio BETWEEN hora_inicio AND hora_fin
             OR hora_inicio BETWEEN p_hora_inicio AND p_hora_inicio + 200);
        
        RETURN (v_count = 0);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END validar_horario_funcion;
    
    PROCEDURE asignar_empleado_sala(p_empleado_id IN NUMBER, p_sala_id IN NUMBER) IS
        v_existe_empleado NUMBER;
        v_existe_sala NUMBER;
        v_ya_asignado NUMBER;
        
        empleado_inexistente EXCEPTION;
        sala_inexistente EXCEPTION;
        ya_asignado EXCEPTION;
    BEGIN
        -- Verificar existencia del empleado
        SELECT COUNT(*) INTO v_existe_empleado FROM Empleados WHERE empleado_id = p_empleado_id;
        IF v_existe_empleado = 0 THEN
            RAISE empleado_inexistente;
        END IF;
        
        -- Verificar existencia de la sala
        SELECT COUNT(*) INTO v_existe_sala FROM Salas WHERE sala_id = p_sala_id;
        IF v_existe_sala = 0 THEN
            RAISE sala_inexistente;
        END IF;
        
        -- Verificar si ya está asignado
        SELECT COUNT(*) INTO v_ya_asignado 
        FROM empleados_Sala 
        WHERE empleado_id = p_empleado_id AND sala_id = p_sala_id;
        
        IF v_ya_asignado > 0 THEN
            RAISE ya_asignado;
        END IF;
        
        -- Realizar asignación
        INSERT INTO empleados_Sala (empleado_sala_id, empleado_id, sala_id)
        VALUES ((SELECT NVL(MAX(empleado_sala_id), 0) + 1 FROM empleados_Sala), p_empleado_id, p_sala_id);
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Empleado asignado exitosamente a la sala');
        
    EXCEPTION
        WHEN empleado_inexistente THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Empleado no existe');
        WHEN sala_inexistente THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Sala no existe');
        WHEN ya_asignado THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Empleado ya está asignado a esta sala');
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
    END asignar_empleado_sala;
    
END pkg_cinepolis_management;
/
