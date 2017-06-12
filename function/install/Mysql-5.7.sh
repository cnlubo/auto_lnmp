#!/bin/bash
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @Date:                                   2016-01-25 13:38:17
# @file_name:                              Mysql-5.6.sh
# @Last Modified by:                       ak47
# @Last Modified time:                     2016-02-18 11:23:53
# @Desc                                    mysql-5.6 install scripts
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
port                                = $MysqlPort
socket                              = $MysqlRunPath/mysql$MysqlPort.sock
default_character_set               = UTF8
no_auto_rehash
password                            =$dbrootpwd

[mysqld]
############### GENERAL############
user                                = $mysql_user
port                                = $MysqlPort
bind_address                        = 0.0.0.0
character_set_server                = UTF8
lower_case_table_names              = 1
join_buffer_size                    = 8M
sort_buffer_size                    = 8M
server_id                           = $server_id
metadata_locks_cache_size           = 2048
metadata_locks_hash_instances       = 16
gtid_mode                           = ON
enforce_gtid_consistency            = ON
max_sp_recursion_depth              = 255
log_bin_trust_function_creators     = ON
explicit_defaults_for_timestamp
################DIR################
basedir                             = $MysqlBasePath
pid_file                            = $MysqlRunPath/mysql$MysqlPort.pid
socket                              = $MysqlRunPath/mysql$MysqlPort.sock
datadir                             = $MysqlDataPath
tmpdir                              = $MysqlTmpPath
slave_load_tmpdir                   = $MysqlTmpPath
innodb_data_home_dir                = $MysqlDataPath
innodb_log_group_home_dir           = $MysqlLogPath
log_bin                             = $MysqlLogPath/mysql_bin
log_bin_index                       = $MysqlLogPath/mysql_bin.index
relay_log_index                     = $MysqlLogPath/relay_log.index
relay_log                           = $MysqlLogPath/relay_bin
log_error                           = $MysqlLogPath/alert.log
slow_query_log_file                 = $MysqlLogPath/slow.log
general_log_file                    = $MysqlLogPath/general.log

################MyISAM#############

################ SAFETY############

max_allowed_packet                  = 16M
max_connect_errors                  = 6000
skip_name_resolve
sql_mode                            = STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_AUTO_VALUE_ON_ZERO,NO_ENGINE_SUBSTITUTION,ONLY_FULL_GROUP_BY
sysdate_is_now                      = 1
innodb_strict_mode                  = 1
skip_ssl
safe_user_create                    = 1
#sql_safe_updates                    = 1
################  BINARY LOGGING##########
expire_logs_days                    = 7
sync_binlog                         = 1
binlog_format                       = row
binlog_rows_query_log_events        = 1
binlog_error_action                 = ABORT_SERVER
############### REPLICATION ###############
read_only                           = 1
skip_slave_start                    = 1
log_slave_updates                   = 1
relay_log_recovery                  = 1
relay_log_purge                     = 1
master_info_repository              = TABLE
relay_log_info_repository           = TABLE
slave_parallel_workers              = 3
master_verify_checksum              = 1
slave_skip_errors                   = ddl_exist_errors
binlog_gtid_simple_recovery         = 1
plugin_load                         = "validate_password.so;rpl_semi_sync_master=semisync_master.so;rpl_semi_sync_slave=semisync_slave.so"
loose_rpl_semi_sync_master_enabled  = 1
loose_rpl_semi_sync_master_timeout  = 3000 # 5 second
loose_rpl_semi_sync_slave_enabled   = 1


############## PASSWORD PLUGIN   ##########
validate_password_policy            = MEDIUM
validate-password                   = FORCE_PLUS_PERMANENT

############## CACHES AND LIMITS ##########
max_connections                    = 1000
max_user_connections               = 998
open_files_limit                   = 65535
slave_net_timeout                  = 60
thread_stack                       = 512K

##################INNODB####################################### #

innodb_data_file_path               = ibdata1:1G;ibdata2:512M:autoextend
innodb_flush_method                 = O_DIRECT
innodb_log_file_size                = 512M
innodb_buffer_pool_size             =`expr $RamTotalG \* 80 / 102400 `G
innodb_file_format                  = Barracuda
innodb_file_format_max              = Barracuda
innodb_log_buffer_size              = 64M
innodb_lru_scan_depth               = 2048
innodb_purge_threads                = 4
innodb_sort_buffer_size             = 2M
innodb_write_io_threads             = $CpuProNum
innodb_buffer_pool_load_at_startup  = 1
innodb_buffer_pool_dump_at_shutdown = 1
innodb_lock_wait_timeout            = 5
innodb_io_capacity                  = 200
innodb_undo_tablespaces             = 3
#innodb_print_all_deadlocks          = 1
#innodb_strict_mode                  = 1
################# LOGGING####################### #
slow_query_log                         = 1
general_log                            = 0
long_query_time                        = 3
min_examined_row_limit                 = 100
transaction_isolation                  = READ-COMMITTED


EOF

}

INSTALL_MysqlDB()
{
    echo "${CMSG}[Mysql${mysql_5_7_version} Installing] **************************************************>>${CEND}";
    src_url=http://cdn.mysql.com//Downloads/MySQL-5.7/mysql-$mysql_5_7_version.tar.gz
    Download_src
    cd $script_dir/src
    [ -d mysql-$mysql_5_7_version ] && rm -rf mysql-$mysql_5_7_version
    tar -zxf mysql-$mysql_5_7_version.tar.gz;
    cd mysql-$mysql_5_7_version;

    cmake -DCMAKE_INSTALL_PREFIX=$MysqlBasePath \
    -DDEFAULT_CHARSET=utf8mb4 \
    -DDEFAULT_COLLATION=utf8mb4_general_ci \
    -DENABLED_LOCAL_INFILE=1 \
    -DWITH_BOOST=$script_dir/src/boost_1_59_0 \
    -DBUILD_CONFIG=mysql_release \
    -DWITH_INNODB_MEMCACHED=ON \
    -DWITH_MYSQLD_LDFLAGS='-ljemalloc'


    make -j$CpuProNum;
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
    if ( [ $OS == "Ubuntu" ] && [ $Ubuntu_version == 15 ] ) || ( [ $OS == "CentOS" ] && [ $CentOS_RHEL_version == 7 ] );then
        #-o [$OS="CentOS" -a CentOS_RHEL_version=7];then
        #support Systemd
        [ -L /lib/systemd/system/mysql$MysqlPort.service ] && rm -f /lib/systemd/system/mysql$MysqlPort.service;
        cp $script_dir/template/mysql.service /lib/systemd/system/mysql$MysqlPort.service;
        sed  -i ':a;$!{N;ba};s#PIDFile=#PIDFile='''$MysqlOptPath/run/mysql$MysqlPort.pid'''#' /lib/systemd/system/mysql$MysqlPort.service
        mycnf=''$MysqlOptPath/etc/my$MysqlPort.cnf''
        sed -i ''s#@MysqlBasePath#$MysqlBasePath#g'' /lib/systemd/system/mysql$MysqlPort.service
        sed -i ''s#@defaults-file#$mycnf#g'' /lib/systemd/system/mysql$MysqlPort.service
        systemctl enable mysql$MysqlPort.service
    else
        [ -L /etc/init.d/mysql$MysqlPort ] && rm -f /etc/init.d/mysql$MysqlPort;
        ln -s $MysqlOptPath/init.d/mysql$MysqlPort /etc/init.d/mysql$MysqlPort;
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
    service mysql$MysqlPort start;
    rm -rf $script_dir/src/mysql-$mysql_5_6_version;

}

MysqlDB_Install_Main(){

    MySQL_Var&&MYSQL_BASE_PACKAGES_INSTALL&&INSTALL_MysqlDB
    #&&Create_Conf&&INIT_MySQL_DB


}
