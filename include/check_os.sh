#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @Date:                                   2016-01-25 14:27:13
# @file_name:                              check_os.sh
# @Last Modified by:                       ak47
# @Last Modified time:                     2016-01-27 16:04:05
# @Desc
#----------------------------------------------------------------------------
#get OS name
if [ -n "`grep 'Aliyun Linux release' /etc/issue`" -o -e /etc/redhat-release ];then
    OS=CentOS
    [ -n "`grep ' 7\.' /etc/redhat-release`" ] && CentOS_RHEL_version=7
    [ -n "`grep ' 6\.' /etc/redhat-release`" -o -n "`grep 'Aliyun Linux release6 15' /etc/issue`" ] && CentOS_RHEL_version=6
    [ -n "`grep ' 5\.' /etc/redhat-release`" -o -n "`grep 'Aliyun Linux release5' /etc/issue`" ] && CentOS_RHEL_version=5
elif [ -n "` grep 'CentOS release' /etc/issue`" -o -e /etc/redhait-release ];then
    
    OS=CentOS
    [ -n "`grep ' 7\.' /etc/redhat-release`" ] && CentOS_RHEL_version=7
    [ -n "`grep ' 6\.' /etc/redhat-release`" ] && CentOS_RHEL_version=6
    [ -n "`grep ' 5\.' /etc/redhat-release`" ] && CentOS_RHEL_version=5
elif [ -n "`grep bian /etc/issue`" ];then
    OS=Debian
    [ ! -e "`which lsb_release`" ] && apt-get -y install lsb-release
    Debian_version=`lsb_release -sr | awk -F. '{print $1}'`
elif [ -n "`grep Ubuntu /etc/issue`" ];then
    OS=Ubuntu
    [ ! -e "`which lsb_release`" ] && apt-get -y install lsb-release
    Ubuntu_version=`lsb_release -sr | awk -F. '{print $1}'`
else
    echo "${CFAILURE}Does not support this OS, Please contact the author! ${CEND}"
    kill -9 $$
fi
echo $CentOS_RHEL_version
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
