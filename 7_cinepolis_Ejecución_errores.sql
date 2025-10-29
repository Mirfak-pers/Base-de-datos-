SET SERVEROUTPUT ON;

-- Ejemplo 1: Probar excepción personalizada 'cliente_inexistente' en proc_nueva_reserva
-- Intenta crear una reserva con un ID de cliente que no existe.
DECLARE
    v_resultado VARCHAR2(200);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba 1: Cliente Inexistente ---');
    proc_nueva_reserva(
        p_cliente_id => 999, -- ID de cliente que no existe
        p_funcion_id => 1,
        p_asientos => 2,
        p_resultado => v_resultado
    );
    DBMS_OUTPUT.PUT_LINE('Resultado (No se debería ver): ' || v_resultado);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Excepción capturada en el bloque anónimo: ' || SQLERRM);
        -- El mensaje de error real se imprime dentro del procedimiento
END;
/

-- Ejemplo 2: Probar excepción personalizada 'funcion_inexistente' en proc_nueva_reserva
-- Intenta crear una reserva con un ID de función que no existe.
DECLARE
    v_resultado VARCHAR2(200);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba 2: Función Inexistente ---');
    proc_nueva_reserva(
        p_cliente_id => 1,
        p_funcion_id => 999, -- ID de función que no existe
        p_asientos => 2,
        p_resultado => v_resultado
    );
    DBMS_OUTPUT.PUT_LINE('Resultado (No se debería ver): ' || v_resultado);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Excepción capturada en el bloque anónimo: ' || SQLERRM);
        -- El mensaje de error real se imprime dentro del procedimiento
END;
/

-- Ejemplo 3: Probar excepción personalizada 'capacidad_excedida' en proc_nueva_reserva
-- Intenta reservar más asientos de los disponibles en una función específica.
DECLARE
    v_resultado VARCHAR2(200);
    v_capacidad_sala NUMBER;
    v_asientos_ocupados NUMBER;
    v_asientos_a_reservar NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba 3: Capacidad Excedida ---');
    
    -- Primero, obtenemos la capacidad de la sala y los asientos ocupados para una función
    SELECT s.capacidad INTO v_capacidad_sala
    FROM Salas s
    JOIN Funciones f ON s.sala_id = f.sala_id
    WHERE f.funcion_id = 1; -- Usamos la función 1

    SELECT NVL(SUM(asientos_reservados), 0) INTO v_asientos_ocupados
    FROM Reserva
    WHERE funcion_id = 1;

    -- Calculamos un número de asientos que exceda la capacidad
    v_asientos_a_reservar := (v_capacidad_sala - v_asientos_ocupados) + 5; -- 5 más de los disponibles

    DBMS_OUTPUT.PUT_LINE('Capacidad sala: ' || v_capacidad_sala || ', Ocupados: ' || v_asientos_ocupados || ', A reservar: ' || v_asientos_a_reservar);

    proc_nueva_reserva(
        p_cliente_id => 1,
        p_funcion_id => 1, -- Función válida
        p_asientos => v_asientos_a_reservar, -- Asientos que exceden la capacidad
        p_resultado => v_resultado
    );
    DBMS_OUTPUT.PUT_LINE('Resultado (No se debería ver): ' || v_resultado);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Excepción capturada en el bloque anónimo: ' || SQLERRM);
        -- El mensaje de error real se imprime dentro del procedimiento
END;
/

-- Ejemplo 4: Probar excepción personalizada 'no_reservas_exception' en el Bloque Anónimo A.2
-- Modificamos temporalmente las fechas del cursor para que no encuentre resultados.
-- Esto requiere ejecutar el bloque A.2 con fechas que no tengan funciones.
-- Como no podemos modificar el bloque A.2 directamente aquí, simulamos la condición.
-- La excepción 'no_reservas_exception' se levanta si un cursor anidado no encuentra datos.
-- Para probarlo, ejecuta el bloque A.2 con fechas sin funciones, por ejemplo:
-- c_funciones_periodo(TO_DATE('2020-01-01', 'YYYY-MM-DD'), TO_DATE('2020-01-02', 'YYYY-MM-DD'))
-- (Esto se deja como una ejecución manual para demostrar el concepto).

-- Ejemplo 5: Probar excepción personalizada 'fecha_invalida_exception' en el Bloque Anónimo A.2
-- Similar al ejemplo 4, esta excepción se levanta si la fecha de inicio es futura.
-- Se puede probar modificando la condición IF en el bloque A.2.
-- IF TO_DATE('2025-09-16', 'YYYY-MM-DD') > SYSDATE THEN
-- A una fecha futura, por ejemplo:
-- IF TO_DATE('2030-01-01', 'YYYY-MM-DD') > SYSDATE THEN
-- (Esto también se deja como una ejecución manual).

-- Ejemplo 6: Probar excepción personalizada 'empleado_inexistente' en pkg_cinepolis_management.asignar_empleado_sala
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba 6: Empleado Inexistente ---');
    pkg_cinepolis_management.asignar_empleado_sala(
        p_empleado_id => 999, -- ID de empleado que no existe
        p_sala_id => 1
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Excepción capturada en el bloque anónimo: ' || SQLERRM);
        -- El mensaje de error real se imprime dentro del procedimiento del paquete
END;
/

-- Ejemplo 7: Probar excepción personalizada 'sala_inexistente' en pkg_cinepolis_management.asignar_empleado_sala
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba 7: Sala Inexistente ---');
    pkg_cinepolis_management.asignar_empleado_sala(
        p_empleado_id => 1,
        p_sala_id => 999 -- ID de sala que no existe
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Excepción capturada en el bloque anónimo: ' || SQLERRM);
        -- El mensaje de error real se imprime dentro del procedimiento del paquete
END;
/

-- Ejemplo 8: Probar excepción personalizada 'ya_asignado' en pkg_cinepolis_management.asignar_empleado_sala
-- Primero, asegurémonos de que la asignación ya exista (según los datos de Cinepolis.txt)
-- Luego intentamos asignarla de nuevo.
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba 8: Empleado Ya Asignado ---');
    -- Supongamos que el empleado 1 ya está asignado a la sala 1 según los datos iniciales.
    -- Verificamos la tabla empleados_Sala:
    -- empleado_sala_id=1, empleado_id=1, sala_id=1
    pkg_cinepolis_management.asignar_empleado_sala(
        p_empleado_id => 1, -- Empleado ya asignado
        p_sala_id => 1      -- A la misma sala
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Excepción capturada en el bloque anónimo: ' || SQLERRM);
        -- El mensaje de error real se imprime dentro del procedimiento del paquete
END;
/

-- Ejemplo 9: Probar función func_calcular_ocupacion_sala con sala inexistente
-- Esta función maneja NO_DATA_FOUND y retorna 0 o -1.
DECLARE
    v_resultado NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba 9: Función con Sala Inexistente ---');
    v_resultado := func_calcular_ocupacion_sala(999, TO_DATE('2025-09-16', 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('Resultado ocupación (debería ser 0 o -1): ' || v_resultado);
END;
/

-- Ejemplo 10: Probar trigger trg_validar_capacidad_reserva (capacidad_excedida)
-- Intentamos insertar directamente en Reserva violando la capacidad.
-- Esto debería levantar la excepción RAISE_APPLICATION_ERROR del trigger.
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba 10: Trigger Capacidad Excedida (Inserción Directa) ---');
    DBMS_OUTPUT.PUT_LINE('Intentando insertar reserva que excede capacidad...');
    
    -- Primero, obtenemos la capacidad de la sala para la función 1
    DECLARE
        v_capacidad_sala NUMBER;
        v_asientos_ocupados NUMBER;
        v_asientos_a_reservar NUMBER;
    BEGIN
        SELECT s.capacidad INTO v_capacidad_sala
        FROM Salas s
        JOIN Funciones f ON s.sala_id = f.sala_id
        WHERE f.funcion_id = 1;

        SELECT NVL(SUM(asientos_reservados), 0) INTO v_asientos_ocupados
        FROM Reserva
        WHERE funcion_id = 1;

        v_asientos_a_reservar := (v_capacidad_sala - v_asientos_ocupados) + 3; -- 3 más de los disponibles

        INSERT INTO Reserva (
            reserva_id, cliente_id, funcion_id, 
            asientos_reservados, fecha_reserva, total_pago
        ) VALUES (
            (SELECT NVL(MAX(reserva_id), 0) + 1 FROM Reserva),
            2, 1, v_asientos_a_reservar, SYSDATE, v_asientos_a_reservar * 4000
        );
        -- Si llega aquí, el trigger no funcionó como se esperaba
        DBMS_OUTPUT.PUT_LINE('Inserción completada (esto no debería pasar si el trigger funciona).');
        -- Hacemos ROLLBACK para no alterar los datos
        ROLLBACK;
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        -- El trigger debería haber hecho ROLLBACK y lanzado RAISE_APPLICATION_ERROR
        DBMS_OUTPUT.PUT_LINE('Error esperado del trigger: ' || SQLERRM);
        -- Confirmamos el ROLLBACK del trigger
        ROLLBACK;
END;
/
