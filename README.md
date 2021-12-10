NAME:
  addmrpt.sql

DESCRIPTION:
  This script generates oracle ADDM report.

SUPPORTED ORACLE VERSION:
  11g, 19c

USAGE:
  sqlplus连接数据库，运行脚本 SQL> @addmrpt

在当前目录生成数据库ADDM报告[默认当天9:00-10:00，可修改]

参数定义：day=0-当天;1-昨天;2-前天;依此类推

报告名字：checkdb_hostname_instance_service_addmrpt_YYYYMMDD_StartHour-EndHour.txt

报告名字示例：checkdb_zzjk01_zzjk1_zzjk_addmrpt_20211210_9-10.txt
