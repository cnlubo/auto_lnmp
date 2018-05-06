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
    chown -Rf ${pgsql_user:?}:${pgsql_user:?} ${PgsqlBasePath:?}
    # 设置环境变量
    if [ -f /home/${default_user:?}/.zshrc ]; then
        echo export "PATH=$PATH:${PgsqlBasePath:?}/bin" >>/home/${default_user:?}/.zshrc
        echo export "PGHOME=${PgsqlBasePath:?}" >>/home/${default_user:?}/.zshrc
        echo export "PGHOST=${PgsqlOptPath:?}/run" >>/home/${default_user:?}/.zshrc
        echo export "PGDATA=${PgsqlOptPath:?}/data" >>/home/${default_user:?}/.zshrc
        su - ${pgsql_user:?} -c "source /home/${default_user:?}/.zshrc"
    else
        echo export "PATH=$PATH:${PgsqlBasePath:?}/bin" >>/home/${pgsql_user:?}/.bash_profile
        echo export "PGHOME=${PgsqlBasePath:?}" >>/home/${pgsql_user:?}/.bash_profile
        echo export "PGHOST=${PgsqlOptPath:?}/run" >>/home/${pgsql_user:?}/.bash_profile
        echo export "PGDATA=${PgsqlOptPath:?}/data" >>/home/${pgsql_user:?}/.bash_profile
    fi

    INFO_MSG "[Initialization default Database ]"
    sudo -u ${pgsql_user:?} -H ${PgsqlBasePath:?}/bin/initdb --encoding=UTF-8 --pgdata=${PgsqlOptPath:?}/data
    # postgresql.conf
    echo -e unix_socket_directories = \'${PgsqlOptPath:?}/run\' >>${PgsqlOptPath:?}/data/postgresql.conf
    echo unix_socket_permissions = 0770 >>${PgsqlOptPath:?}/data/postgresql.conf
    # enable remote connect
    echo -e listen_addresses = \'*\' >>${PgsqlOptPath:?}/data/postgresql.conf
    INFO_MSG "[Staring Database  ]"
    # 手工启动数据库
    sudo -u ${pgsql_user:?} -H ${PgsqlBasePath:?}/bin/pg_ctl -D ${PgsqlOptPath:?}/data -l ${PgsqlOptPath:?}/logs/alert.log start
    # set pgsql_user passwd
    dbrootpwd=`mkpasswd -l 8`
    su - ${pgsql_user:?} -c "${PgsqlBasePath:?}/bin/psql -h 127.0.0.1 -d postgres -c \"alter user ${pgsql_user:?} with password '$dbrootpwd';\""
    echo -e "${CRED}[PostgreSQL db ${pgsql_user:?} passwd:$dbrootpwd ] **************************>>${CEND}\n"
    # enabled password validate
    sed -i 's@^host.*@#&@g' $PgsqlOptPath/data/pg_hba.conf
    sed -i 's@^local.*@#&@g' $PgsqlOptPath/data/pg_hba.conf
    echo -e '\nlocal   all             all                                     md5' >> $PgsqlOptPath/data/pg_hba.conf
    echo 'host    all             all             0.0.0.0/0               md5' >> $PgsqlOptPath/data/pg_hba.conf
    sudo -u ${pgsql_user:?} -H ${PgsqlBasePath:?}/bin/pg_ctl -D ${PgsqlOptPath:?}/data -l ${PgsqlOptPath:?}/logs/alert.log stop

}

Config_PostgreSQL(){
    #systemd
    if ( [ $OS == "Ubuntu" ] && [ ${Ubuntu_version:?} -ge 15 ] ) || ( [ $OS == "CentOS" ] && [ ${CentOS_RHEL_version:?} -ge 7 ] );then
        [ -L /lib/systemd/system/pgsql.service ]  && systemctl disable pgsql.service && rm -f /lib/systemd/system/pgsql.service
        cp $script_dir/template/systemd/pgsql.service /lib/systemd/system/pgsql.service
        sed -i "s#@pgsqluser#${pgsql_user:?}#g" /lib/systemd/system/pgsql.service
        sed -i "s#@PgsqlBasePath#${PgsqlBasePath:?}#g" /lib/systemd/system/pgsql.service
        sed -i "s#@PgsqlDataPath#${PgsqlDataPath:?}#g" /lib/systemd/system/pgsql.service
        systemctl enable pgsql.service
        echo -e "${CMSG}[starting PostgreSQL ] **************************************************>>${CEND}\n"
        systemctl start pgsql.service
        echo -e "${CMSG}[start PostgreSQL OK ] **************************************************>>${CEND}\n"
    else
        echo ""
    fi
    # setting options.conf
    sed -i "s@^pgsql_user.*@pgsql_user=${pgsql_user:?}@" ./options.conf
    sed -i "s@^pgsqlbasepath.*@pgsqlbasepath=${PgsqlBasePath:?}@" ./options.conf
    SOURCE_SCRIPT ${ScriptPath:?}/options.conf
}



PostgreSQL_10_Install_Main(){

    PostgreSQL_Var&&PostgreSQL_Base_Packages_Install&&Install_PostgreSQL&&Init_PostgreSQL&&Config_PostgreSQL
}
