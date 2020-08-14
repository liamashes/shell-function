# log cfg file delimiter
logParserFieldDeli="###"

# key words and its tag
declare -a logParserKeyWords=(
        [1]="logParserError${logParserFieldDeli}[^-_]error[^-_]"
        [2]="logParserFailed${logParserFieldDeli}[^-_]failed[^-_]"
)

# filter with key tags ahead
declare -a logParserErrorFilter=(
        [1]="ERROR StatusLogger No log4j2 configuration file found"
        [2]="Ended Job = .* with errors"
        [3]="obtaining debugging information"
        [4]="obtaining error information"
        [5]="Error: java"
        [6]="at com.*(.*java:[0-9]*)"
        [7]="at org.*(.*java:[0-9]*)"
        [8]="\[taskAppId=.*\].* null"
)

declare -a logParserFailedFilter=(
        [1]="Failed Shuffles=0"
        [2]="\[taskAppId=.*\].* null"
        [3]="Task failed\!"
        [4]="WARN NOTSET"
        [5]="convert success"
        [6]="echo *\\\""
)

# matcher with key tags ahead
declare -a logParserErrorMatcher=(
        [1]="SemanticException${logParserFieldDeli}hive-sql：语义错误"
        [2]="Execution Error${logParserFieldDeli}hive-sql：执行错误"
        [3]="ERROR [0-9]\{4\} ([0-9a-zA-Z]\{5\})${logParserFieldDeli}mysql错误"
        [4]="UnknownHostException${logParserFieldDeli}调度系统未识别的host异常"
        [5]="process error${logParserFieldDeli}调度系统调度流程错误"
        [6]="syntax error${logParserFieldDeli}$脚本语法错误{logParserFieldDeli}1-1${logParserFieldDeli}"
        [7]="Unable to copy file /${logParserFieldDeli}mapreduce中，日志文件因未找到而无法复制日志文件"
        [8]="Unable to move file /${logParserFieldDeli}mapreduce中，日志文件因未找到而无法移动日志文件"
        [9]="Export job failed${logParserFieldDeli}sqoop导出失败"
        [10]="ack with firstBadLink${logParserFieldDeli}集群某节点无法连接"
        [11]="IOException${logParserFieldDeli}无效输入的异常"
        [12]="RuntimeException${logParserFieldDeli}运行时错误"
        [13]="RemoteException${logParserFieldDeli}远程异常"
        [14]="Import job failed${logParserFieldDeli}sqoop导入失败"
        [15]="MySQLSyntaxErrorException${logParserFieldDeli}mysql语法错误"
        [16]="hive.HiveImport${logParserFieldDeli}hive导入异常"
        [17]="Error in acquiring locks${logParserFieldDeli}hive并发触发了互斥锁"
        [18]="escheduler.server.*process exception${logParserFieldDeli}调度中的定时异常或流程执行异常"
        [19]="escheduler.server.*escheduler failure${logParserFieldDeli}调度中的定时异常或流程执行异常"
        [20]="tar: Exiting with failure status due to previous errors${logParserFieldDeli}tar命令异常退出"
        [21]="escheduler.server.*Cannot run program${logParserFieldDeli}调度中的定时异常或流程执行异常"
        [22]="escheduler.server.*send mail failed${logParserFieldDeli}调度中的定时异常或流程执行异常"
)

declare -a logParserFailedMatcher=(
        [1]="SemanticException${logParserFieldDeli}语句书写错误"
        [2]="Execution Error${logParserFieldDeli}hive-sql：执行错误"
        [3]="Execution failed with exit status:${logParserFieldDeli}hive-sql：执行错误"
        [4]="ParseException${logParserFieldDeli}语句书写错误"
        [5]="mapreduce.Job${logParserFieldDeli}mapreduce任务失败"
        [6]="Job failed as tasks failed${logParserFieldDeli}mapreduce任务失败"
        [7]="Failed map tasks${logParserFieldDeli}mapreduce任务失败"
        [8]="Host key verification${logParserFieldDeli}密钥验证失败"
        [9]="Insert data into .* failed${logParserFieldDeli}监控一致性稽核生成数据失败"
        [10]="Generate data into .* failed${logParserFieldDeli}监控一致性稽核生成数据失败"
        [11]="GET .* META_DATA FAILED${logParserFieldDeli}监控一致性稽核生成数据失败"
        [12]="kill job: job_.*${logParserFieldDeli}hive杀任务失败"
        [13]="IOException${logParserFieldDeli}IO异常"
        [14]="ConnectException${logParserFieldDeli}连接错误"
        [15]="ShellRunner runs failed${logParserFieldDeli}etl任务执行失败"
        [16]="Export job failed${logParserFieldDeli}sqoop导入/出失败"
        [17]="Import job failed${logParserFieldDeli}sqoop导入/出失败"
        [18]="550 Create directory operation failed${logParserFieldDeli}脚本进行lftp交互操作时，创建目录失败"
        [19]="NullPointerException${logParserFieldDeli}分区表未指定分区/Union all情况下，前后2段的字段名、数据类型不匹配"
        [20]="RuntimeException${logParserFieldDeli}运行时错误"
        [21]="RemoteException${logParserFieldDeli}远端异常"
        [22]="hive.HiveImport${logParserFieldDeli}hive导入失败"
        [23]="cd: Access failed${logParserFieldDeli}切换目录错误（不存在或无权限）"
        [24]="Error in acquiring locks${logParserFieldDeli}hive并发触发了互斥锁"
        [25]="escheduler.server.*send mail failed${logParserFieldDeli}调度中的定时异常或流程执行异常"
)
