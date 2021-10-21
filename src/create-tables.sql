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
    description varchar(512) not null,
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


create table sector (
    id serial primary key,
    name varchar(64) not null
        check ( length(name) > 0 )
);


create table system (
    id serial primary key,
    name varchar(64) not null unique
        check ( length(name) > 0 ),
    sector int not null
        references sector
            on delete cascade
            on update cascade
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
            on update cascade
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

create table living_races (
    id serial primary key,
    race_id int
        references race
            on delete cascade
            on update cascade not null,
    planet_info_id int
        references planet_info
            on delete cascade
            on update cascade not null,
    unique (race_id, planet_info_id)
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
   karma int not null default 0
);


create table action (
    id serial primary key,
    date date not null default now(),
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


create table permissions_log (
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

-- triggers and functions

-- Updates a pilot_passport karma by it's id
create or replace function update_karma() returns trigger as $$
    declare
        pilot_id_arg int;
    begin
        pilot_id_arg := new.pilot_id;
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
        return new;
    end;
$$ language plpgsql;


create trigger update_karma_trigger
    after insert
    on action
    for each row
execute procedure update_karma();



create or replace function process_permission() returns trigger as $$
    declare

        spaceship_id_arg int;
        spacebase_id_arg int;

        landing_time timestamp;
        min_required_karma int;
        max_required_karma int;

        pilot_karma int;

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

        insert into permissions_log values
        (
            default,
            now(),
            permission_received_local,
            spaceship_id_arg,
            spacebase_id_arg
        );

        return new;
    end;
$$ language plpgsql;


create trigger process_permission_trigger
    before insert
    on permissions_log
    for each row
execute procedure process_permission();
