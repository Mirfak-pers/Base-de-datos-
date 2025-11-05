--Creacion de el paquete
--Autores: Benjamin Araya, Gabriel Hernandez

create or replace PACKAGE Cinepolis_paquete as

--Errores Personalizados de asientos insuficientes, funcion no existe y cliente no existe
    e_asientos_insuficientes EXCEPTION;
    pragma EXCEPTION_Init(e_asientos_insuficientes, -20001);

    e_funcion_no_existe EXCEPTION;
    pragma EXCEPTION_Init(e_funcion_no_existe, -20002);

    e_cliente_no_existe EXCEPTION;
    pragma EXCEPTION_Init(e_cliente_no_existe, -20003);

    e_pelicula_sin_funciones EXCEPTION;
    pragma EXCEPTION_Init(e_pelicula_sin_funciones, -20006);

    --Record: Autor Benjamin Araya
    type rec_reporte_pelicula is record(
        titulo_peli peliculas.titulo%type,
        total_espectadores number,
        ingresos_totales number,
        funcion_mas_popular funciones.funcion_id%type
    );

    --Varray para almacenar el historial de reservas: 
    type varray_historial_reservas is varray(100) of Reserva%RowType;

    --Funciones: Autor Benjamin Araya
    --1: Ver la disponibilidad de asientos para una funcion
    Function disponibilidad_asientos(p_funcion_id in number) return number;
    --2: Obtener el historial completo de reservas de un cliente
    function obtener_historial_cliente(p_cliente_id in number) return varray_historial_reservas;
    --3: Validar si un cliente es mayor de edad para cierta categoria de peliculas
    function verificar_restricciones_pelicula(p_cliente_id in NUMBER, p_funcion_id in NUMBER) return VARCHAR2;
    --4: Generar un reporte de rendimiento completo para una pelicula - Autor: Gabriel Hernandez
    function generar_reporte_pelicula(p_pelicula_id in number) return rec_reporte_pelicula;
    --5: Mejor horario para una pelicula basandose en la mayor disponibilidad - Autor: Gabriel Hernandez
    function mejor_horario (p_pelicula_id in number ) return number;

    --Procedimientos: Autor Benjamin Araya

    --1: Registrar una nueva reserva
    procedure pc_registrar_reserva(
        p_cliente_id in number,
        p_funcion_id in number,
        p_asientos_reservados in number
    );

    --2: Reporte de ocupacion por salas
    procedure pc_reporte_ocupacion_salas(p_salas_id in number);

    --3: registrar errores del sistema
    procedure pc_registrar_error(
        p_mensaje_error in varchar2,
        p_contexto in varchar2
    );

    --4: Actualizar masivamente salarios de empleados por puesto
    procedure pc_atualizar_salarios(
        p_puesto in varchar2,
        p_porcentaje_aumento in NUMBER
    );

end Cinepolis_paquete;
/

create or replace PACKAGE body Cinepolis_paquete as

    --Funcion 1: Benjamin Araya
    FUNCTION disponibilidad_asientos(p_funcion_id in number)
    return number is
        --Variables a utilizar
        v_capacidad_sala number;
        v_asientos_reservados number;
        v_disponibilidad number;
    begin
        --Obtener la capacidad de la sala para la funcion dada
        select 
        s.capacidad
        into v_capacidad_sala
        from Salas s
        join Funciones f on s.sala_id = f.sala_id
        where f.funcion_id = p_funcion_id;

        --Obtener la cantidad de asientos ya reservados para la funcion dada
        select 
        nvl(sum(r.asientos_reservados), 0)
        into v_asientos_reservados
        from Reserva r 
        where funcion_id = p_funcion_id;

        --Calcular la disponibilidad de asientos
        v_disponibilidad := v_capacidad_sala - v_asientos_reservados;
        return v_disponibilidad;
    exception
        when no_data_found then
            raise e_funcion_no_existe;
        when others then
            pc_registrar_error(sqlerrm, 'fn_disponibilidad_asientos');
            return -1;
    end disponibilidad_asientos;

    --Funcion 2: Benjamin Araya
    function obtener_historial_cliente(p_cliente_id in number)
    return varray_historial_reservas is
        --Variables a utilizar
        v_historial varray_historial_reservas := varray_historial_reservas();
        cursor c_reservas is 
            select * from reserva where cliente_id = p_cliente_id;
        v_contador number := 0;
    begin
        --Verificar si el cliente existe
        select count(*)
        into v_contador
        from CLIENTES
        where cliente_id = p_cliente_id;

        if v_contador = 0 then 
            raise e_cliente_no_existe;
        end if;

        --Obtener el historial de reservas
        for rec in c_reservas loop
            v_historial.extend; --Esto genera un nuevo espacio en el varray
            --Asigna el ultimo espacio del varray con el registro actual
            v_historial(v_historial.Last) := rec; 
        end loop;
        return v_historial;
    exception
        when e_cliente_no_existe then 
            raise;
        when others then
            pc_registrar_error(sqlerrm, 'fn_obtener_historial_cliente');
            return null;
    end obtener_historial_cliente;

    --Funcion 3: Benjamin Araya, Verificar restricciones de pelicula
    function verificar_restricciones_pelicula(p_cliente_id in number, p_funcion_id in number)
    return VARCHAR2 IS
        v_fecha_nac CLIENTES.fecha_nacimiento%TYPE;
        v_clasificacion peliculas.clasificacion%TYPE;
        v_edad number;
    BEGIN
        --Obtener la fecha de nacimiento del cliente
        select c.fecha_nacimiento
        into v_fecha_nac
        from CLIENTES c
        where c.cliente_id = p_cliente_id;
        
        --Obtener la clasificacion de la pelicula para la funcion dada
        select p.clasificacion
        into v_clasificacion
        from PELICULAS p
        join FUNCIONES f on p.pelicula_id = f.pelicula_id
        where f.funcion_id = p_funcion_id;

        --Calcular la edad del cliente
        v_edad := trunc(months_between(sysdate, v_fecha_nac) / 12);

        --Case para Validar Las clasificaciones
        case v_clasificacion
            when 'G' then return 'APTO';
            when 'PG' then return 'APTO';
            when 'PG-13' then 
                if v_edad >= 13 then 
                    return 'APTO';
                else 
                    return 'No apto para menores de 13 años';
                end if;
            when 'R' then 
                if v_edad >= 18 then 
                    return 'APTO';
                else 
                    return 'No apto para menores de 18 años';
                end if;
            else
                return 'Clasificación desconocida';
        end case;
    exception
        when no_data_found then 
            return 'Datos Insuficientes para verificar restricciones';
        when others then 
            pc_registrar_error(sqlerrm, 'fn_verificar_restricciones_pelicula');
            return 'Error al verificar restricciones';
    end verificar_restricciones_pelicula; 

    --Funcion 4: Generar un reporte de rendimiento completo para una pelicula
    --Autor: Gabriel Hernandez
    function generar_reporte_pelicula(p_pelicula_id in number) 
    return rec_reporte_pelicula is
        v_reporte rec_reporte_pelicula;
    begin
        -- Obtener título, total de espectadores e ingresos
        select 
            p.titulo, 
            nvl(sum(r.asientos_reservados), 0), 
            nvl(sum(r.total_pago), 0)
        into 
            v_reporte.titulo_peli, 
            v_reporte.total_espectadores, 
            v_reporte.ingresos_totales
        from Peliculas p
        left join Funciones f on p.pelicula_id = f.pelicula_id
        left join Reserva r on f.funcion_id = r.funcion_id
        where p.pelicula_id = p_pelicula_id
        group by p.titulo;
        
        -- Encontrar la función más popular (con más asientos reservados)
        begin
            select f.funcion_id 
            into v_reporte.funcion_mas_popular
            from Funciones f
            join Reserva r on f.funcion_id = r.funcion_id
            where f.pelicula_id = p_pelicula_id
            group by f.funcion_id
            order by sum(r.asientos_reservados) desc
            fetch first 1 rows only;
        exception
            -- Si no hay reservas, la función más popular es NULL
            when no_data_found then 
                v_reporte.funcion_mas_popular := null;
        end;

        return v_reporte;
    exception
        when others then 
            pc_registrar_error(sqlerrm, 'fn_generar_reporte_pelicula');
            return null;
    end generar_reporte_pelicula;

    --Funcion 5: Mejor horario para una pelicula basandose en la mayor disponibilidad
    --Autor: Gabriel Hernandez
    function mejor_horario (p_pelicula_id in number) 
    return number is
        cursor c_funciones_futuras is
            select f.funcion_id
            from Funciones f
            where f.pelicula_id = p_pelicula_id and f.fecha >= trunc(sysdate)
            order by f.fecha, f.hora_inicio;
            
        v_mejor_funcion_id number := null;
        v_maxima_disponibilidad number := -1;
        v_disponibilidad_actual number;
        v_count_funciones number := 0;
    begin
        -- Verificar si hay funciones futuras para esta película
        select count(*) 
        into v_count_funciones 
        from Funciones 
        where pelicula_id = p_pelicula_id and fecha >= trunc(sysdate);

        if v_count_funciones = 0 then 
            raise e_pelicula_sin_funciones; 
        end if;

        -- Iterar sobre las funciones futuras
        for reg in c_funciones_futuras loop
            -- Usar la Función 1 ya definida en este paquete
            v_disponibilidad_actual := disponibilidad_asientos(reg.funcion_id); 
            
            if v_disponibilidad_actual > v_maxima_disponibilidad then
                v_maxima_disponibilidad := v_disponibilidad_actual;
                v_mejor_funcion_id := reg.funcion_id;
            end if;
        end loop;
        
        return v_mejor_funcion_id;
    exception
        when e_pelicula_sin_funciones then 
            raise;
        when others then 
            pc_registrar_error(sqlerrm, 'fn_mejor_horario');
            return null;
    end mejor_horario;

    --Procedimientos: Autor Benjamin Araya
    --1: Registrar una nueva reserva
    procedure pc_registrar_reserva(
        p_cliente_id in number,
        p_funcion_id in number,
        p_asientos_reservados in number
    ) is
        v_disponibilidad number;
        v_total_pago number;
        v_reserva_id number;
        v_estado_cliente VARCHAR2(100);
        v_precio CONSTANT number := 5000; --Precio fijo por asiento
    begin
        v_disponibilidad := disponibilidad_asientos(p_funcion_id);

        --Validar si hay suficientes asientos
        if v_disponibilidad < p_asientos_reservados then
            raise e_asientos_insuficientes;
        end if;

        --Validar restricciones de edad para el cliente
        v_estado_cliente := verificar_restricciones_pelicula(p_cliente_id, p_funcion_id);
        if v_estado_cliente != 'APTO' then 
            raise_application_error(-20004, 'El cliente no cumple con las restricciones de edad: ' || v_estado_cliente);
        end if;

        --Calcular el total a pagar
        v_total_pago := p_asientos_reservados * v_precio;

        --Insertar la nueva reserva
        select nvl(max(reserva_id), 0) + 1 into v_reserva_id from reserva;
        insert into Reserva(reserva_id, cliente_id, funcion_id, asientos_reservados, FECHA_RESERVA, total_pago)
        values(v_reserva_id, p_cliente_id, p_funcion_id, p_asientos_reservados, sysdate, v_total_pago);
        --Guardar los cambios
        COMMIT;
        dbms_output.put_line('Reserva registrada exitosamente, Con ID: ' || v_reserva_id);
    exception
        when e_asientos_insuficientes then
            pc_registrar_error('Asientos insuficientes para la funcion ' || p_funcion_id, 'pc_registrar_reserva');
            ROLLBACK;
        when e_funcion_no_existe then
            pc_registrar_error('La funcion ' || p_funcion_id || ' no existe', 'pc_registrar_reserva');
            ROLLBACK;
        when others then
            pc_registrar_error(sqlerrm, 'pc_registrar_reserva');
            ROLLBACK;
    end pc_registrar_reserva;

    --Procedimiento 2: reporte de ocupacion por salas
    procedure pc_reporte_ocupacion_salas(p_salas_id in number) is
        cursor c_funciones_salas is 
            select f.funcion_id, p.titulo, f.fecha, f.HORA_INICIO, s.capacidad
            from funciones f
            join peliculas p on f.pelicula_id = p.pelicula_id
            join Salas s on f.sala_id = s.sala_id
            where f.sala_id = p_salas_id
            order by f.fecha;
        v_asientos_reservados number;
        v_porcentaje_ocupacion number;
    begin
        DBMS_OUTPUT.PUT_LINE('Reporte de ocupacion para la sala ID: ' || p_salas_id);
        for reg in c_funciones_salas loop
            --Obtener cantidad de asientos reservados para la funcion actual
            select nvl(sum(r.asientos_reservados), 0) 
            into v_asientos_reservados
            from Reserva r
            where r.funcion_id = reg.funcion_id;
            --Calcular porcentaje de ocupacion
            v_porcentaje_ocupacion := (v_asientos_reservados / reg.capacidad) * 100;

            DBMS_OUTPUT.PUT_LINE('Funcion ID: ' || reg.funcion_id || 
                ', Titulo: ' || reg.titulo ||
                ', Fecha: ' || TO_CHAR(reg.fecha, 'DD-MM-YYYY') ||
                ', Hora Inicio: ' || TO_CHAR(reg.hora_inicio) ||
                ', Asientos Ocupados: ' || v_asientos_reservados ||
                ', Capacidad Sala: ' || reg.capacidad ||
                ', Porcentaje Ocupacion: ' || ROUND(v_porcentaje_ocupacion, 2) || '%');
        end loop;
    exception
        when others then
            pc_registrar_error(sqlerrm, 'pc_reporte_ocupacion_salas');
    end pc_reporte_ocupacion_salas;

    --Procedimiento 3: registrar errores del sistema
    procedure pc_registrar_error(p_mensaje_error in VARCHAR2, p_contexto in VARCHAR2) 
    is 
        Pragma Autonomous_Transaction; --Permite que este procedimiento maneje su propia transaccion
    begin 
        insert into error_log(mensaje_error, contexto) 
        values(substr(p_mensaje_error, 1, 4000), p_contexto); -- Limitar a 4000 caracteres
        COMMIT;
    end pc_registrar_error;

    --Procedimiento 4: Actualizar masivamente salarios de empleados por puesto
    procedure pc_atualizar_salarios(p_puesto in varchar2, p_porcentaje_aumento in NUMBER)
    is 
        cursor c_empleados is 
            select empleado_id, salario from empleados where puesto = p_puesto 
            for update of salario; -- Bloqueo de filas para actualizacion, evita condiciones de carrera 
    begin 
        if p_porcentaje_aumento <= 0 then 
            raise_application_error(-20005, 'El porcentaje de aumento debe ser mayor que cero.');
        end if;
        --Recorrer los empleados y actualizar sus salarios
        for emp in c_empleados loop
            update empleados 
            set salario = emp.salario * (1 + p_porcentaje_aumento / 100) 
            where current of c_empleados; -- Actualizacion de la fila actual del cursor
        end loop;
        commit;
        dbms_output.put_line('Salarios actualizados exitosamente para el puesto: ' || p_puesto);
    exception 
        when others then 
            pc_registrar_error(sqlerrm, 'pc_atualizar_salarios');
            ROLLBACK;
    end pc_atualizar_salarios;

end Cinepolis_paquete;
/
--Trigger 1: Validar salario mínimo de empleado Gabriel Hernandez
CREATE OR REPLACE TRIGGER trg_validar_salario_empleado
BEFORE INSERT OR UPDATE ON Empleados
FOR EACH ROW
BEGIN
    IF :NEW.salario < 350000 THEN
        :NEW.salario := 350000; -- Asigna un valor mínimo si no se cumple la regla
        DBMS_OUTPUT.PUT_LINE('Salario no válido, se asignó el mínimo de 350000.');
    END IF;
END;
/

--Trigger 2: Validar horario de función (evitar solapamiento de salas) Gabriel Hernandez
CREATE OR REPLACE TRIGGER trg_validar_horario_funcion
BEFORE INSERT ON Funciones
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM Funciones
    WHERE sala_id = :NEW.sala_id
    AND fecha = :NEW.fecha
    AND :NEW.hora_inicio < hora_fin AND :NEW.hora_fin > hora_inicio;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'La sala ya está ocupada en ese horario.');
    END IF;
END;
/

--Trigger 3: Auditar operaciones en reservas Gabriel Hernandez
CREATE OR REPLACE TRIGGER trg_auditar_reservas
AFTER INSERT OR UPDATE OR DELETE ON Reserva
FOR EACH ROW
DECLARE
    v_accion VARCHAR2(10);
    v_valores_anteriores VARCHAR2(500) := '';
BEGIN
    IF INSERTING THEN
        v_accion := 'INSERT';
    ELSIF UPDATING THEN
        v_accion := 'UPDATE';
        v_valores_anteriores := 'Asientos: ' || :OLD.asientos_reservados || ', Total: ' || :OLD.total_pago;
    ELSIF DELETING THEN
        v_accion := 'DELETE';
    END IF;

    INSERT INTO audit_reservas (
        accion, reserva_id, cliente_id, funcion_id, 
        asientos_reservados, total_pago, usuario, 
        fecha_auditoria, valores_anteriores
    )
    VALUES (
        v_accion,
        NVL(:NEW.reserva_id, :OLD.reserva_id),
        NVL(:NEW.cliente_id, :OLD.cliente_id),
        NVL(:NEW.funcion_id, :OLD.funcion_id),
        NVL(:NEW.asientos_reservados, :OLD.asientos_reservados),
        NVL(:NEW.total_pago, :OLD.total_pago),
        USER,
        SYSDATE,
        v_valores_anteriores
    );
END;
/

--Trigger 4: Auditar cambios en salarios de empleados Gabriel Hernandez
CREATE OR REPLACE TRIGGER trg_auditar_empleados
AFTER UPDATE OF salario ON Empleados
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('Auditoría: El salario del empleado ' || 
        :OLD.empleado_id || ' cambió de ' || 
        :OLD.salario || ' a ' || :NEW.salario);
END;
/

--Trigger 5: Actualizar estadísticas de ocupación automáticamente Gabriel Hernandez
CREATE OR REPLACE TRIGGER trg_actualizar_estadisticas_ocupacion
AFTER INSERT ON Reserva
FOR EACH ROW
DECLARE
    v_sala_id NUMBER;
    v_fecha DATE;
    v_capacidad NUMBER;
    v_total_asientos_ocupados NUMBER;
    v_total_ingresos NUMBER;
BEGIN
    -- Obtener datos de la función
    SELECT f.sala_id, f.fecha, s.capacidad
    INTO v_sala_id, v_fecha, v_capacidad
    FROM Funciones f
    JOIN Salas s ON f.sala_id = s.sala_id
    WHERE f.funcion_id = :NEW.funcion_id;

    -- Calcular totales para esa sala y fecha
    SELECT NVL(SUM(r.asientos_reservados), 0), NVL(SUM(r.total_pago), 0)
    INTO v_total_asientos_ocupados, v_total_ingresos
    FROM Reserva r
    JOIN Funciones f ON r.funcion_id = f.funcion_id
    WHERE f.sala_id = v_sala_id AND f.fecha = v_fecha;

    -- Actualizar o insertar (MERGE) en la tabla de estadísticas
    MERGE INTO estadisticas_ocupacion eo
    USING (SELECT v_sala_id AS sala_id, v_fecha AS fecha FROM dual) src
    ON (eo.sala_id = src.sala_id AND eo.fecha = src.fecha)
    WHEN MATCHED THEN
        UPDATE SET
            asientos_ocupados = v_total_asientos_ocupados,
            ingresos_generados = v_total_ingresos,
            porcentaje_ocupacion = (v_total_asientos_ocupados / v_capacidad) * 100,
            ultima_actualizacion = SYSDATE
    WHEN NOT MATCHED THEN
        INSERT (sala_id, fecha, asientos_ocupados, porcentaje_ocupacion, ingresos_generados)
        VALUES (v_sala_id, v_fecha, :NEW.asientos_reservados, 
                (:NEW.asientos_reservados / v_capacidad) * 100, :NEW.total_pago);
END;
/