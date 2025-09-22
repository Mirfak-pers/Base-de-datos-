CREATE OR REPLACE PROCEDURE proc_nueva_reserva (
    p_cliente_id IN NUMBER,
    p_funcion_id IN NUMBER,
    p_asientos IN NUMBER,
    p_resultado OUT VARCHAR2
) IS
    v_capacidad NUMBER;
    v_ocupados NUMBER;
    v_precio_unitario NUMBER := 4000; -- Precio base por asiento
    v_total NUMBER;
    
    -- Excepciones personalizadas
    capacidad_excedida EXCEPTION;
    cliente_inexistente EXCEPTION;
    funcion_inexistente EXCEPTION;
    
BEGIN
    -- Verificar existencia del cliente
    BEGIN
        SELECT COUNT(*) INTO v_ocupados FROM Clientes WHERE cliente_id = p_cliente_id;
        IF v_ocupados = 0 THEN
            RAISE cliente_inexistente;
        END IF;
    END;
    
    -- Verificar capacidad disponible
    SELECT s.capacidad INTO v_capacidad
    FROM Salas s
    JOIN Funciones f ON s.sala_id = f.sala_id
    WHERE f.funcion_id = p_funcion_id;
    
    SELECT NVL(SUM(asientos_reservados), 0) INTO v_ocupados
    FROM Reserva
    WHERE funcion_id = p_funcion_id;
    
    IF (v_ocupados + p_asientos) > v_capacidad THEN
        RAISE capacidad_excedida;
    END IF;
    
    -- Calcular total
    v_total := p_asientos * v_precio_unitario;
    
    -- Crear reserva
    INSERT INTO Reserva (
        reserva_id, cliente_id, funcion_id, 
        asientos_reservados, fecha_reserva, total_pago
    ) VALUES (
        (SELECT NVL(MAX(reserva_id), 0) + 1 FROM Reserva),
        p_cliente_id, p_funcion_id, p_asientos, SYSDATE, v_total
    );
    
    COMMIT;
    p_resultado := 'Reserva creada exitosamente. Total: $' || v_total;
    
EXCEPTION
    WHEN capacidad_excedida THEN
        ROLLBACK;
        p_resultado := 'ERROR: No hay suficientes asientos disponibles';
    WHEN cliente_inexistente THEN
        ROLLBACK;
        p_resultado := 'ERROR: Cliente no existe';
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        p_resultado := 'ERROR: Función no encontrada';
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR: ' || SQLERRM;
END proc_nueva_reserva;
/