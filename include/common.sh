#!/bin/bash
# -------------------------------------------
# @Author  : cnlubo (454331202@qq.com)
# @Link    :
# @desc    : common functions
#--------------------------------------------

EXIT_MSG(){
    ExitMsg="$1"
    echo -e "${CFAILURE}$(date +%Y-%m-%d-%H:%M) -Error $ExitMsg " |tee -a ${ErrLog:?} && exit 1
}

INFO_MSG(){
    InfoMsg="$1"
    # echo -e "$(date +%Y-%m-%d-%H:%M) -INFO $InfoMsg " |tee -a $InfoLog
    echo -e "${CMSG}$(date +%Y-%m-%d-%H:%M) -INFO $InfoMsg *****>>${CEND}\n"
}
SUCCESS_MSG(){
    InfoMsg="$1"
    echo -e "${CSUCCESS}$(date +%Y-%m-%d-%H:%M) -SUCCESS $InfoMsg *****>>${CEND}\n"
}
SUCCESS_MSG(){
    InfoMsg="$1"
    echo -e "${CSUCCESS}$(date +%Y-%m-%d-%H:%M) -SUCCESS $InfoMsg *****>>${CEND}\n"
}
FAILURE_MSG()
{
    InfoMsg="$1"
    echo -e "${CFAILURE}$(date +%Y-%m-%d-%H:%M) -FAILURE $InfoMsg *****>>${CEND}\n"
}
#check script exists and loading
SOURCE_SCRIPT(){
    for arg do
        if [ ! -f "$arg" ]; then
            EXIT_MSG "not exist $arg,so $0 can not be supported!"
        else
            #INFO_MSG "loading $arg now, continue ......"
            # shellcheck source=/dev/null.
            source $arg
        fi
    done
}
PASS_ENTER_TO_EXIT(){
    InfoMsg="input enter or wait 10s to continue"
    # shellcheck disable=SC2034
    read -p "$InfoMsg" -t 10 ok
    echo ""
}

TEST_FILE(){
    if [[ ! -f $1 ]];then
        INFO_MSG "Not exist $1"
        PASS_ENTER_TO_EXIT
        return 1
    else
        INFO_MSG "loading $1 now..."
        return 0
    fi
}
TEST_PROGRAMS(){
    for arg do
        if [[ -z $(which $arg) ]];then
            INFO_MSG "Your system do not have $arg"
            return 1
        else
            INFO_MSG "loading $arg ..."
            return 0
        fi
    done
}
BACK_TO_INDEX(){
    if [[ $? -gt 0 ]];then
        INFO_MSG "Ready back to index"
        PASS_ENTER_TO_EXIT
        SELECT_RUN_SCRIPT
    else
        INFO_MSG "succeed , continue ..."
    fi
}
INPUT_CHOOSE(){

    VarTmp=
    select vars in "$@" "exit"; do
        case $vars in
            $vars)
                # shellcheck disable=SC2034
                [[ "$vars" == "exit" ]] && VarTmp="" || VarTmp="$vars"
                break ;;
        esac
        INFO_MSG "Input again"
    done
}


INSTALL_BASE_PACKAGES(){
    case   $OS in
        "CentOS")
            {
                # echo '[yum-fastestmirror Installing] ************************************************** >>';
                # [[ -z $SysCount ]] && yum -y install yum-fastestmirror && SysCount="1"
                cp /etc/yum.conf /etc/yum.conf.back
                sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf
                #echo '[set the Epel CentOS 6 repo] ****************************************>>';
                #wget -c http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm -P /etc/yum.repos.d/rpm -Uvh /etc/yum.repos.d/epel-release-6-8.noarch.rpm
                #yum repolist
                echo '[Enable EPEL Repository in RHEL/CentOS 7/6/5] ************************************ >>';
                for arg do
                    INFO_MSG "正在安装 ${arg} ************************************************** >>" "[${arg} Installing] ************************************************** >>";
                    yum -y install $arg;
                done;
                mv -f /etc/yum.conf.back /etc/yum.conf;
            }
            ;;
        "Ubuntu")
            {
                [[ -z $SysCount ]] && apt-get update && SysCount="1"
                apt-get -fy install;apt-get -y autoremove --purge;
                dpkg -l |grep ^rc|awk '{print $2}' |sudo xargs dpkg -P
                for arg do
                    INFO_MSG "正在安装 ${arg} ************************************************** >>" "[${arg} Installing] ************************************************** >>";
                    apt-get install -y $arg --force-yes;
                done;
            }
            ;;

        *)
            echo "unknow System" ;;
    esac
    return 1
}

# INSTALL_BASE_CMD(){
#     declare count
#     declare -a ProgramsList
#     count=0
#     for arg do
#         TEST_PROGRAMS $arg
#         if [[ $? -eq 1 ]];then
#             ProgramsList[$count]=$arg
#             count=$[$count+1]
#         fi
#     done
#     INFO_MSG "Setting up these programs : ${ProgramsList[@]}"
#     INSTALL_BASE_PACKAGES ${ProgramsList[@]}
# }
# PACKET_TOOLS(){
#     declare CmdScript
#     declare InstallToolsScript
#     declare TmpCmdScript
#     INFO_MSG "Are packaged, please later..."
#     CmdScript="$1"
#     InstallToolsScript="$2"
#     #检测需要的程序
#     TEST_PROGRAMS "gzexe" "tar"
#     TEST_FILE "$CmdScript"
#     TEST_FILE "$InstallToolsScript"
#     [[ ! -d $ScriptPath/packet ]] && mkdir -p $ScriptPath/packet
#     cp $CmdScript ${DownloadTmp}/
#     TmpCmdScript=$(basename $CmdScript)
#     cd "${DownloadTmp}/" && gzexe "$TmpCmdScript" && tar -zcf "${TmpCmdScript%%.*}" "$TmpCmdScript" && cat $InstallToolsScript "${TmpCmdScript%%.*}" > $ScriptPath/packet/$(basename $InstallToolsScript) && cd $ScriptPath/packet/ && gzexe $(basename $InstallToolsScript) && mv ${DownloadTmp}/$(basename $InstallToolsScript) ${ScriptPath}/packet/$(basename $InstallToolsScript) && rm -rf ${DownloadTmp}/${TmpCmdScript}* && rm -rf ${ScriptPath}/packet/$(basename $InstallToolsScript)~ || EXIT_MSG "The corresponding create false!"
#     INFO_MSG "The installation package has been generated, the path is : ${ScriptPath}/packet/$(basename $InstallToolsScript)"
# }

Download_src() {
    [ -s "${src_dir:?}/${src_url:?##*/}" ] && echo "[${CMSG}${src_url##*/}${CEND}] found" || wget -c -P $src_dir --no-check-certificate $src_url
    if [ ! -e "$src_dir/${src_url##*/}" ];then
        echo "${CFAILURE}${src_url##*/} download failed, Please contact the author! ${CEND}"
        kill -9 $$
    fi
}
#调正时钟
#
# TIMEZONE_SET(){
#     rm -rf /etc/localtime;
#     ln -s /usr/share/zoneinfo/Asia/Chongqing /etc/localtime;
#     echo '[ntp Installing] ******************************** >>';
#     [ "$SysName" == 'centos' ] && yum install -y ntp || apt-get install -y ntpdate;
#     ntpdate -u pool.ntp.org;
#     TimeCron="0 * * * * /usr/sbin/ntpdate cn.pool.ntp.org >> /dev/null 2>&1 ;hwclock -w"
#     [[ "$(grep $TimeCron /etc/crontab)" == "" ]] && echo "$TimeCron" >> /etc/crontab
#     [ "$SysName" == 'centos' ] && /etc/init.d/crond restart || /etc/init.d/cron restart
# }
get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}
