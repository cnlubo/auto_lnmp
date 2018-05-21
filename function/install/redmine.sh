#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              redmine.sh
# @Desc
#----------------------------------------------------------------------------
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
                    WARNING_MSG "[ User remine password:$redmine_pass !!!!!!!]"
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

    INFO_MSG "[ Redmine Database Setuping.........]"
    Setup_DataBase
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
    # 临时修改源
    bundle config mirror.https://rubygems.org https://gems.ruby-china.org/
    # 安装依赖
    cd ${wwwroot_dir:?}/redmine
    bundle install --without development test
    # Generate the secret token, then generate the database
    INFO_MSG "[ Generate the secret token,then generate the database....]"
    bundle exec rake generate_secret_token RAILS_ENV=production
    bundle exec rake db:migrate RAILS_ENV=production
    bundle exec rake redmine:load_default_data RAILS_ENV=production REDMINE_LANG=zh
}

Config_Redmine(){

    INFO_MSG "[ Setup User and Directorys Permission ............. ]"
    id ${run_user:?} >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        app_user_setup ${run_user:?}
    fi
    sed -i "s@^redmine_run_user.*@redmine_run_user=${run_user:?}@" ${script_dir:?}/config/redmine.conf
    SOURCE_SCRIPT ${script_dir:?}/config/redmine.conf
    chown -Rf ${redmine_run_user:?}:$redmine_run_user ${wwwroot_dir:?}/redmine
    chmod 0666 ${wwwroot_dir:?}/redmine/log/production.log
    cd ${wwwroot_dir:?}/redmine && mkdir -p tmp tmp/pdf public/plugin_assets
    chown -R ${redmine_run_user:?}:$redmine_run_user files log tmp public/plugin_assets
    chmod -R 755 files log tmp public/plugin_assets
    usermod -a -G ${default_user:?} ${redmine_run_user:?}
    # modify redmine configure
    cp config/configuration.yml.example config/configuration.yml
    cp config/additional_environment.rb.example config/additional_environment.rb
    INFO_MSG "[setup log configuration ....]"
    cat >> config/additional_environment.rb <<EOF

config.logger = Logger.new(Rails.root.join("log",Rails.env + ".log"),3,5*1024*1024)
config.logger.level = Logger::WARN
EOF

    INFO_MSG "[Redmine-${redmine_verion:?} install finish Please Restart Your Shell ......]"
}

Redmine_Plugin_Install() {

    if [ -d ${wwwroot_dir:?}/redmine ] && [ ! -z ${redmine_run_user:?} ];then
        cd ${wwwroot_dir:?}/redmine
        INFO_MSG "[redmine_ckeditor Plugin ......]"

        if [ -d ${wwwroot_dir:?}/redmine/plugins/redmine_ckeditor ]; then
            cd ${wwwroot_dir:?}/redmine/plugins/redmine_ckeditor && git pull && cd ${wwwroot_dir:?}/redmine
        else
            sudo -u ${redmine_run_user:?} -H git clone https://github.com/a-ono/redmine_ckeditor.git \
                ${wwwroot_dir:?}/redmine/plugins/redmine_ckeditor
        fi

        INFO_MSG "[redmine_dmsf Plugin ......]"

        yum -y install xapian-core xapian-bindings-ruby libxapian-dev xpdf \
            poppler-utils antiword unzip catdoc libwpd-tools \
            libwps-tools gzip unrtf catdvi djview djview3 uuid \
            uuid-dev xz libemail-outlook-message-perl
        if [ -d ${wwwroot_dir:?}/redmine/plugins/redmine_dmsf ]; then
            cd ${wwwroot_dir:?}/redmine/plugins/redmine_dmsf && git pull && cd ${wwwroot_dir:?}/redmine
        else
            sudo -u ${redmine_run_user:?} -H git clone https://github.com/danmunn/redmine_dmsf.git \
                ${wwwroot_dir:?}/redmine/plugins/redmine_dmsf
            cd ${wwwroot_dir:?}/redmine/plugins/redmine_dmsf
            sudo -u ${redmine_run_user:?} -H git checkout v1.6.0
            cd ${wwwroot_dir:?}/redmine
        fi

        INFO_MSG "[redmine_lightbox2 Plugin ......]"
        if [ -d ${wwwroot_dir:?}/redmine/plugins/redmine_lightbox2 ]; then
            cd ${wwwroot_dir:?}/redmine/plugins/redmine_lightbox2 && git pull && cd ${wwwroot_dir:?}/redmine
        else
            sudo -u ${redmine_run_user:?} -H git clone https://github.com/paginagmbh/redmine_lightbox2.git \
                ${wwwroot_dir:?}/redmine/plugins/redmine_lightbox2
        fi

        INFO_MSG " [ redmine_work_time Plugin ......]"
        [ -d ${wwwroot_dir:?}/redmine/plugins/redmine_work_time ] && rm -rf ${wwwroot_dir:?}/redmine/plugins/redmine_work_time
        wget https://github.com/tkusukawa/redmine_work_time/archive/${redmine_work_time_version:?}.tar.gz
        if [ -f ${redmine_work_time_version:?}.tar.gz ]; then
            # redmine_work_time-0.3.4
            tar xf ${redmine_work_time_version:?}.tar.gz && mv redmine_work_time-${redmine_work_time_version:?} plugins/redmine_work_time
            chown -Rf ${redmine_run_user:?}:${redmine_run_user:?} plugins/redmine_work_time
            rm -rf ${redmine_work_time_version:?}.tar.gz
        fi
        # INFO_MSG " [ Timesheet Plugin ......]" # uncompatible with redmine 3.4
        # if [ -d ${wwwroot_dir:?}/redmine/plugins/timesheet ]; then
        #     cd ${wwwroot_dir:?}/redmine/plugins/timesheet && git pull && cd ${wwwroot_dir:?}/redmine
        # else
        #     sudo -u ${redmine_run_user:?} -H git clone https://github.com/Contargo/redmine-timesheet-plugin.git \
        #             ${wwwroot_dir:?}/redmine/plugins/timesheet
        # fi
        INFO_MSG " [ redmine_banner Plugin ......]"
        if [ -d ${wwwroot_dir:?}/redmine/plugins/redmine_banner ]; then
            cd ${wwwroot_dir:?}/redmine/plugins/redmine_banner && git pull && cd ${wwwroot_dir:?}/redmine
        else
            sudo -u ${redmine_run_user:?} -H git clone https://github.com/akiko-pusu/redmine_banner.git \
                ${wwwroot_dir:?}/redmine/plugins/redmine_banner
        fi
        INFO_MSG "[Additionals Plugin for Redmine ......]"
        if [ -d ${wwwroot_dir:?}/redmine/plugins/additionals ]; then
            cd ${wwwroot_dir:?}/redmine/plugins/additionals && git pull && cd ${wwwroot_dir:?}/redmine
        else
            sudo -u ${redmine_run_user:?} -H git clone git://github.com/alphanodes/additionals.git \
                ${wwwroot_dir:?}/redmine/plugins/additionals
        fi
        INFO_MSG "[Redmine clipboard_image_paste plugin ......]"
        if [ -d ${wwwroot_dir:?}/redmine/plugins/clipboard_image_paste ]; then
            cd ${wwwroot_dir:?}/redmine/plugins/clipboard_image_paste && git pull && cd ${wwwroot_dir:?}/redmine
        else
            sudo -u ${redmine_run_user:?} -H git clone https://github.com/peclik/clipboard_image_paste.git \
                ${wwwroot_dir:?}/redmine/plugins/clipboard_image_paste
        fi
        INFO_MSG "[Redmine Issue Badge Plugin ......]"
        if [ -d ${wwwroot_dir:?}/redmine/plugins/redmine_issue_badge ]; then
            cd ${wwwroot_dir:?}/redmine/plugins/redmine_issue_badge && git pull && cd ${wwwroot_dir:?}/redmine
        else
            sudo -u ${redmine_run_user:?} -H git clone https://github.com/akiko-pusu/redmine_issue_badge.git \
                ${wwwroot_dir:?}/redmine/plugins/redmine_issue_badge
        fi
        INFO_MSG "[Redmine Issue Templates Plugin ......]"
        if [ -d ${wwwroot_dir:?}/redmine/plugins/redmine_issue_templates ]; then
            cd ${wwwroot_dir:?}/redmine/plugins/redmine_issue_templates && git pull && cd ${wwwroot_dir:?}/redmine
        else
            sudo -u ${redmine_run_user:?} -H git clone https://github.com/akiko-pusu/redmine_issue_templates.git \
                ${wwwroot_dir:?}/redmine/plugins/redmine_issue_templates
        fi
        # INFO_MSG "[RedmineIssuesTree Plugin ......]" # uncompatible with redmine 3.4
        # if [ -d ${wwwroot_dir:?}/redmine/plugins/redmine_issues_tree ]; then
        #     cd ${wwwroot_dir:?}/redmine/plugins/redmine_issues_tree && git pull && cd ${wwwroot_dir:?}/redmine
        # else
        #     sudo -u ${redmine_run_user:?} -H git clone https://github.com/Loriowar/redmine_issues_tree.git \
        #         ${wwwroot_dir:?}/redmine/plugins/redmine_issues_tree
        # fi

        INFO_MSG "[Progressive Projects List Plugin ......]"
        if [ -d ${wwwroot_dir:?}/redmine/plugins/progressive_projects_list ]; then
            cd ${wwwroot_dir:?}/redmine/plugins/progressive_projects_list && git pull && cd ${wwwroot_dir:?}/redmine
        else
            sudo -u ${redmine_run_user:?} -H git clone https://github.com/stgeneral/redmine-progressive-projects-list.git \
                ${wwwroot_dir:?}/redmine/plugins/progressive_projects_list
        fi
        INFO_MSG "[Redmine Theme Changer Plugin ......]"
        if [ -d ${wwwroot_dir:?}/redmine/plugins/redmine_theme_changer ]; then
            cd ${wwwroot_dir:?}/redmine/plugins/redmine_theme_changer && git pull && cd ${wwwroot_dir:?}/redmine
        else
            sudo -u ${redmine_run_user:?} -H git clone https://github.com/haru/redmine_theme_changer.git \
                ${wwwroot_dir:?}/redmine/plugins/redmine_theme_changer
        fi

        # install plugin
        bundle config mirror.https://rubygems.org https://gems.ruby-china.org/
        bundle install --without development test
        bundle exec rake redmine:plugins:migrate RAILS_ENV="production"
        [ -d public/plugin_assets/redmine_ckeditor ] && rm -r public/plugin_assets/redmine_ckeditor

        # themes install
        [ -d ${wwwroot_dir:?}/redmine/public/themes/a1 ] && rm -rf  ${wwwroot_dir:?}/redmine/public/themes/a1
        unzip ${script_dir:?}/template/redmine/themes/a1_theme-2_0_0.zip -d ${wwwroot_dir:?}/redmine/public/themes/
        [ -d ${wwwroot_dir:?}/redmine/public/themes/minimalflat2 ] && rm -rf  ${wwwroot_dir:?}/redmine/public/themes/minimalflat2
        unzip ${script_dir:?}/template/redmine/themes/minimalflat2-1.4.0.zip -d ${wwwroot_dir:?}/redmine/public/themes/
        chown -Rf ${redmine_run_user:?}:${redmine_run_user:?} ${wwwroot_dir:?}/redmine/public/themes/

        INFO_MSG "[Plugin install finish, Please restart redmine ......]"


    else
        WARNING_MSG "[ Redmine not exits, Please first installation !!!!!!]"
    fi

}


Redmine_Install_Main() {

    Redmine_Var && Redmine_Dep_Install && Install_Redmine && Config_Redmine

}
