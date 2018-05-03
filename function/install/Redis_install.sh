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

    INFO_MSG "[Redis ${redis_version:?} Installing.........]"
    yum -y install gcc tcl
    # jemalloc
    SOURCE_SCRIPT ${script_dir:?}/include/jemalloc.sh
    Install_Jemalloc
}
Install_Redis(){

    [ -d ${redis_install_dir:?} ] && rm -rf ${redis_install_dir:?}
    cd ${script_dir:?}/src
    # shellcheck disable=SC2034
    src_url=http://download.redis.io/releases/redis-${redis_version:?}.tar.gz
    [ ! -f redis-${redis_version:?}.tar.gz ] && Download_src
    [ -d redis-${redis_version:?} ] && rm -rf redis-${redis_version:?}
    tar xf redis-${redis_version:?}.tar.gz && cd redis-${redis_version:?}
    make -j${CpuProNum:?} && make PREFIX=${redis_install_dir:?} install
    if [ -f "${redis_install_dir:?}/bin/redis-server" ]; then
        #read -p "Please input Port(Default:6379):" RedisPort
        #RedisPort="${RedisPort:=6379}"
        RedisPort=${redis_port:?}
        mkdir -p ${redis_install_dir}/{run,etc,init.d,logs,$RedisPort}
        cp redis.conf ${redis_install_dir}/etc/redis_$RedisPort.conf
        # setting conf file
        sed -i 's@daemonize no@daemonize yes@' ${redis_install_dir}/etc/redis_$RedisPort.conf
        sed -i 's@supervised no@supervised yes@' ${redis_install_dir}/etc/redis_$RedisPort.conf
        sed -i "s@pidfile.*@pidfile ${redis_install_dir}/run/redis_$RedisPort.pid@" ${redis_install_dir}/etc/redis_$RedisPort.conf
        sed -i "s@logfile.*@logfile ${redis_install_dir}/var/redis.log@" ${redis_install_dir}/etc/redis_$RedisPort.conf
        # The working directory
        sed -i "s@^dir.*@dir ${redis_install_dir}/$RedisPort@" ${redis_install_dir}/etc/redis_$RedisPort.conf
        #sed -i "s@^# bind 127.0.0.1@bind 127.0.0.1@" ${redis_install_dir}/etc/redis_$RedisPort.conf
        sed -i "s@^# requirepass foobared@requirepass admin5678@" ${redis_install_dir}/etc/redis_$RedisPort.conf
        # setting Port
        sed -i "s@port 6379@port $RedisPort@" ${redis_install_dir}/etc/redis_$RedisPort.conf
        chown -Rf $redis_user:$redis_user ${redis_install_dir}/
        Config_Redis
    else
        FAILURE_MSG "[Redis install failed, Please Contact the author !!!]"
        kill -9 $$
    fi
}

Config_Redis(){

    INFO_MSG "[setup Redis init script .........]"
    #init.d
    cp $script_dir/template/init.d/Redis.centos ${redis_install_dir}/init.d/redis
    chmod 775 ${redis_install_dir}/init.d/redis

    sed -i "s#@redis_install_dir#${redis_install_dir:?}#g" ${redis_install_dir:?}/init.d/redis
    sed -i "s#@RedisPort#$RedisPort#g" ${redis_install_dir:?}/init.d/redis
    # systemd
    # if ( [ $OS == "Ubuntu" ] && [ ${Ubuntu_version:?} -ge 15 ] ) || ( [ $OS == "CentOS" ] && [ ${CentOS_RHEL_version:?} -ge 7 ] );then
    #
    #     [ -L /lib/systemd/system/redis.service ]  && systemctl disable redis.service && rm -f /lib/systemd/system/redis.service
    #     cp $script_dir/template/systemd/redis.service /lib/systemd/system/redis.service
    #     sed -i "s#@redis_install_dir#${redis_install_dir:?}#g" /lib/systemd/system/redis.service
    #     sed -i "s#@RedisPort#$RedisPort#g" /lib/systemd/system/redis.service
    #     sed -i "s#@redis_user#${redis_user:?}#g" /lib/systemd/system/redis.service
    #     systemctl enable redis.service
    #     INFO_MSG "[starting nginx ]"
    #     systemctl start redis.service
    # else
    #     [ -L /etc/init.d/redis ] && rm -f /etc/init.d/redis
    #     ln -s ${redis_install_dir:?}/init.d/redis /etc/init.d/redis
    #     INFO_MSG "[starting nginx ]"
    #     service start redis
    # fi


}

Redis_Install_Main() {

    Redis_Var && Redis_Dep_Install && Install_Redis

}
