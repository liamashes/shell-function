# 需要预定义 logParserLockFile
logParserDecrypt() {
    echo "$1" | base64 -d
}

logParserLock() {
    logParserLockPreCheck=$( logParserIsParamEmpty $logParserLockFile )
    if [ ${logParserLockPreCheck} -ne 0 ];then
        echo "set logParserLockFile first"
        exit -1
    fi
    if [ ! -f $logParserLockFile ];then
        touch $logParserLockFile
        logParserSetLockStatus "lock"
    else
        logParserLockStatus=$( logParserGetLockStatus )
        if [ x"$logParserLockStatus" == "xlock" ];then
            echo "Log Parser Main Running,Wait Unlock"
            exit 0
        else
            logParserSetLockStatus "lock"
        fi
    fi
}

logParserUnlock() {
    logParserSetLockStatus "unlock"
}

logParserSetLockStatus() {
    if [ x"$1" == "xlock" ] || [ x"$1" == "xunlock" ];then
        echo $1 >  $logParserLockFile
    else
        logError "Usage:logParserSetLockStatus lock/unlock"
    fi
}

logParserGetLockStatus() {
    cat $logParserLockFile
}

logParserMysqlExecute() {
    # 2>/dev/null
    lpMysqlPasswordDc=$( logParserDecrypt ${lpMysqlPassword} )
    logParserMysqlExecuteCmd="mysql -h ${lpMysqlIp} -P ${lpMysqlPort} -u ${lpMysqlUsername} -p${lpMysqlPasswordDc} -e 2>/dev/null \"$1\""
    eval $logParserMysqlExecuteCmd
}

logParserMysqlLogAllExecute() {
    # 2>/dev/null
    lpMysqlLogAllPasswordDc=$( logParserDecrypt ${lpMysqlLogAllPassword} )
    logParserMysqlLogAllExecuteCmd="mysql -h ${lpMysqlLogAllIp} -P ${lpMysqlLogAllPort} -u ${lpMysqlLogAllUsername} -p${lpMysqlLogAllPasswordDc} -e 2>/dev/null \"$1\""
    eval $logParserMysqlLogAllExecuteCmd
}

logParserRemoveHeadLine() {
    sed -i '1d' $1
}

logParserCheckTbExists() {
    logParserGetTableSql="select 1 from information_schema.tables where table_schema='${lpMysqlTableDb}' and table_name='t_log_parser_map';"
    logParserGetTableResult=$( logParserMysqlExecute "${logParserGetTableSql}" )
    if [ "${logParserGetTableResult}" == "" ];then
        echo "Initial ${lpMysqlTableDb}.t_log_parser_map"
        logParserInit
    fi
}

logParserInit() {
    logParserTbDdl="create table ${lpMysqlTableDb}.t_log_parser_map(
                    tb_name varchar(128) NOT NULL COMMENT '表名',
                    tb_id varchar(128) COMMENT '表中的唯一ID',
                    log_path varchar(128) COMMENT '日志存放路径',
                    PRIMARY KEY (tb_id),
                    KEY name_id (tb_id,tb_name) using BTREE
                    )ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
                    Insert into ${lpMysqlTableDb}.t_log_parser_map(tb_name,tb_id,log_path)
                    select '${lpMysqlTableDb}.${lpMysqlTableName}', $lpMysqlTableFieldId, $lpMysqlTableFieldPath
                    from ${lpMysqlTableDb}.${lpMysqlTableName}
                    where ${lpMysqlTableStatus} in ${lpMysqlTableStatusDone};"
    
    logParserMysqlExecute "${logParserTbDdl}"
}

logParserCheckLogAllExists() {
    logParserCheckLogAllSql="select 1 from information_schema.tables where table_schema='${lpMysqlLogAllTableDb}' and table_name='${lpMysqlLogAllTableName}';"
    
    #echo $logParserLoadCmd
    logParserCheckLogAllResult=$( logParserMysqlLogAllExecute "$logParserCheckLogAllSql" )
    if [ "${logParserCheckLogAllResult}" == "" ];then
        echo "Initial ${lpMysqlLogAllTableDb}.${lpMysqlLogAllTableName}"
        logParserCheckLogAllInit
    fi
}

logParserCheckLogAllInit() {
    logParserCheckLogAllDdl="create table ${lpMysqlLogAllTableDb}.${lpMysqlLogAllTableName}(
                             id int(11) NOT NULL AUTO_INCREMENT COMMENT 'key',
                             log_id varchar(255) DEFAULT NULL COMMENT '日志ID',
                             source varchar(255) DEFAULT NULL COMMENT '来源',
                             type varchar(32) DEFAULT NULL COMMENT '类型',
                             info varchar(255) NOT NULL COMMENT '信息简称',
                             detail text COMMENT '日志内容（详细的日志内容）',
                             submitter varchar(128) COMMENT '提交人',
                             submit_time  varchar(128) COMMENT '提交时间',
                             PRIMARY KEY (id)
                             )ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8"
    logParserMysqlLogAllExecute "$logParserCheckLogAllDdl"
}

# 需要预定义 logParserAllList logParserLoggedList logParserTaskListDone
logParserGetUnloggedInfoDone() {
    logParserGetAllInfoSql="select a.${lpMysqlTableFieldId},a.${lpMysqlTableFieldPath} 
                                 from ${lpMysqlTableDb}.t_escheduler_task_instance a
                                 where a.${lpMysqlTableStatus} in ${lpMysqlTableStatusDone} order by ${lpMysqlTableFieldId} asc;"     
    logParserGetLoggedInfoSql="select cast(tb_id as unsigned integer) id, log_path 
                                 from ${lpMysqlTableDb}.t_log_parser_map
                                 where tb_name='${lpMysqlTableDb}.${lpMysqlTableName}' order by id asc;"   
                                                             
    logParserMysqlExecute "${logParserGetAllInfoSql}" > ${logParserAllList}
    logParserMysqlExecute "${logParserGetLoggedInfoSql}" > ${logParserLoggedList}
    
    logParserRemoveHeadLine ${logParserAllList}
    logParserRemoveHeadLine ${logParserLoggedList}
    
    diff ${logParserLoggedList} ${logParserAllList} | grep ">" | sed "s/^> //g" > ${logParserTaskListDone}
}

logParserLogDone(){
    # tb_name
    _logParserLogDone1=${lpMysqlTableDb}.${lpMysqlTableName}
    # tb_id
    _logParserLogDone2=$1
    # log_path
    _logParserLogDone3=$2
    
    logParserLogDoneSql="Insert Into ${lpMysqlTableDb}.t_log_parser_map(tb_name, tb_id, log_path)
                         select '$_logParserLogDone1','$_logParserLogDone2','$_logParserLogDone3'"
    logParserMysqlExecute "$logParserLogDoneSql"
}

logParserLoadInfo() {
    # id
    # _logParserLoad1="null"
    # log_id
    _logParserLoad2=$1
    # source
    _logParserLoad3=$lpMysqlLogAllSource
    # type
    _logParserLoad4="error"
    # info
    _logParserLoad5=$2
    # detail
    _logParserLoad6=$( echo $3 | sed "s/'/\\\'/g" )
    # submitter
    _logParserLoad7="AUTO_GENERATE"
    # submit_time
    _logParserLoad8=$( date +%Y%m%d%H%M%S )
    
    logParserLoadSql="Insert Into ${lpMysqlLogAllTableDb}.${lpMysqlLogAllTableName}(log_id, source, type, info, detail, submitter, submit_time)
                      Select '$_logParserLoad2','$_logParserLoad3','$_logParserLoad4','$_logParserLoad5','$_logParserLoad6','$_logParserLoad7','$_logParserLoad8'";
    logParserMysqlLogAllExecute "$logParserLoadSql"
}

logParserGetField(){
    echo $1 | awk -F $3 '{fieldNums="'$2'";print $fieldNums}'
}

logParserCheckParam(){
    for _logParserParam in "${logParserParam[@]}"
    do
        _logParserParamCombine=$( eval echo "\${$1${_logParserParam}[*]}")
        logParserCheckParamStatus=$( logParserIsParamEmpty ${_logParserParamCombine} )
        if [ ${logParserCheckParamStatus} -ne 0 ];then
            echo "$1's ${_logParserParam} is not Set"
            exit -1
        fi
    done
}

logParserIsParamEmpty(){
    if [ x"$1" == x ];then
        echo -1
    else
        echo 0
    fi
}

logParserVerfDir(){
    if [ ! -d $1 ];then
        mkdir -p $1
    fi
}

logParserVerfFile(){
    if [ ! -f $1 ];then
        touch $1
    fi
}

logParserProcessEnd(){
    rm -r ${logParserProcessWorkDir}
}

logParserProcess() {
    logParserLogDir=$1
    logParserId=$2
    
    # 创建任务文件路径
    logParserProcessWorkDir=${logParserMainBasePath}/work/${logParserId}
    logParserVerfDir ${logParserProcessWorkDir}
    
    # 初始化配置文件
    source ${logParserMainBasePath}/conf/cfg.sh
    
    # 内置分析层次
    declare -a logParserParam=(
            [1]="Filter"
            [2]="Matcher"
    )
    
    logParserUnmatchedType="未知异常"
    
    for _logParserKey in "${logParserKeyWords[@]}"
    do
        logParserKey=$( logParserGetField ${_logParserKey} 1 ${logParserFieldDeli} )
        logParserKeyPattern=$( logParserGetField ${_logParserKey} 2 ${logParserFieldDeli} )
        
        
        # 检查参数是否都具备
        logParserCheckParam ${logParserKey}
        
        # 根据keyPattern做初步筛选
        logParserKeyPatternCmdOutPut=${logParserProcessWorkDir}/${logParserKey}.log
        logParserKeyPatternCmd="find ${logParserLogDir} -name \"*.log\" -type f | xargs grep -i -n \"${logParserKeyPattern}\" > ${logParserKeyPatternCmdOutPut}"
        logParserVerfFile ${logParserKeyPatternCmdOutPut}
        eval $logParserKeyPatternCmd
        
        
        # Filter
        logParserParamFilterSize=$( eval echo "\${#${logParserKey}${logParserParam[1]}[*]}")
        for j in $(seq 1 ${logParserParamFilterSize})
        do
            logParserParamFilter=${logParserParamFilter}" -e \""$(eval echo $( eval echo "'\${${logParserKey}${logParserParam[1]}[$j]}'"))"\""
        done
        logParserFilterCmdOutPut=${logParserProcessWorkDir}/${logParserKey}.log.filter
        logParserFilterCmd="grep -v -i ${logParserParamFilter} ${logParserKeyPatternCmdOutPut} > ${logParserFilterCmdOutPut}"
        logParserVerfFile ${logParserFilterCmdOutPut}
        eval $logParserFilterCmd
        
        # Matcher
        _logParserMatcherCmdMidStorage=${logParserProcessWorkDir}/${logParserKey}.log.midS
        logParserParamMatcherSize=$( eval echo "\${#${logParserKey}${logParserParam[2]}[*]}")
        for j in $(seq 1 ${logParserParamMatcherSize})
        do
            # 获取当前Matcher的规则和类型
            _logParserParamMatcher=$(eval echo $( eval echo "'\${${logParserKey}${logParserParam[2]}[$j]}'"))
            logParserParamMatcher=$( logParserGetField "${_logParserParamMatcher}" 1 "${logParserFieldDeli}" )
            logParserParamMatcherType=$( logParserGetField "${_logParserParamMatcher}" 2 "${logParserFieldDeli}" )
            
            # 生成获取命令
            logParserMatcherCmdOutPut=${logParserProcessWorkDir}/${logParserKey}.log.matcher.$j
            logParserMatcherCmd="grep -i \"${logParserParamMatcher}\" ${logParserFilterCmdOutPut} > ${logParserMatcherCmdOutPut}"
            logParserMatcherCmd=$logParserMatcherCmd";grep -v -i \"${logParserParamMatcher}\" ${logParserFilterCmdOutPut} > ${_logParserMatcherCmdMidStorage}"
            logParserMatcherCmd=$logParserMatcherCmd";mv ${_logParserMatcherCmdMidStorage} ${logParserFilterCmdOutPut}"
            
            # 获取日志
            logParserVerfFile ${logParserMatcherCmdOutPut}
            eval $logParserMatcherCmd
            
            # 存储输出结果
            
            while read logParserMatcherResult
            do
                logParserLoadInfo "$logParserId" "$logParserParamMatcherType" "$logParserMatcherResult"
            done < ${logParserMatcherCmdOutPut}
        done
        
        # 读取剩余的结果，以未知类型入库
        while read logParserMatcherResult
        do
            logParserLoadInfo "$logParserId" "$logParserUnmatchedType" "$logParserMatcherResult"
        done < ${logParserFilterCmdOutPut}     
        
    done
    
    logParserProcessEnd
}