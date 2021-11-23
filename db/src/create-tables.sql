create sequence object_id_sequence
    start 1
    increment 1;


create table sector
(
    id   serial primary key,
    name varchar(64) not null
        check ( length( name ) > 0 )
);


create table system
(
    id     serial primary key,
    name   varchar(64) not null unique
        check ( length( name ) > 0 ),
    sector int         not null
        references sector
            on delete cascade
            on update cascade
);

create table space_object_type(
    id serial primary key,
    name varchar(64) not null
);

create table space_object(
    id serial primary key,
    name varchar(64) not null unique check ( length( name ) > 0 ),
    object_type int references space_object_type,
    system int references system on delete cascade not null
);

create table spacebase_type
(
    id          serial primary key,
    name        varchar(16)  not null unique check ( length( name ) > 0 ),
    description varchar(512),
    karma_from  int check ( karma_from >= -100 and karma_from < 100 ),
    karma_to    int check (karma_to < 100 and karma_to > -100
                and karma_to > karma_from)
);


create table spacebase
(
    id          serial primary key,
    obj_id int references space_object on delete cascade on update cascade not null,
    spacebase_type_id int         not null references spacebase_type on delete restrict
        on update cascade, -- no reason to delete the type

    system_id         int         not null
        references system
            on delete cascade  -- delete a system - delete everything
            on update cascade
);





create table politics
(
    id          serial primary key,
    name        varchar(32)  not null
        check ( length( name ) > 0 ),
    description varchar(256) not null
        check ( length( description ) > 0 )
);


create table economics
(
    id          serial primary key,
    name        varchar(32)  not null
        check ( length( name ) > 0 ),
    description varchar(256) not null
        check ( length( description ) > 0 )
);


create table race
(
    id          serial primary key,
    name        varchar(32)  not null
        check ( length( name ) > 0 ),
    description varchar(256) not null
        check ( length( description ) > 0 )
);

create table planet
(
    
    obj_id int references space_object on delete cascade on update cascade not null,
    citizens  int not null
        check ( citizens >= 0 ), -- citizens - кол-во жителей (в тыс.)
    politics  int
        references politics
            on delete set null
            on update cascade,
    economics integer
        references economics
            on delete set null
            on update cascade
);

create table action_type
(
    id            serial primary key,
    name          varchar(32) not null unique
        check ( length( name ) > 0 ),
    action_impact int         not null
        check
            (
                    action_impact >= -10
                and action_impact <= 10
            )
);

create table user_role(
                          id serial primary key,
                          role_name varchar(32)
);

create table "user"(
                       id serial primary key,
                       login varchar(64) not null,
                       password varchar(64) not null,
                       role integer references user_role not null
);

create table pilot
(
    id               serial primary key,
    name             varchar(64) not null unique
        check ( length( name ) > 0 ),
    description      varchar(256)
        check ( length( description ) > 0),
    race_id          int
        references race
            on delete set null
            on update cascade,
    karma            int         not null default 0,

    owner integer references "user" on delete cascade not null
);

create table spaceship_type
(
    id          serial primary key,
    name        varchar(16) not null unique
        check ( length( name ) > 0 ),
    description varchar(256)
);


create table spaceship
(
    id                serial primary key,
    name              varchar(64) not null unique,
    spaceship_type_id int         not null
        references spaceship_type
            on delete set null
            on update cascade,
    pilot_id          int         not null
        references pilot
            on delete cascade -- spaceship without pilot doesn't exist
            on update cascade
);


create table action
(
    id                 serial primary key,
    date               date not null default now( ),
    action_description text,
    pilot_id           int  not null
        references pilot
            on delete cascade
            on update cascade,
    action_type_id     int  not null
        references action_type
            on delete restrict
            on update cascade
);


create table LIVING_RACES
(
    id             serial primary key,
    race_id        int
        references race
            on delete cascade
            on update cascade not null,
    planet_info_id int
        references planet_info
            on delete cascade
            on update cascade not null,
    unique ( race_id, planet_info_id )
);

create table landings(
    spaceship_id integer references spaceship on delete cascade not null,
    space_obj_id integer references space_object on delete cascade not null,
    primary key (spaceship_id, space_obj_id)
)


