set scan off
set serveroutput on
set escape off
whenever sqlerror exit
DECLARE
    h1 number;
    errorvarchar varchar2(100):= 'ERROR';
    tryGetStatus number := 0;
begin
    h1 := dbms_datapump.open (operation => 'IMPORT', job_mode => 'FULL', job_name => 'IMPORT_CONCORD_AA2', version => 'COMPATIBLE');
    tryGetStatus := 1;
    dbms_datapump.set_parallel(handle => h1, degree => 4);
    dbms_datapump.add_file(handle => h1, filename => 'IMPORT.LOG', directory => 'BACKUPS', filetype => 3);
    dbms_datapump.set_parameter(handle => h1, name => 'KEEP_MASTER', value => 1);
    dbms_datapump.add_file(handle => h1, filename => 'CONCORDPROD.dpdmp', directory => 'BACKUPS', filetype => 1);
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'AAREF_DATA', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'AAREF_INDEX', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'AATRAN_DATA', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'AATRAN_INDEX', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'AAUSERS', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'ACCELA_DATA', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'BCHCKBOX_DATA', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'BCHCKBOX_IDX_BIG', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'CONTROL_DATA', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'CONTROL_INDEX', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'F4FEE_DATA', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'F4FEE_INDEX', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'FEE_AUDIT_DATA', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'FEE_AUDIT_INDEX', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'G6ACTION_DATA', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'GPROCESS_DATA_BIG', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'USERS', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'USERS1', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'G6ACT_DATA', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'G6ACTION_INDEX', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'CURRENT_PERMITS', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'GPROCESS_DATA', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'GPROCESS_HIST_DATA', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'GPROCESS_HIST_INDEX', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'GPROCESS_INDEX', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'L3APO_DATA', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'L3APO_INDEX', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'G6ACT_INDEX', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'GPROCESS_INDEX_BIG', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'CURRENT_PERMITS_INDEX', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'BAPPSVAL_INDEX', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'BCHCKBOX_INDEX', value => UPPER('DATA') );
    dbms_datapump.metadata_remap(handle => h1, name => 'REMAP_TABLESPACE', old_value => 'LOB_DATA', value => UPPER('DATA') );
    dbms_datapump.set_parameter(handle => h1, name => 'INCLUDE_METADATA', value => 1);
    dbms_datapump.set_parameter(handle => h1, name => 'DATA_ACCESS_METHOD', value => 'AUTOMATIC');
    dbms_datapump.set_parameter(handle => h1, name => 'REUSE_DATAFILES', value => 1);
    dbms_datapump.set_parameter(handle => h1, name => 'TABLE_EXISTS_ACTION', value => 'REPLACE');
    dbms_datapump.set_parameter(handle => h1, name => 'SKIP_UNUSABLE_INDEXES', value => 1);
    dbms_datapump.start_job(handle => h1, skip_current => 0, abort_step => 0);
    dbms_datapump.detach(handle => h1);
    errorvarchar := 'NO_ERROR';
EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        IF ((errorvarchar = 'ERROR')AND(tryGetStatus=1)) THEN
            DBMS_DATAPUMP.DETACH(h1);
        END IF;
    EXCEPTION
    WHEN OTHERS THEN
        NULL;
    END;
    RAISE;
END;
/
