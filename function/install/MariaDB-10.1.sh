#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @Date:                                   2016-01-25 13:38:17
# @file_name:                              MariaDB-10.1.sh
# @Last Modified by:                       ak47
# @Last Modified time:                     2016-02-18 11:23:53
# @Desc                                    mariadb-10.0 install scripts
#----------------------------------------------------------------------------

Create_Conf() {

    HostIP=`python $script_dir/py2/get_local_ip.py`
    a=`echo $HostIP|cut -d\. -f1`
    b=`echo $HostIP|cut -d\. -f2`
    c=`echo $HostIP|cut -d\. -f3`
    d=`echo $HostIP|cut -d\. -f4`
    pt=`echo $MysqlPort % 256 | bc`
    server_id=`expr $b \* 256 \* 256 \* 256 + $c \* 256 \* 256 + $d \* 256 + $pt`
    cat > $MysqlConfigPath/my$MysqlPort.cnf << EOF
[mysql]
############## CLIENT #############
port                               = $MysqlPort
socket                             = $MysqlRunPath/mysql$MysqlPort.sock
default_character_set              = UTF8
no_auto_rehash
password=$dbrootpwd

[mysqld]
############### GENERAL############
user                               = $mysql_user
port                               = $MysqlPort
default_storage_engine             = InnoDB
bind_address                       = 0.0.0.0
character_set_server               = UTF8
old_passwords                      = 0
performance_schema                 = 1
connect_timeout                    = 8
lower_case_table_names             = 1
join_buffer_size                   = 8M
sort_buffer_size                   = 8M
server_id                          = $server_id
thread_handling                    = pool-of-threads  #open thread pool only support by percona and mariadb
max_sp_recursion_depth             = 255
log_bin_trust_function_creators    = ON

################DIR################
basedir                            = $MysqlBasePath
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
binlog_checksum                    = CRC32
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
innodb_buffer_pool_size            =`expr $RamTotalG \* 70 / 102400 `G
innodb_file_format                 = Barracuda
innodb_log_buffer_size             = 64M
innodb_lru_scan_depth              = 2048
innodb_online_alter_log_max_size   = 2G
innodb_purge_threads               = 4
innodb_sort_buffer_size            = 2M
innodb_thread_concurrency          = 10    #A recommended value is 2 times the number of CPUs plus the number of disk
innodb_use_native_aio              = 0
innodb_write_io_threads            = $CpuProNum

################# LOGGING####################### #
log_queries_not_using_indexes      = 1
slow_query_log                     = 1
general_log                        = 0
log_slow_admin_statements          = 1
long_query_time                    = 1
transaction_isolation              = READ-COMMITTED


EOF

}

INSTALL_MariaDB()
{
    echo "${CMSG}[mariadb${mariadb_10_1_version} Installing] **************************************************>>${CEND}";
    src_url=https://mirrors.tuna.tsinghua.edu.cn/mariadb//mariadb-$mariadb_10_1_version/source/mariadb-$mariadb_10_1_version.tar.gz
    Download_src
    cd $script_dir/src
    [ -d mariadb-$mariadb_10_1_version ] && rm -rf mariadb-$mariadb_10_1_version
    tar -zxf mariadb-$mariadb_10_1_version.tar.gz;
    cd mariadb-$mariadb_10_1_version;

    cmake -DCMAKE_INSTALL_PREFIX=$MysqlBasePath \
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DWITH_EXTRA_CHARSETS=all \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_XTRADB_STORAGE_ENGINE=1 \
    -DENABLED_LOCAL_INFILE=1 \
    -DBUILD_CONFIG=mysql_release \
    -DWITH_INNODB_MEMCACHED=ON \
    -DENABLE_GPROF=1 \
    -DWITH_SSL=bundled \
    -DWITH_EMBEDDED_SERVER=1 \
    -DCMAKE_EXE_LINKER_FLAGS="-ljemalloc" \
    -DWITH_SAFEMALLOC=OFF
    #make -j$CpuCores;
    make; -j2
    make install;

    chown -R mysql:mysql $MysqlBasePath;

    [ -L /usr/bin/mysql ] && rm -f /usr/bin/mysql;
    ln -s $MysqlBasePath/bin/mysql /usr/bin/mysql;
    [ -L /usr/bin/mysqladmin ] && rm -f /usr/bin/mysqladmin;
    ln -s $MysqlBasePath/bin/mysqladmin /usr/bin/mysqladmin;
    echo PATH='$PATH:'$MysqlBasePath/bin >>/etc/profile
    echo export PATH >>/etc/profile
    echo export 'MYSQL_PS1="\\u@\\h:\\d \\r:\\m:\\s>"' >>/etc/profile
    source /etc/profile

}
INIT_MySQL_DB(){

    #初始化创建数据库
    for path in $MysqlLogPath $MysqlConfigPath $MysqlDataPath $MysqlTmpPath $MysqlRunPath;do
        [ ! -d $path ] && mkdir -p $path
        chmod 755 $path;
        chown -R mysql:mysql $path;
    done
    chown -R mysql.mysql $MysqlConfigPath/
    chmod 777 $MysqlBasePath/scripts/mysql_install_db
    echo "${CMSG}[Initialization Database] **************************************************>>${CEND}"
    $MysqlBasePath/scripts/mysql_install_db --user=mysql --defaults-file=$MysqlConfigPath/my$MysqlPort.cnf --basedir=$MysqlBasePath --datadir=$MysqlDataPath;
    mkdir -p $MysqlOptPath/init.d
    chown -R mysql.mysql $MysqlOptPath/
    cp $script_dir/template/mysql_start $MysqlOptPath/init.d/mysql$MysqlPort;
    chmod 775 $MysqlOptPath/init.d/mysql$MysqlPort;
    chown -R mysql.mysql $MysqlOptPath/init.d/
    sed  -i ':a;$!{N;ba};s#basedir=#basedir='''$MysqlBasePath'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    sed  -i ':a;$!{N;ba};s#datadir=#datadir='''$MysqlDataPath'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    sed  -i ':a;$!{N;ba};s#conf=#conf='''$MysqlConfigPath/my$MysqlPort.cnf'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    sed  -i ':a;$!{N;ba};s#mysql_user=#mysql_user='''$mysql_user'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    sed  -i ':a;$!{N;ba};s#mysqld_pid_file_path=#mysqld_pid_file_path='''$MysqlRunPath/mysql$MysqlPort\.pid'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    #if ([ $OS="Ubuntu" ]&&[ Ubuntu_version=15 ])||([ $OS="CentOS" ]&&[ CentOS_RHEL_version=7 ]);then
    if ( [ $OS == "Ubuntu" ] && [ $Ubuntu_version == 15 ] ) || ( [ $OS == "CentOS" ] && [ $CentOS_RHEL_version == 7 ] );then
        #support Systemd
        [ -L /lib/systemd/system/mariadb.service ] && rm -f /lib/systemd/system/mariadb.service;
        cp $script_dir/template/mariadb.service /lib/systemd/system/mariadb.service;
        sed  -i ':a;$!{N;ba};s#PIDFile=#PIDFile='''$MysqlOptPath/run/mysql$MysqlPort.pid'''#' /lib/systemd/system/mariadb.service
        mycnf=''$MysqlOptPath/etc/my$MysqlPort.cnf''
        sed -i ''s#@MysqlBasePath#$MysqlBasePath#g'' /lib/systemd/system/mariadb.service
        sed -i ''s#@defaults-file#$mycnf#g'' /lib/systemd/system/mariadb.service
        systemctl enable mariadb.service
    else
        [ -L /etc/init.d/mysql$MysqlPort ] && rm -f /etc/init.d/mariadb;
        ln -s $MysqlOptPath/init.d/mysql$MysqlPort /etc/init.d/mariadb;
    fi;
    echo "${CMSG}[config db ] **************************************************>>${CEND}";
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
    echo "${CMSG}[config db ] **************************************************>>${CEND}";
    service mariadb start;
    rm -rf $script_dir/src/mariadb-$mariadb_10_0_version;

}

MariaDB_Install_Main(){

    MySQL_Var&&MYSQL_BASE_PACKAGES_INSTALL&&INSTALL_MariaDB&&Create_Conf&&INIT_MySQL_DB


}
