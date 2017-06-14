#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @Date:                                   2016-01-25 14:27:13
# @file_name:                              check_os.sh
# @Desc
#----------------------------------------------------------------------------
#get OS name
# if [ -n "`grep 'Aliyun Linux release' /etc/issue`" -o -e /etc/redhat-release ];then
#     OS=CentOS
#     [ -n "`grep ' 7\.' /etc/redhat-release`" ] && CentOS_RHEL_version=7
#     [ -n "`grep ' 6\.' /etc/redhat-release`" -o -n "`grep 'Aliyun Linux release6 15' /etc/issue`" ] && CentOS_RHEL_version=6
#     [ -n "`grep ' 5\.' /etc/redhat-release`" -o -n "`grep 'Aliyun Linux release5' /etc/issue`" ] && CentOS_RHEL_version=5
#     elif [ -n "` grep 'CentOS release' /etc/issue`" -o -e /etc/redhait-release ];then
#
#     OS=CentOS
#     [ -n "`grep ' 7\.' /etc/redhat-release`" ] && CentOS_RHEL_version=7
#     [ -n "`grep ' 6\.' /etc/redhat-release`" ] && CentOS_RHEL_version=6
#     [ -n "`grep ' 5\.' /etc/redhat-release`" ] && CentOS_RHEL_version=5
#     elif [ -n "`grep bian /etc/issue`" ];then
#     OS=Debian
#     [ ! -e "`which lsb_release`" ] && apt-get -y install lsb-release
#     Debian_version=`lsb_release -sr | awk -F. '{print $1}'`
#     elif [ -n "`grep Ubuntu /etc/issue`" ];then
#     OS=Ubuntu
#     [ ! -e "`which lsb_release`" ] && apt-get -y install lsb-release
#     Ubuntu_version=`lsb_release -sr | awk -F. '{print $1}'`
# else
#     echo "${CFAILURE}Does not support this OS, Please contact the author! ${CEND}"
#     kill -9 $$
# fi
# echo $CentOS_RHEL_version
#sysOS=`uname -s`
#if [ $sysOS == "Darwin" ];then
#	echo "I'm MacOS"
#elif [ $sysOS == "Linux" ];then
#	echo "I'm Linux"
#else
#	echo "Other OS: $sysOS"
# fi
#
#
sysOS=`uname -s`
if  [ $sysOS == "Linux" ]; then
    source /etc/os-release
    # DNF即Dandified YUM，基于RPM， Linux发行版下一代软件包管理工具。
    # 它首先在Fedora 18中出现，并且在最近发行的Fedora 22中替代YUM工具集。
    # CentOS 和 OpenSUSE等Linux发行版也可以使用。
    case $ID in
        debian|ubuntu|devuan)
            sudo apt-get install lsb-release
            if [ $ID == ubuntu ];then
                $Ubuntu_version=`lsb_release -sr | awk -F. '{print $1}'`
                $OS=Ubuntu
                elif [ $ID == debian ]; then
                $Debian_version=`lsb_release -sr | awk -F. '{print $1}'`
                $OS=Debian
            fi
        ;;
        centos|fedora|rhel)
            yumdnf="yum"
            if test "$(echo "$VERSION_ID >= 22" | bc)" -ne 0; then
                yumdnf="dnf"
            fi
            if ! [ -f "/usr/bin/lsb_release" ];then
                $yumdnf install -y redhat-lsb-core
            fi
            # OS=$ID
            if [ $ID == centos ];then
                $CentOS_RHEL_version =`lsb_release -sr | awk -F. '{print $1}'`
                $OS=CentOS
                elif [ $ID == fedora ]; then
                $Fedora_version =`lsb_release -sr | awk -F. '{print $1}'`
                $OS=fedora
            fi
        ;;
        *)
            echo "${CFAILURE}Does not support this OS! ${CEND}"
            kill -9 $$
        ;;
    esac
else
    echo "${CFAILURE}Does not support this OS!! ${CEND}"
    kill -9 $$
fi



if [ `getconf WORD_BIT` == 32 ] && [ `getconf LONG_BIT` == 64 ];then
    OS_BIT=64
    SYS_BIG_FLAG=x64 #jdk
    SYS_BIT_a=x86_64;SYS_BIT_b=x86_64; #mariadb
else
    OS_BIT=32
    SYS_BIG_FLAG=i586
    SYS_BIT_a=x86;SYS_BIT_b=i686;
fi
##systeminfo
CpuProNum=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
RamSwapG=`awk '/SwapTotal/{swtotal=$2}END{print int(swtotal/1024)}'  /proc/meminfo`
RamSumG=`awk '/MemTotal/{memtotal=$2}/SwapTotal/{swtotal=$2}END{print int((memtotal+swtotal)/1024)}'  /proc/meminfo`
RamTotalG=`awk '/MemTotal/{memtotal=$2}END{print int(memtotal/1024)}'  /proc/meminfo`
CpuCores=$(grep 'cpu cores' /proc/cpuinfo |uniq |awk -F : '{print $2}' |sed 's/^[ \t]*//g')


OS_command(){
    if [ $OS == 'CentOS' ];then
        echo -e $OS_CentOS | bash
        elif [ $OS == 'Debian' -o $OS == 'Ubuntu' ];then
        echo -e $OS_Debian_Ubuntu | bash
    else
        echo "${CFAILURE}Does not support this OS, Please contact the author! ${CEND}"
        kill -9 $$
    fi
}
