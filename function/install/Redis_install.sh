#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              redis_install.sh
# @Desc
#----------------------------------------------------------------------------
SOURCE_SCRIPT ${ScriptPath:?}/config/redis.conf

Redis_Var() {

    check_app_status 'Redis'
    if [ $? -eq 0 ]; then
        WARNING_MSG "[Error Redis is running please stop !!!!]" && exit 0
    fi
    INFO_MSG "[create user and group ..........]"
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
        redisport=${redis_port:?}
        redissock=${redis_install_dir}/run/redis.sock
        mkdir -p ${redis_install_dir}/{run,etc,init.d,logs,$redisport}
        cp redis.conf ${redis_install_dir}/etc/redis_$redisport.conf
        # setting conf file
        sed -i 's@daemonize no@daemonize yes@' ${redis_install_dir}/etc/redis_$redisport.conf
        sed -i 's@supervised no@supervised auto@' ${redis_install_dir}/etc/redis_$redisport.conf
        sed -i "s@pidfile.*@pidfile ${redis_install_dir}/run/redis_$redisport.pid@" ${redis_install_dir}/etc/redis_$redisport.conf
        sed -i "s@logfile.*@logfile ${redis_install_dir}/logs/redis.log@" ${redis_install_dir}/etc/redis_$redisport.conf
        # The working directory
        sed -i "s@^dir.*@dir ${redis_install_dir}/$redisport@" ${redis_install_dir}/etc/redis_$redisport.conf
        #sed -i "s@^# bind 127.0.0.1@bind 127.0.0.1@" ${redis_install_dir}/etc/redis_$RedisPort.conf
        # redis pass
        redispass=`mkpasswd -l 20 -d 5 -c 7 -C 8 -s 0`
        sed -i "s@^# requirepass.*@requirepass $redispass@" ${redis_install_dir}/etc/redis_$redisport.conf
        # setting Port or sock
        if [ ${listen_type:?} = 'tcp' ]; then
            sed -i "s@port 6379@port $redisport@" ${redis_install_dir}/etc/redis_$redisport.conf
        elif [ ${listen_type:?} = 'sock' ]; then
            sed -i "s@port 6379@port 0@" ${redis_install_dir}/etc/redis_$redisport.conf
            sed -i "s@^# unixsocket /tmp/redis.sock@unixsocket $redissock@" \
                ${redis_install_dir}/etc/redis_$redisport.conf
            sed -i "s@^# unixsocketperm 700@unixsocketperm 770@" \
                ${redis_install_dir}/etc/redis_$redisport.conf
        fi
        chown -Rf $redis_user:$redis_user ${redis_install_dir}/
        [ -L /usr/local/bin/redis-cli ] && rm -f /usr/local/bin/redis-cli
        ln -s ${redis_install_dir}/bin/redis-cli /usr/local/bin/redis-cli
        # 解决运行警告
        if   [ $OS == "CentOS" ] && [ ${CentOS_RHEL_version:?} -ge 7 ] ;then
            # setup sysctl.conf
            [ -z "`grep 'vm.overcommit_memory' /etc/sysctl.conf`" ] && echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
            [ -z "`grep 'net.core.somaxconn' /etc/sysctl.conf`" ] && echo 'net.core.somaxconn = 511' >> /etc/sysctl.conf
            sysctl -p
        fi
        if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
            echo never > /sys/kernel/mm/transparent_hugepage/enabled
        fi
        if test -z "`grep 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' /etc/rc.local`"; then
            cat >> /etc/rc.local << EOF
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
EOF
            chmod +x /etc/rc.d/rc.local
        fi

        # if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
        #     echo never > /sys/kernel/mm/transparent_hugepage/defrag
        # fi
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
    sed -i "s#@RedisPort#$redisport#g" ${redis_install_dir:?}/init.d/redis
    sed -i "s#@redispass#$redispass#g" ${redis_install_dir:?}/init.d/redis
    # systemd
    if ( [ $OS == "Ubuntu" ] && [ ${Ubuntu_version:?} -ge 15 ] ) || ( [ $OS == "CentOS" ] && [ ${CentOS_RHEL_version:?} -ge 7 ] );then

        [ -L /lib/systemd/system/redis.service ]  && systemctl disable redis.service && rm -f /lib/systemd/system/redis.service
        cp $script_dir/template/systemd/redis.service /lib/systemd/system/redis.service
        sed -i "s#@redis_install_dir#${redis_install_dir:?}#g" /lib/systemd/system/redis.service
        sed -i "s#@redisport#$redisport#g" /lib/systemd/system/redis.service
        sed -i "s#@redis_user#${redis_user:?}#g" /lib/systemd/system/redis.service
        sed -i "s#@redispass#$redispass#g" /lib/systemd/system/redis.service
        sed -i "s#@redissock#$redissock#g" /lib/systemd/system/redis.service
        if [ ${listen_type:?} = 'tcp' ]; then
            sed -i "s@^ExecStop=.*@ExecStop=${redis_install_dir:?}/bin/redis-cli -p \$RedisPort -a \$PASS shutdown@" \
                /lib/systemd/system/redis.service
        elif [ ${listen_type:?} = 'sock' ]; then
            sed -i "s@^ExecStop=.*@ExecStop=${redis_install_dir:?}/bin/redis-cli -s \$RedisSock -a \$PASS shutdown@" \
                /lib/systemd/system/redis.service
        fi
        systemctl enable redis.service
        INFO_MSG "[starting redis ........]"
        systemctl start redis.service

    else
        [ -L /etc/init.d/redis ] && rm -f /etc/init.d/redis
        ln -s ${redis_install_dir:?}/init.d/redis /etc/init.d/redis
        INFO_MSG "[starting redis ........]"
        service start redis
    fi
    sleep 2s
    if [ ${listen_type:?} = 'tcp' ]; then
        ERROR_MSG=`${redis_install_dir:?}/bin/redis-cli -a ${redispass:?} -p $redisport PING`
    else
        ERROR_MSG=`${redis_install_dir:?}/bin/redis-cli -a ${redispass:?} -s ${redissock:?} PING`
    fi
    if [ "$ERROR_MSG" != "PONG" ];then
        FAILURE_MSG "[Redis Install failure,Please contact the author !!!]" && exit 1
    else
        SUCCESS_MSG "[Redis Install Success !!!]"
    fi


}

Redis_Install_Main() {

    Redis_Var && Redis_Dep_Install && Install_Redis
}
