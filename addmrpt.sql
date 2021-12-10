-- NAME
--   addmrpt.sql
--
-- DESCRIPTION
--   This script generates ADDM report.
--
-- SUPPORTED ORACLE VERSION
--   11g, 19c
--
-- USAGE
--   sqlplus连接数据库，运行脚本：
--   SQL> @addmrpt
--   在当前目录生成数据库ADDM报告[默认当天9:00-10:00，可修改]
--   参数定义：day=0-当天;1-昨天;2-前天;依此类推
--
--   报告名字：checkdb_hostname_instance_service_addmrpt_YYYYMMDD_StartHour-EndHour.txt
--   报告名字示例：checkdb_zzjk01_zzjk1_zzjk_addmrpt_20211210_9-10.txt
--   注，普通数据库用户需具备如下权限：
--   grant execute on DBMS_WORKLOAD_REPOSITORY to username;
--   grant select_catalog_role to username;
--   grant advisor to username;
--
-- MODIFIED (YYYY-MM-DD)
-- likingzi  2021-12-10 - Created

prompt +-----------------------------+
prompt + Oracle Database ADDM Report +
prompt +-----------------------------+

set echo off
set termout off
set trimout off
set feedback off
set heading on
set linesize 200
set pagesize 10000
set numwidth 20
alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';

-- Define rpt_name <
set termout on
prompt Specify day of report: '0' - today, '1' - yesterday, and so on [Default to '0']
set termout off
column day new_value day noprint;
-- define day=0
select nvl('&&day','0') day from dual;
select 0 day from dual where '&day' < 0 or '&day' > 7;
set termout on
prompt Using day: &day
set termout off
--
set termout on
prompt Specify startTime of report: '0 - 23' [Default to '9']
set termout off
column startTime new_value startTime;
-- define startTime=9
select nvl('&&startTime','9') startTime from dual;
select 9 startTime from dual where &startTime < 0 or &startTime > 23;
set termout on
prompt Using startTime: &startTime
set termout off
--
set termout on
prompt Specify endTime of report: '0 - 23' [Default to '10']
set termout off
column endTime new_value endTime;
-- define endTime=10
select nvl('&&endTime','10') endTime from dual;
select 10 endTime from dual where &endTime < 0 or &endTime > 23 or &endTime < &startTime + 1;
set termout on
prompt Using endTime: &endTime
set termout off
--
COLUMN min_id NEW_VALUE begin_snap NOPRINT
COLUMN max_id NEW_VALUE end_snap NOPRINT
SELECT to_char(min(snap_id)) min_id,to_char(max(snap_id)) max_id FROM dba_hist_snapshot b
WHERE b.end_interval_time BETWEEN trunc(sysdate) - &day + &startTime / 24 AND trunc(sysdate) - &day + ( &endTime + 1) / 24;
--
COLUMN service_names NEW_VALUE service_names NOPRINT
select value service_names from v$parameter where upper(name) like '%SERVICE_NAMES%';
COLUMN rpt_name NEW_VALUE rpt_name NOPRINT
SELECT 'checkdb_'||host_name||'_'||instance_name||'_'||'&service_names'||'_addmrpt_'||TO_CHAR(SYSDATE - &day,'YYYYMMDD_')||'&startTime'||'-'||'&endTime'||'.txt' rpt_name FROM v$instance;
-- Define rpt_name >

set pagesize 0;
set heading off echo off feedback off verify off;

COLUMN dbid NEW_VALUE dbid NOPRINT
SELECT dbid FROM v$database;
COLUMN instance_number NEW_VALUE instance_number NOPRINT
SELECT instance_number FROM v$instance;

define view_loc_def = 'AWR_PDB';
define view_loc     = '&view_loc_def';

variable dbid       number;
variable inst_num   number;
begin
  :dbid      :=  &dbid;
  :inst_num  :=  &instance_number;
end;
/

variable bid        number;
variable eid        number;
begin
  :bid       :=  &begin_snap;
  :eid       :=  &end_snap;
end;
/

variable task_name  varchar2(40);

set termout on
prompt
prompt Running the ADDM analysis on the specified pair of snapshots ...
set termout off

begin
  declare
    id number;
    name varchar2(100);
    descr varchar2(500);
  BEGIN
     name := '';
     descr := 'ADDM run: snapshots [' || :bid || ', '
              || :eid || '], instance ' || :inst_num
              || ', database id ' || :dbid;

     dbms_advisor.create_task('ADDM',id,name,descr,null);

     :task_name := name;

     -- set time window
     dbms_advisor.set_task_parameter(name, 'START_SNAPSHOT', :bid);
     dbms_advisor.set_task_parameter(name, 'END_SNAPSHOT', :eid);

     -- set instance number
     dbms_advisor.set_task_parameter(name, 'INSTANCE', :inst_num);

     -- set dbid
     dbms_advisor.set_task_parameter(name, 'DB_ID', :dbid);

     -- execute task
     dbms_advisor.execute_task(name);

  end;
end;
/

set termout on
prompt
prompt Generating the ADDM report for this analysis ...
set termout off

spool &rpt_name;

set long 1000000 pagesize 0 longchunksize 1000
column get_clob format a80

select dbms_advisor.get_task_report(:task_name, 'TEXT', 'TYPICAL')
from   sys.dual;

spool off;
set termout on
prompt
prompt End of Report
prompt Report written to &rpt_name.
