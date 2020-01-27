/*
User Defined Variables:

@source_spc - The SERV_PROV_CODE of the source agency to clone
@target_spc - The SERV_PROV_CODE of the agency you want to create from the cloned data

**/

DECLARE @source_spc varchar(15), @target_spc varchar(15), @table varchar(50), @sqltext varchar(max);

-- Disable contraints
EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"

SET @source_spc = 'DEV';
SET @target_spc = 'CRC2';

-- initial checks
if(select count(*) from RSERV_PROV where SERV_PROV_CODE = @target_spc) > 0
throw 500001, 'Target agency already exists! Pick a different agency', 1;

if(select count(*) from RSERV_PROV where SERV_PROV_CODE = @source_spc) < 1
throw 500001, 'Source agency does not exist! Pick a different agency', 2;

if exists (select name from sys.tables where name = 'AA_TAB_COUNT') 
begin
drop table AA_TAB_COUNT
end

create table AA_TAB_COUNT (TABLE_NAME varchar(32), ROW_COUNT int, SERV_PROV_CODE varchar(15));

-- Get row counts
print('Generating row count data');
print('===========================================================================================');

DECLARE cur CURSOR for 
SELECT t.name AS 'TableName'
FROM sys.columns c
inner join sys.tables t on c.object_id = t.object_id
inner join AA_DATA_DIC ad on t.name = ad.TABLE_NAME
WHERE c.name = 'SERV_PROV_CODE' and c.name <> 'AA_TAB_COUNT';

open cur

fetch next from cur into @table

while @@FETCH_STATUS = 0
begin

SET @sqltext = 'insert into aa_tab_count select ''' + @table + ''', count(*), ''' + @source_spc + ''' from ' + @table + ' where serv_prov_code = ''' + @source_spc + '''';
print @sqltext;
exec(@sqltext);

fetch next from cur into @table
end
close cur
deallocate cur

-- generate create table sql script 
print('Creating staging tables');
print('===========================================================================================');

DECLARE cur CURSOR for 
SELECT TABLE_NAME from AA_TAB_COUNT
where TABLE_NAME NOT IN (SELECT TABLE_NAME FROM AA_DATA_DIC WHERE COLUMN_NAME='SOURCE_SEQ_NBR')
and table_name not in ('ESSO_SESSIONS','ESSO_LOG','GEVENTLOG','REVT_LOG','GEVENTLOG_DETAIL','LOGIN_INFO')
and table_name in (select table_name from aa_tab_count where SERV_PROV_CODE=@source_spc AND ROW_COUNT > 0)
and table_name not like 'GAUDIT%';
open cur

fetch next from cur into @table

while @@FETCH_STATUS = 0
begin

if exists (select * from sys.tables where name = @target_spc + '_' + @table)
begin
SET @sqltext = 'drop table ' + @target_spc + '_' + @table
exec(@sqltext)
end

SET @sqltext = 'select * into ' + @target_spc + '_' + @table + ' from ' + @table + ' where serv_prov_code=''' + @source_spc + '''';
print @sqltext;
exec(@sqltext);

fetch next from cur into @table

end
close cur
deallocate cur

-- remove tracking number from B1PERMIT
print('Removing B1PERMIT.B1_TRACKING_NBR');
print('===========================================================================================');
SET @sqltext= 'update ' + @target_spc + '_B1PERMIT set B1_TRACKING_NBR = NULL where serv_prov_code=''' + @target_spc + '''';
exec(@sqltext)

-- generate update data script 
print('Updating staging data');
print('===========================================================================================');

DECLARE cur CURSOR for 
SELECT TABLE_NAME from AA_TAB_COUNT
where TABLE_NAME NOT IN (SELECT TABLE_NAME FROM AA_DATA_DIC WHERE COLUMN_NAME='SOURCE_SEQ_NBR')
and table_name not in ('ESSO_SESSIONS','ESSO_LOG','GEVENTLOG','REVT_LOG','GEVENTLOG_DETAIL','LOGIN_INFO')
and table_name in (select table_name from aa_tab_count where SERV_PROV_CODE=@source_spc AND ROW_COUNT > 0)
and table_name not like 'GAUDIT%';
open cur

fetch next from cur into @table

while @@FETCH_STATUS = 0
begin


SET @sqltext = 'update ' + @target_spc + '_' + @table + ' set serv_prov_code= ''' + @target_spc + ''' where serv_prov_code=''' + @source_spc + '''';
print @sqltext;
exec(@sqltext);

fetch next from cur into @table
end
close cur
deallocate cur

-- generate copy data script 
print('Copying data');
print('===========================================================================================');

DECLARE cur CURSOR for 
SELECT TABLE_NAME from AA_TAB_COUNT
where TABLE_NAME NOT IN (SELECT TABLE_NAME FROM AA_DATA_DIC WHERE COLUMN_NAME='SOURCE_SEQ_NBR')
and table_name not in ('ESSO_SESSIONS','ESSO_LOG','GEVENTLOG','REVT_LOG','GEVENTLOG_DETAIL','LOGIN_INFO','AA_TAB_COUNT')
and table_name in (select table_name from aa_tab_count where SERV_PROV_CODE=@source_spc AND ROW_COUNT > 0)
and table_name not like 'GAUDIT%';
open cur

fetch next from cur into @table

while @@FETCH_STATUS = 0
begin


SET @sqltext = 'insert into ' + @table + ' select * from ' + @target_spc + '_' + @table + ' where serv_prov_code=''' + @target_spc + '''';
print @sqltext;
exec(@sqltext);

fetch next from cur into @table
end
close cur
deallocate cur

-- handle special cases
print('Handling special cases');
print('===========================================================================================');

update GFILTER_LEVEL SET LEVEL_NAME=SERV_PROV_CODE
where filter_level_type='AGENCY' and LEVEL_NAME !=SERV_PROV_CODE and serv_prov_code=@target_spc;

update GFILTER_LEVEL SET LEVEL_NAME=REPLACE(LEVEL_NAME,SUBSTRING(LEVEL_NAME,1,CHARINDEX(LEVEL_NAME,'$')-1),@target_spc)
where filter_level_type='USER' and LEVEL_NAME LIKE '%$%' and serv_prov_code=@target_spc;

update GFILTER_VIEW SET FILTER_NAME=REPLACE(FILTER_NAME,SUBSTRING(FILTER_NAME,1,CHARINDEX(FILTER_NAME,'$')-1),@target_spc)
where FILTER_NAME LIKE '%$%' and serv_prov_code=@target_spc;

update GFILTER_SCREEN SET SCREEN_NAME=REPLACE(SCREEN_NAME,@source_spc,@target_spc)
where serv_prov_code=@target_spc AND SCREEN_NAME like '%'+@source_spc+'%';

update GFILTER_SCREEN SET SCREEN_LABEL=REPLACE(SCREEN_LABEL,@source_spc,@target_spc)
where serv_prov_code=@target_spc AND SCREEN_LABEL like '%'+@source_spc+'%';

update GFILTER_SCREEN_PERMISSION SET PERMISSION_VALUE=SERV_PROV_CODE
where permission_level='AGENCY' AND serv_Prov_code NOT IN ('STANDARDDATA','ADMIN')
and PERMISSION_VALUE !=SERV_PROV_CODE;

update jconsolereceipt set console_receipt_key=serv_prov_code
where CONSOLE_RECEIPT_TYPE='agency' and CONSOLE_RECEIPT_KEY !=serv_prov_code and serv_prov_code=@target_spc;

update gflow_dgrm_rcpt set recipient_key=serv_prov_code
where recipient_type='agency' and recipient_key !=serv_prov_code and serv_prov_code=@target_spc;

update gui_text_level set text_level_name=serv_prov_code
where upper(text_level_typ)='AGENCY' and text_level_name !=serv_prov_code and serv_prov_code=@target_spc;

update xpolicy set level_DATA=serv_prov_code
where upper(level_type)='AGENCY' and level_data =@source_spc and serv_prov_code=@target_spc;

update xpolicy set DATA1=serv_prov_code
where upper(DATA1) =@source_spc and serv_prov_code=@target_spc;

update xalert_recipient set alert_recipient_key=serv_prov_code
where alert_recipient_type='agency' and alert_recipient_key !=serv_prov_code and serv_prov_code=@target_spc;

update xdispalert_recipient set alert_recipient_key=serv_prov_code
where alert_recipient_type='agency' and alert_recipient_key !=serv_prov_code and serv_prov_code=@target_spc;

update XSET_TYPE_RECIPIENT set recipient_key=serv_prov_code
where UPPER(recipient_type)='AGENCY' and recipient_key !=serv_prov_code and serv_prov_code=@target_spc;

update gmessage set MSG_DEPT= replace(MSG_DEPT,@source_spc,@target_spc)   
WHERE SERV_PROV_CODE=@target_spc AND MSG_DEPT like '%'+@source_spc+'%';

update gmessage set MESSAGE_TEXT= replace(MESSAGE_TEXT,@source_spc,@target_spc)   
WHERE SERV_PROV_CODE=@target_spc AND MESSAGE_TEXT like '%'+@source_spc+'%';

update xmessage_recipient set recipient_key=serv_prov_code
where recipient_type='agency' and recipient_key !=serv_prov_code and serv_prov_code=@target_spc;

UPDATE G3DPTTYP SET R3_DEPT_KEY=REPLACE(R3_DEPT_KEY,SUBSTRING(R3_DEPT_KEY,1,CHARINDEX(R3_DEPT_KEY,'/')-1),@target_spc)
WHERE serv_prov_code=@target_spc AND R3_DEPT_KEY NOT LIKE @target_spc+'%';

update rpt_query set freehand_sql_text= replace(freehand_sql_text,@source_spc,@target_spc)   
WHERE SERV_PROV_CODE=@target_spc AND freehand_sql_text like '%'+@source_spc+'%';

update mrulist set entity_id=replace(entity_id,@source_spc,@target_spc)
where SERV_PROV_CODE=@target_spc and entity_id like '%'+@source_spc+'%';

UPDATE RSERV_PROV SET PARENT_SERV_PROV_CODE=''
WHERE serv_prov_code=@target_spc;

UPDATE XUSER_DELEGATE SET PARENT_SERV_PROV_CODE =SERV_PROV_CODE
WHERE serv_prov_code=@target_spc;

UPDATE XPUBLIC_USER_PROV_LIC SET PA_SERV_PROV_CODE=SERV_PROV_CODE
WHERE serv_prov_code=@target_spc;

UPDATE  XCOLLECTION_BPERMIT SET CAP_SERV_PROV_CODE=SERV_PROV_CODE
WHERE serv_prov_code=@target_spc;

update workflow_metadata set METADATA_DEFINITION=replace(METADATA_DEFINITION,@source_spc,@target_spc)
where SERV_PROV_CODE=@target_spc;

UPDATE rbizdomain_value set value_desc=replace(value_desc,@source_spc,@target_spc)
where SERV_PROV_CODE=@target_spc AND VALUE_DESC LIKE '%'+@source_spc+'%';

UPDATE rbizdomain_value set value_desc=replace(value_desc,@source_spc,@target_spc)
where SERV_PROV_CODE=@target_spc AND VALUE_DESC LIKE '%'+@source_spc+'%';

update revt_agency_script set script_text = replace(script_text,@source_spc,@target_spc)
where script_text like '%'+@source_spc+'%' and serv_prov_code like @target_spc;

update GUI_TEXT_LEVEL set TEXT_LEVEL_NAME = replace(TEXT_LEVEL_NAME,@source_spc,@target_spc)
where TEXT_LEVEL_NAME like '%'+@source_spc+'%' and serv_prov_code like @target_spc;

update PUSER_PROFILE set PROFILE_VALUE= replace(PROFILE_VALUE,@source_spc,@target_spc)   
WHERE SERV_PROV_CODE=@target_spc AND PROFILE_VALUE like '%'+@source_spc+'%';

UPDATE xapp2ref set MASTER_SERV_PROV_CODE=serv_prov_code
where MASTER_SERV_PROV_CODE !=serv_prov_code and serv_prov_code=@target_spc;

UPDATE BDOCUMENT SET REF_SERV_PROV_CODE =''
WHERE serv_prov_code=@target_spc;


-- handle adhoc
print('Handling adhoc reports');
print('===========================================================================================');

--drop table radhoc_reports;
SET @sqltext='select * into ' + @target_spc+'_'+'radhoc_reports from radhoc_reports where tenantid = ''' + @source_spc + '''';
print(@sqltext);
exec(@sqltext);
SET @sqltext='update ' + @target_spc+'_radhoc_reports set tenantid='''+@target_spc+''''+', xml=replace(xml,'''+@source_spc+''','''+@target_spc+''')';
print(@sqltext);
exec(@sqltext);
SET @sqltext='insert into radhoc_reports select * from ' + @target_spc + '_radhoc_reports';
print(@sqltext);
exec(@sqltext);

-- handle special table XPUBLICUSER_PEOPLE
print('Handling public users');
print('===========================================================================================');

SET @sqltext='select * into ' + @target_spc+'_XPUBLICUSER_PEOPLE from XPUBLICUSER_PEOPLE where agency = ''' + @source_spc + '''';
print(@sqltext);
exec(@sqltext);
SET @sqltext='update ' + @target_spc+'_XPUBLICUSER_PEOPLE set agency='''+@target_spc+'''';
print(@sqltext);
exec(@sqltext);
SET @sqltext='insert into XPUBLICUSER_PEOPLE select * from ' + @target_spc + '_XPUBLICUSER_PEOPLE';
print(@sqltext);
exec(@sqltext);

-- handle special table XPUBLICUSER_PEOPLE
print('Handling rserv_prov');
print('===========================================================================================');

SET @sqltext='update rserv_prov set name2 = ''' + @target_spc + ''' where serv_prov_code = ''' + @target_spc + '''';
print(@sqltext);
exec(@sqltext);

-- handle licensing

print('Removing extra license details');
print('===========================================================================================');
delete from XPOLICY where policy_name = 'LoginPolicy' and level_type = 'Licensing' and LEVEL_DATA = 'Licensing' and SERV_PROV_CODE = @target_spc


-- set admin password to 'admin'
print('Resetting admin password');
print('===========================================================================================');

UPDATE PUSER SET PASSWORD='d033e22ae348aeb5660fc2140aec35850c4da997'
where serv_prov_code=@target_spc and user_name='ADMIN' ;

print('Updating user profiles');
print('===========================================================================================');

update PUSER_PROFILE set PROFILE_VALUE= replace(PROFILE_VALUE,@source_spc,@target_spc)   
WHERE SERV_PROV_CODE=@target_spc AND PROFILE_VALUE like '%'+@source_spc+'%';


-- jetspeed_user_profile
print('jetspeed_user_profile');
print('===========================================================================================');

declare @PSML_ID int, @USER_NAME varchar(max), @MEDIA_TYPE varchar(max), @LANGUAGE varchar(max), @COUNTRY varchar(max), @PAGE varchar(max), @PROFILE varbinary

DECLARE cur cursor for
select PSML_ID,USER_NAME,MEDIA_TYPE,LANGUAGE,COUNTRY,PAGE,PROFILE 
	from jetspeed_user_profile
		where user_name like @source_spc+'.%';

open cur
while @@FETCH_STATUS = 0
begin
	insert into jetspeed_user_profile values
	(REPLACE(@USER_NAME,@source_spc+'.',@target_spc+'.'),
	@MEDIA_TYPE,@LANGUAGE,@COUNTRY,@PAGE,@PROFILE);

fetch next from cur into @PSML_ID,@USER_NAME,@MEDIA_TYPE,@LANGUAGE,@COUNTRY,@PAGE,@PROFILE

end;

close cur;
deallocate cur;

--turbine_user
print('turbine_user');
print('===========================================================================================');

declare @USER_ID int, @LOGIN_NAME varchar(max), @PASSWORD_VALUE varchar(max), @FIRST_NAME varchar(max), @LAST_NAME varchar(max), @EMAIL varchar(max), @CONFIRM_VALUE varchar(max), 
@MODIFIED datetime,@CREATED datetime, @LAST_LOGIN datetime, @DISABLED char, @OBJECTDATA binary, @PASSWORD_CHANGED datetime

DECLARE cur1 cursor for
select USER_ID,LOGIN_NAME,PASSWORD_VALUE,FIRST_NAME,LAST_NAME,EMAIL,CONFIRM_VALUE,MODIFIED,CREATED,LAST_LOGIN,DISABLED,OBJECTDATA,PASSWORD_CHANGED 
	from turbine_user
		where login_name like @source_spc+'.%CONSOLE';

open cur1

fetch next from cur1 into @USER_ID,@LOGIN_NAME,@PASSWORD_VALUE,@FIRST_NAME,@LAST_NAME,@EMAIL,@CONFIRM_VALUE,@MODIFIED,@CREATED,@LAST_LOGIN,@DISABLED,@OBJECTDATA,@PASSWORD_CHANGED

while @@FETCH_STATUS = 0
begin
	insert into turbine_user values
	(REPLACE(@LOGIN_NAME,@source_spc,@target_spc),@PASSWORD_VALUE,@FIRST_NAME,@LAST_NAME,@EMAIL,
	@CONFIRM_VALUE,@MODIFIED,@CREATED,@LAST_LOGIN,@DISABLED,@OBJECTDATA,@PASSWORD_CHANGED);

fetch next from cur1 into @USER_ID,@LOGIN_NAME,@PASSWORD_VALUE,@FIRST_NAME,@LAST_NAME,@EMAIL,@CONFIRM_VALUE,@MODIFIED,@CREATED,@LAST_LOGIN,@DISABLED,@OBJECTDATA,@PASSWORD_CHANGED
end;

close cur1
deallocate cur1;

-- generate drop staging tables script 
print('Dropping staging tables');
print('===========================================================================================');

DECLARE cur CURSOR for 
SELECT name from sys.tables where name like @target_spc + '_%'
and name not in (select TABLE_NAME from AA_DATA_DIC)
open cur

fetch next from cur into @table

while @@FETCH_STATUS = 0
begin


SET @sqltext = 'drop table ' + @table;
print @sqltext;
exec(@sqltext);

fetch next from cur into @table
end
close cur
deallocate cur

EXEC sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all";
