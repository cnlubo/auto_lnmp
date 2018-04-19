#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              PostgreSQL-10.sh
#----------------------------------------------------------------------------

Install_PostgreSQL()
{
    INFO_MSG "[PostgreSQL${postgresql_install_version:?} Installing]"
    cd ${script_dir:?}/src
    # shellcheck disable=SC2034
    src_url=https://ftp.postgresql.org/pub/source/v$postgresql_install_version/postgresql-$postgresql_install_version.tar.gz
    [ ! -f postgresql-$postgresql_install_version.tar.gz ] && Download_src
    [ -d postgresql-$postgresql_install_version ] && rm -rf postgresql-$postgresql_install_version
    tar -zxf postgresql-$postgresql_install_version.tar.gz && cd postgresql-$postgresql_install_version
    [ -d ${PgsqlBasePath:?} ] && rm -rf $PgsqlBasePath

    ./configure --prefix=${PgsqlBasePath:?} \
        --with-pgport=5432 \
        --with-perl \
        --with-python \
        --with-tcl \
        --with-openssl \
        --with-includes="${openssl11_install_dir:?}/include ${zlib_install_dir:?}/include" \
        --with-libraries="${openssl11_install_dir:?}/lib ${zlib_install_dir:?}/lib" \
        --with-pam \
        --with-ldap \
        --with-libxml \
        --with-libxslt \
        --enable-thread-safety \
        --enable-dtrace \
        --enable-debug  \
        --with-wal-blocksize=16 \
        --with-blocksize=16
    make -j${CpuProNum:?} && make install
    # contrib
    #cd contrib && make -j${CpuProNum:?} && make install
    # all doc all contrib
    gmake world && gmake install-world


}
Init_PostgreSQL(){

    INFO_MSG "[setting envionment variables !!! ]"
    #echo ${pgsql_user:?}
    chown -R ${pgsql_user:?}:${pgsql_user:?} ${PgsqlBasePath:?}
    #echo ${PgsqlBasePath:?}
    # 设置环境变量
    if [ -f /home/${default_user:?}/.zshrc ]; then
        echo export "PATH=$PATH:${PgsqlBasePath:?}/bin" >>/home/${default_user:?}/.zshrc
        echo export "PGHOME=${PgsqlBasePath:?}" >>/home/${default_user:?}/.zshrc
        echo export "PGHOST=${PgsqlOptPath:?}/run" >>/home/${default_user:?}/.zshrc
        echo export "PGDATA=${PgsqlOptPath:?}/data" >>/home/${default_user:?}/.zshrc
        su ${pgsql_user:?} && source /home/${default_user:?}/.zshrc && sudo su - && cd ${script_dir:?}/src
    else
        echo export "PATH=$PATH:${PgsqlBasePath:?}/bin" >>/home/${pgsql_user:?}/.bash_profile
        echo export "PGHOME=${PgsqlBasePath:?}" >>/home/${pgsql_user:?}/.bash_profile
        echo export "PGHOST=${PgsqlOptPath:?}/run" >>/home/${pgsql_user:?}/.bash_profile
        echo export "PGDATA=${PgsqlOptPath:?}/data" >>/home/${pgsql_user:?}/.bash_profile
        # source /home/${pgsql_user:?}/.bash_profile
    fi

    INFO_MSG "[Initialization default Database ]"
    # ./initdb --encoding=UTF-8  --local=zh_CN.UTF8 --username=postgres --pwprompt --pgdata=/opt/PostgreSQL/data/
    sudo -u ${pgsql_user:?} -c ${PgsqlBasePath:?}/bin/initdb --encoding=UTF-8 --pgdata=${PgsqlOptPath:?}/data

}

# Init_PostgreSQL(){
#
#     chown -R mysql.mysql $MysqlConfigPath/
#     chmod 777 $MysqlBasePath/scripts/mysql_install_db
#     #初始化数据库
#     echo -e "${CMSG}[Initialization Database] **********************************>>${CEND}\n"
#     $MysqlBasePath/scripts/mysql_install_db --user=mysql --defaults-file=$MysqlConfigPath/my$MysqlPort.cnf \
    #         --basedir=$MysqlBasePath --datadir=$MysqlDataPath
#     # 启动脚本
#     mkdir -p ${MysqlOptPath:?}/init.d
#     chown -R mysql.mysql $MysqlOptPath/
#     cp $script_dir/template/mysql_start $MysqlOptPath/init.d/mysql$MysqlPort
#     chmod 775 $MysqlOptPath/init.d/mysql$MysqlPort
#     chown -R mysql.mysql $MysqlOptPath/init.d/
#     sed  -i ':a;$!{N;ba};s#basedir=#basedir='''$MysqlBasePath'''#' $MysqlOptPath/init.d/mysql$MysqlPort
#     sed  -i ':a;$!{N;ba};s#datadir=#datadir='''$MysqlDataPath'''#' $MysqlOptPath/init.d/mysql$MysqlPort
#     sed  -i ':a;$!{N;ba};s#conf=#conf='''$MysqlConfigPath/my$MysqlPort.cnf'''#' $MysqlOptPath/init.d/mysql$MysqlPort
#     sed  -i ':a;$!{N;ba};s#mysql_user=#mysql_user='''$mysql_user'''#' $MysqlOptPath/init.d/mysql$MysqlPort
#     sed  -i ':a;$!{N;ba};s#mysqld_pid_file_path=#mysqld_pid_file_path='''$MysqlRunPath/mysql$MysqlPort\.pid'''#' $MysqlOptPath/init.d/mysql$MysqlPort
#
#     #启动服务脚本
#     if ( [ $OS == "Ubuntu" ] && [ ${Ubuntu_version:?} -ge 15 ] ) || ( [ $OS == "CentOS" ] && [ ${CentOS_RHEL_version:?} -ge 7 ] );then
#         #support Systemd
#         [ -L /lib/systemd/system/mariadb$MysqlPort.service ] && rm -f /lib/systemd/system/mariadb$MysqlPort.service
#         cp $script_dir/template/mariadb.service /lib/systemd/system/mariadb$MysqlPort.service
#         sed  -i ':a;$!{N;ba};s#PIDFile=#PIDFile='''$MysqlOptPath/run/mysql$MysqlPort.pid'''#' /lib/systemd/system/mariadb$MysqlPort.service
#         mycnf=''$MysqlOptPath/etc/my$MysqlPort.cnf''
#         sed -i ''s#@MysqlBasePath#$MysqlBasePath#g'' /lib/systemd/system/mariadb$MysqlPort.service
#         sed -i ''s#@defaults-file#$mycnf#g'' /lib/systemd/system/mariadb$MysqlPort.service
#         systemctl enable mariadb$MysqlPort.service
#         #echo "${CMSG}[starting db ] **************************************************>>${CEND}"
#         #systemctl start mysql$MysqlPort.service #启动数据库
#     else
#         [ -L /etc/init.d/mariadb$MysqlPort ] && rm -f /etc/init.d/mariadb$MysqlPort
#         ln -s $MysqlOptPath/init.d/mysql$MysqlPort /etc/init.d/mariadb$MysqlPort
#         #echo "${CMSG}[starting db ] **************************************************>>${CEND}";
#         #service start mysql$MysqlPort
#     fi
#
# }
# Config_PostgreSQL(){
#
#     echo -e "${CMSG}[config db ] *******************************>>${CEND}\n"
#     $MysqlOptPath/init.d/mysql$MysqlPort start;
#
#     $MysqlBasePath/bin/mysql -S $MysqlRunPath/mysql$MysqlPort.sock -e "grant all privileges on *.* to root@'127.0.0.1' identified by \"$dbrootpwd\" with grant option;"
#     $MysqlBasePath/bin/mysql -S $MysqlRunPath/mysql$MysqlPort.sock -e "grant all privileges on *.* to root@'localhost' identified by \"$dbrootpwd\" with grant option;"
#     mysql -uroot -S $MysqlRunPath/mysql$MysqlPort.sock -p$dbrootpwd <<EOF
#     USE mysql;
#     delete from user where Password='';
#     DELETE FROM user WHERE user='';
#     delete from proxies_priv where Host!='localhost';
#     drop database test;
#     DROP USER ''@'%';
#     reset master;
#     FLUSH PRIVILEGES;
# EOF
#     $MysqlOptPath/init.d/mysql$MysqlPort stop
#     #启动数据库
#     echo -e "${CMSG}[starting db ] ********************************>>${CEND}\n"
#     if ( [ $OS == "Ubuntu" ] && [ $Ubuntu_version -ge 15 ] ) || ( [ $OS == "CentOS" ] && [ $CentOS_RHEL_version -ge 7 ] );then
#         systemctl start mariadb$MysqlPort.service
#     else
#         service start mariadb$MysqlPort
#     fi
#     rm -rf $script_dir/src/mariadb-$mariadb_10_1_version
#     #环境变量设置
#     [ -f /root/.zshrc ] && echo export 'MYSQL_PS1="\\u@\\h:\\d \\r:\\m:\\s>"' >>/root/.zshrc
#     id ${default_user:?} >/dev/null 2>&1
#     if [ $? -eq 0 ]; then
#         [ -f /home/${default_user:?}/.zshrc ] && echo export 'MYSQL_PS1="\\u@\\h:\\d \\r:\\m:\\s>"' >>/home/${default_user:?}/.zshrc
#     fi
#     #echo PATH='$PATH:'$MysqlBasePath/bin >>/etc/profile
#     #echo export PATH >>/etc/profile
#     #echo export 'MYSQL_PS1="\\u@\\h:\\d \\r:\\m:\\s>"' >>/etc/profile
#     #source /etc/profile
#     echo -e "${CRED}[db root user passwd:$dbrootpwd ] *******************************>>${CEND}\n"
#
# }

PostgreSQL_10_Install_Main(){

    PostgreSQL_Var&&PostgreSQL_Base_Packages_Install&&Install_PostgreSQL && Init_PostgreSQL
    #&&Init_PostgreSQL&&Config_PostgreSQL
}
