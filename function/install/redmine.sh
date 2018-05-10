#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              redmine.sh
# @Desc
#----------------------------------------------------------------------------


Redmine_Dep_Install(){

    INFO_MSG "[ Redmine Deps installing.........]"
    yum -y install ImageMagick ImageMagick-devel ImageMagick-c++-devel mysql-devel
    INFO_MSG "[ Ruby、rubygem、rails Installing.........]"
    SOURCE_SCRIPT ${script_dir:?}/include/ruby.sh
    Install_Ruby
    INFO_MSG "[ Redmine Database Setuping.........]"
    Setup_DataBase

}

Setup_DataBase() {

    case   ${redmine_dbtype:?} in
        "postgreSQL")
            {
                while :; do
                    while :; do
                        read -p "Please input PostgreSQL install path (Default:${pgsqlbasepath:?}):" PgsqlPath
                        PgsqlPath="${PgsqlPath:=${pgsqlbasepath:?}}"
                        if [ ! -x $PgsqlPath/bin/psql ]; then
                            FAILURE_MSG "[ $PgsqlPath/bin/psql not exists  !!!]"
                        else
                            break
                        fi
                    done

                    while :; do
                        read -p "Please input PostgreSQL run user (Default:${pgsqluser:?}):" PgsqlUser
                        PgsqlUser="${PgsqlUser:=${pgsqluser:?}}"
                        id $PgsqlUser >/dev/null 2>&1
                        if [ $? -eq 0 ]; then
                            break
                        else
                            FAILURE_MSG "[ User $PgsqlUser not exists  !!!]"
                        fi
                    done
                    read -p "Please input PostgreSQL host (Default:localhost):" PgsqlHost
                    PgsqlHost="${PgsqlHost:=localhost}"

                    read -s -p "Please input PostgreSQL password :" PgsqlPass
                    PgsqlPass="${PgsqlPass}"
                    echo
                    export PGUSER=$PgsqlUser PGPASSWORD=$PgsqlPass \
                        PGDATABASE=postgres PGHOST=$PgsqlHost
                    pg_version=$($PgsqlPath/bin/psql -A -t -c "show server_version")
                    if [ -z $pg_version ]; then
                        FAILURE_MSG "[ PostgreSQL connect error  !!!]"
                        unset PGUSER PGPASSWORD PGDATABASE PGHOST
                    else
                        break
                    fi
                done
                #major=$(echo $pg_version | cut -d. -f1,2)
                #minor=$(echo $pg_version | cut -d. -f3)
                INFO_MSG "[ current PostgreSQL version is $pg_version ........]"
                INFO_MSG "[ Create Redmine Database ........]"
                # test redmine db is exists
                if [ "$($PgsqlPath/bin/psql -lqt | cut -d \| -f 1 | grep -qw 'redmine')" ] \
                    || [ "$($PgsqlPath/bin/psql -t -d postgres -c '\du' | cut -d \| -f 1 | grep -w 'redmine')" ]; then
                    while :; do
                        read -n1 -p "Db and User exists Do You Want to Delete? [y/n]: " del_yn
                        if [[ ! ${del_yn} =~ ^[y,n]$ ]]; then
                            WARNING_MSG "[input error! Please only input 'y' or 'n' ....]"
                        else
                            if [ "${del_yn}" == 'y' ]; then
                                echo
                                INFO_MSG "[ Drop User and Db ........]"
                                $PgsqlPath/bin/psql -c " DROP DATABASE  IF EXISTS redmine;"
                                $PgsqlPath/bin/psql -c " DROP ROLE IF EXISTS redmine;"
                            else
                                echo
                                FAILURE_MSG "[ Redmine DataBase can not Create  !!!]" && exit 0
                            fi
                            break
                        fi
                    done
                fi
                INFO_MSG "[ Create Redmine User and Db .........]"
                redmine_pass=`mkpasswd -s 0 -l 8`
                $PgsqlPath/bin/psql -c " CREATE ROLE redmine LOGIN ENCRYPTED PASSWORD '$redmine_pass' NOINHERIT VALID UNTIL 'infinity';"
                $PgsqlPath/bin/psql -c "CREATE DATABASE redmine WITH ENCODING='UTF8' OWNER=redmine;"
                unset PGUSER PGPASSWORD PGDATABASE PGHOST
                PGUSER='redmine'
                PGPASSWORD=$redmine_pass
                PGDATABASE='redmine'
                PGHOST=$PgsqlHost
                export PGUSER PGPASSWORD PGDATABASE PGHOST
                if $PgsqlPath/bin/psql -lqt | cut -d \| -f 1 | grep -qw $PGDATABASE ; then
                    # database exists
                    # $? is 0
                    SUCCESS_MSG "[ Redmine DataBase Create SUCCESS !!!!]"
                    WARNING_MSG "[ User remine passwd:$redmine_pass !!!!!!!]"
                else
                    # ruh-roh
                    # $? is 1
                    FAILURE_MSG "[ Redmine DataBase Create failure  !!!]"
                    unset PGUSER PGPASSWORD PGDATABASE PGHOST
                    kill -9 $$
                fi
                unset PGUSER PGPASSWORD PGDATABASE PGHOST

            }
            ;;

        "MySql")
            {
                echo
            }
            ;;
        *)
            echo "unknow Dbtype" && exit ;;
    esac
}

Install_Redmine(){

    INFO_MSG "[ redmine-${redmine_verion:?} Installing.........]"
    cd ${script_dir:?}/src
    # shellcheck disable=SC2034
    src_url=https://www.redmine.org/releases/redmine-${redmine_verion:?}.tar.gz
    [ ! -f redmine-${redmine_verion:?}.tar.gz ] && Download_src
    [ -d redmine-${redmine_verion:?} ] && rm -rf redmine-${redmine_verion:?}
    tar xf redmine-${redmine_verion:?}.tar.gz
    [ ! -d ${wwwroot_dir:?} ] && mkdir -p ${wwwroot_dir:?}

    [ -d ${wwwroot_dir:?}/redmine ] && rm -rf ${wwwroot_dir:?}/redmine
    mv redmine-${redmine_verion:?} ${wwwroot_dir:?}/redmine
    cd ${wwwroot_dir:?}/redmine
    INFO_MSG "[ setup remine configure.........]"
    # modify redmine configure
    cp config/configuration.yml.example config/configuration.yml
    cp config/database.yml.example config/database.yml
    # 注释默认的mysql 数据库配置
    sed -i '/^production:/,+6s/\(.*\)/#&/' config/database.yml
    cat >> config/database.yml <<EOF

production:
  adapter: postgresql
  database: redmine
  host: $PgsqlHost
  username: redmine
  password: "$redmine_pass"
EOF

    INFO_MSG "[ install remine dependence.........]"
    su - ${default_user:?} -c "gem sources --add https://gems.ruby-china.org/ --remove https://rubygems.org/"
    # 临时修改源
    su - ${default_user:?} -c "bundle config mirror.https://rubygems.org https://gems.ruby-china.org/"
    # 安装依赖
    su - ${default_user:?} -c "cd ${wwwroot_dir:?}/redmine && bundle install \
        --without development test  --path /home/${default_user:?}/.gem"
    # Generate the secret token, then generate the database
    INFO_MSG "[ Generate the secret token,then generate the database....]"
    su - ${default_user:?} -c "cd ${wwwroot_dir:?}/redmine && \
        bundle exec rake generate_secret_token RAILS_ENV=production"
    su - ${default_user:?} -c "cd ${wwwroot_dir:?}/redmine && \
        bundle exec rake db:migrate RAILS_ENV=production"
    su - ${default_user:?} -c "cd ${wwwroot_dir:?}/redmine && \
        bundle exec rake redmine:load_default_data RAILS_ENV=production REDMINE_LANG=zh"



    # INFO_MSG "[ Phusion Passenger Installing ......]"
    # su - ${default_user:?} -c "gem install passenger --no-ri --no-rdoc --user-install"
    # if [ -f /home/${default_user:?}/.zshrc ]; then
    #     echo export 'PATH=$PATH:'"/home/${default_user:?}/.gem/ruby/2.4.0/bin" >>/home/${default_user:?}/.zshrc
    #     su - ${default_user:?} -c "source /home/${default_user:?}/.zshrc"
    # else
    #     echo export 'PATH=$PATH:'"/home/${default_user:?}/.gem/ruby/2.4.0/bin" >>/home/${default_user:?}/.bash_profile
    #     su - ${default_user:?} -c "source /home/${default_user:?}/.bash_profile"
    # fi
    # for file in /home/${default_user:?}/.gem/ruby/2.4.0/bin/passenger*
    # do
    #     fname=$(basename $file)
    #     [ -L /usr/local/bin/$fname ] && rm -rf /usr/local/bin/$fname
    #     ln -s $file /usr/local/bin/$fname
    # done
    #
    # passenger_path=$(su - ${default_user:?} -c "passenger-config --root")
    #
    # echo ${passenger_path:?}

}

Config_Redmine(){

    INFO_MSG "[ Setup Directorys Permission ............. ]"
    grep ${run_user:?} /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd $run_user
    fi
    id $run_user >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g $run_user  -M -s /sbin/nologin $run_user
    fi
    chown -Rf ${run_user:?}:$run_user ${wwwroot_dir:?}/redmine
    chmod 0666 ${wwwroot_dir:?}/redmine/log/production.log
    cd ${wwwroot_dir:?}/redmine && mkdir -p tmp tmp/pdf public/plugin_assets
    chown -R ${run_user:?}:$run_user files log tmp public/plugin_assets
    chmod -R 755 files log tmp public/plugin_assets
    INFO_MSG "[Redmine-${redmine_verion:?} install finish ......]"
}


Redmine_Install_Main() {

    Redmine_Var && Redmine_Dep_Install && Install_Redmine && Config_Redmine

}
