--version = 7

-- ----------------------------------------------------------------------------
--Добавление функциональности технологическому объекту на основе
--пользовательского объекта.
function add_functionality( tbl_main, tbl_2 )
    if not tbl_main or not tbl_2 then
        return
    end

    for field, value in pairs( tbl_2 ) do
        tbl_main[ field ] = value
    end

    local meta = getmetatable( tbl_2 )
    while meta
    do
        local new_functionality = meta.__index
        if new_functionality then
            for field, value in pairs( new_functionality ) do
                if not tbl_main[ field ] then tbl_main[ field ] = value end
            end
        end
        meta = getmetatable( meta )
    end
end

function add_functionality_for_group( src, ... )
    for _, obj in ipairs( arg ) do
        add_functionality( obj, src )
      end
end
-- ----------------------------------------------------------------------------
--Класс технологический объект со значениями параметров по умолчанию.
project_tech_object =
    {
    name        = "Объект",
    n           = 1,
    object_type = 1,
    modes_count = 32,

    timers_count               = 1,
    params_float_count         = 1,
    runtime_params_float_count = 1,
    params_uint_count          = 1,
    runtime_params_uint_count  = 1,

    sys_tech_object = 0,

    name_Lua = "OBJECT",

    idx = 1
    }
-- ----------------------------------------------------------------------------
--Создание экземпляра класса, при этом создаем соответствующий системный
--технологический объект из С++.
function project_tech_object:new( o )


    o = o or {} -- Create table if user does not provide one.
    setmetatable( o, self )
    self.__index = self

    --Создаем системный объект.
    if o.tech_type >= 111 and o.tech_type <= 120 then -- 111 - модуль мойки 112 - модуль мойки с функцией очистки емкостей на моечной станции 113 - Мойка молоковозов
        o.sys_tech_object = cipline_tech_object( o.name,
        o.n,
        o.tech_type,
        o.name_Lua..self.idx,
        o.modes_count,
        o.timers_count,
        o.params_float_count,
        o.runtime_params_float_count,
        o.params_uint_count,
        o.runtime_params_uint_count )
    else
        o.sys_tech_object = tech_object( o.name,
        o.n,
        o.tech_type,
        o.name_Lua..self.idx,
        o.modes_count,
        o.timers_count,
        o.params_float_count,
        o.runtime_params_float_count,
        o.params_uint_count,
        o.runtime_params_uint_count )
    end

    --Переназначаем переменную для параметров, для удобного доступа.
    o.rt_par_float = o.sys_tech_object.rt_par_float
    o.par_float = o.sys_tech_object.par_float
    o.rt_par_uint = o.sys_tech_object.rt_par_uint
    o.par_uint = o.sys_tech_object.par_uint
    o.timers = o.sys_tech_object.timers

    --Регистрация необходимых объектов.
    _G[ o.name_Lua..self.idx ] = o
    _G[ "__"..o.name_Lua..self.idx ] = o

    object_manager:add_object( o )

    o.g_idx = self.idx

    self.idx = self.idx + 1
    return o
end
-- ----------------------------------------------------------------------------
--Заглушки для функций, они ничего не делают, вызываются если не реализованы
--далее в проекте (файл main.lua).
function project_tech_object:exec_cmd( cmd )
    return 0
end

function project_tech_object:check_on_mode( mode )
    return 0
end

function project_tech_object:init_mode( mode )
    return 0
end

function project_tech_object:check_off_mode( mode )
    return 0
end

function project_tech_object:final_mode( mode )
    return 0
end

function project_tech_object:init_runtime_params( par )
    return 0
end

function project_tech_object:is_check_mode( mode )
    return 1
end

function project_tech_object:on_pause( mode )
    return 0
end

function project_tech_object:on_stop( mode )
    return 0
end

function project_tech_object:on_start( mode )
    return 0
end
-- ----------------------------------------------------------------------------
--Функции, которые переадресуются в вызовы соответствующих функций
--системного технологического объекта (релизованы на С++).
function project_tech_object:get_modes_count()
    return self.sys_tech_object:get_modes_count()
end

function project_tech_object:get_mode( mode )
    return self.sys_tech_object:get_mode( mode )
end

function project_tech_object:get_operation_state( operation )
    return self.sys_tech_object:get_operation_state( operation )
end

function project_tech_object:set_mode( mode, new_state )
    return self.sys_tech_object:set_mode( mode, new_state )
end

function project_tech_object:exec_cmd( cmd )
    return self.sys_tech_object:exec_cmd( cmd )
end

function project_tech_object:get_modes_manager()
    return self.sys_tech_object:get_modes_manager()
end

function project_tech_object:set_cmd( prop, idx, n )
    return self.sys_tech_object:set_cmd( prop, idx, n )
end

function project_tech_object:set_param( par_id, index, value )
    return self.sys_tech_object:set_param( par_id, index, value )
end

function project_tech_object:set_err_msg( msg, mode, new_mode, msg_type )
    new_mode = new_mode or 0
    msg_type = msg_type or tech_object.ERR_CANT_ON
    return self.sys_tech_object:set_err_msg( msg, mode, new_mode, msg_type )
end

function project_tech_object:get_number()
    return self.sys_tech_object:get_number()
end

function project_tech_object:check_operation_on( operation_n, show_error )
    if show_error == nil then
        return self.sys_tech_object:check_operation_on( operation_n )
    else
        return self.sys_tech_object:check_operation_on( operation_n, show_error )
    end
end

function project_tech_object:is_any_message()
    return self.sys_tech_object:is_any_message()
end

function project_tech_object:is_any_error()
    return self.sys_tech_object:is_any_error()
end
-- ----------------------------------------------------------------------------
--Представление всех созданных пользовательских технологических объектов
--(гребенки, танков) для доступа из C++.
object_manager =
    {
    objects = {}, --Пользовательские технологические объекты.

    --Добавление пользовательского технологического объекта.
    add_object = function ( self, new_object )
        self.objects[ #self.objects + 1 ] = new_object
    end,

    --Получение количества пользовательских технологических объектов.
    get_objects_count = function( self )
        return #self.objects
    end,

    --Получение пользовательского технологического объекта.
    get_object = function( self, object_idx )
        local res = self.objects[ object_idx ]
        if res then
            return self.objects[ object_idx ].sys_tech_object
        else
            return 0
        end
    end
    }
-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
--Инициализация операций, параметров и т.д. объектов.
OBJECTS = {}

init_tech_objects = function()

    local process_dev_ex = function( mode, state, step_n, action, devices,
        group_idx, sub_group_idx )
        group_idx = group_idx or 0
        sub_group_idx = sub_group_idx or 0
        if devices ~= nil then
            for _, value in pairs( devices ) do
                assert( loadstring( "dev = __"..value ) )( )
                if dev == nil then
                    print( "Error: unknown device '"..value.."' (__"..value..")." )
                    dev = DEVICE( -1 )
                end

                mode[ state ][ step_n ][ action ]:add_dev( dev, group_idx, sub_group_idx )
            end
        end
    end

    local process_seat_ex = function( mode, state, step_n, action, devices, t )

        if devices ~= nil then
            local group = 0
            for _, value in pairs( devices ) do
                for _, value in pairs( value ) do
                    assert( loadstring( "dev = __"..value ) )( )
                    if dev == nil then
                        print( "Error: unknown device '"..value.."' (__"..value..")." )
                        dev = DEVICE( -1 )
                    end

                    mode[ state ][ step_n ][ action ]:add_dev( dev, group, t )
                end
                group = group + 1
            end
        end
    end

    local proc_devices_action = function( item, group_idx, step_w, object )

        for field, element in pairs( item ) do

            local sub_group_idx = nil
            if element ~= nil then --Группа.
                if field == 'DI' then
                    sub_group_idx = 0
                elseif field == 'DO' then
                    sub_group_idx = 1
                elseif field == 'devices' then
                    sub_group_idx = 2
                elseif field == 'rev_devices' then
                    sub_group_idx = 3
                elseif field == 'pump_freq' then
                    sub_group_idx = 4

                    if type( element ) == "number" then
                        --Добавляем индекс параметра производительности.
                        step_w:set_param_idx( group_idx - 1, element )
                    elseif type( element ) == "string" then

                        --Добавляем AI производительности.
                        local dev = _G[ "__"..element ]
                        if dev == nil then
                            local param_n = object.PAR_FLOAT[ element ]
                            if param_n then
                                --Добавляем индекс параметра производительности.
                                step_w:set_param_idx( group_idx - 1, param_n )
                            else
                                print( "Error: unknown device '"..element..
                                    "' (__"..element..")." )
                            end
                        else
                            step_w:add_dev( dev, group_idx - 1, sub_group_idx )
                        end
                    end
                    element = {}

                --jump_if
                elseif field == 'on_devices' then
                    sub_group_idx = 0
                elseif field == 'off_devices' then
                    sub_group_idx = 1
                elseif field == 'next_step_n' then
                    step_w:set_int_property( 'next_step_n', group_idx - 1, element )
                end

                if sub_group_idx then
                    for _, value in pairs( element ) do --Устройства.

                        local dev = _G[ "__"..value ]
                        if dev == nil then
                            print( "Error: unknown device '"..value..
                                "' (__"..value..")." )
                            dev = DEVICE( -1 )
                        end

                        step_w:add_dev( dev, group_idx - 1, sub_group_idx )
                    end
                end
            end
        end
    end

    local process_step = function( mode, state_n, step_n, value, object )
        process_dev_ex( mode, state_n, step_n, step.A_CHECKED_DEVICES,
            value.checked_devices )
        process_dev_ex( mode, state_n, step_n, step.A_ON,
            value.opened_devices )
        process_dev_ex( mode, state_n, step_n, step.A_ON_REVERSE,
            value.opened_reverse_devices )
        process_dev_ex( mode, state_n, step_n, step.A_OFF,
            value.closed_devices )

        process_seat_ex( mode, state_n, step_n, step.A_UPPER_SEATS_ON,
            value.opened_upper_seat_v, valve.V_UPPER_SEAT )
        process_seat_ex( mode, state_n, step_n, step.A_LOWER_SEATS_ON,
            value.opened_lower_seat_v, valve.V_LOWER_SEAT )

        process_dev_ex( mode, state_n, step_n, step.A_REQUIRED_FB,
            value.required_FB )

        local to_step_if = value.jump_if
        if to_step_if and to_step_if[ 1 ] then
            local step_w = mode[ state_n ][ step_n ][ step.A_JUMP_IF ]
            for group_idx, item in ipairs( to_step_if ) do
                proc_devices_action( item, group_idx, step_w, object )
            end
        end

        --Группа устройств DI->DO.
        if value.DI_DO ~= nil then
            for sub_group, devices in pairs( value.DI_DO ) do
                process_dev_ex( mode, state_n, step_n, step.A_DI_DO, devices,
                    0, sub_group - 1 )
            end
        end

        --Группа устройств инвертированный DI->DO.
        if value.inverted_DI_DO ~= nil then
            for sub_group, devices in pairs( value.inverted_DI_DO ) do
                process_dev_ex( mode, state_n, step_n, step.A_INVERTED_DI_DO,
                    devices, 0, sub_group - 1 )
            end
        end

        --Группа сигналов, по наличию которых автоматически включается шаг.
        if value.enable_step_by_signal then
            for sub_group, item in pairs( value.enable_step_by_signal ) do
                if type( item ) == "boolean" then
                    local step_on = mode[ state_n ][ step_n ][ step.A_ENABLE_STEP_BY_SIGNAL ]
                    --Добавляем параметр отключения/не отключения шага при
                    --пропадании сигналов.
                    step_on:set_bool_property( "should_turn_off", item )

                elseif type( item ) == "table" then
                    process_dev_ex( mode, state_n, step_n, step.A_ENABLE_STEP_BY_SIGNAL,
                        item, 0, sub_group - 1 )
                end
            end
        end

        --Группа устройств AI->AO.
        if value.AI_AO ~= nil then

            local group = 0
            for _, value in pairs( value.AI_AO ) do
                for _, value in pairs( value ) do
                    assert( loadstring( "dev = __"..value ) )( )
                    if dev == nil then
                        print( "Error: unknown device '"..value..
                            "' (__"..value..")." )
                        dev = DEVICE( -1 )
                    end
                    mode[ state_n ][ step_n ][ step.A_AI_AO ]:add_dev(
                        dev, 0, group )
                end

                group = group + 1
            end
        end

        --Устройства.
        if value.devices_data ~= nil then
            if value.devices_data[ 1 ] then
                local step_w = mode[ state_n ][ step_n ][ step.A_WASH ]
                for group_idx, item in ipairs( value.devices_data ) do
                    proc_devices_action( item, group_idx, step_w, object )
                end
            end

        elseif value.wash_data ~= nil then
            --Устаревшее описание.
            local step_w = mode[ state_n ][ step_n ][ step.A_WASH ]
            proc_devices_action( value.wash_data, 1, step_w )
        end

        if value.delay_opened_devices then
            for sub_group, group in pairs( value.delay_opened_devices ) do
                process_dev_ex( mode, state_n, step_n, step.A_DELAY_ON, group[ 1 ],
                    0, sub_group - 1 )

                --Добавляем индекс параметра.
                local param_idx = group[ 2 ]
                if param_idx then
                    local a_step = mode[ state_n ][ step_n ][ step.A_DELAY_ON ]
                    a_step:set_param_idx( sub_group - 1, param_idx )
                end
            end
        end

        if value.delay_closed_devices then
            for sub_group, group in pairs( value.delay_closed_devices ) do
                process_dev_ex( mode, state_n, step_n, step.A_DELAY_OFF, group[ 1 ],
                    0, sub_group - 1 )

                --Добавляем индекс параметра.
                local param_idx = group[ 2 ]
                if param_idx then
                    local a_step = mode[ state_n ][ step_n ][ step.A_DELAY_OFF ]
                    a_step:set_param_idx( sub_group - 1, param_idx )
                end
            end
        end
    end

    --Пример команды от сервера в виде скрипта:
    --  cmd = V95:set_cmd( "st", 0, 1 )
    --  cmd = OBJECT1:set_cmd( "CMD", 0, 1000 )
    SYSTEM = G_PAC_INFO() --Информаци о PAC, которую добавляем в Lua.
    __SYSTEM = SYSTEM     --Информаци о PAC, которую добавляем в Lua.

    for _, obj_info in ipairs( init_tech_objects_modes() ) do

        local modes_count = 0
        if ( obj_info.modes ~= nil ) then
            modes_count = #obj_info.modes
        end

        local par_float_count = 1
        if type( obj_info.par_float ) == "table" then
            par_float_count = #obj_info.par_float
        end
        local rt_par_float_count = 1
        if type( obj_info.rt_par_float ) == "table" then
            rt_par_float_count = #obj_info.rt_par_float
        end
        local par_uint_count = 1
        if type( obj_info.par_uint ) == "table" then
            par_uint_count = #obj_info.par_uint
        end
        local rt_par_uint_count = 1
        if type( obj_info.rt_par_uint ) == "table" then
            rt_par_uint_count = #obj_info.rt_par_uint
        end

        --Создаем технологический объект.
        local object = project_tech_object:new
            {
            name         = obj_info.name or "ОБЪЕКТ",
            n            = obj_info.n or 1,
            tech_type    = obj_info.tech_type or 1,
            modes_count  = modes_count,
            timers_count = obj_info.timers or 1,

            params_float_count         = par_float_count,
            runtime_params_float_count = rt_par_float_count,
            params_uint_count          = par_uint_count,
            runtime_params_uint_count  = rt_par_uint_count
            }

        --Системные параметры.
        object.system_parameters = obj_info.system_parameters

        --Параметры.
        object.PAR_FLOAT = {}
        obj_info.par_float = obj_info.par_float or {}
        for field, v in pairs( obj_info.par_float ) do
            --self.PAR_FLOAT.EXAMPLE_NAME_LUA = 1
            object.PAR_FLOAT[ v.nameLua ] = field

            --self.PAR_FLOAT[ 1 ] = 1.2
            object.PAR_FLOAT[ field ] = v.value
        end
        --Инициализация параметров.
        object.init_params_float = function ( self )
            for field, val in ipairs( self.PAR_FLOAT ) do
                self.par_float[ field ] = val
            end

            self.par_float:save_all()
        end

        object.PAR_UINT = {}
        obj_info.par_uint = obj_info.par_uint or {}
        for field, v in pairs( obj_info.par_uint ) do
            object.PAR_UINT[ v.nameLua ] = field
            object.PAR_UINT[ field ] = v.value
        end
        object.init_params_uint = function ( self )
            for field, val in ipairs( self.PAR_UINT ) do
                self.par_uint[ field ] = val
            end

            self.par_uint:save_all()
        end

        object.RT_PAR_FLOAT = {}
        obj_info.rt_par_float = obj_info.rt_par_float or {}
        for field, v in pairs( obj_info.rt_par_float ) do
            object.RT_PAR_FLOAT[ v.nameLua ] = field
        end
        object.RT_PAR_UINT = {}
        obj_info.rt_par_uint = obj_info.rt_par_uint or {}
        for field, v in pairs( obj_info.rt_par_uint ) do
            object.RT_PAR_UINT[ v.nameLua ] = field
        end

        OBJECTS[ #OBJECTS + 1 ] = object
        local modes_manager = object:get_modes_manager()

        for _, oper_info in ipairs( obj_info.modes ) do

            local operation = modes_manager:add_mode( oper_info.name )

            --Описание с состояниями.
            if oper_info.states ~= nil then
                for state_n, state_info in pairs( oper_info.states ) do

                    process_step( operation, state_n, -1, state_info, object )

                    --Шаги.
                    if state_info.steps ~= nil then

                        for step_n, step_info in ipairs( state_info.steps ) do
                            local time_param_n = step_info.time_param_n or 0
                            local next_step_n = step_info.next_step_n or 0
                            local step = operation:add_step( step_info.name, next_step_n,
                                time_param_n, state_n )
                            process_step( operation, state_n, step_n, step_info, object )

                            --Обрабатываем связанный с шагом объект.
                            local o_idx = step_info.attached_object
                            if o_idx and type( o_idx ) == "number" then
                                if step.set_tag then step:set_tag( o_idx ) end
                                step.attached_object = o_idx
                            end
                        end
                    end
                end
            end
        end -- for _, oper_info in ipairs( value.modes ) do

    end

    return 0
end

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
--Функция, выполняемая каждый цикл в PAC. Вызывается из управляющей программы
--(из С++).
function eval()
    for _, obj in pairs( object_manager.objects ) do
        if obj.evaluate then obj:evaluate() end
    end

    if remote_gateways then eval_gateways( remote_gateways ) end
    if user_eval then user_eval() end
end
-- ----------------------------------------------------------------------------
--Функция, выполняемая один раз в PAC.  Вызывается из управляющей программы
--(из С++).
function init()
    for _, obj in pairs( object_manager.objects ) do
        if obj.user_init then obj:user_init() end
        if obj.init then obj:init() end
    end

    if remote_gateways then init_gateways( remote_gateways ) end
    if user_init then user_init() end

    for _, obj in pairs( object_manager.objects ) do
        if obj.post_init then obj:post_init() end
    end
end
-- ----------------------------------------------------------------------------
-- Функция, выполняемая один раз в PAC. Служит для инициализации параметров.
-- Вызывается из управляющей программы (из С++).
function init_params()
    for _, obj in pairs( object_manager.objects ) do
        if obj.init_params then obj:init_params() end
        if obj.user_init_params then obj:user_init_params() end
    end

    if user_init_params then user_init_params() end
end
