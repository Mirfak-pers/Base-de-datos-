--Creacion de el paquete

--Autor: Benjamin Araya
create or replace PACKAGE Cinepolis_paquete as

--Errores Personalizados de asientos insuficientes, funcion no existe y cliente no existe
    e_asientos_insuficientes EXCEPTION;
    pragma EXCEPTION_Init(e_asientos_insuficientes, -20001);

    e_funcion_no_existe EXCEPTION;
    pragma EXCEPTION_Init(e_funcion_no_existe, -20002);

    e_cliente_no_existe EXCEPTION;
    pragma EXCEPTION_Init(e_cliente_no_existe, -20003);

    e_pelicula_sin_funciones EXCEPTION;
    pragma EXCEPTION_Init(e_pelicula_sin_funciones, -20006); --Luego se utilizaran el -20004 y -20005 para otros errores

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
    function verificar_restricciones_pelicula(p_cliente_id in NUMBER, p_funcion_id in NUMBER) return boolean; -- <-- devuelve un booleanpo, True si es mayor, False si es menor
    --4: Generar un reporte de rendimiento completo para una pelicula
    function generar_reporte_pelicula(p_pelicula_id in number) return rec_reporte_pelicula;
    --5: Mejor horario para una pelicula basandose en la mayor disponibilidad
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

end cinepolis_paquete;
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
        where funcion_id =p_funcion_id;

        --Calcular la disponibilidad de asientos
        v_disponibilidad:= v_capacidad_sala - v_asientos_reservados;
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
            select * from reserva where cliente_id=p_cliente_id;
        v_contador number := 0;
    begin
        --Verificar si el cliente existe
        select count(*)
        into v_contador
        from CLIENTES
        where cliente_id = p_cliente_id;

        if v_contador=0 then 
            raise e_cliente_no_existe;
        end if;

        --Obtener el historial de reservas
        for rec in c_reservas loop
            v_historial.extend; --Esto genera un nuevo espacio en el varray
            --Asigna el ultimo espacio del varray con el registro actual
            v_historial(v_historial.Last):=rec; 
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
                if v_edad>=13 then 
                    return 'APTO';
                else 
                    return 'No apto para menores de 13 años';
                end if;
            when 'R' then 
                if v_edad>=18 then 
                    return 'APTO';
                else 
                    return 'No apto para menores de 18 años';
                end if;
            else
                return 'Clasificación desconocida';
        end case;
    exception
        when no_data_found then 
            return 'Datos Insuficioentes para verificar restricciones';
        when others then 
            pc_registrar_error(sqlerrm, 'fn_verificar_restricciones_pelicula');
            return 'Error al verificar restricciones';
    end verificar_restricciones_pelicula; 


    --Terminar Funciones 4 y 5....




    --    --Procedimientos: Autor Benjamin Araya
    --1: Registrar una nueva reserva: Benjamin Araya
    procedure pc_registrar_reserva(
        p_cliente_id in number,
        p_funcion_id in number,
        p_asientos_reservados in number
    ) is
        v_disponibilidad number;
        v_total_pago number;
        v_reserva_id number;
        v_estado_cliente VARCHAR2(100);
        v_precio CONSTANT number:=5000; --Precio fijo por asiento
    begin
        v_disponibilidad:= disponibilidad_asientos(p_funcion_id);

        --Validar si hay suficientes asientos
        if v_disponibilidad < p_asientos_reservados then
            raise e_asientos_insuficientes;
        end if;

        --Validar restricciones de edad para el cliente
        v_estado_cliente:=verificar_restricciones_pelicula(p_cliente_id, p_funcion_id);
        if v_estado_cliente != 'APTO' then 
            raise_application_error(-20004, 'El cliente no cumple con las restricciones de edad: ' || v_estado_cliente);
        end if;

        --Calcular el total a pagar
        v_total_pago:= p_asientos_reservados * v_precio;

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
            pc_registrar_error('La funcion ' || p_funcion_id || ' no existe',
                'pc_registrar_reserva');
            ROLLBACK;
        when other then
            pc_registrar_error(sqlerrm, 'pc_registrar_reserva');
            ROLLBACK;
    end pc_registrar_reserva;

    --Procedimiento 2: reporte de ocupacion por salas Benjamin Araya
    procedure pc_reporte_ocupacion_salas(p_salas_id in number) is
        cursor c_funciones_salas is 
            select f.funcion_id, p.titulo, f.fecha, f.HORA_INICIO, s.capacidad
            from funciones f
            join peliculas p on f.pelicula_id = p.pelicula_id
            join Salas s on f.sala_id = s.sala_id
            where f.sala_id = p_salas_id;
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
            v_porcentaje_ocupacion:= (v_asientos_reservados / reg.capacidad) * 100;

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

    --Procedimiento 3: registrar errores del sistema Benjamin Araya
    procedure pc_registrar_error( p_mensaje_errori in VARCHAR2, p_contexto in VARCHAR2) 
    is Pragma Autonomous_Transaction; --Permite que este procedimiento maneje su propia transaccion
    begin 
        insert into error_log(mensaje_error, contexto) values(substr(p_mensaje_errori, 1, 4000) -- Limitar a 4000 caracteres
        ,p_contexto);
        COMMIT;
    end pc_registrar_error;

    --Procedimiento 4: Actualizar masivamente salarios de empleados por puesto Benjamin Araya
    procedure pc_atualizar_salarios(p_puesto in varchar2,p_porcentaje_aumento in NUMBER)
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
            update empleados set salario = emp.salario *(1+ p_porcentaje_aumento/100) where current of c_empleados; -- Actualizacion de la fila actual del cursor
        end loop;
        commit;
        dbms_output.put_line('Salarios actualizados exitosamente para el puesto: ' ||p_puesto);
    exception 
        when others then 
            pc_registrar_error(sqlerrm, 'pc_atualizar_salarios');
            ROLLBACK;
    end pc_atualizar_salarios;
end Cinepolis_paquete;
/
