insert into spaceship_type
values (default,
        'Торговый корабль',
        'Медленный, бронированный и грузоподъёмный. Нет вооружения.'),
       (default,
        'Лайнер',
        'Среднескоростной и бронированный, служит для транспортировки пассажиров. Нет вооружения.'),
       (default,
        'Корсар',
        'быстрый корабль, хорошее вооружение, плохая броня.');

insert into spacebase_type
values (default,
        'Пиратская база',
        'Пиратская база - логово всяких негодяев и убийц. Но даже так, некоторые говорят, что у них есть свой кодекс.',
        -100,
        -77);


insert into spacebase_type
values (default,
        'Медицинский центр',
        'Медицинский центр - отличное место после тяжелой заварушки.',
        -32,
        100);

insert into spacebase_type
values (default,
        'Бизнес-центр',
        'Космический банк. Работает как любой другой банк.',
        0,
        100),
       (default,
        'Военная база',
        'Космическая база. Информация, которая там хранится строго засекречена.',
        75,
        100),
       (default,
        'Черный рынок',
        'Место скопления воров и мошенников. Здесь можно прибрести не совсем законные вещи.',
        -100,
        100),
       (default,
        'Научная станция',
        'Научная станция - отличное место для приобретения передовых технологий.',
        20,
        100);

insert into politics
values (default,
        'Абсолютная монархия',
        'Все подчиняются королю.'),
       (default,
        'Демократия',
        'Все граждане имеют равные права.');

insert into economics
values (default, 'Аграрная', 'Преобладает сельское хозяйство.'),
       (default, 'Индустриальная', 'Преобладает промышленность с гибкими динамичными структурами.');

insert into race
values (default, 'Человек', 'Две руги, две ноги - на макаку похож'),
       (default, 'Фэяне', 'Раса гуманоидов-гермафродитов с большим мозгом и фасеточными глазами'),
       (default, 'Маллоки', ' крупные, мощного телосложения гуманоиды. Для них характерна огромная физическая сила, ' ||
                            'выносливость, ' ||
                            'высокая сопротивляемость природным факторам, не слишком активная мыслительная деятельность.');

insert into sector
values (default, 'Карагон'),
       (default, 'Зондур'),
       (default, 'Фаави');


insert into system
values (default,
        'Солнце',
        (select sector.id from sector where sector.name = 'Карагон')),
       (default,
        'Беллатрикс',
        (select sector.id from sector where sector.name = 'Зондур')),
       (default,
        'Таллот',
        (select sector.id from sector where sector.name = 'Фаави'));

insert into planet
VALUES (default, 'Земля', (select system.id from system where system.name = 'Солнце')),
       (default, 'Чанга', (select system.id from system where system.name = 'Беллатрикс')), --Эта планета необитаемая
       (default, 'Орооген', (select system.id from system where system.name = 'Таллот'));

--id, citizens, planet_id, politics, economics
insert into planet_info
values (default,
        10000,
        (select planet.id from planet where planet.name = 'Земля'),
        (select politics.id from politics where politics.name = 'Демократия'),
        (select economics.id from economics where economics.name = 'Аграрная')),
       (default,
        5000,
        (select planet.id from planet where planet.name = 'Орооген'),
        (select politics.id from politics where politics.name = 'Демократия'),
        (select economics.id from economics where economics.name = 'Индустриальная'));


insert into spacebase
values (default,
        'Пьяный корсар',
        (select spacebase_type_id from spacebase_type where spacebase_type.name = 'Пиратская база'),
        (select system_id from system where system.name = 'Таллот')),
       (default,
        'Костоправ',
        (select spacebase_type_id from spacebase_type where spacebase_type.name = 'Медицинский центр'),
        (select system_id from system where system.name = 'Солнце'))
;


insert into living_races
values (default,
        (select race_id
         from race
         where race.name = 'Маллоки'),
        (select planet_info_id
         from planet_info
         where planet_info.planet_id =
               (select planet_id from planet where planet.name = 'Земля'))),
       (default,
        (select race_id
         from race
         where race.name = 'Человек'),
        (select planet_info_id
         from planet_info
         where planet_info.planet_id =
               (select planet_id from planet where planet.name = 'Земля')));


insert into action_type (name, action_impact)
values ('Нападение на торговое судно',
        -4),
       ('Помощь терпящему крушение мирному кораблю',
        +2);

insert into pilot (name, description, race_id, native_planet_id, karma)
values ('Свинка Пепа',
        'Самая храбрая космическая свинка.',
        (select id from race where race.name = 'Человек'),
        (select id from planet where planet.name = 'Земля')),
       ('Джек Воробей',
        'Хм хэм!... Капитан Джек Воробей!',
        (select id from race where race.name = 'Человек'),
        (select id from planet where planet.name = 'Земля'));

insert into action (action_description, pilot_id, action_type_id)
values ('Было совершено ограбление торгового судна. Обошлось без жертв.',
        (select id from pilot where pilot.name = 'Свинка Пепа'),
        (select id from action_type where action_type.name = 'Нападение на торговое судно'));


insert into spaceship (name, spaceship_type_id, pilot_id) values
(
    'Зеленая Мария', -- тут чт-то не тоо с Корсаром
    (select id from spaceship_type where name = 'Корсар'),
    (select id from pilot where name = 'Джек Воробей')
);

insert into permissions_log (date, permission_received, spaceship_id, spacebase_id) values
(
    now(), -- the date is set inside trigger, not depending on this
    true, -- this is set inside trigger
    (select id from spaceship where spaceship.name = ''),
    (select id from spacebase where spacebase.name = '')
);