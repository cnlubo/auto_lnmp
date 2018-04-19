#!/bin/bash\
    # shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              Mysql-5.7.sh
# @Desc                                    mysql-5.7 install scripts
#----------------------------------------------------------------------------
Create_Conf() {

    cat > ${MysqlConfigPath:?}/my${MysqlPort:?}.cnf << EOF
[mysql]
############## CLIENT ##########################
port                                = $MysqlPort
socket                              = ${MysqlRunPath:?}/mysql$MysqlPort.sock
default_character_set               = UTF8
no_auto_rehash
password                            =${dbrootpwd:?}

[mysqld]
############### GENERAL##########################
user                                = ${mysql_user:?}
port                                = $MysqlPort
bind_address                        = 0.0.0.0
# character_set_server                = UTF8
character_set_server               = utf8mb4
collation-server                   = utf8mb4_unicode_ci
init_connect                       = 'SET NAMES utf8mb4' # 初始化连接都设置为utf8mb4
skip-character-set-client-handshake  =true               # 忽略客户端字符集设置,使用init_connect设置
lower_case_table_names              = 1
join_buffer_size                    = 1M
sort_buffer_size                    = 1M
server_id                           = ${server_id:?}
gtid_mode                           = ON
enforce_gtid_consistency            = ON
explicit_defaults_for_timestamp

################DIR#################################
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

################MyISAM##############################

################ SAFETY##############################

max_allowed_packet                  = 16M
max_connect_errors                  = 1000   # 如果客户端尝试连接的错误数量超过这个参数设置的值，则服务器不再接受新的客户端连接
skip_name_resolve                    #禁用DNS解析
#skip-networking                     #设置MySQL不要监听网络，也就只能本机访问
sql_mode                            = STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_AUTO_VALUE_ON_ZERO,NO_ENGINE_SUBSTITUTION,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,ONLY_FULL_GROUP_BY
innodb_strict_mode                  = 1     #>= 5.7.7 default ON
skip_ssl
safe_user_create                    = 1

################  BINARY LOGGING######################
expire_logs_days                    = 7
sync_binlog                         = 1
# binlog_format                       = row    # (>= 5.7.7) default ROW
binlog_rows_query_log_events        = 1
# binlog_error_action                 = ABORT_SERVER # (>= 5.7.7) defualt ABORT_SERVER
log_timestamps                      = system # 主要是控制 errorlog generalog 等日志的显示时间参数，>=5.7.2 默认 UTC 会导致日志中记录的时间比中国这边的慢 修改为 SYSTEM即可

############### REPLICATION ############################
read_only                           = 1
skip_slave_start                    = 1
log_slave_updates                   = 1
relay_log_recovery                  = 1
master_info_repository              = TABLE
relay_log_info_repository           = TABLE
master_verify_checksum              = 1
slave_parallel_workers              = 3
slave_skip_errors                   = ddl_exist_errors
binlog_gtid_simple_recovery         = 1
plugin_load                         = "rpl_semi_sync_master=semisync_master.so;rpl_semi_sync_slave=semisync_slave.so"
loose_rpl_semi_sync_master_enabled  = 1
loose_rpl_semi_sync_master_timeout  = 3000 # 5 second
loose_rpl_semi_sync_slave_enabled   = 1


############## PASSWORD PLUGIN   ############################
#plugin-load-add                    =validate_password.so
#validate_password_policy           = MEDIUM
#validate-password                  = FORCE_PLUS_PERMANENT

############## CACHES AND LIMITS #############################
query_cache_type                   = 0   # Default Value: OFF
query_cache_size                   = 0
max_connections                    = 800     # 允许客户端并发连接的最大数量
open_files_limit                   = 65535
# slave_net_timeout                  = 60   # Default (>= 5.7.7) 60
thread_stack                       = 512K

##################INNODB####################################### #
innodb_data_file_path               = ibdata1:1G;ibdata2:512M:autoextend
innodb_flush_method                 = O_DIRECT
innodb_log_file_size                = 512M
innodb_log_files_in_group           = 2
innodb_buffer_pool_size             = ${innodb_buffer_pool_size:?}
innodb_log_buffer_size              = 16M # Default (>= 5.7.6)	 16m
innodb_sort_buffer_size             = 64M # ORDER BY 或者GROUP BY 操作的buffer缓存大小
innodb_purge_threads                = 4   # Default (>= 5.7.8)	4
innodb_print_all_deadlocks          = 1   # 将死锁相关信息保存到错误日志中

################# LOGGING#########################################
log_queries_not_using_indexes          = 1
log_throttle_queries_not_using_indexes = 10 #每分钟记录到日志的未使用索引的语句数目 如果超过这个数目后只记录语句数量和花费的总时间
slow_query_log                         = 1
general_log                            = 0
log_slow_admin_statements              = 1
long_query_time                        = 3
transaction_isolation                  = READ-COMMITTED
# min_examined_row_limit                 = 100


EOF

}

Install_MySQLDB()
{
    echo "${CMSG}[ Mysql${mysql_5_7_version:?} Installing ] **************************************************>>${CEND}";
    cd ${script_dir:?}/src
    # shellcheck disable=SC2034
    src_url=http://cdn.mysql.com//Downloads/MySQL-5.7/mysql-$mysql_5_7_version.tar.gz
    [ ! -f mysql-$mysql_5_7_version.tar.gz ] && Download_src
    [ -d mysql-$mysql_5_7_version ] && rm -rf mysql-$mysql_5_7_version
    tar -zxf mysql-$mysql_5_7_version.tar.gz && cd mysql-$mysql_5_7_version
    [ -d $MysqlBasePath ] && rm -rf $MysqlBasePath
    cmake -DCMAKE_INSTALL_PREFIX=$MysqlBasePath \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
        -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DENABLED_LOCAL_INFILE=1 \
        -DWITH_BOOST=$script_dir/src/boost_1_59_0 \
        -DBUILD_CONFIG=mysql_release \
        -DWITH_INNODB_MEMCACHED=ON \
        -DWITH_MYSQLD_LDFLAGS='-ljemalloc'

    make -j${CpuProNum:?} && make install
    chown -R mysql:mysql $MysqlBasePath
    [ -L /usr/bin/mysql ] && rm -f /usr/bin/mysql
    ln -s $MysqlBasePath/bin/mysql /usr/bin/mysql
    [ -L /usr/bin/mysqladmin ] && rm -f /usr/bin/mysqladmin
    ln -s $MysqlBasePath/bin/mysqladmin /usr/bin/mysqladmin

}
Init_MySQLDB(){

    #初始化创建数据库
    chown -R mysql.mysql $MysqlConfigPath/
    echo "${CMSG}[ Initialization Database ] **************************************************>>${CEND}"
    # 初始化数据库不生成密码    --initialize：root用户生成随机密码 --initialize-insecure：root用户不生成随机密码
    $MysqlBasePath/bin/mysqld --defaults-file=$MysqlConfigPath/my$MysqlPort.cnf --user=mysql \
        --basedir=$MysqlBasePath --datadir=$MysqlDataPath --initialize-insecure
    #启动脚本
    mkdir -p ${MysqlOptPath:?}/init.d
    chown -R mysql.mysql $MysqlOptPath/
    cp $script_dir/template/mysql_start $MysqlOptPath/init.d/mysql$MysqlPort
    chmod 775 $MysqlOptPath/init.d/mysql$MysqlPort
    chown -R mysql.mysql $MysqlOptPath/init.d/
    sed  -i ':a;$!{N;ba};s#basedir=#basedir='''$MysqlBasePath'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    sed  -i ':a;$!{N;ba};s#datadir=#datadir='''$MysqlDataPath'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    sed  -i ':a;$!{N;ba};s#conf=#conf='''$MysqlConfigPath/my$MysqlPort.cnf'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    sed  -i ':a;$!{N;ba};s#mysql_user=#mysql_user='''$mysql_user'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    sed  -i ':a;$!{N;ba};s#mysqld_pid_file_path=#mysqld_pid_file_path='''$MysqlRunPath/mysql$MysqlPort\.pid'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    #服务脚本
    if ( [ $OS == "Ubuntu" ] && [ ${Ubuntu_version:?} -ge 15 ] ) || ( [ $OS == "CentOS" ] && [ ${CentOS_RHEL_version:?} -ge 7 ] );then
        #support Systemd
        [ -L /lib/systemd/system/mysql$MysqlPort.service ] && rm -f /lib/systemd/system/mysql$MysqlPort.service;
        cp $script_dir/template/mysql.service /lib/systemd/system/mysql$MysqlPort.service;
        sed  -i ':a;$!{N;ba};s#PIDFile=#PIDFile='''$MysqlOptPath/run/mysql$MysqlPort.pid'''#' /lib/systemd/system/mysql$MysqlPort.service
        mycnf=''$MysqlOptPath/etc/my$MysqlPort.cnf''
        sed -i ''s#@MysqlBasePath#$MysqlBasePath#g'' /lib/systemd/system/mysql$MysqlPort.service
        sed -i ''s#@defaults-file#$mycnf#g'' /lib/systemd/system/mysql$MysqlPort.service
        systemctl enable mysql$MysqlPort.service
        #echo "${CMSG}[starting db ] **************************************************>>${CEND}";
        #systemctl start mysql$MysqlPort.service #
    else
        [ -L /etc/init.d/mysql$MysqlPort ] && rm -f /etc/init.d/mysql$MysqlPort
        ln -s $MysqlOptPath/init.d/mysql$MysqlPort /etc/init.d/mysql$MysqlPort
        #echo "${CMSG}[starting db ] **************************************************>>${CEND}";
        #service start mysql$MysqlPort
    fi


}
Config_MySQLDB()
{
    echo "${CMSG}[ config mysql db !!! ] **************************************************>>${CEND}"
    # 生成数据库root用户随机密码(8位长度包含字母数字和特殊字符)
    $MysqlOptPath/init.d/mysql$MysqlPort start
    $MysqlBasePath/bin/mysql -S $MysqlRunPath/mysql$MysqlPort.sock -e "grant all privileges on *.* to root@'127.0.0.1' identified by \"$dbrootpwd\" with grant option;"
    $MysqlBasePath/bin/mysql -S $MysqlRunPath/mysql$MysqlPort.sock -e "grant all privileges on *.* to root@'localhost' identified by \"$dbrootpwd\" with grant option;"
    #打开注释生效validate_password 插件
    sed -i '/plugin-load-add/s/^#//' $MysqlConfigPath/my$MysqlPort.cnf
    sed -i '/validate_password_policy/s/^#//' $MysqlConfigPath/my$MysqlPort.cnf
    sed -i '/validate-password/s/^#//' $MysqlConfigPath/my$MysqlPort.cnf

    $MysqlOptPath/init.d/mysql$MysqlPort stop
    #启动数据库
    if ( [ $OS == "Ubuntu" ] && [ $Ubuntu_version -ge 15 ] ) || ( [ $OS == "CentOS" ] && [ $CentOS_RHEL_version -ge 7 ] );then
        echo -e "${CMSG}[ starting db ] **********************************************>>${CEND}\n"
        systemctl start mysql$MysqlPort.service
    else
        echo -e "${CMSG}[ starting db ] **********************************************>>${CEND}\n"
        service start mysql$MysqlPort
    fi
    rm -rf $script_dir/src/mysql-$mysql_5_7_version
    #环境变量设置
    [ -f /root/.zshrc ] && echo export 'MYSQL_PS1="\\u@\\h:\\d \\r:\\m:\\s>"' >>/root/.zshrc
    id ${default_user:?} >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        [ -f /home/${default_user:?}/.zshrc ] && echo export 'MYSQL_PS1="\\u@\\h:\\d \\r:\\m:\\s>"' >>/home/${default_user:?}/.zshrc
    fi
    #echo PATH='$PATH:'$MysqlBasePath/bin >>/etc/profile
    #echo export PATH >>/etc/profile
    #echo export 'MYSQL_PS1="\\u@\\h:\\d \\r:\\m:\\s>"' >>/etc/profile
    #source /etc/profile
    echo -e "${CRED}[db root user passwd:$dbrootpwd ] **************************>>${CEND}\n"

}

MySQLDB_Install_Main(){

    MySQL_Var&&MySQL_Base_Packages_Install&&Install_MySQLDB&&Create_Conf&&Init_MySQLDB&&Config_MySQLDB
    
}
