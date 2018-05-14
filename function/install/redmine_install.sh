#!/bin/bash

# shellcheck disable=SC2164
# shellcheck disable=SC2034
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              redmine_install.sh
# @Desc
#----------------------------------------------------------------------------
SOURCE_SCRIPT ${ScriptPath:?}/config/postgresql.conf
SOURCE_SCRIPT ${script_dir:?}/config/redmine.conf

Redmine_Var() {

    check_app_status ${redmine_dbtype:?}
    if [ $? -eq 0 ]; then
        WARNING_MSG "[ PostgreSQL installed .........]"
    else
        WARNING_MSG "[DataBase ${redmine_dbtype:?} is not running or install  !!!!]" && exit 0
    fi
}

Redmine_Dep_Install(){

    INFO_MSG "[ Redmine Deps installing.........]"
    yum -y install ImageMagick ImageMagick-devel ImageMagick-c++-devel mysql-devel
    INFO_MSG "[ Ruby、rubygem、rails Installing.........]"
    SOURCE_SCRIPT ${script_dir:?}/include/ruby.sh
    Install_Ruby
    passenger_install
}

passenger_install (){

    INFO_MSG "[ Phusion Passenger Installing ......]"
    # su - ${default_user:?} -c "gem install passenger --no-ri --no-rdoc --user-install"
    gem install passenger --no-ri --no-rdoc
    # if [ -f /home/${default_user:?}/.zshrc ]; then
    #     echo export 'PATH=$PATH:'"/home/${default_user:?}/.gem/ruby/${ruby_major_version:?}.0/bin" >>/home/${default_user:?}/.zshrc
    #     su - ${default_user:?} -c "source /home/${default_user:?}/.zshrc"
    # else
    #     echo export 'PATH=$PATH:'"/home/${default_user:?}/.gem/ruby/${ruby_major_version:?}.0/bin" >>/home/${default_user:?}/.bash_profile
    #     su - ${default_user:?} -c "source /home/${default_user:?}/.bash_profile"
    # fi
    if [ -f /root/.zshrc ]; then
        echo export 'PATH=$PATH:'"${ruby_install_dir:?}/bin" >>/root/.zshrc
        source /root/.zshrc
    else
        echo export 'PATH=$PATH:'"${ruby_install_dir:?}/bin" >>/root/.bash_profile
        source /root/.bash_profile
    fi
    # /usr/local/software/ruby/lib/ruby/gems/2.4.0/gems
    # for file in /home/${default_user:?}/.gem/ruby/${ruby_major_version:?}.0/bin/passenger*
    # do
    #     fname=$(basename $file)
    #     [ -L /usr/local/bin/$fname ] && rm -rf /usr/local/bin/$fname
    #     ln -s $file /usr/local/bin/$fname
    # done
    # passenger_dir=$(su - ${default_user:?} -c "passenger-config --root")
    # sed -i "s@^passenger_root.*@passenger_root=$(su - ${default_user:?} -c "passenger-config --root")@" ${script_dir:?}/config/redmine.conf
    # sed -i "s@^nginx_addon_dir.*@nginx_addon_dir=$(su - ${default_user:?} -c "passenger-config --nginx-addon-dir")@" ${script_dir:?}/config/redmine.conf
    # # sed -i "s@^passenger_ruby.*@passenger_ruby=$(su - ${default_user:?} -c "passenger-config --ruby-command")@" ${script_dir:?}/config/redmine.conf
    # sed -i "s@^passenger_ruby.*@passenger_ruby=/usr/local/software/ruby/bin/ruby@" ${script_dir:?}/config/redmine.conf

    sed -i "s@^passenger_root.*@passenger_root=$(passenger-config --root)@" ${script_dir:?}/config/redmine.conf
    sed -i "s@^nginx_addon_dir.*@nginx_addon_dir=$(passenger-config --nginx-addon-dir)@" ${script_dir:?}/config/redmine.conf
    sed -i "s@^passenger_ruby.*@passenger_ruby=${ruby_install_dir:?}/bin/ruby@" ${script_dir:?}/config/redmine.conf
    SOURCE_SCRIPT ${script_dir:?}/config/redmine.conf
    if [ -f ${nginx_addon_dir:?}/config ]; then
        SUCCESS_MSG "[Phusion Passenger installed successful !!!]"
    else
        FAILURE_MSG "[install Phusion Passenger failed,Please contact the author !!!]"
        kill -9 $$
    fi
}

select_redmine_install(){

    echo "${CMSG}-----------------------------------------------------------------------${CEND}"
    cat << EOF
*  `echo -e "$CMAGENTA  1) Redmine-${redmine_verion:?}   "`
*  `echo -e "$CMAGENTA  2) Nginx-${nginx_mainline_version:?} with Passenger"`
*  `echo -e "$CMAGENTA  3) Redmine Common plug-in "`
*  `echo -e "$CMAGENTA  4) Upgrade Redmine "`
*  `echo -e "$CMAGENTA  5) Back             "`
*  `echo -e "$CMAGENTA  6) Quit             "`
EOF
    read -p "${CBLUE}Which function are you want to select:${CEND} " num3

    case $num3 in
        1)
            SOURCE_SCRIPT ${FunctionPath:?}/install/redmine.sh
            Redmine_Install_Main
            select_redmine_install
            ;;
        2)
            SOURCE_SCRIPT ${FunctionPath:?}/install/nginx_install.sh
            SOURCE_SCRIPT ${FunctionPath:?}/install/Nginx.sh
            nginx_install_version=${nginx_mainline_version:?}
            Nginx_install='Nginx'
            lua_install='n'
            Passenger_install='y'
            Nginx_Var && Nginx_Base_Dep_Install && Install_Nginx
            select_redmine_install
            ;;
        3)
            SOURCE_SCRIPT ${FunctionPath:?}/install/redmine.sh
            Redmine_Plugin_Install
            select_redmine_install
            ;;

        4)
            select_devops_install
            ;;
        5)
            select_devops_install
            ;;
        6)
            clear
            exit 0
            ;;
        *)
            select_redmine_install
    esac
}
