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
    if [ $? -eq 1 ]; then
        WARNING_MSG "[DataBase ${redmine_dbtype:?} is not running or install  !!!!]" && exit 0
    fi
    # check redmine running
    COUNT=$(ps aux|grep ${wwwroot_dir:?}/redmine|grep -v grep |wc -l)
    if [ $COUNT -gt 0 ];then
        WARNING_MSG "[ Redmine is running please firest stop it .........]" && exit 0
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

    if [ -f ${nginx_addon_dir:?}/config ]&&[ -f ${ruby_install_dir:?}/bin/passenger ] ; then
        INFO_MSG "[Phusion Passenger is already installed ......]"
        echo export 'PATH=$PATH:'"${ruby_install_dir:?}/bin" >>/root/.zshrc
        #export SHELL=/usr/local/bin/zsh
        #source /root/.zshrc
        #export SHELL=/bin/bash
        exec /usr/local/bin/zsh
    else
        INFO_MSG "[ Phusion Passenger Installing ......]"
        gem install passenger --no-ri --no-rdoc
        if [ -f /root/.zshrc ]; then
            echo export 'PATH=$PATH:'"${ruby_install_dir:?}/bin" >>/root/.zshrc
            #SOURCE_SCRIPT /root/.zshrc
        else
            echo export 'PATH=$PATH:'"${ruby_install_dir:?}/bin" >>/root/.bash_profile
            #SOURCE_SCRIPT /root/.bash_profile
        fi
        export PATH=$PATH:${ruby_install_dir:?}/bin
        echo $PATH
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
