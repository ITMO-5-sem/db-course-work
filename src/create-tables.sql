create table spaceship_type (
    id serial primary key,
    name varchar(16) not null unique
        check ( length(name) > 0 ),
    description varchar(256)
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
);


create table spacebase_type (
    id serial primary key,
    name varchar(16) not null unique
        check ( length(name) > 0 ),
    description varchar(512) not null
);


create table spacebase (
    id serial primary key,
    name varchar(16) not null unique,
    spacebase_type_id int not null
        references spacebase_type,
    system_id int not null
        references system,
    karma_from int
        check (
                    karma_from >= -100
                and karma_from < 100
            ),
    karma_to int
        check (
                    karma_to < 100
                and karma_to > -100
                and karma_to > karma_from
            )
);

-- todo
create table permission (
    id serial primary key,
    spaceship_id int not null
        references spaceship,
    spacebase_id int not null
        references spacebase,
    allowed bool default false
);

create table sector (
    id serial primary key,
    name varchar(64) not null
);

create table system (
    id serial primary key,
    name varchar(64) not null,
    sector int not null
        references sector
            on delete cascade
);

create table planet (
    id serial primary key,
    name varchar(64) not null,
    system int not null
        references system on delete cascade
);

create table planet_info (
    -- citizens - кол-во жителей (в тыс.)
    id serial primary key,
    citizens int not null check ( citizens >= 0 ),
    politics int
        references politics
            on delete set default null,
    economics integer
        references economics
            on delete set default null
);


create table politics (
    id serial primary key,
    name varchar(32) not null,
    description varchar(256) not null
);


create table economics (
    id serial primary key,
    name varchar(32) not null,
    description varchar(256) not null
);


create table race(
     id serial primary key,
     name varchar(32) not null,
     description varchar(256) not null
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


create table pilot (
    id serial primary key,
    name varchar(64) not null unique,
    passport_id int not null
        references pilot_passport
);


create table pilot_passport (
    id serial primary key,
    pilot_id int not null
        references pilot
            on delete cascade
            on update cascade,
    description varchar(256),
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

create table attitude (
    name varchar(16),
    karma_from int
        check (
            karma_from >= -100
            and karma_from < 100
        ),
    karma_to int
        check (
            karma_to < 100
            and karma_to > -100
            and karma_to > karma_from
        )
);

create table action_type (
    id serial primary key,
    name varchar(32) not null unique,
    action_impact int not null
        check (
                action_impact >= -10
            and action_impact <= 10
        )
);

create table action (
    id serial primary key,
    date date ,
    action_description text,
    pilot_passport_id int not null
        references pilot_passport
            on delete cascade
            on update cascade,
    action_type_id int not null references action_type
        on update cascade
        on delete set null
);


create table landings_log (
    id serial primary key,
    date timestamp,
    permission_received bool,
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
create or replace function update_karma(pilot_passport_id_arg int) returns void as $$
    begin
        update pilot_passport
            set karma =
                (
                    select sum(action_impact)
                    from
                         (
                             select pilot_passport_id, action_impact
                             from
                                  (
                                      action a join action_type a_t on a.action_type_id = a_t.id
                                  )
                         ) as "act_act_t"
                    where act_act_t.pilot_passport_id = pilot_passport_id_arg
                )
            where id = pilot_passport_id_arg;
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
            from pilot_passport
            where pilot_passport.id =
                  (
                      select passport_id
                        from pilot
                        where pilot.id =
                              (
                                  select pilot_id
                                    from spaceship
                                    where spaceship.id = spaceship_id_arg
                              )
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
    execute procedure update_karma(new.pilot_passport_id);

create trigger process_permission_trigger
    before insert
    on landings_log
    for each row
    execute procedure process_permission(new.spaceship_id, new.spacebase_id)
