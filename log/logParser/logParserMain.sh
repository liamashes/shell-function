logParserMainBasePath=$(cd `dirname $0`; pwd)
cd $(dirname "$0")

# 初始化配置和函数
source ${logParserMainBasePath}/conf/cfg-var.sh
source ${logParserMainBasePath}/logParserProcess.sh

# 定义待使用文件
logParserWorkPath=${logParserMainBasePath}/work
# 获取待执行任务列表
logParserAllList=${logParserWorkPath}/logParserAllList.txt
logParserLoggedList=${logParserWorkPath}/logParserLoggedList.txt
logParserTaskListDone=${logParserWorkPath}/logParserTaskListDone.txt
# 文件锁
logParserLockFile=${logParserWorkPath}/.logParserEsLogFile.lock

# 已完成的任务的处理流程
logParserDone() {
    _logParserDoneLineDeli="###"
    while read logParserDoneLine
    do
        _logParserDoneLine=$( echo ${logParserDoneLine} | sed "s/ /$_logParserDoneLineDeli/g" )
        _logParserId=$( logParserGetField $_logParserDoneLine 1 ${_logParserDoneLineDeli} )
        _logParserLogDir=$( logParserGetField $_logParserDoneLine 2 ${_logParserDoneLineDeli} )

        if [ x"${_logParserLogDir}" != "x" ] && [ "${_logParserLogDir}" != "NULL" ] && [ -f ${_logParserLogDir} ];then
            echo "processing ${_logParserId}:${_logParserLogDir}"
            logParserProcess ${_logParserLogDir} ${_logParserId}
        fi    
        logParserLogDone "${_logParserId}" "${_logParserLogDir}"
    done < ${logParserTaskListDone}
}

# 加锁
logParserLock

# 初始化版本记录表及确认全量日志表是否创建
logParserCheckTbExists
logParserCheckLogAllExists

# 生成未处理的任务
logParserGetUnloggedInfoDone

# 处理日志及记录日志
logParserDone

# 解锁
logParserUnlock