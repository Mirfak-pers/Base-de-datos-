-- Ejemplo 1: Crear nueva reserva usando procedimiento
SET SERVEROUTPUT ON;
DECLARE
    v_resultado VARCHAR2(200);
BEGIN
    proc_nueva_reserva(
        p_cliente_id => 1,
        p_funcion_id => 1,
        p_asientos => 2,
        p_resultado => v_resultado
    );
    DBMS_OUTPUT.PUT_LINE(v_resultado);
END;
/

-- Ejemplo 2: Calcular ocupación usando función
SELECT 
    s.numero_sala,
    func_calcular_ocupacion_sala(s.sala_id, TO_DATE('2025-09-16', 'YYYY-MM-DD')) as ocupacion_porcentaje
FROM Salas s
ORDER BY s.numero_sala;

-- Ejemplo 3: Generar reporte usando paquete
BEGIN
    pkg_cinepolis_management.generar_reporte_diario(TO_DATE('2025-09-16', 'YYYY-MM-DD'));
END;
/

-- Ejemplo 4: Consultar ingresos del período
SELECT pkg_cinepolis_management.obtener_ingresos_periodo(
    TO_DATE('2025-09-16', 'YYYY-MM-DD'),
    TO_DATE('2025-09-19', 'YYYY-MM-DD')
) as ingresos_totales_periodo FROM DUAL;
