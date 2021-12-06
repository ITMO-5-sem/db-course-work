create index pilot_index on pilot using hash(id);

create index spaceship_index on spaceship using hash(pilot_id);

create index action_index on action using hash(pilot_id);


create index username_index on username using hash(id);