
-- SESSION 14 - MYSQL TRANSACTION
-- Sinh viên: Ngọc
-- ===============================

-- BÀI 1
create database if not exists social_app_ngoc;
use social_app_ngoc;

create table users(
	user_id int primary key auto_increment,
    username varchar(50) not null,
    posts_count int default 0,
    following_count int default 0,
    followers_count int default 0,
    friends_count int default 0
);

create table posts(
	post_id int primary key auto_increment,
    user_id int not null,
    content text,
    created_at datetime default current_timestamp,
    likes_count int default 0,
    comments_count int default 0,
    foreign key(user_id) references users(user_id)
);

insert into users(username) values ('ngocdev'), ('minhdev');

-- Transaction thành công
start transaction;
insert into posts(user_id, content) values (1, 'Học transaction MySQL');
update users set posts_count = posts_count + 1 where user_id = 1;
commit;

-- Transaction lỗi
start transaction;
insert into posts(user_id, content) values (1, 'Rollback demo');
update users set posts_count = posts_count + 1 where user_id = 99;
rollback;

-- BÀI 2
create table likes(
	like_id int primary key auto_increment,
    post_id int not null,
    user_id int not null,
    foreign key(post_id) references posts(post_id),
    foreign key(user_id) references users(user_id)
);

start transaction;
insert into likes(user_id, post_id) values (1,1);
update posts set likes_count = likes_count + 1 where post_id = 1;
commit;

-- BÀI 3
create table followers(
	follower_id int,
    followed_id int,
    primary key(follower_id, followed_id),
    foreign key(follower_id) references users(user_id),
    foreign key(followed_id) references users(user_id)
);

delimiter $$
create procedure sp_follow_user_ngoc(p_from int, p_to int)
begin
	start transaction;
	insert into followers values(p_from, p_to);
	update users set following_count = following_count + 1 where user_id = p_from;
	update users set followers_count = followers_count + 1 where user_id = p_to;
	commit;
end $$
delimiter ;

-- BÀI 4
create table comments(
	comment_id int primary key auto_increment,
    post_id int,
    user_id int,
    content text,
    created_at datetime default now(),
    foreign key(post_id) references posts(post_id),
    foreign key(user_id) references users(user_id)
);

delimiter $$
create procedure sp_add_comment_ngoc(p_post int, p_user int, p_content text, p_error int)
begin
	start transaction;
	insert into comments(post_id, user_id, content) values(p_post, p_user, p_content);
	savepoint s1;
	if p_error = 1 then
		update posts set comments_count = comments_count + 1 where post_id = 999;
		rollback to s1;
	else
		update posts set comments_count = comments_count + 1 where post_id = p_post;
	end if;
	commit;
end $$
delimiter ;

-- BÀI 5
create table delete_logs(
	log_id int primary key auto_increment,
    post_id int,
    deleted_by int,
    deleted_at datetime
);

delimiter $$
create procedure sp_remove_post_ngoc(p_post int, p_user int)
begin
	start transaction;
	delete from likes where post_id = p_post;
	delete from comments where post_id = p_post;
	delete from posts where post_id = p_post;
	update users set posts_count = posts_count - 1 where user_id = p_user;
	insert into delete_logs values(null, p_post, p_user, now());
	commit;
end $$
delimiter ;

-- BÀI 6
create table friend_requests(
	request_id int primary key auto_increment,
    from_user int,
    to_user int,
    status enum('pending','accepted','rejected') default 'pending'
);

create table friends(
	user_id int,
    friend_id int,
    primary key(user_id, friend_id)
);

delimiter $$
create procedure sp_accept_friend_ngoc(p_request int, p_user int)
begin
	declare u_from int;
	start transaction;
	select from_user into u_from from friend_requests where request_id = p_request;
	insert into friends values(u_from, p_user);
	insert into friends values(p_user, u_from);
	update users set friends_count = friends_count + 1 where user_id in (u_from, p_user);
	update friend_requests set status = 'accepted' where request_id = p_request;
	commit;
end $$
delimiter ;
