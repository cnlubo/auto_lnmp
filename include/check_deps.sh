#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @Desc                                    install  packages and software
#---------------------------------------------------------------------------

installDepsCentOS() {

    #sed -i 's@^exclude@#exclude@' /etc/yum.conf #注释exclude
    echo -e "${CMSG}[ Install yum-fastestmirror epel-release ] **********************************>>${CEND}\n"
    # yum -y install yum-fastestmirror epel-release
    yum -y install epel-release
    yum clean all
    # yum makecache
    echo -e "${CMSG}[ Disable selinux ] **********************************>>${CEND}\n"
    setenforce 0
    sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
    # Uninstall the conflicting packages
    echo -e "${CMSG}[ Removing the conflicting packages ] **********************************>>${CEND}"
    if [ "${CentOS_RHEL_version:?}" == '7' ]; then
        yum -y groupremove "Basic Web Server" "MySQL Database server" "MySQL Database client" "File and Print Server"
        systemctl mask firewalld.service
        yum -y install iptables-services net-tools
        # systemctl enable iptables.service
    elif [ "${CentOS_RHEL_version}" == '6' ]; then
        yum -y groupremove "FTP Server" "PostgreSQL Database client" "PostgreSQL Database server" "MySQL Database server" "MySQL Database client" "Web Server" "Office Suite and Productivity" "E-mail server" "Ruby Support" "Printing client"
    elif [ "${CentOS_RHEL_version}" == '5' ]; then
        yum -y groupremove "FTP Server" "Windows File Server" "PostgreSQL Database" "News Server" "MySQL Database" "DNS Name Server" "Web Server" "Dialup Networking Support" "Mail Server" "Ruby" "Office/Productivity" "Sound and Video" "Printing Support" "OpenFabrics Enterprise Distribution"
    fi
    echo -e "${CMSG}[ Installing dependencies packages ] **********************************>>${CEND}\n"
    yum check-update
    # Install needed packages
    #pkgList="deltarpm gcc gcc-c++ make cmake autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel libaio numactl numactl-libs readline-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5-devel libidn libidn-devel openssl openssl-devel libxslt-devel libicu-devel libevent-devel libtool libtool-ltdl bison gd-devel vim-enhanced pcre-devel zip unzip ntpdate sqlite-devel sysstat patch bc expect expat-devel rsync rsyslog git lsof lrzsz wget net-tools"

    pkgList="deltarpm gcc gcc-c++ make cmake autoconf glibc glibc-devel glib2 glib2-devel \
        bzip2-devel bzip2 curl libcurl-devel e2fsprogs e2fsprogs-devel krb5-devel openssl openssl-devel \
        libidn libidn-devel bison pcre pcre-devel zip unzip ntpdate sqlite-devel \
        patch bc expect expat-devel rsyslog lsof wget net-tools mkpasswd"

    for Package in ${pkgList}; do
        yum -y install ${Package}
    done
    yum -y update bash openssl glibc
    yum -y upgrade
    # centos devtoolset
    # devtoolset-3(gcc-4.9.2)、devtoolset-4(gcc-5.2.1)

    # echo -e "${CMSG}[ Installing centos devtoolset3(gcc-4.9.2) ] **********************************>>${CEND}"
    # yum -y install scl-utils
    # if [ "$CentOS_RHEL_version" == '7' ];then
    #     rpm -ivh "http://www.softwarecollections.org/repos/rhscl/devtoolset-3/epel-7-x86_64/noarch/rhscl-devtoolset-3-epel-7-x86_64-1-2.noarch.rpm"
    # elif [ "$CentOS_RHEL_version" == '6' ];then
    #     rpm -ivh "http://www.softwarecollections.org/repos/rhscl/devtoolset-3/epel-6-x86_64/noarch/rhscl-devtoolset-3-epel-6-x86_64-1-2.noarch.rpm"
    # fi
    # yum -y install devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-gdb

}

installDepsUbuntu() {
    # Uninstall the conflicting software
    echo -e "${CMSG}Removing the conflicting packages...${CEND}\n"
    pkgList="apache2 apache2-data apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-mpm-worker mysql-client mysql-server mysql-common libmysqlclient18 php5 php5-common php5-cgi php5-mysql php5-curl php5-gd libmysql* mysql-*"
    for Package in ${pkgList}; do
        apt-get -y remove --purge ${Package}
    done
    dpkg -l | grep ^rc | awk '{print $2}' | xargs dpkg -P

    apt-get autoremove

    echo -e "${CMSG}Installing dependencies packages...${CEND}"
    apt-get -y update
    # critical security updates
    grep security /etc/apt/sources.list > /tmp/security.sources.list
    apt-get -y upgrade -o Dir::Etc::SourceList=/tmp/security.sources.list

    # Install needed packages
    pkgList="gcc g++ make cmake autoconf libjpeg8 libjpeg8-dev libpng12-0 libpng12-dev libpng3 libfreetype6 libfreetype6-dev libxml2 libxml2-dev zlib1g zlib1g-dev libc6 libc6-dev libglib2.0-0 libglib2.0-dev bzip2 libzip-dev libbz2-1.0 libncurses5 libncurses5-dev libaio1 libaio-dev numactl libreadline-dev curl libcurl3 libcurl4-openssl-dev e2fsprogs libkrb5-3 libkrb5-dev libltdl-dev libidn11 libidn11-dev openssl libssl-dev libtool libevent-dev re2c libsasl2-dev libxslt1-dev libicu-dev libsqlite3-dev patch vim zip unzip tmux htop bc dc expect libexpat1-dev iptables rsyslog rsync git lsof lrzsz ntpdate wget sysv-rc"
    for Package in ${pkgList}; do
        apt-get -y install ${Package} --force-yes
    done

    if [[ "${Ubuntu_version:?}" =~ ^14$|^15$ ]]; then
        apt-get -y install libcloog-ppl1
        apt-get -y remove bison
        ln -sf /usr/include/freetype2 /usr/include/freetype2/freetype
    elif [ "${Ubuntu_version}" == "13" ]; then
        apt-get -y install bison libcloog-ppl1
    elif [ "${Ubuntu_version}" == "12" ]; then
        apt-get -y install bison libcloog-ppl0
    else
        apt-get -y install bison libcloog-ppl1
    fi
}
installDepsDebian() {
    echo -e "${CMSG}Removing the conflicting packages...${CEND}\n"
    pkgList="apache2 apache2-data apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-mpm-worker mysql-client mysql-server mysql-common libmysqlclient18 php5 php5-common php5-cgi php5-mysql php5-curl php5-gd libmysql* mysql-*"
    for Package in ${pkgList};do
        apt-get -y remove --purge ${Package}
    done
    dpkg -l | grep ^rc | awk '{print $2}' | xargs dpkg -P

    apt-get -y update
    echo -e "${CMSG}Installing dependencies packages...${CEND}"
    # critical security updates
    grep security /etc/apt/sources.list > /tmp/security.sources.list
    apt-get -y upgrade -o Dir::Etc::SourceList=/tmp/security.sources.list

    apt-get autoremove

    # Install needed packages
    case "${Debian_version:?}" in
        [6,7])
            pkgList="gcc g++ make cmake autoconf libjpeg8 libjpeg8-dev libjpeg-dev libpng12-0 libpng12-dev libpng3 libfreetype6 libfreetype6-dev libxml2 libxml2-dev zlib1g zlib1g-dev libc6 libc6-dev libglib2.0-0 libglib2.0-dev bzip2 libzip-dev libbz2-1.0 libncurses5 libncurses5-dev libaio1 libaio-dev numactl libreadline-dev curl libcurl3 libcurl4-openssl-dev libcurl4-gnutls-dev e2fsprogs libkrb5-3 libkrb5-dev libltdl-dev libidn11 libidn11-dev openssl libssl-dev libtool libevent-dev bison re2c libsasl2-dev libxslt1-dev libicu-dev locales libcloog-ppl0 patch vim zip unzip tmux htop bc dc expect libexpat1-dev rsync git lsof lrzsz iptables rsyslog cron logrotate ntpdate libsqlite3-dev psmisc wget sysv-rc"
            ;;
        8)
            pkgList="gcc g++ make cmake autoconf libjpeg8 libjpeg62-turbo-dev libjpeg-dev libpng12-0 libpng12-dev libpng3 libfreetype6 libfreetype6-dev libxml2 libxml2-dev zlib1g zlib1g-dev libc6 libc6-dev libglib2.0-0 libglib2.0-dev bzip2 libzip-dev libbz2-1.0 libncurses5 libncurses5-dev libaio1 libaio-dev numactl libreadline-dev curl libcurl3 libcurl4-openssl-dev libcurl4-gnutls-dev e2fsprogs libkrb5-3 libkrb5-dev libltdl-dev libidn11 libidn11-dev openssl libssl-dev libtool libevent-dev bison re2c libsasl2-dev libxslt1-dev libicu-dev locales libcloog-ppl0 patch vim zip unzip tmux htop bc dc expect libexpat1-dev rsync git lsof lrzsz iptables rsyslog cron logrotate ntpdate libsqlite3-dev psmisc wget sysv-rc"
            ;;
        9)
            pkgList="gcc g++ make cmake autoconf libjpeg62-turbo-dev libjpeg-dev libpng-dev libfreetype6 libfreetype6-dev libxml2 libxml2-dev zlib1g zlib1g-dev libc6 libc6-dev libglib2.0-0 libglib2.0-dev bzip2 libzip-dev libbz2-1.0 libncurses5 libncurses5-dev libaio1 libaio-dev numactl libreadline-dev curl libcurl3 libcurl4-openssl-dev libcurl4-gnutls-dev e2fsprogs libkrb5-3 libkrb5-dev libltdl-dev libidn11 libidn11-dev openssl libssl-dev libtool libevent-dev bison re2c libsasl2-dev libxslt1-dev libicu-dev locales libcloog-ppl1 patch vim zip unzip tmux htop bc dc expect libexpat1-dev rsync git lsof lrzsz iptables rsyslog cron logrotate ntpdate libsqlite3-dev psmisc wget sysv-rc"
            ;;
        *)
            echo -e "${CFAILURE}Your system Debian ${Debian_version} are not supported!${CEND}\n"
            kill -9 $$
            ;;
    esac

    for Package in ${pkgList}; do
        apt-get -y install ${Package}
    done
}


installDepsBySrc() {

    if [ "${OS}" == "CentOS" ]; then
        # git
        yum -y remove git
        if [ -e "$( which git )" ]; then
            U_V1=`git --version 2>&1|awk '{print $3}'|awk -F '.' '{print $1}'`
            U_V2=`git --version 2>&1|awk '{print $3}'|awk -F '.' '{print $2}'`
            U_V3=`git --version 2>&1|awk '{print $3}'|awk -F '.' '{print $3}'`
            Git_version=$U_V1.$U_V2.$U_V3
        fi
        if [ $Git_version != ${git_version:?} ] || [ ! -e "$( which git )" ]; then
            echo -e "${CMSG} [ git$git_version install begin ] **************************>>${CEND}\n"
            cd ${script_dir:?}/src
            src_url=https://www.kernel.org/pub/software/scm/git/git-$git_version.tar.gz
            [ -d git-$git_version ] && rm -rf git-$git_version
            [ ! -f git-$git_version.tar.gz ] && Download_src
            tar xf git-$git_version.tar.gz
            cd git-${git_version:?}
            # 安装依赖
            yum -y install gcc openssl-devel curl-devel expat-devel perl-devel
            [ -d /usr/local/git ] && rm -rf /usr/local/git
            make prefix=/usr/local/git all && make prefix=/usr/local/git install
            if [ $? -eq 0 ];then
                echo -e "${CMSG} [ git$git_version install success ! ] *******************>>${CEND}\n"
                rm -rf /usr/bin/git*  && ln -s /usr/local/git/bin/* /usr/bin/
            else
                echo -e "${CFAILURE} [ git$git_version install fail ! ] *******************>>${CEND}\n"
            fi
            cd .. && rm -rf git-$git_version
        else
            echo -e "${CMSG} [ git has been  install !] *************************************>>${CEND}\n"
        fi
        # python
        if [ -e "$( which python )" ]; then
            U_V1=`python -V 2>&1|awk '{print $2}'|awk -F '.' '{print $1}'`
            U_V2=`python -V 2>&1|awk '{print $2}'|awk -F '.' '{print $2}'`
            U_V3=`python -V 2>&1|awk '{print $2}'|awk -F '.' '{print $3}'`
            Python_version=$U_V1.$U_V2.$U_V3
        fi
        if [ "$Python_version" != "${python2_version:?}" ] || [ ! -e "$( which python )" ] ; then
            cd $script_dir/src
            echo -e "${CMSG} [ Python-$python2_version install begin ] **************************>>${CEND}\n"
            src_url=https://www.python.org/ftp/python/$python2_version/Python-$python2_version.tar.xz
            [ -d Python-$python2_version ] && rm -rf Python-$python2_version
            [ ! -f Python-$python2_version.tar.xz ] && Download_src
            tar xf Python-$python2_version.tar.xz && cd Python-$python2_version
            # 安装依赖
            yum -y install  openssl-devel ncurses-devel  bzip2-devel sqlite-devel readline-devel zlib-devel  tk-devel gdbm-devel
            [ -d /usr/local/python$python2_version ] && rm -rf /usr/local/python$python2_version
            mkdir -p /usr/local/python$python2_version/lib
            ./configure --enable-shared  --enable-unicode=ucs4 --with-cxx-main=g++ --prefix=/usr/local/python$python2_version LDFLAGS="-Wl,-rpath /usr/local/python$python2_version/lib"
            make && make install
            if [ $? -eq 0 ];then
                echo -e "${CMSG} [ Python-$python2_version install success ! ] ********************>>${CEND}\n"
                # 替换默认python
                echo -e "${CMSG} [ Update System Python begin ] **********************************>>${CEND}\n"
                if [ "${CentOS_RHEL_version}" == '7' ]; then
                    if [ -h /usr/bin/python2.7 ]; then
                        rm -rf /usr/bin/python2.7
                    else
                        [ ! -f /usr/bin/python2.7.5 ] && mkdir -p /usr/bin/backup_python && mv /usr/bin/python2.7 /usr/bin/python2.7.5 && cp /usr/bin/python2.7.5 /usr/bin/backup_python
                    fi
                    # ln -s /usr/local/python2.7.14/bin/python2.7-config /usr/bin/python2.7-config
                    ln -s /usr/local/python$python2_version/bin/python2.7 /usr/bin/python2.7
                    [ -f /usr/bin/python2.7-config ] && mv /usr/bin/python2.7-config /usr/bin/backup_python/
                    ln -s /usr/local/python$python2_version/bin/python2.7-config /usr/bin/python2.7-config
                    # 修改 /usr/bin/yum和/usr/libexec/urlgrabber-ext-down的Python版本
                    if [ -f /usr/bin/python2.7.5 ]; then
                        #sed -i "s@^#\!/usr/bin/python.*@#\!  /usr/bin/python2.7.5@" /usr/bin/yum
                        #sed -i "s@^#\!/usr/bin/python.*@#\!  /usr/bin/python2.7.5@" /usr/libexec/urlgrabber-ext-down
                        sed -i "1c #\!  /usr/bin/python2.7.5" /usr/bin/yum
                        sed -i "1c #\!  /usr/bin/python2.7.5" /usr/bin/yum-config-manager
                        sed -i "1c #\!  /usr/bin/python2.7.5" /usr/libexec/urlgrabber-ext-down

                    fi
                    # python.h
                    [ ! -d /usr/include/python2.7 ] && mkdir -p /usr/include/python2.7
                    [ -h /usr/include/python2.7/Python.h ] && rm -rf /usr/include/python2.7/Python.h
                    [ -f /usr/include/python2.7/Python.h ] && mv  /usr/include/python2.7/Python.h /usr/include/python2.7/Python.h_bak
                    ln -s /usr/local/python$python2_version/include/python2.7/Python.h /usr/include/python2.7/Python.h
                fi
                echo -e "${CMSG} [ setuptools vs pip install begin ] *****************************>>${CEND}\n"
                # setuptools
                cd $script_dir/src
                src_url=https://github.com/pypa/setuptools/archive/v${setuptools_version:?}.tar.gz
                [ ! -f v$setuptools_version.tar.gz ] && Download_src
                [ -d setuptools-$setuptools_version ] && rm -rf setuptools-$setuptools_version
                tar xf v$setuptools_version.tar.gz && cd setuptools-$setuptools_version
                python bootstrap.py && python setup.py install
                if [ $? -eq 0 ];then
                    echo -e "${CMSG} [ setuptools-$setuptools_version install success !!!] ***********>>${CEND}\n"
                    rm -rf /usr/bin/easy_install*
                    ln -s /usr/local/python$python2_version/bin/easy_install /usr/bin/easy_install
                    ln -s /usr/local/python$python2_version/bin/easy_install-2.7 /usr/bin/easy_install-2.7
                else
                    echo -e "${CFAILURE} [ setuptools-$setuptools_version install fail !!!] **********>>${CEND}\n"
                fi
                cd .. && rm -rf setuptools-$setuptools_version
                # pip
                src_url=https://github.com/pypa/pip/archive/${pip_version:?}.tar.gz
                [ ! -f $pip_version.tar.gz ] && Download_src
                [ -d pip-$pip_version ] && rm -rf pip-$pip_version
                tar xf $pip_version.tar.gz && cd pip-$pip_version
                python setup.py install
                if [ $? -eq 0 ];then
                    echo -e "${CMSG} [ pip-$pip_version install success !!!]************************>>${CEND}\n"
                    rm -rf /usr/bin/pip*
                    ln -s /usr/local/python$python2_version/bin/pip /usr/bin/pip
                    ln -s /usr/local/python$python2_version/bin/pip2 /usr/bin/pip2
                    ln -s /usr/local/python$python2_version/bin/pip2.7 /usr/bin/pip2.7
                    # pip镜像
                    echo -e "${CMSG}[ setup pip.conf ]**********************************>>${CEND}\n"
                    [ ! -d /root/.pip ] && mkdir -p /root/.pip
                    [ -f /root/.pip/pip.conf ] && mv /root/.pip/pip.conf /root/.pip/pip.conf_bak
                    cp ${script_dir:?}/config/pip.conf /root/.pip/pip.conf
                    id ${default_user:?} >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        [ -d /home/${default_user:?}/.pip ] && rm -rf /home/${default_user:?}/.pip
                        mkdir -p /home/${default_user:?}/.pip && cp ${script_dir:?}/config/pip.conf /home/${default_user:?}/.pip/pip.conf
                        chown -Rf ${default_user:?}:${default_user:?} /home/${default_user:?}/.pip/
                    fi
                else
                    echo -e "${CFAILURE}[ pip-$pip_version install fail !!!] ******************>>${CEND}\n"
                fi
                cd .. && rm -rf pip-$pip_version

            else
                echo -e "${CFAILURE}[ Python-$python2_version install fail !!!]  *****************>>${CEND}\n"
            fi
            rm -rf $script_dir/src/Python-$python2_version
        else
            echo -e "${CMSG}[ python2 has been install !!!] **************************************>>${CEND}\n"
        fi

        # zsh
        if [ ! -e "$(which zsh)" ]; then
            yum -y install ncurses-devel
            cd $script_dir/src
            # shellcheck disable=SC2034
            src_url=https://sourceforge.net/projects/zsh/files/zsh/${zsh_version:?}/zsh-$zsh_version.tar.gz/download
            [ ! -f zsh-$zsh_version.tar.gz ] && Download_src && mv download zsh-$zsh_version.tar.gz
            [ -d zsh-$zsh_version ] && rm -rf zsh-$zsh_version
            tar xvf zsh-$zsh_version.tar.gz
            cd zsh-$zsh_version
            ./configure && make && make install
            if [ $? -eq 0 ];then
                echo -e "${CMSG} [ zsh $zsh_version install success !!!] **********************************${CEND}\n"
                # zsh 加入到ect shells 中
                if [ "$(grep -c /usr/local/bin/zsh /etc/shells)" -eq 0 ]; then
                    echo "/usr/local/bin/zsh" | tee -a /etc/shells
                fi
                CHECK_ZSH_INSTALLED=$(grep /zsh$ /etc/shells | wc -l)
                if [ $CHECK_ZSH_INSTALLED -ge 1 ]; then
                    id ${default_user:?} >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        default_user_exists=1
                        normal_zsh=/home/${default_user:?}/.oh-my-zsh
                    else
                        default_user_exists=0
                    fi
                    root_zsh=/root/.oh-my-zsh
                    cp /etc/passwd /etc/passwd_bak
                    sed -i  "s@root:/bin/bash@root:/usr/local/bin/zsh@g" /etc/passwd
                    #root 用户
                    if [ $default_user_exists -eq 1 ]; then
                        sed -i  "s@${default_user:?}:/bin/bash@${default_user:?}:/usr/local/bin/zsh@g" /etc/passwd
                    fi
                    # Oh My Zsh
                    if [ -d $root_zsh ] || [ -d $normal_zsh ]; then
                        echo -e "${CRED}[root or ${default_user:?} already have Oh My Zsh installed !!! ] ***************${CEND}\n"
                        echo -e "${CRED}[You'll need to remove $ZSH if you want to re-install !!! ] ***************${CEND}\n"

                    else
                        echo -e "${CMSG} [Oh My Zsh install ] ************************>>${CEND}\n"
                        if [ $default_user_exists -eq 1 ]; then
                            sudo -u ${default_user:?} -H git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git $normal_zsh
                            ln -s $normal_zsh $root_zsh
                            if [ -f /home/${default_user:?}/.zshrc ] || [ -h /home/${default_user:?}/.zshrc ]; then
                                echo -e "${CMSG}[Found /home/${default_user:?}/.zshrc. Backing up to /home/${default_user:?}/.zshrc.pre-oh-my-zsh ] *****${CEND}\n"
                                sudo -u ${default_user:?} -H mv /home/${default_user:?}/.zshrc /home/${default_user:?}/.zshrc.pre-oh-my-zsh
                            fi
                            echo  "${CMSG}[Using the Oh My Zsh template file and adding it to /home/${default_user:?}/.zshrc] *****${CEND}\n"
                            sudo -u ${default_user:?} -H cp $normal_zsh/templates/zshrc.zsh-template /home/${default_user:?}/.zshrc
                            sudo -u ${default_user:?} -H sed -i "/^export ZSH=/c export ZSH=$normal_zsh" /home/${default_user:?}/.zshrc
                            echo -e "${CMSG}[powerline install ] ****************************>>${CEND}\n"
                            [ -d /home/${default_user:?}/.ohmyzsh-powerline ] && sudo -u ${default_user:?} -H rm -rf /home/${default_user:?}/.ohmyzsh-powerline
                            [ -d /root/.ohmyzsh-powerline ] && rm -rf /root/.ohmyzsh-powerline
                            sudo -u ${default_user:?} -H git clone git://github.com/jeremyFreeAgent/oh-my-zsh-powerline-theme /home/${default_user:?}/.ohmyzsh-powerline
                            sudo -u ${default_user:?} -H mkdir -p /home/${default_user:?}/.oh-my-zsh/custom/themes/
                            sudo -u ${default_user:?} -H ln -f /home/${default_user:?}/.ohmyzsh-powerline/powerline.zsh-theme /home/${default_user:?}/.oh-my-zsh/custom/themes/powerline.zsh-theme
                            ln -s /home/${default_user:?}/.ohmyzsh-powerline /root/.ohmyzsh-powerline
                            # fonts
                            if [ ! -d /home/${default_user:?}/fonts ]; then
                                if [ -f $script_dir/src/powerline-fonts.tar.gz ]; then
                                    cd $script_dir/src && tar xvf powerline-fonts.tar.gz -C /home/${default_user:?}/
                                    chown -Rf ${default_user:?}:${default_user:?} /home/${default_user:?}/fonts
                                else
                                    sudo -u ${default_user:?} -H git clone https://github.com/powerline/fonts.git /home/${default_user:?}/fonts
                                fi
                            fi
                            cd /home/${default_user:?}/fonts && sudo -u ${default_user:?} -H git pull && cd $script_dir
                            sudo -u ${default_user:?} -H /home/${default_user:?}/fonts/install.sh
                            ln -s /home/${default_user:?}/fonts /root/fonts
                            # zsh theme
                            echo -e "${CMSG}[custom zsh theme install ] *********************>>${CEND}\n"
                            [ -d /home/${default_user:?}/.oh-my-zsh/custom/themes ] && sudo -u ${default_user:?} -H mkdir -p /home/${default_user:?}/.oh-my-zsh/custom/themes
                            sudo -u ${default_user:?} -H cp $script_dir/template/zsh/ak47.zsh-theme /home/${default_user:?}/.oh-my-zsh/custom/themes/
                            # 修改配置文件
                            if [ -f /home/${default_user:?}/.zshrc ] || [ -h /home/${default_user:?}/.zshrc ]; then
                                sudo -u ${default_user:?} -H cp /home/${default_user:?}/.zshrc /home/${default_user:?}/.zshrc.pre
                                # 注释原有模版
                                sudo -u ${default_user:?} -H sed -i '\@ZSH_THEME=@s@^@\#@1' /home/${default_user:?}/.zshrc
                                sudo -u ${default_user:?} -H sed -i "s@^#ZSH_THEME.*@&\nsetopt no_nomatch@" /home/${default_user:?}/.zshrc
                                # 设置新模版
                                sudo -u ${default_user:?} -H sed -i "s@^#ZSH_THEME.*@&\nZSH_THEME=\"ak47\"@" /home/${default_user:?}/.zshrc
                                # 设置插件
                                # 删除原有设置
                                #sed -i  "/#/b;/plugins=(/,/)/d" /root/.zshrc
                                sudo -u ${default_user:?} -H sed -i  "/#/b;/plugins=(/,/)/c plugins=(git z wd extract)" /home/${default_user:?}/.zshrc
                                # set language environment
                                sudo -u ${default_user:?} -H sed -i "s@^# export LANG=en_US.UTF-8@&\nexport LANG=en_US.UTF-8@" /home/${default_user:?}/.zshrc

                            fi
                        else
                            git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git $root_zsh
                            echo -e "${CMSG}[ powerline install ] ***********************>>${CEND}\n"
                            git clone git://github.com/jeremyFreeAgent/oh-my-zsh-powerline-theme /root/.ohmyzsh-powerline
                            mkdir -p /root/.oh-my-zsh/custom/themes/
                            ln -f /root/.ohmyzsh-powerline/powerline.zsh-theme /root/.oh-my-zsh/custom/themes/powerline.zsh-theme
                            # fonts
                            if [ ! -d /root/fonts ]; then
                                if [ -f $script_dir/src/powerline-fonts.tar.gz ]; then
                                    cd $script_dir/src && tar xvf powerline-fonts.tar.gz -C /root/
                                    chown -Rf root:root /root/fonts
                                else
                                    git clone https://github.com/powerline/fonts.git /root/fonts
                                fi
                            fi
                            cd /root/fonts && git pull && cd $script_dir
                            echo -e "${CMSG}[custom zsh theme install ] *****************************>>${CEND}\n"
                            [ -d /root/.oh-my-zsh/custom/themes ] && mkdir -p /root/.oh-my-zsh/custom/themes
                            cp $script_dir/template/zsh/ak47.zsh-theme /root/.oh-my-zsh/custom/themes/
                        fi

                        if [ -f /root/.zshrc ] || [ -h /root/.zshrc ]; then
                            echo -e "${CMSG} [ Found /root/.zshrc. Backing up to /root/.zshrc.pre-oh-my-zsh ] *******>>${CEND}\n"
                            mv /root/.zshrc /root/.zshrc.pre-oh-my-zsh
                        fi
                        cp $root_zsh/templates/zshrc.zsh-template /root/.zshrc
                        sed -i "/^export ZSH=/c export ZSH=$root_zsh" /root/.zshrc
                        # fonts
                        /root/fonts/install.sh
                        if [ -f /root/.zshrc ] || [ -h /root/.zshrc ]; then
                            cp /root/.zshrc /root/.zshrc.pre
                            # 注释原有模版
                            sed -i '\@ZSH_THEME=@s@^@\#@1' /root/.zshrc
                            sed -i "s@^#ZSH_THEME.*@&\nsetopt no_nomatch@" /root/.zshrc
                            # 设置新模版
                            sed -i "s@^#ZSH_THEME.*@&\nZSH_THEME=\"ak47\"@" /root/.zshrc
                            # 设置插件
                            # 删除原有设置
                            sed -i  "/#/b;/plugins=(/,/)/c plugins=(git z wd extract)" /root/.zshrc
                            # set language environment
                            sed -i "s@^# export LANG=en_US.UTF-8@&\nexport LANG=en_US.UTF-8@" /root/.zshrc

                        fi
                        echo -e "${CMSG}[ Oh My Zsh install success !!!] ****************>>${CEND}\n"
                    fi
                else
                    echo -e "${CRED}[ zsh $zsh_version is not installed!! Please install zsh first!!!] *************>>${CEND}\n"
                fi
                unset CHECK_ZSH_INSTALLED
                unset normal_zsh
                unset root_zsh
            else
                echo -e "${CFAILURE} [ zsh $zsh_version install fail !!!] ***************${CEND}\n"
            fi
            rm -rf $script_dir/src/zsh-$zsh_version
        fi
        # vim
        # 卸载系统默认vim
        yum -y  remove vim-common vim-filesystem
        if [ ! -e "$(which vim)" ] && [ -e "$( which python )" ]; then
            cd $script_dir/src
            echo -e "${CMSG}[ vim install begin ]  **********************>>${CEND}\n"
            yum -y install ncurses-devel perl-ExtUtils-Embed lua-devel
            [ ! -d vim ] && git clone https://github.com/vim/vim.git
            cd vim && git pull
            ./configure --prefix=/usr/local/vim --with-features=huge --enable-gui=gtk2 \
                --enable-fontset --enable-multibyte --enable-pythoninterp \
                --with-python-config-dir=/usr/local/python$python2_version/lib/python2.7/config \
                --enable-perlinterp --enable-rubyinterp --enable-luainterp --enable-cscope --enable-xim --with-x  --with-luajit
            make CFLAGS="-O2 -D_FORTIFY_SOURCE=1" && make install
            if [ $? -eq 0 ];then
                echo -e "${CMSG}[ vim install success !!!]*************************>>${CEND}\n"
                [ -h /usr/local/bin/vim ] && rm -rf /usr/local/bin/vim
                ln -s /usr/local/vim/bin/vim /usr/local/bin/vim
                echo -e "${CMSG}[ vim plugins install begin ]**********************>>${CEND}\n"
                echo -e "${CMSG}[ Step1:backing up current vim config ]************>>${CEND}\n"
                today=`date +%Y%m%d`
                home_path=/home/${default_user:?}
                for i in $home_path/.vim $home_path/.vimrc $home_path/.gvimrc $home_path/.vimrc.bundles
                do
                    [ -e $i ] && [ ! -L $i ] && sudo -u ${default_user:?} -H mv $i $home_path/$i.$today
                done
                for i in $home_path/.vim $home_path/.vimrc $home_path/.gvimrc $home_path/.vimrc.bundles
                do
                    [ -L $i ] && sudo -u ${default_user:?} -H unlink $i
                done
                for i in /root/.vim /root/.vimrc /root/.gvimrc /root/.vimrc.bundles
                do
                    [ -e $i ] && [ ! -L $i ] && mv $i /root/$i.$today
                done
                for i in /root/.vim /root/.vimrc /root/.gvimrc /root/.vimrc.bundles
                do
                    [ -L $i ] && unlink $i
                done
                echo -e "${CMSG}[ Step2: setting up ]******************************>>${CEND}\n"
                [ -d /opt/modules/vim ] && rm -rf /opt/modules/vim
                mkdir -p /opt/modules/vim
                mkdir -p /opt/modules/vim/autoload
                mkdir -p /opt/modules/vim/bundle
                mkdir -p /opt/modules/vim/syntax
                cp $script_dir/config/vim/vimrc /opt/modules/vim/
                cp $script_dir/config/vim/vimrc.bundles /opt/modules/vim/
                cp $script_dir/config/vim/filetype.vim /opt/modules/vim/
                cp $script_dir/config/vim/syntax/nginx.vim /opt/modules/vim/syntax/
                chown -Rf ${default_user:?}:${default_user:?} /opt/modules/vim/
                sudo -u ${default_user:?} -H ln -s /opt/modules/vim/vimrc $home_path/.vimrc
                sudo -u ${default_user:?} -H ln -s /opt/modules/vim/vimrc.bundles $home_path/.vimrc.bundles
                sudo -u ${default_user:?} -H ln -s /opt/modules/vim $home_path/.vim
                # root user
                ln -s /opt/modules/vim/vimrc /root/.vimrc
                ln -s /opt/modules/vim/vimrc.bundles /root/.vimrc.bundles
                ln -s /opt/modules/vim /root/.vim

                echo -e "${CMSG}[ Step3: update/install plugins using Vim-plug]*********>>${CEND}\n"
                system_shell=$SHELL
                export SHELL="/bin/sh"
                yum -y install ctags
                sudo -u ${default_user:?} -H curl -fLo $home_path/.vim/autoload/plug.vim --create-dirs \
                    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
                sudo  -u ${default_user:?} -H  vim -u $home_path/.vimrc.bundles +PlugInstall! +PlugClean! +qall
                export SHELL=$system_shell
                echo -e "${CMSG}[ vim plugins install done !!!]********************>>${CEND}\n"
            else
                echo -e "${CFAILURE}[ vim install fail !!!] ***********************>>${CEND}\n"
            fi
        else
            echo -e "${CMSG} [ vim  has been  install !!!] **************************>>${CEND}\n"
        fi

        # tmux
        if [ ! -e "$(which tmux)" ]; then
            echo -e "${CMSG} [ tmux install begin ] **********************************>>${CEND}\n"
            yum -y install ncurses-devel automake
            # Install libevent first
            cd $script_dir/src
            # shellcheck disable=SC2034
            src_url=https://github.com/libevent/libevent/releases/download/release-${libevent_version:?}/libevent-${libevent_version:?}.tar.gz
            [ ! -f libevent-$libevent_version.tar.gz ] && Download_src
            [ -d libevent-${libevent_version} ] && rm -rf libevent-${libevent_version}
            tar xzf libevent-${libevent_version}.tar.gz
            cd  libevent-${libevent_version}
            ./configure && make && make install
            if [ $? -eq 0 ];then
                echo -e "${CMSG} [ libevent-${libevent_version} install success !!!] *******>>${CEND}\n"
            else
                echo -e "${CFAILURE} [ libevent-${libevent_version} install fail !!!] ********>>${CEND}\n"
            fi
            cd .. && rm -rf libevent-${libevent_version}
            # tmux install
            [ ! -d tmux ] && git clone https://github.com/tmux/tmux.git
            cd tmux && git pull && sh autogen.sh
            CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" ./configure
            make && make install
            if [ $? -eq 0 ];then
                echo -e "${CMSG}[tmux install success !!!] ************************${CEND}\n"
            else
                echo -e "${CFAILURE}[tmux install fail !!!] **********************${CEND}\n"
            fi
            unset LDFLAGS
            if [ "${OS_BIT}" == "64" ]; then
                [ -h /usr/lib64/libevent-2.1.so.6 ] && rm -rf /usr/lib64/libevent-2.1.so.6
                ln -s /usr/local/lib/libevent-2.1.so.6 /usr/lib64/libevent-2.1.so.6
            else
                [ -h /usr/lib64/libevent-2.1.so.6 ] && rm -rf /usr/lib64/libevent-2.1.so.6
                ln -s /usr/local/lib/libevent-2.1.so.6 /usr/lib/libevent-2.1.so.6
            fi
        else
            echo -e "${CMSG}[tmux has been  install !!!] *************************>>${CEND}\n"
        fi
    elif [ "${OS}" == "Ubuntu" ]; then
        # Install tmux
        # install htop
        if [ ! -e "$(which htop)" ]; then
            tar xzf htop-${htop_version:?}.tar.gz
            pushd htop-${htop_version:?}
            ./configure
            make -j ${THREAD} && make install
            popd
            rm -rf htop-${htop_version}
        fi
    else
        echo -e "${CMSG}[No need to install software from source packages] ************>>${CEND}\n"
    fi


}
