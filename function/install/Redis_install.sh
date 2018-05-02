#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              redis_install.sh
# @Desc
#----------------------------------------------------------------------------

Redis_Var() {

    # #第二种，准确判断pid的信息，
    # #-C 表示的是nginx完整命令，不带匹配的操作
    # #--no-header 表示不要表头的数据
    # #wc -l 表示计数
    # COUNT=$(ps -C nginx --no-header |wc -l)
    # #echo "ps -c|方法:"$COUNT
    # if [ $COUNT -gt 0 ]
    # then
    #     echo -e "${CWARNING}[Error nginx or Tengine is running please stop !!!!]${CEND}\n" && exit
    # fi
    # echo -e "${CMSG}[create user and group ]***********************************>>${CEND}\n"

    grep ${redis_user:?} /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd $redis_user
    fi
    id $redis_user >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g $redis_user  -M -s /sbin/nologin $redis_user
    fi

}

Redis_Dep_Install(){

    yum -y install gcc tcl
}
Install_Redis(){

    INFO_MSG "[Redis Installing]"
    [ -d ${redis_install_dir:?} ] && rm -rf ${redis_install_dir:?}
    cd ${script_dir:?}/src
    # shellcheck disable=SC2034
    src_url=http://download.redis.io/releases/redis-${redis_version:?}.tar.gz
    [ ! -f redis-${redis_version:?}.tar.gz ] && Download_src
    [ -d redis-${redis_version:?} ] && rm -rf redis-${redis_version:?}
    tar xf redis-${redis_version:?}.tar.gz && cd redis-${redis_version:?}
}

Config_Redis(){

    echo
}

Redis_Install_Main() {
    Redis_Var && Redis_Dep_Install && Install_Redis
    #&& Config_Redis

}
