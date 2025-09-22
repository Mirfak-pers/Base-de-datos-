DECLARE
    -- A.1 Tipos de Datos Compuestos (definidos localmente dentro del bloque)
    TYPE funcion_completa_rec IS RECORD (
        funcion_id NUMBER,
        titulo_pelicula VARCHAR2(100),
        genero VARCHAR2(100),
        nombre_cliente VARCHAR2(100),
        asientos_reservados NUMBER,
        total_pago NUMBER,
        fecha_funcion DATE
    );

    TYPE estadisticas_sala_rec IS RECORD (
        numero_sala NUMBER,
        capacidad_total NUMBER,
        asientos_ocupados NUMBER,
        porcentaje_ocupacion NUMBER(5,2),
        ingresos_generados NUMBER
    );

    TYPE generos_populares_array IS VARRAY(15) OF VARCHAR2(50);
    TYPE horarios_disponibles_array IS VARRAY(20) OF NUMBER;

    -- Variables y tipos de datos compuestos
    v_funcion_info funcion_completa_rec;
    v_estadisticas estadisticas_sala_rec;
    v_generos_populares generos_populares_array := generos_populares_array();
    v_total_ingresos NUMBER := 0;
    v_contador NUMBER := 0;
    
    -- Excepciones personalizadas
    no_reservas_exception EXCEPTION;
    fecha_invalida_exception EXCEPTION;
    
    -- Cursor principal con parámetros
    CURSOR c_funciones_periodo(p_fecha_inicio DATE, p_fecha_fin DATE) IS
        SELECT f.funcion_id, f.fecha, f.hora_inicio, f.hora_fin,
               p.titulo, p.genero, p.duracion_min,
               s.numero_sala, s.capacidad
        FROM Funciones f
        JOIN Peliculas p ON f.pelicula_id = p.pelicula_id
        JOIN Salas s ON f.sala_id = s.sala_id
        WHERE f.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
        ORDER BY f.fecha, s.numero_sala;
    
    -- Cursor anidado para reservas por función
    CURSOR c_reservas_detalle(p_funcion_id NUMBER) IS
        SELECT r.reserva_id, r.asientos_reservados, r.total_pago, r.fecha_reserva,
               c.nombre, c.email, c.telefono,
               TRUNC(MONTHS_BETWEEN(SYSDATE, c.fecha_nacimiento)/12) AS edad
        FROM Reserva r
        JOIN Clientes c ON r.cliente_id = c.cliente_id
        WHERE r.funcion_id = p_funcion_id
        ORDER BY r.fecha_reserva;
    
    -- Cursor para análisis de empleados por sala
    CURSOR c_empleados_sala(p_sala_id NUMBER) IS
        SELECT e.nombre, e.puesto, e.salario,
               TRUNC(SYSDATE - e.fecha_contratacion) AS dias_experiencia
        FROM Empleados e
        JOIN empleados_Sala es ON e.empleado_id = es.empleado_id
        WHERE es.sala_id = p_sala_id;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== REPORTE INTEGRAL CINÉPOLIS ===');
    DBMS_OUTPUT.PUT_LINE('Fecha de generación: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Validación de fechas
    IF TO_DATE('2025-09-16', 'YYYY-MM-DD') > SYSDATE THEN
        RAISE fecha_invalida_exception;
    END IF;
    
    -- Procesamiento principal con bucles anidados
    FOR func_rec IN c_funciones_periodo(TO_DATE('2025-09-16', 'YYYY-MM-DD'), 
                                       TO_DATE('2025-09-19', 'YYYY-MM-DD')) LOOP
        
        DBMS_OUTPUT.PUT_LINE('--- Función: ' || func_rec.titulo || ' ---');
        DBMS_OUTPUT.PUT_LINE('Sala: ' || func_rec.numero_sala || 
                           ' | Fecha: ' || TO_CHAR(func_rec.fecha, 'DD/MM/YYYY') ||
                           ' | Horario: ' || func_rec.hora_inicio || '-' || func_rec.hora_fin);
        
        -- Inicializar estadísticas para esta función
        v_estadisticas.numero_sala := func_rec.numero_sala;
        v_estadisticas.capacidad_total := func_rec.capacidad;
        v_estadisticas.asientos_ocupados := 0;
        v_estadisticas.ingresos_generados := 0;
        
        -- Procesamiento de reservas anidado
        v_contador := 0;
        FOR reserva_rec IN c_reservas_detalle(func_rec.funcion_id) LOOP
            v_contador := v_contador + 1;
            
            -- Acumular estadísticas
            v_estadisticas.asientos_ocupados := v_estadisticas.asientos_ocupados + reserva_rec.asientos_reservados;
            v_estadisticas.ingresos_generados := v_estadisticas.ingresos_generados + reserva_rec.total_pago;
            v_total_ingresos := v_total_ingresos + reserva_rec.total_pago;
            
            -- Almacenar información completa en RECORD
            v_funcion_info.funcion_id := func_rec.funcion_id;
            v_funcion_info.titulo_pelicula := func_rec.titulo;
            v_funcion_info.genero := func_rec.genero;
            v_funcion_info.nombre_cliente := reserva_rec.nombre;
            v_funcion_info.asientos_reservados := reserva_rec.asientos_reservados;
            v_funcion_info.total_pago := reserva_rec.total_pago;
            v_funcion_info.fecha_funcion := func_rec.fecha;
            
            DBMS_OUTPUT.PUT_LINE('  Cliente: ' || reserva_rec.nombre || 
                               ' | Asientos: ' || reserva_rec.asientos_reservados ||
                               ' | Pago: $' || reserva_rec.total_pago ||
                               ' | Edad: ' || reserva_rec.edad);
        END LOOP;
        
        -- Verificar si la función tiene reservas
        IF v_contador = 0 THEN
            RAISE no_reservas_exception;
        END IF;
        
        -- Calcular porcentaje de ocupación
        v_estadisticas.porcentaje_ocupacion := 
            ROUND((v_estadisticas.asientos_ocupados / v_estadisticas.capacidad_total) * 100, 2);
        
        DBMS_OUTPUT.PUT_LINE('  RESUMEN - Ocupación: ' || v_estadisticas.asientos_ocupados || 
                           '/' || v_estadisticas.capacidad_total ||
                           ' (' || v_estadisticas.porcentaje_ocupacion || '%) | ' ||
                           'Ingresos: $' || v_estadisticas.ingresos_generados);
        
        -- Análisis de personal asignado
        DBMS_OUTPUT.PUT_LINE('  Personal asignado:');
        FOR emp_rec IN c_empleados_sala(func_rec.numero_sala) LOOP
            DBMS_OUTPUT.PUT_LINE('    ' || emp_rec.nombre || ' (' || emp_rec.puesto || ')');
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    
    -- Resumen general utilizando VARRAY para géneros
    v_generos_populares.EXTEND(5);
    v_generos_populares(1) := 'Ciencia Ficción';
    v_generos_populares(2) := 'Comedia Romántica';
    v_generos_populares(3) := 'Acción';
    v_generos_populares(4) := 'Aventura';
    v_generos_populares(5) := 'Thriller';
    
    DBMS_OUTPUT.PUT_LINE('=== RESUMEN EJECUTIVO ===');
    DBMS_OUTPUT.PUT_LINE('Ingresos totales del período: $' || v_total_ingresos);
    DBMS_OUTPUT.PUT_LINE('Géneros más populares:');
    
    FOR i IN 1..v_generos_populares.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || i || '. ' || v_generos_populares(i));
    END LOOP;

EXCEPTION
    WHEN no_reservas_exception THEN
        DBMS_OUTPUT.PUT_LINE('ADVERTENCIA: Función sin reservas detectada');
    WHEN fecha_invalida_exception THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Fecha de consulta inválida');
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Error en conversión de datos numéricos');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Código de error: ' || SQLCODE);
END;
/