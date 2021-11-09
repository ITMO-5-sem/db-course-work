-- triggers and functions

-- Updates a pilot's karma by it's id
create or replace function update_karma() returns trigger as
$$
declare
    pilot_id_arg int;
begin
    update pilot
    set karma =
    (
        (
            select karma
            from pilot
            where id = new.pilot_id
        )
        +
        (
            select action_impact
            from (
                     select *
                     from action
                     where pilot_id = new.pilot_id
                 ) as a
                     join
                 action_type as a_t
                 on a.action_type_id = a_t.id
        )
    )
--         update pilot
--             set karma =
--             (
--                 select sum(action_impact)
--                 from
--                 (
--                     select pilot_id, action_impact
--                     from
--                     (
--                         action a join action_type a_t on a.action_type_id = a_t.id
--                     )
--                 ) as "act_act_t"
--                 where act_act_t.pilot_id = pilot_id_arg
--             )
    where id = pilot_id_arg;
    return new;
end;
$$ language plpgsql;


create trigger update_karma_trigger
    after insert
    on action
    for each row
execute procedure update_karma();



create or replace function process_permission() returns trigger as
$$
declare

    spaceship_id_arg          int;
    spacebase_id_arg          int;
    landing_time              timestamp;
    min_required_karma        int;
    max_required_karma        int;
    pilot_karma               int;
    permission_received_local bool;

begin

    spaceship_id_arg := new.spaceship_id;
    spacebase_id_arg := new.spacebase_id;

    landing_time := now();
    select karma_from, karma_to
    into min_required_karma, max_required_karma
    from spacebase_type
    where spacebase_type.id =
          (
              select spacebase_type_id
              from spacebase
              where spacebase.id = spacebase_id_arg
          );

    select karma
    into pilot_karma
    from pilot
    where pilot.id =
          (
              select pilot_id
              from spaceship
              where spaceship.id = spaceship_id_arg
          );


    permission_received_local := false;

    if ((min_required_karma < pilot_karma) and (pilot_karma < max_required_karma)) then
        permission_received_local := true;
    end if;

    insert into permissions_log
    values (default,
            now(),
            permission_received_local,
            spaceship_id_arg,
            spacebase_id_arg);

    return new;
end;
$$ language plpgsql;


create trigger process_permission_trigger
    before insert
    on permissions_log
    for each row
execute procedure process_permission();



create or replace function tr_fn_Pilot_insert() returns trigger as
$$
begin
     new.karma = 0;

    return new;
end;
$$ language plpgsql;


create or replace function tr_fn_Pilot_update() returns trigger as
$$
begin
    if ( ! new.karma is null ) then
        raise exception 'Karma cannot be changed explicitly. It is only calculated based on pilot actions.';
    end if;

    return new;
end;
$$ language plpgsql;


create trigger tr_Pilot_update
    before update
    on pilot
    for each row
execute procedure tr_fn_Pilot_insert();


create trigger tr_Pilot_insert
    before update
    on pilot
    for each row
execute procedure tr_fn_Pilot_update();
