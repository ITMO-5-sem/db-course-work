create table spaceship_type (
    id serial primary key,
    name varchar(16) not null unique
        check ( length(name) > 0 ),
    description varchar(256)
);


create table spacebase_type (
    id serial primary key,
    name varchar(16) not null unique
        check ( length(name) > 0 ),
    description varchar(512) not null
);


create table sector (
    id serial primary key,
    name varchar(64) not null
        check ( length(name) > 0 )
);


create table system (
    id serial primary key,
    name varchar(64) not null
        check ( length(name) > 0 ),
    sector int not null
        references sector
            on delete cascade
);


create table spacebase (
    id serial primary key,
    name varchar(16) not null unique,
    spacebase_type_id int not null
        references spacebase_type
            on delete restrict
            on update cascade , -- no reason to delete the type
    system_id int not null
        references system
            on delete cascade -- delete a system - delete everything
            on update cascade,
    karma_from int
        check
            (
                    karma_from >= -100
                and karma_from < 100
            ),
    karma_to int
        check
            (
                    karma_to < 100
                and karma_to > -100
                and karma_to > karma_from
            )
);


create table planet (
    id serial primary key,
    name varchar(64) not null,
    system int not null
        references system
            on delete cascade -- remove system - remove all planets
            on update cascade
);


create table politics (
    id serial primary key,
    name varchar(32) not null
        check ( length(name) > 0 ),
    description varchar(256) not null
        check ( length(description) > 0 )
);


create table economics (
    id serial primary key,
    name varchar(32) not null
        check ( length(name) > 0 ),
    description varchar(256) not null
        check ( length(description) > 0 )
);

create table race (
    id serial primary key,
    name varchar(32) not null
        check ( length(name) > 0 ),
    description varchar(256) not null
        check ( length(description) > 0 )
);


create table living_races (
    -- todo Нужен ли здесь отдельный id ?
    race_id int
        references race
            on delete cascade
            on update cascade not null,
    planet_id int
        references planet
            on delete cascade
            on update cascade not null,
    primary key(race_id, planet_id)
);


create table planet_info (
    -- citizens - кол-во жителей (в тыс.)
    id serial primary key,
    citizens int not null
        check ( citizens >= 0 ),
    planet_id int
        references planet
            on delete cascade -- delete planet - delete planet info
            on update cascade,
    politics int
        references politics
            on delete set null
            on update cascade,
    economics integer
        references economics
            on delete set null
            on update cascade
);


create table action_type (
    id serial primary key,
    name varchar(32) not null unique
        check ( length(name) > 0 ),
    action_impact int not null
        check
            (
                    action_impact >= -10
                and action_impact <= 10
            )
);


create table pilot (
   id serial primary key,
   name varchar(64) not null unique
       check ( length(name) > 0 ),
   description varchar(256)
       check ( length(description) > 0),
   race_id int
       references race
           on delete set null
           on update cascade,
   native_planet_id int not null
       references planet
           on delete set null
           on update cascade,
   karma int not null
);


create table action (
    id serial primary key,
    date date not null ,
    action_description text,
    pilot_id int not null
        references pilot
            on delete cascade
            on update cascade,
    action_type_id int not null
        references action_type
            on delete restrict
            on update cascade
);


create table spaceship (
    id serial primary key,
    name varchar(64) not null unique,
    spaceship_type_id int not null
        references spaceship_type
            on delete set null
            on update cascade,
    pilot_id int not null
        references pilot
           on delete cascade -- spaceship without pilot doesn't exist
           on update cascade
);


create table landings_log (
    id serial primary key,
    date timestamp not null,
    permission_received bool not null,
    spaceship_id int not null
        references spaceship
              on delete restrict
              on update cascade,
    spacebase_id int not null
        references spacebase
            on delete restrict
            on update cascade
);

-- Updates a pilot_passport karma by it's id
create or replace function update_karma(pilot_id_arg int) returns void as $$
    begin
        update pilot
            set karma =
            (
                select sum(action_impact)
                from
                (
                    select pilot_id, action_impact
                    from
                    (
                        action a join action_type a_t on a.action_type_id = a_t.id
                    )
                ) as "act_act_t"
                where act_act_t.pilot_id = pilot_id_arg
            )
            where id = pilot_id_arg;
    end;
$$ language plpgsql;


create or replace function process_permission(spaceship_id_arg int, spacebase_id_arg int) returns void as $$
    declare
        landing_time timestamp;
        min_required_karma int;
        max_required_karma int;

        pilot_karma int;

        permission_received_local bool;

    begin
        landing_time := now();
        select karma_from, karma_to
            into min_required_karma, max_required_karma
            from spacebase where spacebase.id = spacebase_id_arg;

        select karma into pilot_karma
            from pilot
            where pilot.id =
            (
                select pilot_id
                from spaceship
                where spaceship.id = spaceship_id_arg
            );


        permission_received_local := false;

        if ( ( min_required_karma < pilot_karma ) and ( pilot_karma < max_required_karma )) then
            permission_received_local := true;
        end if;

        insert into landings_log values
        (
            default,
            now(),
            permission_received_local,
            spaceship_id_arg,
            spacebase_id_arg
        );

    end;
$$ language plpgsql;


create trigger update_karma_trigger
    after insert
    on action
    for each row
    execute procedure update_karma(new.pilot_id);


create trigger process_permission_trigger
    before insert
    on landings_log
    for each row
    execute procedure process_permission(new.spaceship_id, new.spacebase_id)
