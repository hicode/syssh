-- 监测是否有未设定type的领域
select * from project_label where label_name in ('公司','房产建筑','劳动人事','涉外','韩日','知识产权','婚姻家庭','诉讼','刑事行政') and type is null;

-- 监测是否有未设定领域的案件
select * from project where type='cases' and id not in (select project from project_label where type = '领域');

-- 根据业务领域确定案件小组
update 
project 
inner join project_label on project_label.project=project.id and project_label.type = '领域' 
inner join team on team.name = project_label.label_name
set project.team=team.id;

-- 根据业务领域确定帐目小组
update 
account 
inner join project on project.id=account.project
set account.team=project.team;

-- 检测没有案源类型的案件
select * from project where type = 'cases' 
	and id not in (select project from project_label where label_name in ('所内案源','个人案源'));

-- 所内案源都有接洽律师
select * from project where type='cases'
and id in (select project from project_label where label_name = '所内案源')
and id not in (select project from project_people where role = '接洽律师')

-- 校验并纠正item-label.label_name冗余
update account_label inner join label on account_label.label = label.id set account_label.label_name = label.name;
update people_label inner join label on people_label.label = label.id set people_label.label_name = label.name;
update project_label inner join label on project_label.label = label.id set project_label.label_name = label.name;
update document_label inner join label on document_label.label = label.id set document_label.label_name = label.name;
update schedule_label inner join label on schedule_label.label = label.id set schedule_label.label_name = label.name;

-- 确定个人案源的案源总和
select project,sum(weight) sum from project_people where role = '案源人'
and project in (select project from project_label where label_name='个人案源')
group by project having sum > 1

-- 确定所内案源接洽总和
select project,sum(weight) sum from project_people where role = '接洽律师'
and project in (select project from project_label where label_name='所内案源')
group by project having sum != 1

-- 确认已申请归档案件的实际贡献总额
select project.id,project.name,sum(weight) sum from
project left join project_people on project.id = project_people.project and project_people.role = '实际贡献'
where project.active=1 
and project.id in (select project from project_label where label_name='已申请归档')
	and project.id not in (select project from project_label where label_name='案卷已归档')
group by project.id having sum != 1 or sum is null;

-- 协办律师没有比例
select * from project_people where weight is not null and role = '协办律师';

-- 确定办案总和
select project,sum(weight) sum from project_people where role = '主办律师'
group by project having sum != 1

-- 清除添加失败的project
delete from project_people where project in (select id from project where display = 0 and name is null);
delete from project where display = 0 and name is null;

-- 删除错误的标签
delete from people_label where label in (select id from label where name = '');
delete from project_label where label in (select id from label where name = '');
delete from document_label where label in (select id from label where name = '');
delete from label where name = '';

delete from people_label where label_name ='null';
delete from document_label where label_name ='null';
delete from label where name = 'null';

-- 对于没有督办人的案件设置默认督办人
insert ignore into project_people (project,people,role)
select id,6356,'督办人' from project where type = 'cases';

-- 统计所内案源创收
select amount,project.name,group_concat(people.name)
from account 
inner join project on project.id = account.project 
inner join project_label on project_label.project=account.project and project_label.label_name = '所内案源'
inner join project_people on project_people.project = account.project
inner join people on people.id = project_people.people
where account.date between '2013-01-01' and '2013-06-30' and received = 1
group by account.id
order by amount desc;

-- 将人员资料项中的电话更新到人员基本字段
update people inner join people_profile on people_profile.people=people.id and people_profile.name in ('电话','手机','固定电话')
set people.phone = people_profile.content
where people.phone is null;
update people inner join people_profile on people_profile.people=people.id and people_profile.name in ('电子邮件')
set people.email = people_profile.content
where people.email is null;

-- 人员信息导出
select
people.name `姓名`,
school.content `初中`,
phone `电话`,
address.content `地址`,
score1.content `语文`,
score2.content `数学`,
score3.content `英语`,
score4.content `理化`,
locale.content `户籍`
from
people 
left join people_profile school on school.name = '就读初中' and school.people=people.id
left join people_profile address on address.name = '联系地址' and address.people=people.id
left join people_profile score1 on score1.name = '区质管考语文成绩' and score1.people=people.id
left join people_profile score2 on score2.name = '区质管考数学成绩' and score2.people=people.id
left join people_profile score3 on score3.name = '区质管考英语成绩' and score3.people=people.id
left join people_profile score4 on score4.name = '区质管考理化成绩' and score4.people=people.id
left join people_profile locale on locale.name = '户籍情况' and locale.people=people.id
inner join people_label on people.id = people_label.people and people_label.label_name='报名考生';

-- 含有职员的组也是职员
insert ignore into staff (id)
select people from people_relationship
where people in (select id from team)
and relative in (select id from staff);

-- 含有用户的组也是用户
insert ignore into user (id)
select people from people_relationship
where people in (select id from team)
and relative in (select id from user);

-- 用户组下的人员都是用户
insert ignore into user (id,name,company)
select id,name,company from people where id in(
	select relative from people_relationship where people in (select id from user) and people in (select id from team) and relative not in (select id from user)
);

-- 根据人员名更新空的组名和用户名
update user inner join people using (id) set user.name = people.name where user.name is null;
update team inner join people using (id) set team.name = people.name where team.name is null;

-- 给项目成员以项目文件的读权限
insert ignore into document_mod (document,people,`mod`)
select document,people,1
from project_document inner join project_people using (project)
where project_people.people in (select id from staff);

-- 更新学生学号
update people
inner join people_relationship class_student ON class_student.relative = people.id AND class_student.till>=CURDATE()
inner join team ON team.id = class_student.people
inner join people people_team ON people_team.id = class_student.people
SET people.num = RIGHT((1000000 + CONCAT(people_team.num, RIGHT((100 + class_student.num),2))),6)
where people.type = 'student';

-- 到账贡献明细
create temporary table account_detail
select project.name project_name,account.date account_date,people.id people, people.name people_name,
account.amount,project_people.role,project_people.weight
from account inner join project on project.id=account.project
inner join project_people on project_people.project=account.project and role = '主办律师'
inner join people on people.id = project_people.people
where account.date between '2013-01-01' and '2013-06-30'
and account.received=1;

create temporary table account_detail_grouped
select people,people_name,role,
SUM(amount * weight) contribute
from account_detail
group by people;

select *,
ROUND(IF(contribute-1000000>0,contribute-1000000,0)*0.4
+IF(IF(contribute>1000000,1000000,contribute)-500000>0,IF(contribute>1000000,1000000,contribute)-500000,0)*0.35
+IF(IF(contribute>500000,500000,contribute)-300000>0,IF(contribute>500000,500000,contribute)-300000,0)*0.25
+IF(IF(contribute>300000,500000,contribute)-100000>0,IF(contribute>300000,300000,contribute)-100000,0)*0.15
,2) bonus
from account_detail_grouped;

-- 删除孤立消息
create temporary table t
select id from message_user m
where message not in (select message from dialog_message where dialog in (select dialog from dialog_user where user = m.user))
and m.read = 0;

delete from message_user where id  in (select id from t);

-- 给星瀚每个用户加一个系统对话
insert into dialog(company,users,uid,time)
select 1,1,id,unix_timestamp() from user where company = 1;

insert into dialog_user(dialog,user,title)
select id,uid,'系统' from dialog where company = 1 and users = 1;

-- 根据符合条件的案件创建一组消息
insert into message (content,time)
select concat('您主办的案件 <a href="#cases/',project.id,'">',project.name,'</a> 已申请归档，但实际贡献尚未输入，请核实，否则将影响结案奖金发放，谢谢配合'),unix_timestamp() -- ,project_people.people
from
project
where
project.id in (select project from project_label where label_name = '已申请归档')
and (select sum(weight) from project_people where project = project.id and role = '实际贡献') != 1

-- 向每个主办律师推送消息
create temporary table t
select 
message.id message
,project_people.people user
from
project
inner join project_people on project_people.project = project.id and role='主办律师'
inner join message on content = concat('您主办的案件 <a href="#cases/',project.id,'">',project.name,'</a> 已申请归档，但实际贡献尚未输入，请核实，否则将影响结案奖金发放，谢谢配合')
where
project.id in (select project from project_label where label_name = '已申请归档')
and (select sum(weight) from project_people where project = project.id and role = '实际贡献') != 1;

insert into message_user (message,user)
select message,user from t;

insert into dialog_message (dialog,message)
select dialog.id,t.message
from dialog inner join t on dialog.uid = t.user and dialog.users=1;

update dialog inner join t on dialog.uid = t.user and dialog.users=1 set last_message = t.message;

update project set active = 0 , end = '2013-06-30' where 
id in (select project from project_label where label_name = '通过财务审核')
and id in (select project from project_label where label_name = '通过信息审核')
and id in (select project from project_label where label_name = '通过主管审核')
and (
	id in (select project from project_label where label_name = '案卷已归档')
	OR id in (select project from project_label where label_name = '确认无实体归档')
)
and active = 1;
