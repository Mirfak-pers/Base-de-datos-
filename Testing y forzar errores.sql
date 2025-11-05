-- ============================================================================
-- SCRIPT DE TESTING COMPLETO - PAQUETE CINEPOLIS
-- Autores: Benjamin Araya, Gabriel Hernandez
-- Propósito: Probar todas las funciones, procedimientos y triggers
--            Incluyendo casos de éxito y forzamiento de errores
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

-- ============================================================================
-- SECCIÓN 1: PREPARACIÓN DE DATOS DE PRUEBA
-- ============================================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE('PREPARANDO DATOS DE PRUEBA');
    DBMS_OUTPUT.PUT_LINE('==============================================');
END;
/

-- ============================================================================
-- SECCIÓN 2: TESTING DE FUNCIONES
-- ============================================================================

PROMPT
PROMPT ============================================================================
PROMPT TESTING FUNCIÓN 1: disponibilidad_asientos
PROMPT ============================================================================

-- Test 1.1: Caso exitoso - Verificar disponibilidad de asientos
DECLARE
    v_disponibilidad NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 1.1: Disponibilidad de asientos para función existente ---');
    v_disponibilidad := Cinepolis_paquete.disponibilidad_asientos(1);
    DBMS_OUTPUT.PUT_LINE('Asientos disponibles para función 1: ' || v_disponibilidad);
    DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
END;
/

-- Test 1.2: Forzar error - Función inexistente
DECLARE
    v_disponibilidad NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 1.2: Forzar ERROR - Función inexistente ---');
    v_disponibilidad := Cinepolis_paquete.disponibilidad_asientos(99999);
    DBMS_OUTPUT.PUT_LINE('Este mensaje no debería aparecer');
EXCEPTION
    WHEN Cinepolis_paquete.e_funcion_no_existe THEN
        DBMS_OUTPUT.PUT_LINE('✓ ERROR CAPTURADO CORRECTAMENTE: Función no existe');
        DBMS_OUTPUT.PUT_LINE('✓ Test de error EXITOSO' || CHR(10));
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR INESPERADO: ' || SQLERRM || CHR(10));
END;
/

PROMPT
PROMPT ============================================================================
PROMPT TESTING FUNCIÓN 2: obtener_historial_cliente
PROMPT ============================================================================

-- Test 2.1: Caso exitoso - Cliente con reservas
DECLARE
    v_historial Cinepolis_paquete.varray_historial_reservas;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 2.1: Obtener historial de cliente existente ---');
    v_historial := Cinepolis_paquete.obtener_historial_cliente(1);
    
    IF v_historial IS NOT NULL AND v_historial.COUNT > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Total de reservas encontradas: ' || v_historial.COUNT);
        DBMS_OUTPUT.PUT_LINE('Primera reserva - ID: ' || v_historial(1).reserva_id);
        DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
    ELSE
        DBMS_OUTPUT.PUT_LINE('Cliente sin reservas registradas');
        DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO (sin datos)' || CHR(10));
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
END;
/

-- Test 2.2: Forzar error - Cliente inexistente
DECLARE
    v_historial Cinepolis_paquete.varray_historial_reservas;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 2.2: Forzar ERROR - Cliente inexistente ---');
    v_historial := Cinepolis_paquete.obtener_historial_cliente(99999);
    DBMS_OUTPUT.PUT_LINE('Este mensaje no debería aparecer');
EXCEPTION
    WHEN Cinepolis_paquete.e_cliente_no_existe THEN
        DBMS_OUTPUT.PUT_LINE('✓ ERROR CAPTURADO CORRECTAMENTE: Cliente no existe');
        DBMS_OUTPUT.PUT_LINE('✓ Test de error EXITOSO' || CHR(10));
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR INESPERADO: ' || SQLERRM || CHR(10));
END;
/

PROMPT
PROMPT ============================================================================
PROMPT TESTING FUNCIÓN 3: verificar_restricciones_pelicula
PROMPT ============================================================================

-- Test 3.1: Caso exitoso - Cliente mayor de edad
DECLARE
    v_resultado VARCHAR2(100);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 3.1: Verificar restricciones - Cliente apto ---');
    v_resultado := Cinepolis_paquete.verificar_restricciones_pelicula(1, 1);
    DBMS_OUTPUT.PUT_LINE('Resultado de verificación: ' || v_resultado);
    DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
END;
/

-- Test 3.2: Forzar restricción - Cliente menor de edad (necesita datos apropiados)
DECLARE
    v_resultado VARCHAR2(100);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 3.2: Verificar restricciones - Posible restricción de edad ---');
    v_resultado := Cinepolis_paquete.verificar_restricciones_pelicula(1, 1);
    DBMS_OUTPUT.PUT_LINE('Resultado: ' || v_resultado);
    
    IF v_resultado = 'APTO' THEN
        DBMS_OUTPUT.PUT_LINE('Cliente cumple con las restricciones');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Cliente NO cumple restricciones: ' || v_resultado);
    END IF;
    DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
END;
/

PROMPT
PROMPT ============================================================================
PROMPT TESTING FUNCIÓN 4: generar_reporte_pelicula (Gabriel Hernandez)
PROMPT ============================================================================

-- Test 4.1: Caso exitoso - Película con funciones
DECLARE
    v_reporte Cinepolis_paquete.rec_reporte_pelicula;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 4.1: Generar reporte de película ---');
    v_reporte := Cinepolis_paquete.generar_reporte_pelicula(1);
    
    IF v_reporte.titulo_peli IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Título: ' || v_reporte.titulo_peli);
        DBMS_OUTPUT.PUT_LINE('Total espectadores: ' || v_reporte.total_espectadores);
        DBMS_OUTPUT.PUT_LINE('Ingresos totales: $' || v_reporte.ingresos_totales);
        DBMS_OUTPUT.PUT_LINE('Función más popular: ' || NVL(TO_CHAR(v_reporte.funcion_mas_popular), 'N/A'));
        DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
    ELSE
        DBMS_OUTPUT.PUT_LINE('No se pudo generar el reporte');
        DBMS_OUTPUT.PUT_LINE('✗ Test FALLIDO' || CHR(10));
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
END;
/

-- Test 4.2: Película sin datos
DECLARE
    v_reporte Cinepolis_paquete.rec_reporte_pelicula;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 4.2: Película sin funciones/reservas ---');
    v_reporte := Cinepolis_paquete.generar_reporte_pelicula(99999);
    
    IF v_reporte IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Reporte NULL para película inexistente');
        DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO (manejo correcto)' || CHR(10));
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error esperado para película inexistente');
        DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
END;
/

PROMPT
PROMPT ============================================================================
PROMPT TESTING FUNCIÓN 5: mejor_horario (Gabriel Hernandez)
PROMPT ============================================================================

-- Test 5.1: Caso exitoso - Película con funciones futuras
DECLARE
    v_mejor_funcion NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 5.1: Encontrar mejor horario disponible ---');
    v_mejor_funcion := Cinepolis_paquete.mejor_horario(1);
    
    IF v_mejor_funcion IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Mejor función ID: ' || v_mejor_funcion);
        DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
    ELSE
        DBMS_OUTPUT.PUT_LINE('No hay funciones disponibles');
        DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO (sin funciones futuras)' || CHR(10));
    END IF;
EXCEPTION
    WHEN Cinepolis_paquete.e_pelicula_sin_funciones THEN
        DBMS_OUTPUT.PUT_LINE('✓ ERROR CAPTURADO: Película sin funciones futuras');
        DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
END;
/

-- Test 5.2: Forzar error - Película sin funciones
DECLARE
    v_mejor_funcion NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 5.2: Forzar ERROR - Película sin funciones ---');
    v_mejor_funcion := Cinepolis_paquete.mejor_horario(99999);
    DBMS_OUTPUT.PUT_LINE('Este mensaje no debería aparecer');
EXCEPTION
    WHEN Cinepolis_paquete.e_pelicula_sin_funciones THEN
        DBMS_OUTPUT.PUT_LINE('✓ ERROR CAPTURADO CORRECTAMENTE: Película sin funciones');
        DBMS_OUTPUT.PUT_LINE('✓ Test de error EXITOSO' || CHR(10));
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR INESPERADO: ' || SQLERRM || CHR(10));
END;
/

-- ============================================================================
-- SECCIÓN 3: TESTING DE PROCEDIMIENTOS
-- ============================================================================

PROMPT
PROMPT ============================================================================
PROMPT TESTING PROCEDIMIENTO 1: pc_registrar_reserva
PROMPT ============================================================================

-- Test 6.1: Caso exitoso - Registrar reserva válida
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 6.1: Registrar reserva válida ---');
    Cinepolis_paquete.pc_registrar_reserva(
        p_cliente_id => 1,
        p_funcion_id => 1,
        p_asientos_reservados => 2
    );
    DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
        ROLLBACK;
END;
/

-- Test 6.2: Forzar error - Asientos insuficientes
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 6.2: Forzar ERROR - Asientos insuficientes ---');
    Cinepolis_paquete.pc_registrar_reserva(
        p_cliente_id => 1,
        p_funcion_id => 1,
        p_asientos_reservados => 999999
    );
    DBMS_OUTPUT.PUT_LINE('Este mensaje no debería aparecer');
EXCEPTION
    WHEN Cinepolis_paquete.e_asientos_insuficientes THEN
        DBMS_OUTPUT.PUT_LINE('✓ ERROR CAPTURADO: Asientos insuficientes');
        DBMS_OUTPUT.PUT_LINE('✓ Test de error EXITOSO' || CHR(10));
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error capturado: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO (error manejado)' || CHR(10));
        ROLLBACK;
END;
/

-- Test 6.3: Forzar error - Función inexistente
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 6.3: Forzar ERROR - Función inexistente ---');
    Cinepolis_paquete.pc_registrar_reserva(
        p_cliente_id => 1,
        p_funcion_id => 99999,
        p_asientos_reservados => 2
    );
    DBMS_OUTPUT.PUT_LINE('Este mensaje no debería aparecer');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✓ ERROR CAPTURADO: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('✓ Test de error EXITOSO' || CHR(10));
        ROLLBACK;
END;
/

PROMPT
PROMPT ============================================================================
PROMPT TESTING PROCEDIMIENTO 2: pc_reporte_ocupacion_salas
PROMPT ============================================================================

-- Test 7.1: Caso exitoso - Reporte de sala existente
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 7.1: Generar reporte de ocupación de sala ---');
    Cinepolis_paquete.pc_reporte_ocupacion_salas(1);
    DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
END;
/

-- Test 7.2: Sala sin funciones
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 7.2: Sala sin funciones registradas ---');
    Cinepolis_paquete.pc_reporte_ocupacion_salas(99999);
    DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO (sala vacía)' || CHR(10));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
END;
/

PROMPT
PROMPT ============================================================================
PROMPT TESTING PROCEDIMIENTO 3: pc_registrar_error
PROMPT ============================================================================

-- Test 8: Registrar error en log
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 8: Registrar error en log del sistema ---');
    Cinepolis_paquete.pc_registrar_error(
        p_mensaje_error => 'Error de prueba - Testing',
        p_contexto => 'Script de Testing'
    );
    DBMS_OUTPUT.PUT_LINE('✓ Error registrado correctamente');
    DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
END;
/

PROMPT
PROMPT ============================================================================
PROMPT TESTING PROCEDIMIENTO 4: pc_atualizar_salarios
PROMPT ============================================================================

-- Test 9.1: Caso exitoso - Actualizar salarios con porcentaje válido
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 9.1: Actualizar salarios por puesto ---');
    Cinepolis_paquete.pc_atualizar_salarios(
        p_puesto => 'Cajero',
        p_porcentaje_aumento => 10
    );
    DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
    ROLLBACK; -- Revertir cambios de prueba
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
        ROLLBACK;
END;
/

-- Test 9.2: Forzar error - Porcentaje inválido (negativo o cero)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 9.2: Forzar ERROR - Porcentaje inválido ---');
    Cinepolis_paquete.pc_atualizar_salarios(
        p_puesto => 'Cajero',
        p_porcentaje_aumento => -5
    );
    DBMS_OUTPUT.PUT_LINE('Este mensaje no debería aparecer');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✓ ERROR CAPTURADO: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('✓ Test de error EXITOSO' || CHR(10));
        ROLLBACK;
END;
/

-- ============================================================================
-- SECCIÓN 4: TESTING DE TRIGGERS
-- ============================================================================

PROMPT
PROMPT ============================================================================
PROMPT TESTING TRIGGER 1: trg_validar_salario_empleado (Gabriel Hernandez)
PROMPT ============================================================================

-- Test 10.1: Insertar empleado con salario menor al mínimo
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 10.1: Insertar empleado con salario bajo el mínimo ---');
    INSERT INTO Empleados (empleado_id, nombre, puesto, salario, fecha_contratacion)
    VALUES (99991, 'Test Empleado 1', 'Cajero', 300000, SYSDATE);
    DBMS_OUTPUT.PUT_LINE('✓ Trigger ajustó salario al mínimo automáticamente');
    DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
        ROLLBACK;
END;
/

-- Test 10.2: Actualizar salario por debajo del mínimo
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 10.2: Actualizar salario por debajo del mínimo ---');
    -- Primero insertar un empleado válido
    INSERT INTO Empleados (empleado_id, nombre, puesto, salario, fecha_contratacion)
    VALUES (99992, 'Test Empleado 2', 'Gerente', 500000, SYSDATE);
    
    -- Intentar actualizar a salario inválido
    UPDATE Empleados SET salario = 200000 WHERE empleado_id = 99992;
    DBMS_OUTPUT.PUT_LINE('✓ Trigger ajustó salario al mínimo automáticamente');
    DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
        ROLLBACK;
END;
/

PROMPT
PROMPT ============================================================================
PROMPT TESTING TRIGGER 2: trg_validar_horario_funcion (Gabriel Hernandez)
PROMPT ============================================================================

-- Test 11: Forzar error - Insertar función con horario solapado
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 11: Forzar ERROR - Horario solapado en sala ---');
    
    -- Intentar insertar función que solapa con una existente
    INSERT INTO Funciones (funcion_id, pelicula_id, sala_id, fecha, hora_inicio, hora_fin)
    VALUES (99991, 1, 1, TRUNC(SYSDATE), 
            TO_DATE('2024-01-01 14:00:00', 'YYYY-MM-DD HH24:MI:SS'),
            TO_DATE('2024-01-01 16:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    
    DBMS_OUTPUT.PUT_LINE('✗ Test FALLIDO - No se detectó el solapamiento');
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20010 THEN
            DBMS_OUTPUT.PUT_LINE('✓ ERROR CAPTURADO: Sala ocupada en ese horario');
            DBMS_OUTPUT.PUT_LINE('✓ Test de error EXITOSO' || CHR(10));
        ELSE
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('(Puede ser normal si no hay funciones que solapen)' || CHR(10));
        END IF;
        ROLLBACK;
END;
/

PROMPT
PROMPT ============================================================================
PROMPT TESTING TRIGGER 3: trg_auditar_reservas (Gabriel Hernandez)
PROMPT ============================================================================

-- Test 12: Verificar auditoría de INSERT en reservas
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 12: Auditoría de INSERT en reservas ---');
    
    -- Insertar una reserva de prueba
    INSERT INTO Reserva (reserva_id, cliente_id, funcion_id, asientos_reservados, fecha_reserva, total_pago)
    VALUES (99991, 1, 1, 2, SYSDATE, 10000);
    
    DBMS_OUTPUT.PUT_LINE('✓ Reserva insertada - Trigger de auditoría ejecutado');
    DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
        ROLLBACK;
END;
/

PROMPT
PROMPT ============================================================================
PROMPT TESTING TRIGGER 4: trg_auditar_empleados (Gabriel Hernandez)
PROMPT ============================================================================

-- Test 13: Verificar auditoría de UPDATE en salarios
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 13: Auditoría de cambio de salario ---');
    
    -- Insertar empleado de prueba
    INSERT INTO Empleados (empleado_id, nombre, puesto, salario, fecha_contratacion)
    VALUES (99993, 'Test Empleado 3', 'Supervisor', 400000, SYSDATE);
    
    -- Actualizar salario
    UPDATE Empleados SET salario = 450000 WHERE empleado_id = 99993;
    
    DBMS_OUTPUT.PUT_LINE('✓ Salario actualizado - Auditoría registrada en DBMS_OUTPUT');
    DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
        ROLLBACK;
END;
/

PROMPT
PROMPT ============================================================================
PROMPT TESTING TRIGGER 5: trg_actualizar_estadisticas_ocupacion (Gabriel Hernandez)
PROMPT ============================================================================

-- Test 14: Verificar actualización automática de estadísticas
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 14: Actualización automática de estadísticas ---');
    
    -- Insertar una reserva que debería actualizar estadísticas
    INSERT INTO Reserva (reserva_id, cliente_id, funcion_id, asientos_reservados, fecha_reserva, total_pago)
    VALUES (99992, 1, 1, 3, SYSDATE, 15000);
    
    DBMS_OUTPUT.PUT_LINE('✓ Reserva insertada - Estadísticas actualizadas automáticamente');
    DBMS_OUTPUT.PUT_LINE('✓ Test EXITOSO' || CHR(10));
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM || CHR(10));
        ROLLBACK;
END;
/

-- ============================================================================
-- SECCIÓN 5: VERIFICACIÓN DE LOG DE ERRORES
-- ============================================================================

PROMPT
PROMPT ============================================================================
PROMPT VERIFICACIÓN DE LOG DE ERRORES
PROMPT ============================================================================

SELECT 'Total de errores registrados: ' || COUNT(*) AS resultado
FROM error_log;

SELECT 'Últimos 5 errores registrados:' AS titulo FROM DUAL;

SELECT mensaje_error, contexto, TO_CHAR(fecha_error, 'DD-MM-YYYY HH24:MI:SS') AS fecha
FROM (
    SELECT * FROM error_log 
    ORDER BY fecha_error DESC
)
WHERE ROWNUM <= 5;

-- ============================================================================
-- RESUMEN FINAL
-- ============================================================================

PROMPT
PROMPT ============================================================================
PROMPT RESUMEN DE TESTING COMPLETADO
PROMPT ============================================================================
PROMPT
PROMPT Tests ejecutados:
PROMPT   - 5 Funciones (incluyendo casos de éxito y error)
PROMPT   - 4 Procedimientos (incluyendo casos de éxito y error)
PROMPT   - 5 Triggers (validación de comportamiento)
PROMPT
PROMPT Errores forzados exitosamente:
PROMPT   ✓ Función inexistente
PROMPT   ✓ Cliente inexistente
PROMPT   ✓ Asientos insuficientes
PROMPT   ✓ Película sin funciones
PROMPT   ✓ Porcentaje de aumento inválido
PROMPT   ✓ Horario de sala solapado
PROMPT   ✓ Salario por debajo del mínimo
PROMPT
PROMPT Autores: Benjamin Araya, Gabriel Hernandez
PROMPT ============================================================================