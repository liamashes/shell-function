# [ log file record table in mysql ]
lpMysqlIp=XX.XXX.XX.XX
lpMysqlUsername=username
lpMysqlPassword="cGFzc3dvcmQK"
lpMysqlPort=3306
lpMysqlTableDb=database
# log file record table name
lpMysqlTableName=table_name

# [ table field ]
# key id
lpMysqlTableFieldId=id
# log file name with absolute path
lpMysqlTableFieldPath=file_name
# log status
lpMysqlTableStatus=state

# [ log file status : update & finished ]
# status that indicates whether log file is finished updating
# real-time log file parser not r&d yet
lpMysqlTableStatusUpdate="('0','1','2','3','4','5')"
lpMysqlTableStatusDone="('6','7','8','9')"

# [ table that store all log info from different source ]
lpMysqlLogAllIp=XX.XXX.XX.XX
lpMysqlLogAllUsername=username2
lpMysqlLogAllPassword="cGFzc3dvcmQK"
lpMysqlLogAllPort=3306
lpMysqlLogAllTableDb=database2
lpMysqlLogAllTableName=table_name
# where the log generated
lpMysqlLogAllSource="LOG_SOURCE_TYPE"
