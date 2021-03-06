#!/bin/bash
###
# @Author: cnak47
# @Date: 2018-04-30 23:59:11
# @LastEditors: cnak47
# @LastEditTime: 2020-02-25 14:32:14
# @Description:
###
# shellcheck disable=SC2164

Create_Conf() {

    cat >"${MysqlConfigPath:?}"/my"${MysqlPort:?}".cnf <<EOF
[mysql]

############## CLIENT ##########################
port                                = $MysqlPort
socket                              = ${MysqlRunPath:?}/mysql$MysqlPort.sock
default_character_set               = utf8mb4
no_auto_rehash                      # 关闭自动补齐
password                            =${dbrootpwd:?}

[mysqld]
############### GLOBAL ##########################

user                                 = ${mysql_user:?}
port                                 = $MysqlPort
lower_case_table_names               = 1
join_buffer_size                     = 1M
sort_buffer_size                     = 4M
server_id                            = ${server_id:?}
explicit_defaults_for_timestamp      # default on
default-time_zone                    = '+8:00'
# mysqlx                             = 0
max_prepared_stmt_count              = 16382
# 同一时间在mysqld所有会话中的prepare语句的上限数量，默认值为16382 超出这个值的prepare语句会报1461错误
#sql_require_primary_key             = ON 
# >=8.0.13 Whether statements that create new tables or alter the structure of existing tables enforce the requirement that tables have a primary key.
event_scheduler                      = OFF 
# 关闭mysql定时器功能
activate_all_roles_on_login          = ON
# 控制在账户登录时是否激活已经授予的角色

################ DIR #################################

basedir                             = ${MysqlBasePath:?}
pid_file                            = $MysqlRunPath/mysql$MysqlPort.pid
socket                              = $MysqlRunPath/mysql$MysqlPort.sock
datadir                             = ${MysqlDataPath:?}
tmpdir                              = ${MysqlTmpPath:?}
slave_load_tmpdir                   = $MysqlTmpPath
innodb_data_home_dir                = $MysqlDataPath
innodb_log_group_home_dir           = ${MysqlLogPath:?}
log_bin                             = $MysqlLogPath/mysql_bin
log_bin_index                       = $MysqlLogPath/mysql_bin.index
relay_log_index                     = $MysqlLogPath/relay_log.index
relay_log                           = $MysqlLogPath/relay_bin
log_error                           = $MysqlLogPath/alert.log
slow_query_log_file                 = $MysqlLogPath/slow.log
general_log_file                    = $MysqlLogPath/general.log

################ gtid ##################################

gtid_mode                              = ON
enforce_gtid_consistency               = ON
# 强制 gtid 的一致性
binlog_gtid_simple_recovery            = ON  # default on
gtid_executed_compression_period       = 1000

############### character ###############################

character_set_server                 = utf8mb4
collation-server                     = utf8mb4_0900_ai_ci
init_connect                         = 'SET NAMES utf8mb4'
# 初始化连接都设置为utf8mb4
skip-character-set-client-handshake
# 忽略客户端字符集设置,使用init_connect设置


################ NETWORK ################################

bind_address                         = 0.0.0.0
max_allowed_packet                  = 256M
net_buffer_length                   = 32k # default 16k
# 用来存放客户端连接线程的连接信息和返回客户端的结果集
# net_buffer_lenth 参数所设置的仅仅只是该缓存区的初始化大小
# MySQL会根据实际需要自行申请更多的内存以满足需求，
# 但最大不会超过 max_allowed_packet 参数大小
skip_name_resolve                    # 禁用DNS解析
# skip-networking                    # 设置MySQL不要监听网络，也就只能本机访问
max_connect_errors                  = 100000
# 如果客户端尝试连接的错误数量超过这个参数设置的值，则服务器不再接受新的客户端连接
max_connections                     = 10000
# 允许客户端并发连接的最大数量

################ SAFETY #################################

sql_mode                            = ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION,PIPES_AS_CONCAT,ANSI_QUOTES
# sql_mode 保留使用oracle的习惯 NO_AUTO_CREATE_USER mysql 8 已经移除
innodb_strict_mode                  = 1     
#>= 5.7.7 default ON
skip_ssl
safe_user_create                    = ON
default_authentication_plugin	    = mysql_native_password
# 8.0 默认采用新的加密方式：caching_sha2_password，会导致8.0以下版本的客户端连接不上

################  BINARY LOGGING ######################

binlog_expire_logs_seconds               = 604800         # 单位:秒 7*60*60*24
# expire-logs-days 被binlog_expire_logs_seconds替代
# MySQL 8.0 下 expire-logs-days尚被支持
# 当前两个参数并存并且有一个非0时则以非0的参数为binlog自动清理时间
# 如果两个都为非0值则以binlog_expire_logs_seconds为binlog清理时间忽略expire_logs_days参数
sync_binlog                              = 1              # default 1
binlog_format                            = row            # (>= 5.7.7) default row
binlog_rows_query_log_events             = 1              
# binlog_format=row模式下，把sql语句打印到binlog日志里面.默认是0(off).对查看原始的SQL语句很有帮助
binlog_error_action                      = ABORT_SERVER   
# (>= 5.7.7) defualt ABORT_SERVER
# mysql在写binlog遇到严重错误时,比如磁盘满、文件系统不可写入等,触发mysql进程自动关闭,可以保证binlog和从库都是安全的
binlog_checksum                          = NONE
# 如果slaves 是旧版本mysql 设置为NONE以避免复制报错
# binlog校验规则,5.6之后的高版本是CRC32,低版本都是NONE,但是MGR要求使用NONE
binlog_transaction_dependency_tracking   = WRITESET

############### REPLICATION #####################################
read_only                            = on
# 开启只读 防止slave被意外写入数据，但是对super 用户无效
# super_read_only                    = on
# 开启super 用户只读

######### -- replication master ##################################

master_verify_checksum               = 1

######### -- replication slave  ##################################

skip_slave_start                     = 1
# 从服务器当服务器启动时不启动从服务器线程,使用START SLAVE语句在以后启动线程
# log_slave_updates                  = 1 
# MySQL5.6的GTID复制模式，必须开启log_slave_updates，否则启动就报错
# MySQL5.7 用gtid_executed系统表记录同步复制的信息(UUID:事务号) 这样就可以不用开启log_slave_updates参数,以减少从库的压力
# default on
relay_log_recovery                   = 1
# 从库中将relay_log_recovery设置为ON,能避免由于从库relay log损坏导致的主从不一致的情形
slave-preserve-commit-order          = 1
# 控制Slave上的binlog提交顺序和Master上的binlog的提交顺序一样,保证GTID的顺序 
slave_parallel_type                  = LOGICAL_CLOCK
# 采用基于GroupCommit的并行回放,同一个Group内的事务将会在Slave上并行回放
# When slave_preserve_commit_order=1 is set, you can only use LOGICAL_CLOCK.
slave_parallel_workers               = 4
# slave_skip_errors                  = ddl_exist_errors

############## semi sync replication settings #############
### 增强版的半同步复制 lossless replication  #################
plugin_load                          = "rpl_semi_sync_master=semisync_master.so;rpl_semi_sync_slave=semisync_slave.so"
loose_rpl_semi_sync_master_enabled   = 1
loose_rpl_semi_sync_master_timeout   = 3000 # 5 second
loose_rpl_semi_sync_slave_enabled    = 1

############## Password Validation Component ############################
#validate_password.policy            = 1 # default MEDIUM
#validate_password.check_user_name   = 1
#validate_password.length            = 9

############## CACHES AND LIMITS #############################
table_open_cache                   = 4000
# The number of open tables for all threads. 
# Increasing this value increases the number of file descriptors that mysqld requires
#table_definition_cache             = -1
# The number of table definitions that can be stored in the definition cache
table_open_cache_instances         = 32
# 打开的表缓存实例的数量.为了通过减少会话间的争用来提高可伸缩性
# 可以将打开的表缓存划分为几个大小为table_open_cache / table_open_cache_instances的较小缓存实例
open_files_limit                   = 65536
# slave_net_timeout                  = 60   # Default (>= 5.7.7) 60
thread_stack                       = 280K
# 设置为每一个线程栈分配多大的内存 default 280k

################## INNODB ########################################

innodb_data_file_path                  = ibdata1:1G;ibdata2:1G:autoextend
# 可以设置参数 innodb_dedicated_server=ON来让MySQL自动探测服务器的内存资源，
# 确定innodb_buffer_pool_size, innodb_log_file_size 和 innodb_flush_method 三个参数的取值
# innodb_flush_method                  = O_DIRECT_NO_FSYNC
innodb_buffer_pool_size                = ${innodb_buffer_pool_size:?}
innodb_buffer_pool_instances           = 8
# default 8
innodb_log_file_size                   = 1024M
# <1G: 48M(default value if innodb_dedicated_server is OFF)
# <=4G: 128M <=8G: 512M <=16G: 1024M >16G: 2G
innodb_log_files_in_group              = 2
# default 2
innodb_log_buffer_size                 = 16M
# Default (>= 5.7.6)	 16m
# 事务在内存中的缓冲，也就是日志缓冲区的大小
# 如果需要处理大量的TEXT，或是BLOB字段，可以考虑增加这个参数的值
innodb_sort_buffer_size                = 8M
# ORDER BY 或者GROUP BY 操作的buffer缓存大小 最大值64m
innodb_purge_threads                   = 4
# Default (>= 5.7.8)	4
innodb_print_all_deadlocks             = ON
# 将死锁相关信息保存到错误日志中
innodb_flush_neighbors                 = 1
# 在刷新脏页过程中，如果脏页邻近范围也是脏页，会把这个脏页也flush
# 对于机械硬盘开启此参数，可以减少随机io，增加性能
# ssd类磁盘，建议设置为0可以更快的刷新脏页. Mysql8.0中，这个参数已经默认为0
innodb_stats_on_metadata               = ON
# When this variable is enabled, InnoDB updates statistics during metadata statements
# 当设置为ON的时候,在执show table status 或访问 INFORMATION_SCHEMA.TABLES、INFORMATION_SCHEMA.STATISTICS 系统表的时候,更新非持久化统计信息（类似于ANALYZE TABLE）
innodb_flush_sync                      = OFF
# innodb_io_capacity                   = 200
# default 200
#innodb_io_capacity_max                = 2000


################# LOGGING #########################################
log_queries_not_using_indexes          = 1    # 未使用索引的查询也被记录到慢查询日志中
log_throttle_queries_not_using_indexes = 10   # 每分钟记录到日志的未使用索引的语句数目 如果超过这个数目后只记录语句数量和花费的总时间
slow_query_log                         = 1
general_log                            = 0    # default off
log_slow_admin_statements              = 1
long_query_time                        = 0.05 # 50毫秒
transaction_isolation                  = READ-COMMITTED
# min_examined_row_limit               = 100
log_timestamps                         = system         
# errorlog generalog 等日志的显示时间参数，>=5.7.2 默认 UTC 会导致日志中记录的时间比中国这边的慢,修改为 SYSTEM即可
log_statements_unsafe_for_binlog       = ON                             
# for error 1592 default on

#### performance_schema ##############################################
performance_schema                                      = ON
# default ON
# 使用默认配置规则，其他规则根据需要进行开启
# performance_schema_consumer_events_waits_current      = ON
# 开启等待事件当前纪录表
# performance_schema_consumer_events_waits_history      = ON
# 开启等待事件历史纪录表
performance-schema-instrument                         ='memory/%=COUNTED'
# 开启所有的memory instruments 监控内存使用情况


EOF

}
Download_MySQL8() {

    # MySQL 8.0
    DOWN_ADDR_MYSQL=http://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-8.0
    DOWN_ADDR_MYSQL_BK=http://mirrors.ustc.edu.cn/mysql-ftp/Downloads/MySQL-8.0
    # DOWN_ADDR_MYSQL_BK2=http://mirrors.huaweicloud.com/repository/toolkit/mysql/Downloads/MySQL-8.0

    cd "${script_dir:?}"/src
    if [ "${dbinstallmethod:?}" == '2' ]; then
        INFO_MSG "Download MySQL 8.0 source package..."
        FILE_NAME=mysql-${mysql_8_0_version:?}.tar.gz
    elif [ "${dbinstallmethod:?}" == '1' ]; then # binary package instal;
        INFO_MSG " Download MySQL 8.0 binary package ....."
        FILE_NAME=mysql-${mysql_8_0_version:?}-linux-glibc2.12-${SYS_BIT_b:?}.tar.xz
    else
        echo ""
    fi
    src_url=${DOWN_ADDR_MYSQL}/${FILE_NAME} && Download_src
    # shellcheck disable=SC2034
    src_url=${DOWN_ADDR_MYSQL}/${FILE_NAME}.md5 && Download_src
    # verifying download

    INFO_MSG "verifying download file $FILE_NAME ....."
    MYSQL_TAR_MD5=$(awk '{print $1}' "${FILE_NAME}".md5)
    [ -z "${MYSQL_TAR_MD5}" ] && MYSQL_TAR_MD5=$(curl -s ${DOWN_ADDR_MYSQL_BK}/"${FILE_NAME}".md5 | grep "${FILE_NAME}" | awk '{print $1}')
    tryDlCount=0
    while [ "$(md5sum "${FILE_NAME}" | awk '{print $1}')" != "${MYSQL_TAR_MD5}" ]; do
        wget -c -P "${src_dir:?}"--no-check-certificate ${DOWN_ADDR_MYSQL_BK}/"${FILE_NAME}"
        sleep 1
        ((tryDlCount++))
        if [ "$(md5sum "${FILE_NAME}" | awk '{print $1}')" == "${MYSQL_TAR_MD5}" ] || [ "${tryDlCount}" == '6' ]; then
            break
        else
            continue
        fi
    done

    if [ ${tryDlCount} -eq 6 ]; then
        FAILURE_MSG "${FILE_NAME} download failed, Please contact the author!!!! "
        kill -9 $$
    fi

}

Install_MySQLDB() {

    cd "${script_dir:?}"/src
    if [ "${dbinstallmethod:?}" == '2' ]; then # source code install
        if [ ! -f mysql-"$mysql_8_0_version".tar.gz ]; then
            FAILURE_MSG "${FILE_NAME} download failed, Please contact the author! "
            kill -9 $$
        fi
        [ -d mysql-"$mysql_8_0_version" ] && rm -rf mysql-"$mysql_8_0_version"
        tar -zxf mysql-"$mysql_8_0_version".tar.gz && cd mysql-"$mysql_8_0_version"
        [ -d "$MysqlBasePath" ] && rm -rf "$MysqlBasePath"
        # openssl
        SOURCE_SCRIPT "${script_dir:?}"/include/openssl.sh
        Install_OpenSSL_Main "${openssl_latest_version:?}" "${openssl11_install_dir:?}"
        cmake3 -DCMAKE_INSTALL_PREFIX="$MysqlBasePath" \
            -DDEFAULT_CHARSET=utf8mb4 \
            -DDEFAULT_COLLATION=utf8mb4_general_ci \
            -DEXTRA_CHARSETS=all \
            -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
            -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
            -DWITH_INNOBASE_STORAGE_ENGINE=1 \
            -DWITH_FEDERATED_STORAGE_ENGINE=1 \
            -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
            -DENABLE_DTRACE=0 \
            -DWITH_EMBEDDED_SERVER=1 \
            -DWITH_SSL="${openssl11_install_dir:?}" \
            -DENABLED_LOCAL_INFILE=1 \
            -DWITH_BOOST="$script_dir"/src/boost_"${boostVersion2:?}" \
            -DBUILD_CONFIG=mysql_release \
            -DWITH_INNODB_MEMCACHED=ON \
            -DWITH_MYSQLD_LDFLAGS='-ljemalloc'

        make -j"${CpuProNum:?}" && make install
    elif [ "${dbinstallmethod:?}" == '1' ]; then # binary package install
        if [ ! -f mysql-"${mysql_8_0_version:?}"-linux-glibc2.12-"${SYS_BIT_b:?}".tar.xz ]; then
            FAILURE_MSG "${FILE_NAME} download failed, Please contact the author !!! "
            kill -9 $$
        fi
        #  extract mysql
        INFO_MSG " extract ${FILE_NAME} ....."
        [ -d "$MysqlBasePath" ] && rm -rf "$MysqlBasePath"
        mkdir -p "$MysqlBasePath"
        tar xf mysql-"${mysql_8_0_version:?}"-linux-glibc2.12-"${SYS_BIT_b}".tar.xz
        mv mysql-"${mysql_8_0_version}"-linux-glibc2.12-"${SYS_BIT_b}"/* "${MysqlBasePath}"
        sed -i 's@executing mysqld_safe@executing mysqld_safe\nexport LD_PRELOAD=/usr/local/lib/libjemalloc.so@' "${MysqlBasePath}"/bin/mysqld_safe
        sed -i "s@/usr/local/mysql@${MysqlBasePath}@g" "${MysqlBasePath}"/bin/mysqld_safe
    fi

    # check whether install success
    if [ -f "${MysqlBasePath}/bin/mysql" ]; then
        SUCCESS_MSG " MySQL ${mysql_8_0_version:?} installed successfully !!!! "
        chown -R mysql:mysql "$MysqlBasePath"
        [ -L /usr/local/bin/mysql ] && rm -f /usr/local/bin/mysql
        ln -s "$MysqlBasePath"/bin/mysql /usr/local/bin/mysql
        [ -L /usr/local/bin/mysqladmin ] && rm -f /usr/local/bin/mysqladmin
        ln -s "$MysqlBasePath"/bin/mysqladmin /usr/local/bin/mysqladmin

        # if [ "${dbinstallmethod}" == "1" ]; then
        #     rm -rf mysql-${mysql_5_7_version}-*-${SYS_BIT_b}
        # elif [ "${dbinstallmethod}" == "2" ]; then
        #     rm -rf mysql-${mysql_5_7_version} boost_${boostVersion2}
        # fi
    else
        FAILURE_MSG "MySQL ${mysql_8_0_version:?} install failed, Please contact the author !!!!! "
        exit 1
    fi
}
Init_MySQLDB() {

    #初始化创建数据库
    chown -R mysql.mysql "$MysqlConfigPath"/
    INFO_MSG " Initialization Database ....."
    # --initialize：root用户生成随机密码 --initialize-insecure：root用户不生成随机密码
    "$MysqlBasePath"/bin/mysqld --defaults-file="$MysqlConfigPath"/my"$MysqlPort".cnf --user=mysql \
        --basedir="$MysqlBasePath" --datadir="$MysqlDataPath" --initialize-insecure
    mkdir -p "${MysqlOptPath:?}"/init.d
    chown -R mysql.mysql "$MysqlOptPath"/
    cp "$script_dir"/template/mysql_start "$MysqlOptPath"/init.d/mysql"$MysqlPort"
    chmod 775 "$MysqlOptPath"/init.d/mysql"$MysqlPort"
    chown -R mysql.mysql "$MysqlOptPath"/init.d/
    # shellcheck disable=SC2086
    sed -i ':a;$!{N;ba};s#basedir=#basedir='''$MysqlBasePath'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    # shellcheck disable=SC2086
    sed -i ':a;$!{N;ba};s#datadir=#datadir='''$MysqlDataPath'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    # shellcheck disable=SC2086
    sed -i ':a;$!{N;ba};s#conf=#conf='''$MysqlConfigPath/my$MysqlPort.cnf'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    # shellcheck disable=SC2086
    sed -i ':a;$!{N;ba};s#mysql_user=#mysql_user='''$mysql_user'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    # shellcheck disable=SC2086
    sed -i ':a;$!{N;ba};s#mysqld_pid_file_path=#mysqld_pid_file_path='''$MysqlRunPath/mysql$MysqlPort\.pid'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    # service script
    if { [ "$OS" == "Ubuntu" ] && [ "${Ubuntu_version:?}" -ge 15 ]; } || { [ "$OS" == "CentOS" ] && [ "${CentOS_RHEL_version:?}" -ge 7 ]; }; then
        #support Systemd
        [ -L /lib/systemd/system/mysql"$MysqlPort".service ] && rm -f /lib/systemd/system/mysql"$MysqlPort".service
        cp "$script_dir"/template/mysql.service /lib/systemd/system/mysql"$MysqlPort".service
        # shellcheck disable=SC2086
        sed -i ':a;$!{N;ba};s#PIDFile=#PIDFile='''$MysqlOptPath/run/mysql$MysqlPort.pid'''#' /lib/systemd/system/mysql$MysqlPort.service
        mycnf=''$MysqlOptPath/etc/my$MysqlPort.cnf''
        # shellcheck disable=SC2086
        sed -i "s#@MysqlBasePath#$MysqlBasePath#g" /lib/systemd/system/mysql$MysqlPort.service
        # shellcheck disable=SC2086
        sed -i "s#@defaults-file#$mycnf#g" /lib/systemd/system/mysql$MysqlPort.service
        systemctl enable mysql"$MysqlPort".service
    else
        [ -L /etc/init.d/mysql"$MysqlPort" ] && rm -f /etc/init.d/mysql"$MysqlPort"
        ln -s "$MysqlOptPath"/init.d/mysql"$MysqlPort" /etc/init.d/mysql"$MysqlPort"
        #service start mysql$MysqlPort
    fi

}

Config_MySQLDB() {

    INFO_MSG " config mysql db ......"
    "$MysqlOptPath"/init.d/mysql"$MysqlPort" start
    #打开注释生效validate_password 插件
    echo "ok2"
    "$MysqlBasePath"/bin/mysql -S "$MysqlRunPath"/mysql"$MysqlPort".sock -e "create user root@'127.0.0.1' identified by \"$dbrootpwd\" ;"
    echo "ok3"
    "$MysqlBasePath"/bin/mysql -S "$MysqlRunPath"/mysql"$MysqlPort".sock -e "grant all privileges on *.* to root@'127.0.0.1' with grant option;"
    echo "ok3"
    "$MysqlBasePath"/bin/mysql -S "$MysqlRunPath"/mysql"$MysqlPort".sock -e "ALTER USER root@'localhost' IDENTIFIED WITH mysql_native_password BY \"$dbrootpwd\" ;"
    echo "ok4"
    "$MysqlBasePath"/bin/mysql -S "$MysqlRunPath"/mysql"$MysqlPort".sock -e "grant all privileges on *.* to root@'localhost' with grant option;" -p"$dbrootpwd"
    echo "ok1"
    "$MysqlBasePath"/bin/mysql -S "$MysqlRunPath"/mysql"$MysqlPort".sock -e "INSTALL COMPONENT 'file://component_validate_password';" -p"$dbrootpwd"

    sed -i '/validate_password.policy/s/^#//' "$MysqlConfigPath"/my"$MysqlPort".cnf
    sed -i '/validate_password.check_user_name/s/^#//' "$MysqlConfigPath"/my"$MysqlPort".cnf
    sed -i '/validate_password.length/s/^#//' "$MysqlConfigPath"/my"$MysqlPort".cnf

    "$MysqlOptPath"/init.d/mysql"$MysqlPort" stop
    #启动数据库
    if { [ "$OS" == "Ubuntu" ] && [ "$Ubuntu_version" -ge 15 ]; } || { [ "$OS" == "CentOS" ] && [ "$CentOS_RHEL_version" -ge 7 ]; }; then
        INFO_MSG " starting db ....."
        systemctl start mysql"$MysqlPort".service
    else
        INFO_MSG " starting db ....."
        service start mysql"$MysqlPort"
    fi
    rm -rf "$script_dir"/src/mysql-"$mysql_8_0_version"
    # 环境变量设置
    # shellcheck disable=SC2028
    [ -f /root/.zshrc ] && echo export 'MYSQL_PS1="\\u@\\h:\\d \\r:\\m:\\s>"' >>/root/.zshrc
    if id "${default_user:?}" >/dev/null 2>&1; then
        # shellcheck disable=SC2028
        [ -f /home/"${default_user:?}"/.zshrc ] && echo export 'MYSQL_PS1="\\u@\\h:\\d \\r:\\m:\\s>"' >>/home/${default_user:?}/.zshrc
    fi
    WARNING_MSG " db root user passwd:$dbrootpwd !!!!"
}

MySQLDB_Install_Main() {

    # check mysql whether running
    check_app_status "MySql"
    if [ "$COUNT" -gt 0 ]; then
        WARNING_MSG " MySQL 8.0 is running please stop it !!!!! "
        EXIT_SCRIPT
    else

        if [ "${dbinstallmethod:?}" == '2' ]; then
            INFO_MSG " install mysql ${mysql_8_0_version:?} by source code ..... "
            MySQL_Var && MySQL_Base_Packages_Install && Download_MySQL8 && Install_MySQLDB
            if [ -f "${MysqlBasePath}/bin/mysql" ]; then
                Create_Conf && Init_MySQLDB && Config_MySQLDB
            fi
        elif [ "${dbinstallmethod:?}" == '1' ]; then
            INFO_MSG " install mysql $mysql_8_0_version by binary package ..... "
            MySQL_Var && MySQL_Base_Packages_Install && Download_MySQL8 && Install_MySQLDB
            if [ -f "${MysqlBasePath}/bin/mysql" ]; then
                Create_Conf && Init_MySQLDB && Config_MySQLDB
            fi
        else
            WARNING_MSG "not support mysql install method ....."
        fi
    fi
}
