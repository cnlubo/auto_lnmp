#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @Date:                                   2016-01-25 13:38:17
# @file_name:                              MariaDB-10.1.sh
# @Last Modified by:                       ak47
# @Last Modified time:                     2016-02-18 11:23:53
# @Desc                                    mariadb-10.1 install scripts
#----------------------------------------------------------------------------

Create_Conf() {


    cat > ${MysqlConfigPath:?}/my${MysqlPort:?}.cnf << EOF
[mysql]

############## CLIENT #############
port                               = $MysqlPort
socket                             = ${MysqlRunPath:?}/mysql$MysqlPort.sock
default_character_set              = UTF8
#default_character_set              = utf8mb4
password                           = ${dbrootpwd:?}

[mysqld]

############### GENERAL############
user                               = ${mysql_user:?}
port                               = $MysqlPort
bind_address                       = 0.0.0.0
# character_set_server               = UTF8
character_set_server               = utf8mb4
collation-server                   = utf8mb4_unicode_ci
init_connect                       = 'SET NAMES utf8mb4' # 初始化连接都设置为utf8mb4
skip-character-set-client-handshake  =true               # 忽略客户端字符集设置,使用init_connect设置
# performance_schema                 = 0                 #  如果设置为1 初始化数据库时失败
lower_case_table_names             = 1
join_buffer_size                   = 1M
sort_buffer_size                   = 1M
server_id                          = ${server_id:?}
thread_handling                    = pool-of-threads

################DIR################
basedir                            = ${MysqlBasePath:?}
pid_file                           = $MysqlRunPath/mysql$MysqlPort.pid
socket                             = $MysqlRunPath/mysql$MysqlPort.sock
datadir                            = ${MysqlDataPath:?}
tmpdir                             = ${MysqlTmpPath:?}
slave_load_tmpdir                  = $MysqlTmpPath
innodb_data_home_dir               = $MysqlDataPath
innodb_log_group_home_dir          = ${MysqlLogPath:?}
log_bin                            = $MysqlLogPath/mysql_bin
log_bin_index                      = $MysqlLogPath/mysql_bin.index
relay_log_index                    = $MysqlLogPath/relay_log.index
relay_log                          = $MysqlLogPath/relay_bin
log_error                          = $MysqlLogPath/alert.log
slow_query_log_file                = $MysqlLogPath/slow.log
general_log_file                   = $MysqlLogPath/general.log

################MyISAM#############

################ SAFETY############
max_allowed_packet                 = 16M  # 16M: ()>= MariaDB 10.2.4) 4M: (>= MariaDB 10.1.7) 1MB (<= MariaDB 10.1.6)
max_connect_errors                 = 1000
skip_name_resolve
sql_mode                           = STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_AUTO_VALUE_ON_ZERO,NO_ENGINE_SUBSTITUTION,ONLY_FULL_GROUP_BY
sysdate_is_now                     = 1
innodb_strict_mode                 = 1   # Default Value: ON (>= MariaDB 10.2.2 OFF (<= MariaDB 10.2.1)
skip_ssl                           # disable_ssl

################  BINARY LOGGING##########
expire_logs_days                   = 7
sync_binlog                        = 1
binlog_checksum                    = CRC32 # CRC32 (>= MariaDB 10.2.1) NONE (<= MariaDB 10.2.0)
binlog_format                      = row # Default Value: MIXED (>= MariaDB 10.2.4) STATEMENT (<= MariaDB 10.2.3)

############### REPLICATION ###############
read_only                          = 1
skip_slave_start                   = 1
log_slave_updates                  = 1
relay_log_recovery                 = 1
# sync_master_info                   = 1 # 10000 (>= MariaDB 10.1.7), 0 (<= MariaDB 10.1.6) 1 is the safest, but slowest
# sync_relay_log                     = 1 # 10000 (>= MariaDB 10.1.7), 0 (<= MariaDB 10.1.6) 1 is the safest, but slowest
# sync_relay_log_info                = 1 # 10000 (>= MariaDB 10.1.7), 0 (<= MariaDB 10.1.6) 1 is the safest, but slowest
master_verify_checksum             = 1

############## CACHES AND LIMITS ##########
# query_cache_type                   = 0   # Default Value: OFF (>= MariaDB 10.1.7), ON (<= MariaDB 10.1.6)
query_cache_size                   = 0
max_connections                    = 800
open_files_limit                   = 65535
table_definition_cache             = 65536
# slave_net_timeout                  = 5  # 60 (1 minute) (>= MariaDB 10.2.4) 3600 (1 hour) (<= MariaDB 10.2.3)
thread_stack                       = 512K

##################INNODB####################################### #
innodb_data_file_path              = ibdata1:1G;ibdata2:512M:autoextend
innodb_flush_method                = O_DIRECT
innodb_log_files_in_group          = 2
innodb_log_file_size               = 512M
innodb_buffer_pool_size            = ${innodb_buffer_pool_size:?}
innodb_file_format                 = Barracuda # Barracuda (>= MariaDB 10.2.2) Antelope (<= MariaDB 10.2.1)
innodb_log_buffer_size             = 16M # 16777216 (16MB) >= MariaDB 10.1.9, 8388608 (8MB) <= MariaDB 10.1.8
innodb_purge_threads               = 4 # 4 (>= MariaDB 10.2.2) 1 (>=MariaDB 10.0 to <= MariaDB 10.2.1) 0 (MariaDB 5.5)
innodb_sort_buffer_size            = 64M

################# LOGGING####################### #
log_queries_not_using_indexes      = 1
slow_query_log                     = 1
general_log                        = 0
log_slow_admin_statements          = 1
long_query_time                    = 3
transaction_isolation              = READ-COMMITTED


EOF

}

Install_MariaDB()
{
    echo -e "${CMSG}[mariadb${mariadb_10_1_version:?} Installing] ****************>>${CEND}\n"
    # shellcheck disable=SC2034
    src_url=https://mirrors.tuna.tsinghua.edu.cn/mariadb//mariadb-$mariadb_10_1_version/source/mariadb-$mariadb_10_1_version.tar.gz
    cd ${script_dir:?}/src
    [ ! -f mariadb-$mariadb_10_1_version.tar.gz ] && Download_src
    [ -d mariadb-$mariadb_10_1_version ] && rm -rf mariadb-$mariadb_10_1_version
    tar -zxf mariadb-$mariadb_10_1_version.tar.gz && cd mariadb-$mariadb_10_1_version
    [ -d $MysqlBasePath ] && rm -rf $MysqlBasePath

    cmake -DCMAKE_INSTALL_PREFIX=$MysqlBasePath \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DWITH_EXTRA_CHARSETS=all \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_XTRADB_STORAGE_ENGINE=1 \
        -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
        -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
        -DENABLED_LOCAL_INFILE=1 \
        -DWITH_INNODB_MEMCACHED=ON \
        -DWITH_SSL=bundled \
        -DWITH_EMBEDDED_SERVER=1 \
        -DCMAKE_EXE_LINKER_FLAGS="-ljemalloc" \
        -DWITH_SAFEMALLOC=OFF

    make -j${CpuProNum:?} && make install
    chown -R mysql:mysql $MysqlBasePath

    [ -L /usr/bin/mysql ] && rm -f /usr/bin/mysql
    ln -s $MysqlBasePath/bin/mysql /usr/bin/mysql
    [ -L /usr/bin/mysqladmin ] && rm -f /usr/bin/mysqladmin
    ln -s $MysqlBasePath/bin/mysqladmin /usr/bin/mysqladmin;

}

Init_MariaDB(){

    chown -R mysql.mysql $MysqlConfigPath/
    chmod 777 $MysqlBasePath/scripts/mysql_install_db
    #初始化数据库
    echo -e "${CMSG}[Initialization Database] **********************************>>${CEND}\n"
    $MysqlBasePath/scripts/mysql_install_db --user=mysql --defaults-file=$MysqlConfigPath/my$MysqlPort.cnf \
        --basedir=$MysqlBasePath --datadir=$MysqlDataPath
    # 启动脚本
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

    #启动服务脚本
    if ( [ $OS == "Ubuntu" ] && [ ${Ubuntu_version:?} -ge 15 ] ) || ( [ $OS == "CentOS" ] && [ ${CentOS_RHEL_version:?} -ge 7 ] );then
        #support Systemd
        [ -L /lib/systemd/system/mariadb$MysqlPort.service ] && rm -f /lib/systemd/system/mariadb$MysqlPort.service
        cp $script_dir/template/mariadb.service /lib/systemd/system/mariadb$MysqlPort.service
        sed  -i ':a;$!{N;ba};s#PIDFile=#PIDFile='''$MysqlOptPath/run/mysql$MysqlPort.pid'''#' /lib/systemd/system/mariadb$MysqlPort.service
        mycnf=''$MysqlOptPath/etc/my$MysqlPort.cnf''
        sed -i ''s#@MysqlBasePath#$MysqlBasePath#g'' /lib/systemd/system/mariadb$MysqlPort.service
        sed -i ''s#@defaults-file#$mycnf#g'' /lib/systemd/system/mariadb$MysqlPort.service
        systemctl enable mariadb$MysqlPort.service
        #echo "${CMSG}[starting db ] **************************************************>>${CEND}"
        #systemctl start mysql$MysqlPort.service #启动数据库
    else
        [ -L /etc/init.d/mariadb$MysqlPort ] && rm -f /etc/init.d/mariadb$MysqlPort
        ln -s $MysqlOptPath/init.d/mysql$MysqlPort /etc/init.d/mariadb$MysqlPort
        #echo "${CMSG}[starting db ] **************************************************>>${CEND}";
        #service start mysql$MysqlPort
    fi

}
Config_MariaDB(){

    echo -e "${CMSG}[config db ] *******************************>>${CEND}\n"
    $MysqlOptPath/init.d/mysql$MysqlPort start;

    $MysqlBasePath/bin/mysql -S $MysqlRunPath/mysql$MysqlPort.sock -e "grant all privileges on *.* to root@'127.0.0.1' identified by \"$dbrootpwd\" with grant option;"
    $MysqlBasePath/bin/mysql -S $MysqlRunPath/mysql$MysqlPort.sock -e "grant all privileges on *.* to root@'localhost' identified by \"$dbrootpwd\" with grant option;"
    mysql -uroot -S $MysqlRunPath/mysql$MysqlPort.sock -p$dbrootpwd <<EOF
    USE mysql;
    delete from user where Password='';
    DELETE FROM user WHERE user='';
    delete from proxies_priv where Host!='localhost';
    drop database test;
    DROP USER ''@'%';
    reset master;
    FLUSH PRIVILEGES;
EOF
    $MysqlOptPath/init.d/mysql$MysqlPort stop
    #启动数据库
    echo -e "${CMSG}[starting db ] ********************************>>${CEND}\n"
    if ( [ $OS == "Ubuntu" ] && [ $Ubuntu_version -ge 15 ] ) || ( [ $OS == "CentOS" ] && [ $CentOS_RHEL_version -ge 7 ] );then
        systemctl start mariadb$MysqlPort.service
    else
        service start mariadb$MysqlPort
    fi
    rm -rf $script_dir/src/mariadb-$mariadb_10_1_version
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
    echo -e "${CRED}[db root user passwd:$dbrootpwd ] *******************************>>${CEND}\n"

}

MariaDB_10_1_Install_Main(){

    MySQL_Var&&MySQL_Base_Packages_Install&&Install_MariaDB&&Create_Conf&&Init_MariaDB&&Config_MariaDB
}
