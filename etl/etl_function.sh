#!/bin/env bash;
########################################################################################################################
## name        : etl_function.sh
## desc        : download file;check file size;getField;uncompressFile;removeHeadTail;convertFile;removeChar
########################################################################################################################

## usage
etlUsage(){
cat <<END
======================================================================
   params instruction:
           --config           :Specify configuration file（required）
           --month            :Specify month（pick one of two）
           --day              :Specify day（pick one of two）
           --param            :Show all params used
======================================================================
END
}

## reserve param
etlFuncParamList(){
    _etlFuncFtpFile=""
    _etlFuncFtpExeFile="./$$.ftpexe"
}


## check input
etlCheckInput(){
    if [ x"$etlConfigFile" = x ] || [ x"$etlMonthId" = x ];then
        if [ "$etlHasDayId" == "true" ]; then
            etlMonthId=`echo $etlMonthId | cut -c 1-4`;
        else
            etlUsage
            exit 3
        fi
    fi
}

etlCheckConfigExists() {
    if [ ! -f ${etlConfigFile} ];then
        if [ -f ${etl_cfg_conf}/${etlConfigFile} ];then
            etlConfigFile=${etl_cfg_conf}/${etlConfigFile}
        elif [ -f ${base_path}/${etlConfigFile} ];then
            etlConfigFile=${base_path}/${etlConfigFile}
        else
            logError "${etlConfigFile} does not exists,please check!"
        fi
    fi
}

## parse config
etlParseConfig(){
    ## check config file whether exists or not
    etlCheckConfigExists

    ## define param using input
    etlInterfaceName=$( echo ${etlConfigFile} | awk -F "/" '{print $NF}' | sed "s/.cfg//g" | sed "s/.xml//g" )
    
    ## pasrse config file
    
    # execute seq
    etlExecuteParam=$( etlGetXmlElement executeParam )
    
    # common param
    etlCfgBadDir=$( etlGetXmlElement badDir )
    etlCfgOutDir=$( etlGetXmlElement outDir )
    etlFileSrcDeli=$( etlGetXmlElement fileSrcDeli )
    etlFileOutDeli=$( etlGetXmlElement fileOutDeli )
    
    ## download
    etlLftpIp=$( etlGetXmlElement lftpIp )
    etlLftpUserName=$( etlGetXmlElement userName )
    etlLftpPassword=$( etlGetXmlElement password )
    etlCfgSrcDir=$( etlGetXmlElement srcdir )
    etlCfgDesDir=$( etlGetXmlElement desdir )
    etlCfgBakDir=$( etlGetXmlElement bakdir )
    etlCfgFileRegex=$( etlGetXmlElement fileRegex )
    
    # get field and add file name
    etlFieldMode=$( etlGetXmlElement fieldMode )
    etlFieldPos=$( etlGetXmlElement fieldPos )
    etlFieldLen=$( etlGetXmlElement fieldLen )
    etlFieldNum=$( etlGetXmlElement fieldNum )
    etlOutFileName=$( etlGetXmlElement outFileName )
    
    # remove head and tail
    etlHeadRow=$( etlGetXmlElement removeHeadRow )
    etlTailRow=$( etlGetXmlElement removeTailRow )
    
    # decompress
    etlCompressType=$( etlGetXmlElement compressType )
    
    # convert code
    etlSrcEncodeType=$( etlGetXmlElement srcEncodeType )
    etlOutEncodeType=$( etlGetXmlElement outEncodeType )
    
    # remove char list
    etlRemoveCharList=$( etlGetXmlElement removeCharList ) 
        
    # default value
    etlSetDefaultValue
    
    # check base params
    etlCheckCfgBaseParam
}

etlSetDefaultValue(){
    # default src delimiter "|"
    if [ x"$etlFileSrcDeli" = x ]; then
        etlFileSrcDeli="|"
    fi
    
    # default out delimiter "|"
    if [ x"$etlFileOutDeli" = x ]; then
        etlFileOutDeli="|"
    fi
}

etlGetXmlElement(){
    grep -E -o -e "<$1>.+</$1>" $etlConfigFile | sed "s/<$1>//g" |sed "s/<\/$1>//g"
}

etlReplaceVar(){
    echo $1 | sed  "s/YYYYMMDD/$etlDayId/g" |sed  "s/YYYYMM/$etlMonthId/g" | sed  "s/YYYY/$etlYearId/g"
}


etlInitParam(){
    # set date info
    etlYearId=`echo $etlMonthId | cut -c 1-4`;

    # initial param use both input and config
    if [ "$etlHasDayId" == "true" ]; then
        etlFileTime=$etlDayId
        etlDownloadRecordFile="downloaded_${etlInterfaceName}_$etlDayId"
    else
        etlFileTime=$etlMonthId
        etlDownloadRecordFile="downloaded_${etlInterfaceName}_$etlMonthId"
    fi
    
    _etlCfgSrcDirRes=$( etlReplaceVar $etlCfgSrcDir )
    _etlCfgDesDirRes=$( etlReplaceVar $etlCfgDesDir )
    _etlCfgBakDirRes=$( etlReplaceVar $etlCfgBakDir )
    _etlCfgFileRegexRes=$( etlReplaceVar $etlCfgFileRegex )
    
    _etlCfgBadDirRes=$( etlReplaceVar $etlCfgBadDir )
    _etlCfgOutDirRes=$( etlReplaceVar $etlCfgOutDir )
    _etlOutFileNameRes=$( etlReplaceVar $etlOutFileName )
    
    _etlExecuteParamList=(${etlExecuteParam//,/ })
    _etlRemoveCharList=(${etlRemoveCharList//,/ })
    
    # define dir
    etletlDRPathName="../../log/"
    etlDRPathName="download_log"
    etlDRPathName="${etletlDRPathName}/${etlDRPathName}/$etlMonthId"
    _etlDRPathNameTmp="${etlDRPathName}/tmp"
    etlFtpFileList="${etlDownloadRecordFile}_list"
    _etletlFtpFileListTmp="${etlDownloadRecordFile}_tmp_list"
    
    
    ## split param
    #etlJobTypeSplit=(${etlJobType//,/ })
    #etlJobIdSplit=(${etlJobId//,/ })
    #etlJobNumberSplit=(${etlJobNumber//,/ })
    #
    ## check array size
    #if [ ${#etlJobTypeSplit[@]} -ne ${#etlJobIdSplit[@]} ] || [ ${#etlJobTypeSplit[@]} -ne ${#etlJobNumberSplit[@]} ]; then
    #    logError "dirs are not equal, please check it."
    #    exit 1
    #fi

}

etlCheckDirExist(){

    etlVerfDir ${etlDRPathName} 
    etlVerfDir ${_etlDRPathNameTmp} 
    
    etlVerfDir ${_etlCfgDesDirRes} 
    etlVerfDir ${_etlCfgBakDirRes}
    etlVerfDir ${_etlCfgBadDirRes}
    etlVerfDir ${_etlCfgOutDirRes}

}

etlVerfDir(){
    if [ ! -d $1 ];then
       mkdir -p $1
    fi
}


etlRemoveInputFiles()
{  
    #rm -f $FILES
    find $_etlCfgDesDirRes -maxdepth 1 -name "$_etlCfgFileRegexRes" -type f | xargs rm -f
    if [ 0 != $? ]; then
        logError " rm -f $FILES failed, please check it."
    fi
    logInfo "rm -f $FILES success."
    exit 0
}

etlCopy2BadPath()
{  
    #cp -f $FILES $BADPATH"/"$LASTMONTH
    find $_etlCfgDesDirRes -maxdepth 1 -name "$_etlCfgFileRegexRes" -type f -exec cp {} $_etlCfgBadDirRes \;
    if [ 0 != $? ]; then
        logError " cp -f $_etlCfgDesDirRes/$_etlCfgFileRegexRes $_etlCfgBadDirRes/ failed, please check it."
    fi
    logInfo "cp -f $_etlCfgDesDirRes/$_etlCfgFileRegexRes $_etlCfgBadDirRes/ success."
    exit 0;
}


etlCheckCfgBaseParam(){
    if [ x"$etlCfgBadDir" = x ] || [ x"$etlCfgOutDir" = x ] || [ x"$etlFileOutDeli" = x ]; then
        logError "badDir, outDir, fileOutDeli are mandatory, please check it."
    fi
}

etlCheckCfgSpecParam(){
    if [ "x"$1 = "xdownloadFile" ];then 
        if [ x"$etlLftpUserName" = x ] || [ x"$etlLftpPassword" = x ] || [ x"$etlCfgSrcDir" = x ] || [ x"$etlCfgDesDir" = x ] || [ x"$etlCfgBakDir" = x ] || [ x"$etlLftpIp" = x ]; then
            logError "lftpIp, userName, password, srcdir, desdir, bakdir are mandatory, please check it."
        fi
    fi
    
    if [ "x"$1 = "xuncompressFile" ];then 
        if [ x"$etlCompressType" = x ]; then
            logError "compressType are mandatory, please check it."
        fi
    fi
    
    if [ "x"$1 = "xgetField" ];then 
        if [ x"$etlFieldMode" = x ] || [ x"$etlFieldPos" = x ] || [ x"$etlFieldLen" = x ] || [ x"$etlOutFileName" = x ]; then
            logError "fieldMode, fieldPos, fieldLen, outFileName are mandatory, please check it."
        fi
    fi
    
    if [ "x"$1 = "xconvertFile" ];then 
        if [ x"$etlSrcEncodeType" = x ] || [ x"$etlOutEncodeType" = x ]; then
            logError "srcEncodeType, outEncodeType are mandatory, please check it."
        fi
    fi
    
    if [ "x"$1 = "xremoveHeadTail" ];then 
        if [ x"$etlHeadRow" = x ] || [ x"$etlTailRow" = x ]; then
            logError "removeHeadRow, removeTailRow are mandatory, please check it."
        fi
    fi
    
    if [ "x"$1 = "xremoveChar" ];then
        if [ x"$etlRemoveCharList" = x ]; then
            logError "removeCharList is mandatory, please check it."
        fi
    fi
}

## etl function
etlGetFileList(){

lftp<<END_SCRIPT
open $etlLftpIp
user $etlLftpUserName $etlLftpPassword
cd   $_etlCfgSrcDirRes
lcd  ${_etlDRPathNameTmp}
dir . > ${_etlFtpFileListTmp} 
bye
END_SCRIPT

    ## filter file from list（need debug）
    _etlListFilter=$( echo "${_etlCfgFileRegexRes}" | sed 's/*//g' )
    awk  '{print $9 "|" $5 "|" $6 "|" $7}' ${_etlDRPathNameTmp}/${_etletlFtpFileListTmp} | grep "${_etlListFilter}" |grep -v "\.|"> ${_etlDRPathNameTmp}/${etlFtpFileList}

}

etlDownloadFile(){
	echo "
lftp<<END_SCRIPT
open $etlLftpIp
user $etlLftpUserName $etlLftpPassword
cd  $_etlCfgSrcDirRes
lcd $_etlCfgBakDirRes
" > ${_etlFuncFtpExeFile}
	while read line
	do		
		_P1_tmp_file_name=$( echo $line | cut -d "|" -f1 )

		if [ -f $etlDRPathName/$etlDownloadRecordFile ];then
			isdownloaded=$(grep ${_P1_tmp_file_name} $etlDRPathName/$etlDownloadRecordFile | wc -l )
		else
			isdownloaded=0
		fi

		if [ $isdownloaded -eq 0 ];then
			_etlFuncFtpFile=${_P1_tmp_file_name}" "${_etlFuncFtpFile}
			echo -e "\tmget ${_P1_tmp_file_name}" >> ${_etlFuncFtpExeFile}
		fi
	done <  $_etlDRPathNameTmp/$etlFtpFileList
	
	echo "
	bye
END_SCRIPT" >> ${_etlFuncFtpExeFile}
	sh ${_etlFuncFtpExeFile}
	rm ${_etlFuncFtpExeFile}
}


etlCheckDownloadedFile(){
		_checkarray=(${_etlFuncFtpFile})

		for(( i=0;i<${#_checkarray[@]};i++))
	  do
    
	  	_checklocalfilesize=$( ls -l $_etlCfgBakDirRes/${_checkarray[i]} | awk '{print $5}' )
	  	_checkftpfilesize=$( grep ${_checkarray[i]} $_etlDRPathNameTmp/$etlFtpFileList | cut -d "|" -f2 )
    
	  	if [[ $_checklocalfilesize -eq $_checkftpfilesize ]];then
	  		echo ${_checkarray[i]} >> $etlDRPathName/$etlDownloadRecordFile
	  	else
	  		rm $_etlCfgBakDirRes/${_checkarray[i]}
	  	fi
    
	  done
}

etlBakDownloadedFile(){
    if [ ! x"$_etlCfgBakDirRes" == x ];then
        ln $_etlCfgBakDirRes/$_etlCfgFileRegexRes $_etlCfgBakDirRes/
    fi
}


etlUploadFileToHdfs() {  
    #判断目录是否存在
    hadoop fs -test -e $hdfsDir
    if [ $? -ne 0 ]; then
        hadoop fs -mkdir -p $hdfsDir
    fi
    
    hadoop fs -put -f $_etlCfgBakDirRes/* $hdfsDir/
    if [ $? -ne 0 ]; then
        logError "从$_etlCfgBakDirRes 上传到 $hdfsDir：上传失败"
        exit 1
    fi
}


etlGetField(){
    #initial get field params
    _etlGetFieldTmpOutPath=${_etlCfgDesDirRes}"/.getfield/"
    etlVerfDir ${_etlGetFieldTmpOutPath}
    etlGetFieldTime=$( date +%Y%m%d%H%M%S )
    etlGetFieldOutFileName=${_etlOutFileNameRes}_${etlFileTime}_${etlGetFieldTime}
    etlGetFieldOutObject=${_etlGetFieldTmpOutPath}/${etlGetFieldOutFileName}
    
    _etlGetFieldFileReg=${_etlCfgFileRegexRes}
    
    sed -i "s/\x0D//g" ${_etlCfgDesDirRes}"/"${_etlGetFieldFileReg}
    
    # use awk to get field 
    if [ "0" = "$etlFieldMode" ]; then
        # delimiter
        find ${_etlCfgDesDirRes} -maxdepth 1 -name "${_etlGetFieldFileReg}" -type f |xargs -n 10000 awk -F $etlFileSrcDeli 'BEGIN{afterseparator="'$etlFileOutDeli'";fieldnums="'$etlFieldNum'";info="'$etlFieldPos'";len=split(info,arr,",");outname="'$etlGetFieldOutObject'";rows=1000000;id=1;name=outname;name=(name"_"id);name=(name".txt");} 
        {{if(NR>rows) {id=id+1;rows=rows+1000000;name=outname;name=(name"_"id);name=(name".txt");} for(k=1;k<=len;k++){if(k<len) printf("%s",$arr[k]""afterseparator) >> name; else print $arr[k]""afterseparator""FILENAME >> name }}}'
    elif [ "1" = "$etlFieldMode" ]; then
        # fixed length
        sed -i "s/|/,/g" ${_etlCfgDesDirRes}"/"${_etlGetFieldFileReg}
        find ${_etlCfgDesDirRes} -maxdepth 1 -name "${_etlGetFieldFileReg}" -type f |xargs -n 10000 awk 'BEGIN{afterseparator="'$etlFileOutDeli'";fieldnums="'$etlFieldNum'";posinfo="'$etlFieldPos'";leninfo="'$etlFieldLen'";posl=split(posinfo,posarr,",");lenl=split(leninfo,lenarr,",");outname="'$etlGetFieldOutObject'";rows=1000000;id=1;name=outname;name=(name"_"id);name=(name".txt");} 
        {if(NR>rows) {id=id+1;rows=rows+1000000;name=outname;name=(name"_"id);name=(name".txt");} for(k=1;k<=posl;k++){if(k<posl) printf substr($0,posarr[k],lenarr[k])""afterseparator >> name; else print substr($0,posarr[k],lenarr[k])""afterseparator""FILENAME >> name}}'
    else
        logError  "fieldMode needs to be 0 or 1, please check it."
    fi
    
    if [ 0 != $? ]; then
        logError " awk failed, srcfile=${_etlGetFieldFileReg}, destfile= $etlGetFieldOutObject, please check it."
    else
        # move tmp file to real path
        _etlGetFieldTmpAll=${_etlGetFieldTmpOutPath}"*.txt"
        logInfo "cp ${_etlGetFieldTmpAll} ${_etlCfgDesDirRes}"
        eval "cp ${_etlGetFieldTmpAll} ${_etlCfgDesDirRes}"
        if [ 0 != $? ]; then
            logError "mv ${_etlGetFieldTmpAll} ${_etlCfgDesDirRes} failed, please check it."
        fi 
        find $_etlCfgDesDirRes -maxdepth 1 -name "${_etlCfgFileRegexRes}" -type f | xargs rm -f
        eval "mv ${_etlGetFieldTmpAll} ${_etlCfgDesDirRes}"
        logInfo "abstract data from ${_etlGetFieldFileReg} to $etlGetFieldOutObject success."
    fi    
}

etlRmheadtail(){
    if [ x"$etlHeadRow" != x ]; then
        for((k=1;k<=$etlHeadRow;k++))
        do
            find $_etlCfgDesDirRes -maxdepth 1 -name "$_etlCfgFileRegexRes" -type f | xargs sed -i '1d'
            if [ 0 != $? ]; then
                logError "sed header $k failed, please check it."
            fi 
        done
    fi
    
    if [ x"$etlTailRow" != x ]; then
        for((k=1;k<=$etlTailRow;k++))
        do
            find $_etlCfgDesDirRes -maxdepth 1 -name "$_etlCfgFileRegexRes" -type f | xargs sed -i '$d'
            if [ 0 != $? ]; then
                logError "sed tailer $k failed, please check it." 
            fi
        done
    fi  
}

etlUncompressFile(){
    _etlUFOutDIr=$_etlCfgDesDirRes"/.uncompress/"
    etlVerfDir $_etlUFOutDIr
    _etlUFFileReg=$_etlCfgDesDirRes"/"$_etlCfgFileRegexRes
    case $etlCompressType in
      "zip")
          etlUFCmd="find $_etlCfgDesDirRes -maxdepth 1 -name '$_etlCfgFileRegexRes' | xargs -n1 unzip -d $_etlUFOutDIr"
          ;;
      "rar")
          etlUFCmd="unrar x $_etlUFFileReg $_etlUFOutDIr"
          ;;        
      "tar")
          etlUFCmd="tar xvf $_etlUFFileReg -C $_etlUFOutDIr"
          ;;
      "tar.gz")
          etlUFCmd="tar xzf $_etlUFFileReg -C $_etlUFOutDIr"
          ;;
      "tar.xz")
          etlUFCmd="tar xJf $_etlUFFileReg -C $_etlUFOutDIr"
          ;;
      "tar.bz2")
          etlUFCmd="tar xjf $_etlUFFileReg -C $_etlUFOutDIr"
          ;;
      ".Z")
          etlUFCmd="gunzip $_etlUFOutDIr$_etlCfgFileRegexRes"
          mv $_etlCfgDesDirRes"/"$_etlCfgFileRegexRes $_etlUFOutDIr
          ;;
      ".gz")
          etlUFCmd="gunzip $_etlUFOutDIr$_etlCfgFileRegexRes"
          mv $_etlCfgDesDirRes"/"$_etlCfgFileRegexRes $_etlUFOutDIr
          ;;
      "bz2")
          etlUFCmd="bunzip2 $_etlUFOutDIr$_etlCfgFileRegexRes"
          mv $_etlCfgDesDirRes"/"$_etlCfgFileRegexRes $_etlUFOutDIr
          ;;
      *)
          logError "compressType is mismatch, please check it." 
          ;;
    esac
    eval $etlUFCmd
    if [ 0 = $? ]; then
        logInfo "$etlUFCmd success."
        find $_etlCfgDesDirRes -maxdepth 1 -name "${_etlCfgFileRegexRes}" -type f | xargs rm -f
    else
        logError "$etlUFCmd failed, please check it."
    fi
    mv $_etlUFOutDIr"/"$_etlCfgFileRegexRes $_etlCfgDesDirRes
}

etlConvertFile(){
    for _etlCFFile in $( find $_etlCfgDesDirRes -maxdepth 1 -name "$_etlCfgFileRegexRes" -type f )
    do
        _etlCFFileEncode=`enca -L zh_CN -i ${_etlCFFile}`
        if [ "x"${_etlCFFileEncode} = "x" ];then
                _etlCFFileEncode=`chardetor ${_etlCFFile}`
        fi
        etlCFOutFile=$( echo ${_etlCFFile} | awk -F "/" '{print $NF}')
        etlCFOutPath=${_etlCfgFileRegexRes}"/.convert"
        etlVerfDir $etlCFOutPath
        etlCFOutDirFile=${etlCFOutPath}/${etlCFOutFile}
        iconv -f ${_etlCFFileEncode} -c  -t ${etlOutEncodeType} $_etlCFFile > $etlCFOutDirFile
        if [ 0 != $? ]; then
            logError "${_etlCFFile} convert failed"
        fi
    done
    find $_etlCfgDesDirRes -maxdepth 1 -name "$_etlCfgFileRegexRes" -type f | xargs rm -f
    find ${etlCFOutPath} -maxdepth 1 -name "$_etlCfgFileRegexRes" -type f -exec mv {} $_etlCfgDesDirRes \;
}

etlRenameFile(){
    etlVerfDir $_etlCfgDesDirRes"/.rename/"
    for _etlRFFile in `find $_etlCfgDesDirRes -maxdepth 1 -name "${_etlCfgFileRegexRes}"  -type f `
    do
        _etlRFTmpFile1=${_etlRFFile##*/} 
        sed -i "s/$etlFileSrcDeli/$etlFileOutDeli/g" $_etlRFFile
        _etlRFTmpFile2=${_etlRFTmpFile1//-/}
        _etlRFTmpFile=$_etlCfgDesDirRes"/.rename/"$_etlRFTmpFile2
        awk '{if(length !=0) print $0"'$etlFileOutDeli'""'$_etlRFTmpFile1'"}' $_etlRFFile >> $_etlRFTmpFile
    done
    find $_etlCfgDesDirRes -maxdepth 1 -name "${_etlCfgFileRegexRes}" -type f | xargs rm -f
    mv $_etlCfgDesDirRes/.rename/* $_etlCfgDesDirRes
}

etlGetFile() {
    logInfo "get file list to be downloaded"
    etlGetFileList
    
    logInfo "download file not in the record list"
    etlDownloadFile
    
    logInfo "check whether local file size equals ftp file size"
    etlCheckDownloadedFile
    
    logInfo "back up file"
    etlBakDownloadedFile
}

etlRemoveChar(){
    for i in ${!_etlRemoveCharList[@]}
    do   
        sed -i "s/${_etlRemoveCharList[$i]}//g" $_etlCfgDesDirRes/${_etlCfgFileRegexRes}
        logWarn "sed -i \"s/${_etlRemoveCharList[$i]}//g\" $_etlCfgDesDirRes/${_etlCfgFileRegexRes}"
    done
}

etlCleanVerfFile(){
}

etlVerfExecStatus(){
    if [ 0 != $1 ]; then
       logError $2
    fi
}