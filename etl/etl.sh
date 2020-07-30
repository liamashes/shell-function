#!/bin/sh
########################################################################################################################
## name        : etl.sh
## reserve param rule: 
##               1.each formal param should start with etl
##               2.using Camel-Case
##               3.tmp param(delete after all) should start with _, executable file should include $$ 
########################################################################################################################
## initial
source ~/.bash_profile
etlBasePath=$(cd `dirname $0`; pwd)
cd $( dirname "$0" )

# use path.env and var.env
base_path=${etlBasePath}/..
source ${base_path}/env/path.env

## set etl function
source ${etlBasePath}/etl_function.sh


# log set
thisLogFunctionPath=${log_bin}/log.func
thisLogBasePath=${log_dir}
thisLogBusiName=equity-settlement
thisLogScriptName=$0
thisLogExecuteType=etl

## initial log params
source $thisLogFunctionPath
logSetBaseDir $thisLogBasePath
logInit $thisLogBusiName $thisLogScriptName
logSetExecuteType $thisLogExecuteType
logSetErrorExit true

## reserve param
function etlExecuteParamList(){
    cat <<END
======================================================================
    etlConfigFile:          输入的参数文件
    etlInterfaceName:       接口名称
    
    etlYearId:              年
    etlMonthId:             月份
    etlDayId:               日期
    etlHasDayId:            是否有日期参数
    
    etlDownloadRecordFile:  下载记录文件
    etlLogPath:             日志目录
    etlDRPathName:          下载记录文件存放的目录名称
    _etlDRPathNameTmp:      下载记录文件存放的临时目录
    
    etlLftpIp:              服务器：地址，sftp时需要加上"sftp://"的前缀
    etlLftpUserName:        服务器：用户名称
    etlLftpPassword:        服务器：用户密码
    etlCfgSrcDir:           配置：服务器目录
    etlCfgDesDir:           配置：目标目录
    etlCfgBakDir:           配置：备份目录
    etlCfgFileRegex:        配置：文件匹配表达式
    
    _etlCfgSrcDirRes:       解析后配置：服务器目录
    _etlCfgDesDirRes:       解析后配置：目标目录
    _etlCfgBakDirRes:       解析后配置：备份目录
    _etlCfgFileRegexRes:     解析后配置：文件匹配方式
    
    etlJobType:             任务：类型
    etlJobId:               任务：ID
    etlJobNumber:           任务：序号
    
    etlJobTypeSplit:        任务：类型拆分
    etlJobIdSplit:          任务：ID拆分
    etlJobNumberSplit:      任务：序号拆分
    
    etlFtpFileList:         文件列表
    _etlFtpFileListTmp:     临时文件列表
    _etlListFilter:         列表过滤器
    _etlFuncFtpFile:        函数中指定的服务器文件
    _etlFuncFtpExeFile:     函数中生成的临时下载程序文件
    
======================================================================
END
}



## get input param
while [ $# -gt 0 ]; do
  case "$1" in
    --config)
      shift
      etlConfigFile=$1
      shift
      ;;
    --month)
      shift
      etlMonthId=$1
      shift
      ;;
    --day)
      shift
      etlHasDayId=true
      etlDayId=$1
      shift
      ;;
    --param)
      etlExecuteParamList
      shift
      ;;
    *)
      etlUsage
      shift
      ;;
  esac
done

logInfo "check input"
etlCheckInput

logInfo "get param from config file"
etlParseConfig

logInfo "initial param"
etlInitParam

logInfo "check directory, mkdir if not exists"
etlCheckDirExist
    
## process
for i in ${!_etlExecuteParamList[@]}
do   
    if [ ${_etlExecuteParamList[$i]} = "getField" ];then
        etlCheckCfgSpecParam "getField"
        etlGetField
        etlVerfExecStatus $? "getfield failed, please check it."
    elif [ ${_etlExecuteParamList[$i]} = "removeHeadTail" ];then
        etlCheckCfgSpecParam "removeHeadTail"
        etlRmheadtail
        etlVerfExecStatus $? "rmheadtail failed, please check it."
    elif [ ${_etlExecuteParamList[$i]} = "uncompressFile" ];then
        etlCheckCfgSpecParam "uncompressFile"
        etlUncompressFile
        etlVerfExecStatus $? "uncompressfile failed, please check it."
    elif [ ${_etlExecuteParamList[$i]} = "downloadFile" ];then
        etlCheckCfgSpecParam "downloadFile"
        etlGetFile
        etlVerfExecStatus $? "ftpfile failed, please check it."
        etlCleanVerfFile
    elif [ ${_etlExecuteParamList[$i]} = "convertFile" ];then
        etlCheckCfgSpecParam "convertFile"
        etlConvertFile
        etlVerfExecStatus $? "convertfile failed, please check it."
    elif [ ${_etlExecuteParamList[$i]} = "removeChar" ];then
        etlCheckCfgSpecParam "removeChar"
        etlRemoveChar
        etlVerfExecStatus $? "removeChar failed, please check it."
    else    
        ${_etlExecuteParamList[$i]}
        etlVerfExecStatus $? "${_etlExecuteParamList[$i]} failed, please check it."
    fi
done


