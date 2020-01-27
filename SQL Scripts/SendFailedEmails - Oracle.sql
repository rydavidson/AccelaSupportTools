--Get the last rtask_queue sequence number
select last_number + 1 from aa_sys_seq where sequence_name = 'RTASK_QUEUE_SEQ';

--Create a sequence for use later, starting with the result of the previous query
-- Update the 'start with 1' to use the last result
create sequence rtask_queue_seq start with 1 increment by 1;

--Find base count of messages. Adjust sysdate-4 for the number of days to go back:
select count(*) from G7CM_MESSAGE where trunc(rec_date) >trunc(sysdate-4) and message_status='FAILED';

--Insert first 500
insert into rtask_queue ( ENTITY_ID ,    ENTITY_TYPE ,    EXECUTE_TIME ,    RES_ID ,    SERV_PROV_CODE ,    STATUS ,    TASK_NAME ,    REC_DATE ,    REC_FUL_NAM ,    REC_STATUS )
select res_id, 'EMAIL', sysdate, rtask_queue_seq.nextval, serv_prov_code, 'Hold', 'send_communication', sysdate, rec_ful_nam, 'A' from 
G7CM_MESSAGE where trunc(rec_date) >trunc(sysdate-4) and message_status='FAILED' and rownum < 501;

commit;
--Wait for count from step 1 to fully drop by 500
select count(*) from G7CM_MESSAGE where trunc(rec_date) >trunc(sysdate-4) and message_status='FAILED';

--Rinse, wash, repeat until the count is 0

--Update the AA_SYS_SEQ table with the last number value
update aa_sys_seq set last_number=rtask_queue_seq.nextval where sequence_name='RTASK_QUEUE_SEQ';
commit;

--Drop the helper sequence
drop sequence rtask_queue_seq;