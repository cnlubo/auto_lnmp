#!/bin/bash
# @Author: cnak47
# @Date: 2018-04-30 23:59:11
# @LastEditors: cnak47
# @LastEditTime: 2020-01-20 12:00:36
# @Description:
# #

if [ ! -e "$(command -v lsb_release)" ]; then
    if [ -e "/usr/bin/yum" ]; then
        yum -y install redhat-lsb-core && clear
    elif [ -e "/usr/bin/apt-get" ]; then
        apt-get -y update && apt-get -y install lsb-release && clear

    fi
fi
if [ ! -e "$(command -v lsb_release)" ]; then
    FAILURE_MSG "lsb_release install failed !!!!!"
    kill -9 $$

fi
# OS name
sysOS=$(uname -s)
if [ "$sysOS" == "Linux" ]; then
    # OS Version
    # shellcheck disable=SC2143
    if [ -e /etc/redhat-release ]; then
        OS=CentOS
        CentOS_RHEL_version=$(lsb_release -sr | awk -F. '{print $1}')
        [[ "$(lsb_release -is)" =~ ^Aliyun$|^AlibabaCloudEnterpriseServer$ ]] && {
            CentOS_RHEL_version=7
            # shellcheck disable=SC2034
            Aliyun_ver=$(lsb_release -rs)
        }
        [[ "$(lsb_release -is)" =~ ^EulerOS$ ]] && {
            CentOS_RHEL_version=7
            # shellcheck disable=SC2034
            EulerOS_ver=$(lsb_release -rs)
        }
        [ "$(lsb_release -is)" == 'Fedora' ] && [ ${CentOS_RHEL_version} -ge 19 ] >/dev/null 2>&1 && {
            CentOS_RHEL_version=7
            # shellcheck disable=SC2034
            Fedora_ver=$(lsb_release -rs)
        }
    elif [ -n "$(grep 'Amazon Linux' /etc/issue)" ] || [ -n "$(grep 'Amazon Linux' /etc/os-release)" ]; then
        OS=CentOS
        CentOS_RHEL_version=7
    elif [ -n "$(grep 'bian' /etc/issue)" ] || [ "$(lsb_release -is 2>/dev/null)" == "Debian" ]; then
        OS=Debian
        # shellcheck disable=SC2034
        Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
    # elif [ -n "$(grep 'Deepin' /etc/issue)" ] || [ "$(lsb_release -is 2>/dev/null)" == "Deepin" ]; then
    #     OS=Debian
    #     Debian_version=8
    # elif [ -n "$(grep -w 'Kali' /etc/issue)" ] || [ "$(lsb_release -is 2>/dev/null)" == "Kali" ]; then
    #     OS=Debian
    #     if [ -n "$(grep 'VERSION="2016.*"' /etc/os-release)" ]; then
    #         Debian_version=8
    #     elif [ -n "$(grep 'VERSION="2017.*"' /etc/os-release)" ]; then
    #         Debian_version=9
    #     elif [ -n "$(grep 'VERSION="2018.*"' /etc/os-release)" ]; then
    #         Debian_version=9
    #     fi
    elif [ -n "$(grep 'Ubuntu' /etc/issue)" ] || [ "$(lsb_release -is 2>/dev/null)" == "Ubuntu" ] || [ -n "$(grep 'Linux Mint' /etc/issue)" ]; then
        # shellcheck disable=SC2034
        OS=Ubuntu
        Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
        # shellcheck disable=SC2034
        [ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
    # elif [ -n "$(grep 'elementary' /etc/issue)" ] || [ "$(lsb_release -is 2>/dev/null)" == 'elementary' ]; then
    #     OS=Ubuntu
    #     Ubuntu_version=16
    fi

else
    FAILURE_MSG " Does not support this OS ..... "
    kill -9 $$
fi

# Check OS Version
if [ ${CentOS_RHEL_version} -lt 6 ] >/dev/null 2>&1 || [ "${Debian_version}" -lt 8 ] >/dev/null 2>&1 || [ ${Ubuntu_ver} -lt 14 ] >/dev/null 2>&1; then
    FAILURE_MSG " Does not support this OS, Please install CentOS 6+,Debian 8+,Ubuntu 14+ !!!!! "
    kill -9 $$
fi
LIBC_YN=$(awk -v A="$(getconf -a | grep GNU_LIBC_VERSION | awk '{print $NF}')" -v B=2.14 'BEGIN{print(A>=B)?"0":"1"}')
# GLIBC_FLAG for mariadb download
# shellcheck disable=SC2034
[ "${LIBC_YN}" == '0' ] && GLIBC_FLAG=linux-glibc_214 || GLIBC_FLAG=linux
# shellcheck disable=SC2034
if [ "$(uname -r | awk -F- '{print $3}' 2>/dev/null)" == "Microsoft" ]; then
    Wsl=true
fi

# if [ "$(getconf WORD_BIT)" == 32 ] && [ "$(getconf LONG_BIT)" == 64 ]; then
#     OS_BIT=64
#     SYS_BIG_FLAG=x64 #jdk
#     SYS_BIT_a=x86_64
#     SYS_BIT_b=x86_64 #mariadb
# else
#     OS_BIT=32
#     SYS_BIG_FLAG=i586
#     SYS_BIT_a=x86
#     SYS_BIT_b=i686
# fi
if [ "$(getconf WORD_BIT)" == "32" ] && [ "$(getconf LONG_BIT)" == "64" ]; then
    OS_BIT=64
    SYS_BIT_j=x64    #jdk
    SYS_BIT_a=x86_64 #mariadb
    SYS_BIT_b=x86_64 #mariadb
else
    # shellcheck disable=SC2034
    OS_BIT=32
    # shellcheck disable=SC2034
    SYS_BIT_j=i586
    # shellcheck disable=SC2034
    SYS_BIT_a=x86
    # shellcheck disable=SC2034
    SYS_BIT_b=i686
fi

# Percona binary: https://www.percona.com/doc/percona-server/5.7/installation.html#installing-percona-server-from-a-binary-tarball
# if [ "${Debian_version:?}" -lt 9 ] >/dev/null 2>&1 || [ ${Ubuntu_version} -lt 14 ] >/dev/null 2>&1; then
#     sslLibVer=ssl100
# elif [[ "${CentOS_RHEL_version}" =~ ^[6-7]$ ]] && [ "$(lsb_release -is)" != 'Fedora' ]; then
#     sslLibVer=ssl101
# elif [ "${Debian_version}" -ge 9 ] >/dev/null 2>&1 || [ ${Ubuntu_version} -ge 14 ] >/dev/null 2>&1; then
#     sslLibVer=ssl102
# elif [ "${Fedora_ver}" -ge 27 ] >/dev/null 2>&1; then
#     sslLibVer=ssl102
# elif [ "${CentOS_RHEL_version}" == '8' ]; then
#     sslLibVer=ssl1:111
# else
#     # shellcheck disable=SC2034
#     sslLibVer=unknown
# fi

# systeminfo
# shellcheck disable=SC2034
THREAD=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
# shellcheck disable=SC2034
# shellcheck disable=SC2002
CpuProNum=$(cat /proc/cpuinfo | grep -c 'processor')
# shellcheck disable=SC2034
RamSwapG=$(awk '/SwapTotal/{swtotal=$2}END{print int(swtotal/1024)}' /proc/meminfo)
# shellcheck disable=SC2034
RamSumG=$(awk '/MemTotal/{memtotal=$2}/SwapTotal/{swtotal=$2}END{print int((memtotal+swtotal)/1024)}' /proc/meminfo)
# RamTotalG=`awk '/MemTotal/{memtotal=$2}END{print int(memtotal/1024)}'  /proc/meminfo`
# 内存单位 M
# shellcheck disable=SC2034
RamTotal=$(awk '/MemTotal/{memtotal=$2}END{print int(memtotal/1024)}' /proc/meminfo)
# shellcheck disable=SC2034
CpuCores=$(grep 'cpu cores' /proc/cpuinfo | uniq | awk -F : '{print $2}' | sed 's/^[ \t]*//g')

### 内存参数 单位m
# Mem=$(free -m | awk '/Mem:/{print $2}')
#Swap=$(free -m | awk '/Swap:/{print $2}')
# le 小于等于 gt 大于
if [ "$RamTotal" -le 640 ]; then
    Mem_level=512M
    Memory_limit=64
    # THREAD=1
elif [ "$RamTotal" -gt 640 ] && [ "$RamTotal" -le 1280 ]; then
    Mem_level=1G
    Memory_limit=128
elif [ "$RamTotal" -gt 1280 ] && [ "$RamTotal" -le 2500 ]; then
    Mem_level=2G
    Memory_limit=192
elif [ "$RamTotal" -gt 2500 ] && [ "$RamTotal" -le 3500 ]; then
    Mem_level=3G
    Memory_limit=256
elif [ "$RamTotal" -gt 3500 ] && [ "$RamTotal" -le 4500 ]; then
    Mem_level=4G
    Memory_limit=320
elif [ "$RamTotal" -gt 4500 ] && [ "$RamTotal" -le 8000 ]; then
    Mem_level=6G
    Memory_limit=384
elif [ "$RamTotal" -gt 8000 ]; then
    Mem_level=8G
    Memory_limit=448
fi
