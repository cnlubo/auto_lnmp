#!/bin/bash
#---------------------------------------------------------------------------
#   Author:                lubo
#   E-mail:                454331202@qq.com
#   LastModified:          2015-12-02 10:28:34
#   Filename:              mysql_in.sh
#   Desc:
#
#---------------------------------------------------------------------------
#
SYSTEM_CHECK(){
    CpuProNum=$(cat /proc/cpuinfo |grep 'processor'|wc -l)
    RamTotalG=`awk '/MemTotal/{memtotal=$2}END{print int(memtotal/1024)}'  /proc/meminfo`
    RamSwapG=`awk '/SwapTotal/{swtotal=$2}END{print int(swtotal/1024)}'  /proc/meminfo`
    RamSumG=`awk '/MemTotal/{memtotal=$2}/SwapTotal/{swtotal=$2}END{print int((memtotal+swtotal)/1024)}'  /proc/meminfo`
    [[ "$SysName" == '' ]] && echo '[Error] Your system is not supported this script' && exit;
    [ $RamTotalG -lt '1000' ] && echo -e "[Error] Not enough memory install mysql.\nThis script need memory more than 1G.\n" && SELECT_SOFE_INSTALL;
}

MySQL_Version(){
    case $var in
        "MySQL5.6")
            {
                MysqlVersion="mysql-5.6.27"
                MysqlLine="http://cdn.mysql.com/Downloads/MySQL-5.6"
                MysqlFile=$MysqlVersion
            }
        ;;
        "Percona_Server5.6")
            {
                percona_version="5.6.27-75.0"
                MysqlVersion="Percona-Server-$percona_version"
                MysqlFile="percona-server-$percona_version"
                MysqlLine="http://www.percona.com/downloads/Percona-Server-5.6/$MysqlVersion/source/tarball"
            }
        ;;
        "MariaDB10")
            {
                MysqlVersion="mariadb-10.0.22"
                MysqlLine="http://ftp.osuosl.org/pub/mariadb/$MysqlVersion/source/"
                MysqlFile=$MysqlVersion
            }
        ;;
        *)
        echo "unknow version";;
    esac
    MysqlDownloadFile=${MysqlLine}/${MysqlFile}.tar.gz
}
MySQL_Var(){

    case  $var in
        "CreateDbInstance")
            {
                declare -i i=1
                while ((i<=3))
                do
                    read -p "Please input MySQL BaseDirectory:" MysqlBasePath
                    $MysqlBasePath/bin/mysqld --help >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        break
                    else
                        echo '[MySQL BaseDirectory not correct ]****>>'
                        if [ $i -eq 3 ]; then
                            exit 0
                        fi
                    fi
                    let ++i
                done
                i=1
                while ((i<=3))
                do
                    read -p "Please input MySQL Database Directory:" MysqlOptPath
                    if [ ! -d "$MysqlOptpath" ]; then
                        break
                    else
                        echo '[Directory have exists  ]****>>'
                        if [ $i -eq 3 ]; then
                            exit 0
                        fi
                    fi
                    let ++i
                done
                #read -p "Please input MySQL Database Directory:" MysqlOptPath
                MysqlOptPath="${MysqlOptPath:=/opt/mybase}"
                MysqlDataPath="$MysqlOptPath/data"
                MysqlLogPath="$MysqlOptPath/log"
                MysqlConfigPath="$MysqlOptPath/etc"
                MysqlTmpPath="$MysqlOptPath/tmp"
                MysqlRunPath="$MysqlOptPath/run"
                read -p "Please input MYSQL's password:" MysqlPass
                MysqlPass="${MysqlPass:=""}"
                read  -p "Please input Port:" MysqlPort
                MysqlPort="${MysqlPort:=""}"
            }
        ;;
        "MySQL5.6"|"Percona_Server5.6"|"MariaDB10")
            {
                read -p "Please input Port(Default:3306):" MysqlPort
                MysqlPort="${MysqlPort:=3306}"
                read -p "Please input MySQL BaseDirectory(default:/opt/mysql)" MysqlBasePath
                MysqlBasePath="${MysqlBasePath:=/opt/mysql}"
                read -p "Please input MySQL Database Directory(default:/u01/mybase/my$MysqlPort)" MysqlOptPath
                MysqlOptPath="${MysqlOptPath:=/u01/mybase/my$MysqlPort}"
                MysqlDataPath="$MysqlOptPath/data"
                MysqlLogPath="$MysqlOptPath/log"
                MysqlConfigPath="$MysqlOptPath/etc"
                MysqlTmpPath="$MysqlOptPath/tmp"
                MysqlRunPath="$MysqlOptPath/run"
                read -p "Please input MYSQL's password:" MysqlPass
                MysqlPass="${MysqlPass:=""}"
            }
        ;;
        *)
        echo "unknow var";;
    esac

    Mysql_user="mysql"
}

MYSQL_BASE_PACKAGES_INSTALL(){

    if [ "$SysName" == 'centos' ] ;then
        echo '[remove old mysql] **************************************************>>';
        yum -y remove mysql-server mysql;
        BasePackages="wget gcc gcc-c++ autoconf libxml2-devel zlib-devel libjpeg-devel libpng-devel glibc-devel glibc-static glib2-devel  bzip2-devel openssl-devel ncurses-devel bison cmake make libaio-devel";
    else
        apt-get -y remove mysql-client mysql-server mysql-common mariadb-server ;
        BasePackages="wget gcc g++ cmake libjpeg-dev libxml2 libxml2-dev libpng-dev autoconf make bison zlibc bzip2 libncurses5-dev libncurses5 libssl-dev axel libaio-dev";
    fi
    INSTALL_BASE_PACKAGES $BasePackages

    if [ -f "/usr/local/lib/libjemalloc.so" ];then
        echo -e "\033[31mjemalloc having install! \033[0m"
    else
        cd $DownloadTmp
        wget http://www.canonware.com/download/jemalloc/jemalloc-4.0.4.tar.bz2
        tar xjf jemalloc-4.0.4.tar.bz2
        cd jemalloc-4.0.4
        ./configure
        make && make install
        if [ -f "/usr/local/lib/libjemalloc.so" ];then

            echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
            ldconfig
        else
            echo -e "\033[31mjemalloc install failed, Please contact the author! \033[0m"
            kill -9 $$
        fi
        cd ..
        rm -rf jemalloc-4.0.4
        rm -rf jemalloc-4.0.4.tar.bz2
    fi
}

INSTALL_MySQL()
{
    cd $DownloadTmp
    echo "[${MysqlVersion} Installing] **************************************************>>";
    if [ "$SysName" == 'centos' ] ;then
        [ ! -f ${MysqlFile}.tar.gz ] && wget -c  ${MysqlLine}/${MysqlFile}.tar.gz
    else
        [ ! -f ${MysqlFile}.tar.gz ] && axel -n5 ${MysqlLine}/${MysqlFile}.tar.gz
    fi
    [ -d $MysqlFile ] && rm -rf $MysqlFile
    tar -zxf $MysqlFile.tar.gz;
    cd $MysqlFile;
    grep mysql /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd mysql;
    fi
    id mysql >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g mysql  -M -s /sbin/nologin mysql;
    fi
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
    make -j4;
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

Create_Conf() {

    #create group and user
    grep mysql /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd mysql;
    fi
    id mysql >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g mysql  -M -s /sbin/nologin mysql;
    fi
    #create dir
    for path in $MysqlLogPath $MysqlConfigPath $MysqlDataPath $MysqlTmpPath $MysqlRunPath;do
        [ ! -d $path ] && mkdir -p $path
        chmod 755 $path;
        chown -R mysql:mysql $path;
    done
    #create mysql cnf file
    HostIP=`python $Python2Path/get_local_ip.py`
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
password=$MysqlPass

[mysqld]
############### GENERAL############
user                               = $Mysql_user
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
#master_info_repository            = TABLE # only for 5.6
#relay_log_info_repository         = TABLE # only for 5.6
slave_sql_verify_checksum          = 1     # for 5.6
#max_binlog_size                   = 512M (system default 1G)
#gtid_mode                         = ON   #(MariaDB and MySQL have different GTID implementations.)
#enforce_gtid_consistency          = ON   #(MariaDB and MySQL have different GTID implementations.)
sync_master_info                   = 1
sync_relay_log                     = 1
sync_relay_log_info                = 1
relay_log_recovery                 = 1

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
innodb_buffer_pool_size            =`expr $RamTotalG \* 50 / 102400 `G
innodb_file_format                 = Barracuda
#innodb_file_io_threads             = 4 # only for windows
#innodb_flush_neighbors             = 0 # quite useful for ssd
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
INIT_MySQL_DB(){
    #初始化创建数据库
    for path in $MysqlLogPath $MysqlConfigPath $MysqlDataPath $MysqlTmpPath $MysqlRunPath;do
        [ ! -d $path ] && mkdir -p $path
        chmod 755 $path;
        chown -R mysql:mysql $path;
    done
    #    HostIP=python $Python2Path/get_local_ip.py
    #     a=`echo $HostIP|cut -d\. -f1`
    #     b=`echo $HostIP|cut -d\. -f2`
    #     c=`echo $HostIP|cut -d\. -f3`
    #     d=`echo $HostIP|cut -d\. -f4`
    #     pt=`echo $MysqlPort % 256 | bc`
    #     server_id=`expr $b \* 256 \* 256 \* 256 + $c \* 256 \* 256 + $d \* 256 + $pt`
    #     cat > $MysqlConfigPath/my$MysqlPort.cnf << EOF
    # [mysql]
    # ############## CLIENT #############
    # port                               = $MysqlPort
    # socket                             = $MysqlRunPath/mysql$MysqlPort.sock
    # default_character_set              = UTF8
    # no_auto_rehash
    # password=$MysqlPass

    # [mysqld]
    # ############### GENERAL############
    # user                               = $Mysql_user
    # port                               = $MysqlPort
    # default_storage_engine             = InnoDB
    # bind_address                       = 0.0.0.0
    # character_set_server               = UTF8
    # old_passwords                      = 0
    # performance_schema                 = 1
    # connect_timeout                    = 8
    # local_infile                       = 1
    # lower_case_table_names             = 1
    # join_buffer_size                   = `expr $RamTotal \* 2 / 1000`M
    # sort_buffer_size                   = `expr $RamTotal \* 2 / 1000`M
    # read_rnd_buffer_size               = 128K
    # interactive_timeout                = 28800
    # wait_timeout                       = 28800
    # metadata_locks_cache_size          = 10240 # for 5.6
    # metadata_locks_hash_instances      = 64    # for 5.6
    # net_read_timeout                   = 30
    # net_write_timeout                  = 60
    # server_id                          = $server_id

    # ################DIR################
    # basedir                            = $MysqlBasePath
    # pid_file                           = $MysqlRunPath/mysql$MysqlPort.pid
    # socket                             = $MysqlRunPath/mysql$MysqlPort.sock
    # datadir                            = $MysqlDataPath
    # tmpdir                             = $MysqlTmpPath
    # slave_load_tmpdir                  = $MysqlTmpPath
    # innodb_data_home_dir               = $MysqlDataPath
    # innodb_log_group_home_dir          = $MysqlLogPath
    # log_bin                            = $MysqlLogPath/mysql_bin
    # log_bin_index                      = $MysqlLogPath/mysql_bin.index
    # relay_log_index                    = $MysqlLogPath/relay_log.index
    # relay_log                          = $MysqlLogPath/relay_bin
    # log_error                          = $MysqlLogPath/alert.log
    # slow_query_log_file                = $MysqlLogPath/slow.log
    # general_log_file                   = $MysqlLogPath/general.log
    # ################MyISAM#############
    # concurrent_insert                  = 2
    # delayed_insert_timeout             = 300
    # key_buffer_size                    = 32M
    # myisam_recover-options             = FORCE,BACKUP
    # myisam_sort_buffer_size            = 64M

    # ################ SAFETY############
    # #max_allowed_packet                =`expr $RamTotal \* 2 / 1000`M
    # max_allowed_packet                 = 16M
    # max_connect_errors                 = 65536
    # skip_name_resolve
    # sql_mode                           = STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_AUTO_VALUE_ON_ZERO,NO_ENGINE_SUBSTITUTION,ONLY_FULL_GROUP_BY
    # sysdate_is_now                     = 1
    # innodb                             = FORCE
    # innodb_strict_mode                 = 1
    # skip_ssl
    # safe_user_create                   = 1
    # #explicit_defaults_for_timestamp    = TRUE

    # ################  BINARY LOGGING##########
    # expire_logs_days                   = 7
    # sync_binlog                        = 1
    # binlog_cache_size                  = 32K
    # binlog_checksum                    = CRC32 # for 5.6
    # binlog_format                      = row
    # #binlog_rows_query_log_events       = 1

    # ############### REPLICATION ###############
    # read_only                          = 1
    # skip_slave_start                   = 1
    # log_slave_updates                  = 1
    # #master_info_repository             = TABLE # for 5.6
    # #relay_log_info_repository          = TABLE # for 5.6
    # slave_sql_verify_checksum          = 1     # for 5.6
    # #max_binlog_size                    = `expr $(df -m $MysqlLogPath |awk 'NR==2{printf "%s\n",$4}') / 10000`M
    # max_binlog_size                    = 512M
    # #gtid_mode                          = ON
    # #enforce_gtid_consistency           = ON   # for 5.6
    # sync_master_info                   = 1
    # sync_relay_log                     = 1
    # sync_relay_log_info                = 1

    # ############## CACHES AND LIMITS ##########
    # tmp_table_size                     = 32M
    # max_heap_table_size                = `expr $RamTotal / 100`M
    # #max_heap_table_size               = 32M
    # query_cache_type                   = 0
    # query_cache_size                   = 0
    # query_cache_limit                  = 1M     # for 5.6
    # query_cache_min_res_unit           = 1K     # for 5.6
    # max_connections                    = `expr $FileMax \* $CpuNum \* 2 / $RamTotal`
    # #max_connections                   = 8192   # 100
    # max_user_connections               = `expr $FileMax \* $CpuNum \* 2 / $RamTotal \- 10`   #8000
    # thread_cache_size                  = 256
    # open_files_limit                   = 65535
    # table_definition_cache             = 65536
    # #table_open_cache                   = `expr $RamTotal + $RamSwap`
    # table_open_cache                     =524288
    # #table_open_cache                   = 10000
    # slave_net_timeout                  = 4
    # thread_stack                       = 512K
    # ##################INNODB####################################### #

    # innodb_adaptive_flushing           = 1
    # #innodb_additional_mem_pool_size    = 20M    #5.6 not use this canshu
    # innodb_buffer_pool_instances       = 8
    # innodb_change_buffering            = inserts
    # innodb_data_file_path              = ibdata1:512M;ibdata2:16M:autoextend
    # innodb_flush_method                = O_DIRECT
    # innodb_log_files_in_group          = 2 #4
    # innodb_log_file_size               = 512M
    # innodb_flush_log_at_trx_commit     = 1
    # innodb_file_per_table              = 1
    # #innodb_buffer_pool_size            =`expr $RamTotal / 100`M
    # innodb_buffer_pool_size            = 1G
    # innodb_file_format                 = Barracuda
    # innodb_file_io_threads             = 4 # for 5.6 not use for linux
    # innodb_flush_neighbors             = 0 # for 5.6
    # #innodb_io_capacity                 = 200
    # innodb_io_capacity                 = `expr $FileMax \* $CpuNum / $RamTotal`
    # innodb_lock_wait_timeout           = 5
    # innodb_log_buffer_size             = 64M
    # innodb_lru_scan_depth              = 2048 # for 5.6
    # innodb_max_dirty_pages_pct         = 60
    # innodb_old_blocks_time             = 1000
    # innodb_online_alter_log_max_size   = 2G # for 5.6
    # innodb_open_files                  = `expr $FileMax \* $CpuNum / $RamTotal`
    # #innodb_open_files                  = 60000
    # innodb_print_all_deadlocks         = 1
    # innodb_purge_threads               = 1 #4
    # innodb_read_ahead_threshold        = 0 #56?
    # innodb_read_io_threads             = $CpuNum
    # innodb_rollback_on_timeout         = 0
    # innodb_sort_buffer_size            = 2M # for 5.6
    # innodb_spin_wait_delay             = 6
    # innodb_stats_on_metadata           = 0
    # innodb_sync_array_size             = 256 # for 5.6
    # innodb_sync_spin_loops             = 30  # for 5.6
    # innodb_thread_concurrency          = 64
    # innodb_use_native_aio              = 0
    # innodb_write_io_threads            = $CpuNum
    # innodb_support_xa                  = 1
    # innodb_autoinc_lock_mode           = 1

    # ################# LOGGING####################### #
    # log_queries_not_using_indexes      = 1
    # slow_query_log                     = 1
    # general_log                        = 0
    # log_slow_admin_statements          = 1
    # long_query_time                    = 2
    # transaction_isolation              = READ-COMMITTED

    # [mysqld_safe]
    # open_files_limit                   = `expr $FileMax / $CpuNum / 100`

    # EOF

    chown -R mysql.mysql $MysqlConfigPath/
    chmod 777 $MysqlBasePath/scripts/mysql_install_db
    echo '[Initialization Database] **************************************************>>'
    $MysqlBasePath/scripts/mysql_install_db --user=mysql --defaults-file=$MysqlConfigPath/my$MysqlPort.cnf --basedir=$MysqlBasePath --datadir=$MysqlDataPath;
    mkdir -p $MysqlOptPath/init.d
    chown -R mysql.mysql $MysqlOptPath/
    cp $TemplatePath/mysql_start $MysqlOptPath/init.d/mysql$MysqlPort;
    chmod 775 $MysqlOptPath/init.d/mysql$MysqlPort;
    chown -R mysql.mysql $MysqlOptPath/init.d/
    sed  -i ':a;$!{N;ba};s#basedir=#basedir='''$MysqlBasePath'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    sed  -i ':a;$!{N;ba};s#datadir=#datadir='''$MysqlDataPath'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    sed  -i ':a;$!{N;ba};s#conf=#conf='''$MysqlConfigPath/my$MysqlPort.cnf'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    sed  -i ':a;$!{N;ba};s#mysql_user=#mysql_user='''$Mysql_user'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    sed  -i ':a;$!{N;ba};s#mysqld_pid_file_path=#mysqld_pid_file_path='''$MysqlRunPath/mysql$MysqlPort\.pid'''#' $MysqlOptPath/init.d/mysql$MysqlPort
    #sed  -i ':a;$!{N;ba};s#mysqld_pid_file_path=#mysqld_pid_file_path='''$MysqlRunPath/mysql.pid'''#' $MysqlOptPath/init.d/mysql
    [ -L /etc/init.d/mysql$MysqlPort ] && rm -f /etc/init.d/mysql$MysqlPort;
    ln -s $MysqlOptPath/init.d/mysql$MysqlPort /etc/init.d/mysql$MysqlPort;
    echo '[start db ] **************************************************>>';
    #    service mysql$MysqlPort start;
    $MysqlOptPath/init.d/mysql$MysqlPort start;

}
MySQL_Config()
{

    echo '[Config_MySQL] **************************************************>>'
    $MysqlBasePath/bin/mysqladmin -S $MysqlRunPath/mysql$MysqlPort.sock password $MysqlPass;
    rm -rf $MysqlDataPath/test;
    mysql -uroot -S $MysqlRunPath/mysql$MysqlPort.sock -p$MysqlPass <<EOF
    USE mysql;
    DELETE FROM user WHERE user='';
    UPDATE user set password=password('$MysqlPass') WHERE user='root';
    DELETE FROM user WHERE not (user='root');
    DROP USER ''@'%';
    FLUSH PRIVILEGES;
EOF

}
MySQL_Tools_Install()
{
    echo '[installing Percona Toolkit for MySQL] **************************************************>>';
    yum -y install install perl-DBI perl-DBD-MySQL;
    cd /usr/local/src;
    [ ! -f 'percona-toolkit_'${PerconaToolkitVersion}.tar.gz ] && wget -c ${PerconaToolkitLine}/'percona-toolkit_'${PerconaToolkitVersion}.tar.gz                                                                                |~
    [ -d 'percona-toolkit-'$PerconaToolkitVersion ] && rm -rf 'percona-toolkit-'$PerconaToolkitVersion;
    tar -zxf 'percona-toolkit_'$PerconaToolkitVersion.tar.gz;
    cd 'percona-toolkit-'$PerconaToolkitVersion;
    perl Makefile.PL;
    make && make install;

}
MySQL_Install_Main(){

     SYSTEM_CHECK
     echo $RamSumG

    echo "----------------------------------------------------------------"
    declare -a VarLists
    # echo "[Notice] Which Soft are you want to install:"
    VarLists=("Back" "MySQL5.6" "Percona_Server5.6" "MariaDB10" "Percona-toolkit" "CreateDbInstance")
    select var in ${VarLists[@]} ;do
        # case $var in
        #     "Install MariaDB 10")
        #         MySQL_Var&&MySQL_Base_Packages_Install&&INSTALL_MySQL&&INIT_MySQL_DB&&MySQL_Config
        #         #&&MySQL_Tools_Install
        #         echo "[OK] ${MysqlFile} install completed.";;
        #     "Install Mysql Instance")
        #         MySQL_Var&&INIT_MySQL_DB&&MySQL_Config
        #         echo "[OK]";;
        #     "Exit")
        #        # exit 0;;
        #        SELECT_RUN_SCRIPT;;
        #     *)
        #         Install_Main;;
        # esac
        # break
        case $var in
            ${VarLists[1]})
                
            MySQL_Version&&MySQL_Var&&MYSQL_BASE_PACKAGES_INSTALL&&Create_Conf&&INSTALL_MySQL&&INIT_MySQL_DB&&MySQL_Config;;
            ${VarLists[2]})
                #SOURCE_SCRIPT $FunctionPath/install/tomcat_install.sh;
                #TOMCAT_VAR && SELECT_TOMCAT_FUNCTION;;
                #MYSQL_VAR && MYSQL_BASE_PACKAGES_INSTALL && INSTALL_MYSQL;;
             MySQL_Version&&MySQL_Var&&MYSQL_BASE_PACKAGES_INSTALL&&Create_Conf&&INSTALL_MySQL&&INIT_MySQL_DB&&MySQL_Config;;
            ${VarLists[3]})

            MySQL_Version&&MySQL_Var&&MYSQL_BASE_PACKAGES_INSTALL&&Create_Conf&&INSTALL_MySQL&&INIT_MySQL_DB&&MySQL_Config;;
            #MySQL_Version&&MySQL_Var&&Create_Conf&&INIT_MySQL_DB&&MySQL_Config;;

            ${VarLists[4]})
                #SOURCE_SCRIPT $FunctionPath/install/puppet_install.sh
                #PUPPET_VAR && SELECT_PUPPET_FUNCTION;;
                #MYSQL_VAR && MYSQL_BASE_PACKAGES_INSTALL && INSTALL_MYSQL;;
                #MySQL_Tools_Install;;
            MySQL_Version&&MySQL_Var;;
            ${VarLists[5]})
                #SOURCE_SCRIPT $FunctionPath/install/puppet_install.sh
                #PUPPET_VAR && SELECT_PUPPET_FUNCTION;;
                #MYSQL_VAR && MYSQL_BASE_PACKAGES_INSTALL && INSTALL_MYSQL;;
                #MySQL_Var&&INIT_MySQL_DB&&MySQL_Config;;
            MySQL_Version&&MySQL_Var;;
            ${VarLists[0]})
            SELECT_SOFE_INSTALL;;
            *)
            MySQL_Install_Main;;
        esac
        break
    done
    MySQL_Install_Main
}
MySQL_Install_Main



