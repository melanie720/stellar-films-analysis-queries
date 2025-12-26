if not exists (select * from sys.databases where name = 'StellarFilms')
    create database StellarFilms
go

use StellarFilms
go

-- DOWN

if exists (select * from information_schema.table_constraints
    where constraint_name = 'fk_schedules_prod_id')
    alter table schedules drop constraint fk_schedules_prod_id
go

if exists (select * from information_schema.table_constraints
    where constraint_name = 'fk_finances_prod_id')
    alter table finances drop constraint fk_finances_prod_id
go

if exists (select * from information_schema.table_constraints
    where constraint_name = 'fk_productions_prim_location_id')
    alter table productions drop constraint fk_productions_prim_location_id
go

if exists (select * from information_schema.table_constraints
    where constraint_name = 'fk_productions_director_id')
    alter table productions drop constraint fk_productions_director_id
go

if exists (select * from information_schema.table_constraints
    where constraint_name = 'fk_productions_genre_id')
    alter table productions drop constraint fk_productions_genre_id
go

drop table if exists schedules 
go 

drop table if exists finances 
go 

drop table if exists productions 
go 

drop table if exists talent_stats 
go 

drop table if exists locations 
go 

drop table if exists genres 
go 

-- UP

create table genres (
    genre_id int identity not null,
    genre_name varchar(15) not null,
    constraint pk_genres_genre_id primary key (genre_id),
    constraint u_genres_genre_name unique (genre_name)
)

insert into genres (genre_name) values 
    ('Action'), 
    ('Comedy'), 
    ('Drama'), 
    ('Romance'), 
    ('Horror'),
    ('Sci-Fi'), 
    ('Thriller'), 
    ('Documentary'),
    ('Animation')
go

create table locations (
    location_id int identity not null,
    location_name varchar(25) not null,
    constraint pk_locations_location_id primary key (location_id),
    constraint u_locations_location_name unique (location_name)
)

insert into locations (location_name) values 
    ('Vancouver'), 
    ('Atlanta'), 
    ('Prague'), 
    ('Sydney'), 
    ('New Zealand'),
    ('London'), 
    ('Tokyo'), 
    ('Berlin'), 
    ('Toronto'), 
    ('Iceland')
go

create table talent_stats (
    person_id int identity not null,
    person_firstname varchar(20) not null,
    person_lastname varchar(20) not null,
    avg_critical_score decimal(5,2) not null,
    total_career_revenue decimal(15,2) not null,
    constraint pk_talent_stats_person_id primary key (person_id)
)

insert into talent_stats (person_firstname, person_lastname, avg_critical_score, total_career_revenue) values 
    ('Ava', 'Rodriguez', 82.37, 2500000000.00), 
    ('Marcus', 'Lee', 70.84, 900000000.00), 
    ('Helena', 'Strauss', 88.92, 3100000000.00), 
    ('Darius', 'Cole', 65.41, 1200000000.00), 
    ('Rina', 'Patel', 79.63, 1800000000.00),
    ('Jonas', 'Meyer', 74.28, 600000000.00),
    ('Selene', 'Ward', 83.15, 950000000.00),
    ('Bram', 'Keller', 68.72, 420000000.00),
    ('Kaito', 'Sato', 92.10, 4200000000.00), 
    ('Elena', 'Voz', 61.20, 750000000.00), 
    ('Julian', 'Thorne', 77.45, 1100000000.00), 
    ('Sia', 'Mbeki', 85.00, 300000000.00)
go

create table productions (
    prod_id int identity not null,
    title varchar(50) not null,
    genre_id int not null,
    director_id int not null,
    primary_location_id int not null,
    constraint pk_productions_prod_id primary key (prod_id),
    constraint fk_productions_genre_id foreign key (genre_id) references genres(genre_id),
    constraint fk_productions_director_id foreign key (director_id) references talent_stats(person_id),
    constraint fk_productions_prim_location_id foreign key (primary_location_id) references locations(location_id),
)

insert into productions (title, genre_id, director_id, primary_location_id) values
    ('Crimson Horizon', 1, 1, 1),
    ('Laughing Stock', 2, 2, 2),
    ('Silent Scream', 5, 8, 2),
    ('Silent Depths', 3, 3, 3),
    ('Neon Velocity', 1, 4, 4),
    ('Autumn''s Edge', 4, 1, 9),
    ('Quantum Heist', 1, 5, 1),
    ('Paper Hearts', 2, 6, 3),
    ('Frozen Kingdom', 3, 4, 2),
    ('Desert Bloom', 4, 3, 8),
    ('Iron Tempest', 1, 5, 5),
    ('Whispers in the Cellar', 5, 7, 1),
    ('Midnight Harvest', 5, 8, 2),
    ('Solaris Protocol', 6, 1, 7),
    ('The Shadow Network', 7, 5, 6),
    ('The Script', 3, 6, 3),
    ('Echoes of Kyoto', 8, 9, 7),
    ('Midnight in Berlin', 7, 10, 8),
    ('Steel Pulse', 1, 11, 9),
    ('Northern Lights', 3, 12, 10),
    ('Midnight Howl', 5, 7, 2),
    ('The Woods', 5, 8, 5),
    ('The Gilded Cage', 3, 3, 6),
    ('Velocity Protocol', 1, 1, 1),
    ('Starlight', 4, 7, 1),
    ('Apex Predator', 1, 1, 1),
    ('City of Grins', 2, 1, 2),
    ('Grave Mistakes', 5, 6, 3),
    ('Last Echo', 3, 1, 1),
    ('Tactical Edge', 1, 1, 8),
    ('Double Take', 2, 2, 2),
    ('Shadow Strike', 1, 2, 5),
    ('Stand Up', 2, 2, 2),
    ('Broken Waltz', 4, 2, 1),
    ('Blue Velvet', 3, 3, 3),
    ('Vienna Calling', 4, 3, 5),
    ('The Architect', 3, 3, 5),
    ('Shattered Glass', 5, 3, 1),
    ('High Gear', 1, 4, 4),
    ('Down Under', 2, 4, 8),
    ('Speed Limit', 1, 4, 1),
    ('Outback Noir', 3, 4, 8),
    ('Global Ransom', 1, 5, 9),
    ('The Cellar', 5, 8, 2),
    ('Circuit Breaker', 1, 5, 1),
    ('Kauri Spirits', 3, 5, 5),
    ('Love in Auckland', 4, 5, 5),
    ('Punchline', 2, 6, 2),
    ('Haunted Prague', 5, 6, 1),
    ('Blood Moon', 5, 7, 3),
    ('Dark Corridor', 5, 7, 2),
    ('Tears of Joy', 2, 8, 4),
    ('Iron Pulse', 1, 9, 2),
    ('Steel Grin', 2, 9, 1),
    ('Rust & Bone', 3, 9, 2),
    ('Neon Nights', 4, 10, 3),
    ('Digital Soul', 3, 10, 4),
    ('Static Horror', 5, 10, 3),
    ('Savanna Chase', 1, 11, 5),
    ('Golden Sunset', 4, 11, 4),
    ('The Great Rift', 3, 11, 9),
    ('Zenith Point', 1, 12, 1),
    ('Paper Cranes', 3, 12, 5),
    ('Hidden Blade', 1, 12, 5)
go

create table finances (
    finance_id int identity not null,
    prod_id int not null,
    budget_allocated decimal(15,2) not null,
    actual_spend decimal(15,2) not null,
    marketing_spend decimal(15,2) not null,
    box_office_global decimal(15,2) null,
    constraint pk_finance_id primary key (finance_id),
    constraint fk_finances_prod_id foreign key (prod_id) references productions(prod_id)
)

insert into finances (prod_id, budget_allocated, actual_spend, marketing_spend, box_office_global) values
    (1, 120000000, 150000000, 40000000, 550000000),
    (5, 25000000, 22000000, 10000000, 20000000),
    (2, 30000000, 28000000, 15000000, 90000000),
    (3, 45000000, 60000000, 20000000, 50000000),
    (9, 35000000, 50000000, 12000000, 30000000),
    (4, 90000000, 130000000, 50000000, 100000000),
    (8, 80000000, 95000000, 35000000, 120000000),
    (6, 150000000, 200000000, 60000000, 520000000),
    (10, 160000000, 150000000, 70000000, 180000000),
    (7, 20000000, 18000000, 8000000, 60000000),
    (11, 18000000, 16000000, 7000000, 85000000),
    (12, 25000000, 40000000, 12000000, 20000000),
    (28, 20000000, 21000000, 8000000, 15000000),
    (13, 200000000, 215000000, 85000000, 890000000),
    (14, 45000000, 48000000, 15000000, 110000000),
    (52, 14000000, 16000000, 6000000, 41000000),
    (15, 5000000, 4500000, 2000000, 18000000),
    (26, 90000000, 110000000, 35000000, 200000000),
    (16, 65000000, 80000000, 30000000, 45000000),
    (30, 30000000, 28000000, 12000000, 95000000),
    (17, 110000000, 105000000, 40000000, 310000000),
    (18, 12000000, 14000000, 5000000, 42000000),
    (19, 55000000, 52000000, 20000000, 145000000),
    (47, 30000000, 29000000, 15000000, 40000000),
    (20, 95000000, 98500000, 30000000, 115000000),
    (21, 140000000, 145000000, 50000000, 410000000),
    (32, 15000000, 18000000, 5000000, 65000000),
    (22, 35000000, 32000000, 10000000, 85000000),
    (35, 95000000, 105000000, 35000000, 180000000),
    (23, 60000000, 65000000, 15000000, 45000000),
    (24, 120000000, 130000000, 40000000, 390000000),
    (25, 40000000, 38000000, 15000000, 130000000),
    (27, 25000000, 24000000, 10000000, 60000000),
    (29, 50000000, 55000000, 20000000, 130000000),
    (31, 75000000, 82000000, 25000000, 110000000),
    (33, 100000000, 120000000, 45000000, 280000000),
    (34, 30000000, 31000000, 10000000, 55000000),
    (36, 40000000, 42000000, 15000000, 38000000),
    (37, 130000000, 140000000, 55000000, 490000000),
    (45, 15000000, 14000000, 7000000, 70000000),
    (38, 110000000, 115000000, 40000000, 500000000),
    (49, 10000000, 12000000, 4000000, 59000000),
    (40, 25000000, 26000000, 10000000, 45000000),
    (41, 12000000, 11000000, 6000000, 60000000),
    (50, 8000000, 10000000, 3000000, 28000000),
    (42, 28000000, 27000000, 12000000, 72000000),
    (46, 22000000, 25000000, 10000000, 88000000),
    (44, 18000000, 20000000, 8000000, 58000000),
    (43, 40000000, 45000000, 15000000, 35000000),
    (48, 12000000, 14000000, 5000000, 33000000),
    (39, 45000000, 48000000, 18000000, 90000000),
    (51, 20000000, 22000000, 8000000, 18000000),
    (53, 110000000, 118000000, 45000000, 310000000), 
    (54, 40000000, 39000000, 12000000, 92000000), 
    (55, 25000000, 28000000, 5000000, 12000000),
    (56, 60000000, 62000000, 20000000, 155000000), 
    (57, 45000000, 44000000, 15000000, 88000000), 
    (58, 15000000, 17500000, 8000000, 64000000),
    (59, 130000000, 142000000, 50000000, 480000000), 
    (60, 30000000, 30000000, 10000000, 75000000), 
    (61, 85000000, 90000000, 25000000, 135000000),
    (62, 125000000, 120000000, 40000000, 550000000), 
    (63, 20000000, 22000000, 8000000, 55000000), 
    (64, 90000000, 95000000, 35000000, 210000000)
go

create table schedules (
    schedule_id int identity not null,
    prod_id int not null,
    planned_shooting_days int not null,
    actual_shooting_days int not null,
    delay_reason varchar(50) not null default 'None',
    constraint pk_schedules_schedule_id primary key (schedule_id),
    constraint fk_schedules_prod_id foreign key (prod_id) references productions(prod_id)
)

insert into schedules (prod_id, planned_shooting_days, actual_shooting_days, delay_reason) values
    (1, 90, 120, 'Weather'),
    (2, 44, 42, 'None'),
    (3, 60, 78, 'Actor Injury'),
    (4, 80, 110, 'Equipment Failure'),
    (5, 40, 41, 'Permit Issues'),
    (6, 100, 140, 'VFX Pipeline Delays'),
    (7, 35, 33, 'None'),
    (8, 75, 90, 'Weather'),
    (9, 50, 65, 'Location Restrictions'),
    (10, 110, 160, 'Reshoots'),
    (11, 40, 65, 'Location Safety Review'),
    (12, 50, 72, 'Actor Illness'),
    (13, 120, 125, 'VFX Pipeline Delays'),
    (14, 55, 54, 'None'),
    (15, 30, 28, 'None'),
    (16, 70, 95, 'Director Conflict'),
    (17, 85, 80, 'None'),
    (18, 45, 63, 'Volcanic Activity'),
    (19, 60, 60, 'None'),
    (20, 75, 80, 'Equipment Failure'),
    (21, 95, 110, 'Stunt Safety Re-shoot'), 
    (22, 45, 45, 'None'), 
    (23, 65, 82, 'Weather'), 
    (24, 80, 88, 'Customs Delay'),
    (25, 40, 38, 'None'), 
    (26, 75, 90, 'Location Permit Issues'), 
    (27, 45, 44, 'None'), 
    (28, 50, 58, 'Actor Illness'),
    (29, 60, 60, 'None'), 
    (30, 55, 75, 'Visa Issues'), 
    (31, 85, 95, 'Logistics (Remote Location)'), 
    (32, 40, 50, 'None'),
    (33, 90, 115, 'Equipment Failure'), 
    (34, 45, 52, 'Public Interference'), 
    (35, 80, 85, 'VFX Coordination'), 
    (36, 60, 60, 'None'),
    (37, 100, 132, 'Weather (Cyclone)'), 
    (38, 90, 92, 'None'), 
    (39, 55, 65, 'Reshoots'), 
    (40, 45, 45, 'None'),
    (41, 35, 45, 'Set Fire'), 
    (42, 40, 40, 'None'), 
    (43, 60, 68, 'Script Revision'), 
    (44, 40, 52, 'Historical Site Access'),
    (45, 30, 32, 'None'), 
    (46, 40, 60, 'Equipment Failure'), 
    (47, 50, 48, 'None'), 
    (48, 35, 42, 'Makeup/Prosthetics Delay'),
    (49, 30, 30, 'None'), 
    (50, 25, 35, 'Actor Injury'), 
    (51, 45, 48, 'None'), 
    (52, 40, 55, 'Weather'),
    (53, 85, 92, 'Stunt Safety'),
    (54, 45, 45, 'None'),
    (55, 50, 65, 'Labor Strike'),
    (56, 60, 72, 'Local Permit Issues'),
    (57, 55, 55, 'None'),
    (58, 40, 48, 'Technical Issues'),
    (59, 90, 112, 'Extreme Weather'),
    (60, 45, 45, 'None'),
    (61, 75, 80, 'Wildlife Interference'),
    (62, 80, 80, 'None'),
    (63, 50, 66, 'Set Redesign'),
    (64, 85, 102, 'Weather')
go

-- VERIFY

select * from genres;
select * from locations;
select * from talent_stats;
select * from productions;
select * from finances;
select * from schedules;