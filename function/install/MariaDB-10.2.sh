#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @CreateDate:                             2016-01-25 13:38:17
# @file_name:                              MariaDB-10.2.sh
# @Last Modified by:                       ak47
# @Last Modified time:                     2016-02-18 11:23:53
# @Desc                                    mariadb-10.2 install scripts
#----------------------------------------------------------------------------

Create_Conf() {

    HostIP=`python ${script_dir:?}/py2/get_local_ip.py`
    # a=`echo ${HostIP:?}|cut -d\. -f1`
    b=`echo ${HostIP:?}|cut -d\. -f2`
    c=`echo ${HostIP:?}|cut -d\. -f3`
    d=`echo ${HostIP:?}cut -d\. -f4`
    pt=`echo ${MysqlPort:?} % 256 | bc`
    server_id=`expr $b \* 256 \* 256 \* 256 + $c \* 256 \* 256 + $d \* 256 + $pt`
    # create dir
    for path in ${MysqlLogPath:?} ${MysqlConfigPath:?} ${MysqlDataPath:?} ${MysqlTmpPath:?} ${MysqlRunPath:?};do
        [ ! -d $path ] && mkdir -p $path
        chmod 755 $path;
        chown -R mysql:mysql $path;
    done
    # create my.cnf
    cat > $MysqlConfigPath/my$MysqlPort.cnf << EOF
[mysql]
############## CLIENT #############
port                               = $MysqlPort
socket                             = $MysqlRunPath/mysql$MysqlPort.sock
default_character_set              = UTF8
no_auto_rehash
password                           =${dbrootpwd:?}

[mysqld]
############### GENERAL############
user                               = ${mysql_user:?}
port                               = $MysqlPort
default_storage_engine             = InnoDB
bind_address                       = 0.0.0.0
character_set_server               = UTF8
old_passwords                      = 0
performance_schema                 = 1
lower_case_table_names             = 1
join_buffer_size                   = 1M
sort_buffer_size                   = 1M
server_id                          = $server_id
thread_handling                    = pool-of-threads
max_sp_recursion_depth             = 255
log_bin_trust_function_creators    = ON

################DIR################
basedir                            = ${MysqlBasePath:?}
pid_file                           = $MysqlRunPath/mysql$MysqlPort.pid
socket                             = $MysqlRunPath/mysql$MysqlPort.sock
datadir                            = $MysqlDataPath
tmpdir                             = $MysqlTmpPath
slave_load_tmpdir                  = $MysqlTmpPath
innodb_data_home_dir               = $MysqlDataPath
innodb_log_group_home_dir          = $MysqlLogPath
log_bin                            = $MysqlLogPath/mysql_bin
log_bin_index                      = $MysqlLogPath/mysql_bin.index
relay_log_index                    = $MysqlLogPath/relay_log.index
relay_log                          = $MysqlLogPath/relay_bin
log_error                          = $MysqlLogPath/alert.log
slow_query_log_file                = $MysqlLogPath/slow.log
general_log_file                   = $MysqlLogPath/general.log

################MyISAM#############

################ SAFETY############

max_allowed_packet                 = 16M
max_connect_errors                 = 65536
skip_name_resolve
sql_mode                           = STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_AUTO_VALUE_ON_ZERO,NO_ENGINE_SUBSTITUTION,ONLY_FULL_GROUP_BY
sysdate_is_now                     = 1
innodb                             = FORCE
innodb_strict_mode                 = 1
skip_ssl
safe_user_create                   = 1

################  BINARY LOGGING##########
expire_logs_days                   = 7
sync_binlog                        = 1
binlog_format                      = row

############### REPLICATION ###############
read_only                          = 1
skip_slave_start                   = 1
log_slave_updates                  = 1
sync_master_info                   = 1
sync_relay_log                     = 1
sync_relay_log_info                = 1
relay_log_recovery                 = 1
slave-parallel-threads             = 8
master_verify_checksum             = 1
binlog-commit-wait-count           = 4
binlog-commit-wait-usec            = 10000

############## CACHES AND LIMITS ##########
query_cache_type                   = 0
query_cache_size                   = 0
max_connections                    = 8192
max_user_connections               = 8000
open_files_limit                   = 65535
table_definition_cache             = 65536
slave_net_timeout                  = 5
thread_stack                       = 512K
##################INNODB####################################### #

innodb_data_file_path              = ibdata1:1G;ibdata2:512M:autoextend
innodb_flush_method                = O_DIRECT
innodb_log_files_in_group          = 4
innodb_log_file_size               = 512M
innodb_buffer_pool_size            = ${innodb_buffer_pool_size:?}G
innodb_log_buffer_size             = 64M
# innodb_lru_scan_depth              = 2048
# innodb_purge_threads               = 4 # 4 (>= MariaDB 10.2.2) 1 (>=MariaDB 10.0 to <= MariaDB 10.2.1) 0 (MariaDB 5.5)
innodb_sort_buffer_size            = 2M


################# LOGGING####################### #
log_queries_not_using_indexes      = 1
slow_query_log                     = 1
general_log                        = 0
log_slow_admin_statements          = 1
long_query_time                    = 1
transaction_isolation              = READ-COMMITTED


EOF

}

Install_MariaDB()
{
    echo -e "${CMSG}[mariadb${mariadb_10_2_version:?} Installing] **************>>${CEND}\n"
    # shellcheck disable=SC2034
    src_url=https://mirrors.tuna.tsinghua.edu.cn/mariadb//mariadb-$mariadb_10_2_version/source/mariadb-$mariadb_10_2_version.tar.gz
    cd $script_dir/src
    [ ! -f mariadb-$mariadb_10_2_version.tar.gz ] && Download_src
    [ -d mariadb-$mariadb_10_2_version ] && rm -rf mariadb-$mariadb_10_2_version
    tar -zxf mariadb-$mariadb_10_2_version.tar.gz && cd mariadb-$mariadb_10_2_version
    #编译参数
    cmake -DCMAKE_INSTALL_PREFIX=$MysqlBasePath \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DWITH_EXTRA_CHARSETS=all \
        -DENABLED_LOCAL_INFILE=1 \
        -DWITH_SSL=bundled \
        -DWITH_EMBEDDED_SERVER=1 \
        -DCMAKE_EXE_LINKER_FLAGS="-ljemalloc" \
        -DWITH_SAFEMALLOC=OFF

    make -j${CpuProNum:?} && make install
    chown -R mysql:mysql $MysqlBasePath

    [ -L /usr/bin/mysql ] && rm -f /usr/bin/mysql;
    ln -s $MysqlBasePath/bin/mysql /usr/bin/mysql;
    [ -L /usr/bin/mysqladmin ] && rm -f /usr/bin/mysqladmin
    ln -s $MysqlBasePath/bin/mysqladmin /usr/bin/mysqladmin

    #echo PATH='$PATH:'$MysqlBasePath/bin >>/etc/profile
    #echo export PATH >>/etc/profile
    #echo export 'MYSQL_PS1="\\u@\\h:\\d \\r:\\m:\\s>"' >>/etc/profile
    #source /etc/profile

}
Init_MariaDB(){

    chown -R mysql.mysql $MysqlConfigPath/
    chmod 777 $MysqlBasePath/scripts/mysql_install_db
    #初始化数据库
    echo -e "${CMSG}[Initialization Database] **********************************>>${CEND}\n"
    $MysqlBasePath/scripts/mysql_install_db --user=mysql --defaults-file=$MysqlConfigPath/my$MysqlPort.cnf \
        --basedir=$MysqlBasePath --datadir=$MysqlDataPath;
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
    $MysqlOptPath/init.d/mysql$MysqlPort stop;
    #启动数据库
    echo -e "${CMSG}[starting db ] ********************************>>${CEND}\n"

    if ( [ $OS == "Ubuntu" ] && [ $Ubuntu_version -ge 15 ] ) || ( [ $OS == "CentOS" ] && [ $CentOS_RHEL_version -ge 7 ] );then
        systemctl start mariadb$MysqlPort.service
    else
        service start mariadb$MysqlPort
    fi
    rm -rf $script_dir/src/mariadb-$mariadb_10_2_version
    echo -e "${CRED}[db root user passwd:$dbrootpwd ] *******************************>>${CEND}\n"

}

MariaDB_Install_Main(){

    MySQL_Var&&MySQL_Base_Packages_Install&&Install_MariaDB&&Create_Conf&&Init_MariaDB&&Config_MariaDB



}
