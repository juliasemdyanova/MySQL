drop database if exists vk;
create database vk;
use vk;

DROP TABLE IF EXISTS users;
CREATE TABLE users(
	id SERIAL PRIMARY KEY,
	firstname VARCHAR(100),
	lastname VARCHAR(100),
	email VARCHAR(120) UNIQUE,
	password_hash VARCHAR(100),
	phone bigint,
	
	-- индексы
	index (phone),
	index (firstname,lastname)
);

drop table if exists profiles;
create table profiles(
	user_id SERIAL PRIMARY KEY,
	gender char(1),
	birthday DATE,
	photo_id BIGINT unsigned null,
	hometown VARCHAR(100),
	created_at DATETIME default NOW()
);
	
alter table profiles
	add constraint fk_user_id
	foreign key (user_id) references users(id)
	on update cascade
	on delete restrict
;	

drop table if exists messages;
create table messages(
	id SERIAL primary key,
	from_user_id BIGINT unsigned not null,
	to_user_id BIGINT unsigned not null,
	body TEXT,
	created_at DATETIME default now(),
	
	index (from_user_id),
	index (to_user_id),
	foreign key(from_user_id) references users(id),
	foreign key(to_user_id) references users(id)
);	

drop table if exists friend_requests;
create table friend_requests(
	intiator_user_id BIGINT unsigned not null,
	target_user_id BIGINT unsigned not null,
	status ENUM('requested','approved','declined','unfriended'),
	requested_at DATETIME default now(),
	confirmed_at DATETIME,
	
	primary key(intiator_user_id, target_user_id),
	index (intiator_user_id),
	index (target_user_id),
	foreign key(intiator_user_id) references users(id),
	foreign key(target_user_id) references users(id)
);	




drop table if exists communities;
create table communities(
	id SERIAL primary key,
	name VARCHAR(150),
	
	INDEX(name)
);	

drop table if exists users_communities;
create table users_communities(
	user_id BIGINT unsigned not null,
	community_id BIGINT unsigned not null,
	
	primary key(user_id, community_id),
	foreign key(user_id) references users(id),
	foreign key(community_id) references communities(id)
);	

drop table if exists media_types;
create table media_types(
	id SERIAL primary key,
	name VARCHAR(150),
	created_at DATETIME default now()
);	
drop table if exists media;
create table media(
	id SERIAL primary key,
	media_type_id BIGINT unsigned not null,
	user_id BIGINT unsigned not null,
	body TEXT,
	filename VARCHAR(255),
	`size` int,
	metadata JSON,
	created_at DATETIME default now(),
	updated_at DATETIME default current_timestamp on update current_timestamp,
	
	index(user_id),
	foreign key(user_id) references users(id),
	foreign key(media_type_id) references media_types(id)
);

drop table if exists likes;
create table likes(
	id SERIAL primary key,
	user_id BIGINT unsigned not null,
	media_id BIGINT unsigned not null,
	created_at DATETIME default now()
);	

drop table if exists photo_albums;
create table photo_albums(
	id SERIAL primary key,
	name VARCHAR(150),
	user_id BIGINT unsigned not null,
	
	foreign key (user_id) references users(id)
);

drop table if exists photos;
create table photos(
	id SERIAL primary key,
	album_id BIGINT unsigned not null,
	media_id BIGINT unsigned not null,
	
	foreign key (album_id) references photo_albums(id),
	foreign key (media_id) references media(id)
);

- город и фото пользователя
select
	firstname,
	lastname,
	(select hometown from profiles as p where user_id = 10) as 'city',
	(select filename from media where id = 
		(select photo_id from profiles where user_id = 1)
	)	as 'main_photo'	
from users
where id = 10;


select *
from media_types as mt 
where name = 'cum';


-- фотография пользователя

desc media;
select filename
from media 
where user_id = 1
	and media_type_id = 1


select filename
from media 
where user_id = (select id from users where email = "myra.hudson@example.net")
	and media_type_id = (select id from media_types as mt where name = 3)
	
	
select filename
from media as m
where user_id = 1
	and media_type_id = (select id from media_types as mt where name = 'voluptas')
	
select count(*) as 'cums'
from media as m
where media_type_id = (select id from media_types as mt where name = 'cum')	

-- новости какого-либо пользователя
select filename
from media as m
where (filename like '%.mp4'or filename like '%.avi')
;


-- архив новостей по месяцам
select 
	monthname(created_at) as month_name,
	count(*) as cnt,
from media as m
group by month_name
order by
	-- month(created_at);
	cnt desc
-- limit 1	
;	

-- сколько новостей у каждого пользователя?
select 
	count(*) as cnt,
	user_id
from media
-- where user_id = 1
group by user_id
having user_id = 1
   -- cnt > 1

-- выбираем друзей пользователя
select*
from friend_requests as fr
where 
	(intiator_user_id = 8 or target_user_id = 8)
	and status ='approved'

	-- новости мои и друзей
select*
from media
where user_id = 1
	union
select*
from media as m
where user_id in (
	select intiator_user_id from friend_requests as fr where target_user_id = 4 and status = 'approved'
	
	union 
	
	select target_user_id  from friend_requests as fr where  intiator_user_id = 4 and status = 'approved'
	)
	
order by created_at 
limit 10 offset 0

-- лайки
select 
	media_id,
	count(*)
from likes as l
where media_id in (
	select id from media where user_id = 1

)
group by media_id


-- выбираем сообщения от пользователя и к пользователю
select*
from messages as m
where from_user_id = 1
	or to_user_id = 1
order by created_at desc 

alter table messages 
add column is_read BOOL default false;


select*
from messages as m
where to_user_id = 1
	and is_read = 0
order by created_at desc

update messages set is_read = 1
where created_at <date_sub(now(),interval 100 day)
	and to_user_id = 1


-- выводим друзей пользователя с преобразованием пола и возраста
	
select 
	user_id,
	case (gender)
		when 'D' then 'male'
		when 'M' then 'female'
		else 'P'
	end	as gender,
	TIMESTAMPDIFF(year,birthday,now()) as age
from profiles as p
where user_id in (
select intiator_user_id from friend_requests as fr where target_user_id = 4 and status = 'approved'
	union 
	select target_user_id  from friend_requests as fr where  intiator_user_id = 4 and status = 'approved'
	)
	
update communities 
set admin_user_id = 2
where id = 1;

-- является ли пользователь админом группы?
select 1 = (
	select admin_user_id
	from communities as c
	where id = 5
) as 'is admin'

-- Пусть задан некоторый пользователь. Из всех друзей этого пользователя найдите человека,
-- который больше всех общался с нашим пользователем.
select count(*) as count_of_messages
from messages as m
where from_user_id = 5
group by to_user_id 
order by count_of_messages desc
limit 1;


select
	count(*) as count_of_messages,
	from_user_id,
	to_user_id	
from messages as m	
group by to_user_id 
order by count_of_messages desc
limit 10;

--  Подсчитать общее количество лайков, которые получили пользователи младше 10 лет..

select
	count(*)
	media_id,
	TIMESTAMPDIFF(year,birthday,now()) as age
from likes as l
group by media_id;
having age < 10;

group by media_id


select 
	user_id,
	case (gender)
		when 'D' then 'male'
		when 'M' then 'female'
		else 'P'
	end	as gender,
	TIMESTAMPDIFF(year,birthday,now()) as age
from profiles as p
where user_id in (
select intiator_user_id from friend_requests as fr where target_user_id = 4 and status = 'approved'
	union 
	select target_user_id  from friend_requests as fr where  intiator_user_id = 4 and status = 'approved'
	)

-- Определить кто больше поставил лайков (всего) - мужчины или женщины?
	
select 
	count(*)
	user_id,
	case (gender)
		when 'D' then 'male'
		when 'M' then 'female'
		else 'P'
	end	as gender;	
	
