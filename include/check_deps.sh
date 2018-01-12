#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @Desc                                    install  packages and software
#----------------------------------------------------------------------------

installDepsCentOS() {

    #sed -i 's@^exclude@#exclude@' /etc/yum.conf #注释exclude
    echo "${CMSG}[ Install yum-fastestmirror epel-release ] **********************************>>${CEND}"
    # yum -y install yum-fastestmirror epel-release
    yum -y install epel-release
    yum clean all
    # yum makecache
    echo "${CMSG}[ Disable selinux ] **********************************>>${CEND}"
    setenforce 0
    sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
    # Uninstall the conflicting packages
    echo "${CMSG}[ Removing the conflicting packages ] **********************************>>${CEND}"
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
    echo "${CMSG}[ Installing dependencies packages ] **********************************>>${CEND}"
    yum check-update
    # Install needed packages
    #pkgList="deltarpm gcc gcc-c++ make cmake autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel libaio numactl numactl-libs readline-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5-devel libidn libidn-devel openssl openssl-devel libxslt-devel libicu-devel libevent-devel libtool libtool-ltdl bison gd-devel vim-enhanced pcre-devel zip unzip ntpdate sqlite-devel sysstat patch bc expect expat-devel rsync rsyslog git lsof lrzsz wget net-tools"

    pkgList="deltarpm gcc gcc-c++ make cmake autoconf glibc glibc-devel glib2 glib2-devel \
    bzip2-devel curl libcurl-devel e2fsprogs e2fsprogs-devel krb5-devel openssl openssl-devel \
    libidn libidn-devel bison pcre pcre-devel zip unzip ntpdate sqlite-devel \
    patch bc expect expat-devel rsyslog lsof wget net-tools mkpasswd"

    for Package in ${pkgList}; do
        yum -y install ${Package}
    done
    yum -y update bash openssl glibc
    yum -y upgrade
    # centos devtoolset
    # devtoolset-3(gcc-4.9.2)、devtoolset-4(gcc-5.2.1)
    echo "${CMSG}[ Installing centos devtoolset3(gcc-4.9.2) ] **********************************>>${CEND}"
    yum -y install scl-utils
    if [ "$CentOS_RHEL_version" == '7' ];then
        rpm -ivh "http://www.softwarecollections.org/repos/rhscl/devtoolset-3/epel-7-x86_64/noarch/rhscl-devtoolset-3-epel-7-x86_64-1-2.noarch.rpm"
    elif [ "$CentOS_RHEL_version" == '6' ];then
        rpm -ivh "http://www.softwarecollections.org/repos/rhscl/devtoolset-3/epel-6-x86_64/noarch/rhscl-devtoolset-3-epel-6-x86_64-1-2.noarch.rpm"
    fi
    yum -y install devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-gdb

}

installDepsUbuntu() {
    # Uninstall the conflicting software
    echo "${CMSG}Removing the conflicting packages...${CEND}"
    pkgList="apache2 apache2-data apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-mpm-worker mysql-client mysql-server mysql-common libmysqlclient18 php5 php5-common php5-cgi php5-mysql php5-curl php5-gd libmysql* mysql-*"
    for Package in ${pkgList}; do
        apt-get -y remove --purge ${Package}
    done
    dpkg -l | grep ^rc | awk '{print $2}' | xargs dpkg -P

    apt-get autoremove

    echo "${CMSG}Installing dependencies packages...${CEND}"
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
    echo "${CMSG}Removing the conflicting packages...${CEND}"
    pkgList="apache2 apache2-data apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-mpm-worker mysql-client mysql-server mysql-common libmysqlclient18 php5 php5-common php5-cgi php5-mysql php5-curl php5-gd libmysql* mysql-*"
    for Package in ${pkgList};do
        apt-get -y remove --purge ${Package}
    done
    dpkg -l | grep ^rc | awk '{print $2}' | xargs dpkg -P

    apt-get -y update
    echo "${CMSG}Installing dependencies packages...${CEND}"
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
            echo "${CFAILURE}Your system Debian ${Debian_version} are not supported!${CEND}"
            kill -9 $$
        ;;
    esac

    for Package in ${pkgList}; do
        apt-get -y install ${Package}
    done
}


installDepsBySrc() {


    # pushd ${oneinstack_dir}/src
    #
    # if [ "${OS}" == "Ubuntu" ]; then
    #     if [[ "${Ubuntu_version}" =~ ^14$|^15$ ]]; then
    #         # Install bison on ubt 14.x 15.x
    #         tar xzf bison-${bison_version}.tar.gz
    #         pushd bison-${bison_version}
    #         ./configure
    #         make -j ${THREAD} && make install
    #         popd
    #         rm -rf bison-${bison_version}
    #     fi
    # elif [ "${OS}" == "CentOS" ]; then
    #     # Install tmux
    #     if [ ! -e "$(which tmux)" ]; then
    #         # Install libevent first
    #         tar xzf libevent-${libevent_version}.tar.gz
    #         pushd libevent-${libevent_version}
    #         ./configure
    #         make -j ${THREAD} && make install
    #         popd
    #         rm -rf libevent-${libevent_version}
    #
    #         tar xzf tmux-${tmux_version}.tar.gz
    #         pushd tmux-${tmux_version}
    #         CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" ./configure
    #         make -j ${THREAD} && make install
    #         unset LDFLAGS
    #         popd
    #         rm -rf tmux-${tmux_version}
    #
    #         if [ "${OS_BIT}" == "64" ]; then
    #             ln -s /usr/local/lib/libevent-2.0.so.5 /usr/lib64/libevent-2.0.so.5
    #         else
    #             ln -s /usr/local/lib/libevent-2.0.so.5 /usr/lib/libevent-2.0.so.5
    #         fi
    #     fi
    #
    #     # install htop
    #     if [ ! -e "$(which htop)" ]; then
    #         tar xzf htop-${htop_version}.tar.gz
    #         pushd htop-${htop_version}
    #         ./configure
    #         make -j ${THREAD} && make install
    #         popd
    #         rm -rf htop-${htop_version}
    #     fi
    # else
    #     echo "No need to install software from source packages."
    # fi
    # popd
    #
    #
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
            echo "${CMSG} [ git$git_version install begin ] *************************************>>${CEND}"
            echo
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
                echo "${CMSG} [ git$git_version install success ! ] **********************************>>${CEND}"
                echo
                rm -rf /usr/bin/git*  && ln -s /usr/local/git/bin/* /usr/bin/
            else
                echo "${CFAILURE} [ git$git_version install fail ! ] **********************************>>${CEND}"
                echo
            fi
            cd ..
            rm -rf git-$git_version
        else
            echo "${CMSG} [ git has been  install !] ***********************************************>>${CEND}"
            echo

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
            echo "${CMSG} [ Python-$python2_version install begin ] *************************************>>${CEND}"
            echo
            src_url=https://www.python.org/ftp/python/$python2_version/Python-$python2_version.tar.xz
            [ -d Python-$python2_version ] && rm -rf Python-$python2_version
            [ ! -f Python-$python2_version.tar.xz ] && Download_src
            tar xf Python-$python2_version.tar.xz && cd Python-$python2_version
            # 安装依赖
            yum -y install  openssl-devel ncurses-devel  bzip2-devel sqlite-devel readline-devel zlib-devel  tk-devel gdbm-devel
            [ -d /usr/local/python$python2_version ] && rm -rf /usr/local/python$python2_version
            mkdir -p /usr/local/python$python2_version/lib
            ./configure --enable-shared  --enable-unicode=ucs4 --prefix=/usr/local/python$python2_version LDFLAGS="-Wl,-rpath /usr/local/python$python2_version/lib"
            make && make install
            if [ $? -eq 0 ];then
                echo "${CMSG} [ Python-$python2_version install success ! ] **********************************>>${CEND}"
                echo
                # 替换默认python
                echo "${CMSG} [ Update System Python begin ] **********************************>>${CEND}"
                echo
                if [ "${CentOS_RHEL_version}" == '7' ]; then
                    if [ -h /usr/bin/python2.7 ]; then
                        rm -rf /usr/bin/python2.7
                    else
                        [ ! -f /usr/bin/python2.7.5 ] && mkdir -p /usr/bin/backup_python && mv /usr/bin/python2.7 /usr/bin/python2.7.5 && cp /usr/bin/python2.7.5 /usr/bin/backup_python
                    fi
                    ln -s /usr/local/python$python2_version/bin/python2.7 /usr/bin/python2.7
                    # 修改 /usr/bin/yum和/usr/libexec/urlgrabber-ext-down的Python版本
                    if [ -f /usr/bin/python2.7.5 ]; then
                        #sed -i "s@^#\!/usr/bin/python.*@#\!  /usr/bin/python2.7.5@" /usr/bin/yum
                        #sed -i "s@^#\!/usr/bin/python.*@#\!  /usr/bin/python2.7.5@" /usr/libexec/urlgrabber-ext-down
                        sed -i "1c #\!  /usr/bin/python2.7.5" /usr/bin/yum
                        sed -i "1c #\!  /usr/bin/python2.7.5" /usr/libexec/urlgrabber-ext-down
                    fi
                fi
                echo "${CMSG} [ setuptools vs pip install begin ] **********************************>>${CEND}"
                echo
                # setuptools
                cd $script_dir/src
                src_url=https://github.com/pypa/setuptools/archive/v${setuptools_version:?}.tar.gz
                [ ! -f v$setuptools_version.tar.gz ] && Download_src
                [ -d setuptools-$setuptools_version ] && rm -rf setuptools-$setuptools_version
                tar xf v$setuptools_version.tar.gz
                cd setuptools-$setuptools_version
                python bootstrap.py && python setup.py install
                if [ $? -eq 0 ];then
                    echo "${CMSG} [ setuptools-$setuptools_version install success !!!] **********************************>>${CEND}"
                    echo
                    rm -rf /usr/bin/easy_install*
                    ln -s /usr/local/python$python2_version/bin/easy_install /usr/bin/easy_install
                    ln -s /usr/local/python$python2_version/bin/easy_install-2.7 /usr/bin/easy_install-2.7
                else
                    echo "${CFAILURE} [ setuptools-$setuptools_version install fail !!!] **********************************>>${CEND}"
                    echo
                fi
                cd .. && rm -rf setuptools-$setuptools_version
                # pip
                src_url=https://github.com/pypa/pip/archive/${pip_version:?}.tar.gz
                [ ! -f $pip_version.tar.gz ] && Download_src
                [ -d pip-$pip_version ] && rm -rf pip-$pip_version
                tar xvf $pip_version.tar.gz
                cd pip-$pip_version
                python setup.py install
                if [ $? -eq 0 ];then
                    echo "${CMSG} [ pip-$pip_version install success !!!]**********************************>>${CEND}"
                    echo
                    rm -rf /usr/bin/pip*
                    ln -s /usr/local/python$python2_version/bin/pip /usr/bin/pip
                    ln -s /usr/local/python$python2_version/bin/pip2 /usr/bin/pip2
                    ln -s /usr/local/python$python2_version/bin/pip2.7 /usr/bin/pip2.7
                    # pip镜像
                    echo "${CMSG} [ setup pip.conf ]**********************************>>${CEND}"
                    echo
                    [ ! -d /root/.pip ] && mkdir -p /root/.pip
                    [ -f /root/.pip/pip.conf ] && mv /root/.pip/pip.conf /root/.pip/pip.conf_bak
                    cp ${script_dir:?}/config/pip.conf /root/.pip/pip.conf
                    id ${default_user:?} >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        [ -d /home/${default_user:?}/.pip ] && rm -rf /home/${default_user:?}/.pip
                        mkdir -p /home/${default_user:?}/.pip && cp ${script_dir:?}/config/pip.conf /home/${default_user:?}/.pip/pip.conf
                    fi
                else
                    echo "${CFAILURE} [ pip-$pip_version install fail !!!] **********************************>>${CEND}"
                    echo
                fi
                cd .. && rm -rf pip-$pip_version

            else
                echo "${CFAILURE} [ Python-$python2_version install fail !!!]  **********************************>>${CEND}"
                echo
            fi
            rm -rf $script_dir/src/Python-$python2_version
        else
            echo "${CMSG} [ python2 has been install !!!] ********************************************>>${CEND}"
            echo
        fi

        # vim
        if [ ! -e "$(which vim)" ] && [ -e "$( which python )" ]; then
            cd $script_dir/src
            echo "${CMSG} [ vim install begin ]  **********************************>>${CEND}"
            echo
            yum -y install ncurses-devel perl-ExtUtils-Embed lua-devel
            [ ! -d vim ] && git clone https://github.com/vim/vim.git
            cd vim
            git pull
            ./configure --prefix=/usr/local/vim --with-features=huge --enable-gui=gtk2 \
            --enable-fontset --enable-multibyte --enable-pythoninterp \
            --with-python-config-dir=/usr/local/python$python2_version/lib/python2.7/config \
            --enable-perlinterp --enable-rubyinterp --enable-luainterp --enable-cscope --enable-xim --with-x  --with-luajit
            make CFLAGS="-O2 -D_FORTIFY_SOURCE=1" && make install
            if [ $? -eq 0 ];then
                echo "${CMSG} [ vim install success !!!]**********************************>>${CEND}"
                echo
                [ -h /usr/local/bin/vim ] && rm -rf /usr/local/bin/vim
                ln -s /usr/local/vim/bin/vim /usr/local/bin/vim
            else
                echo "${CFAILURE} [ vim install fail !!!] **********************************>>${CEND}"
                echo
            fi
            # cd .. && rm -rf vim
        else
            echo "${CMSG} [ vim  has been  install !!!] ***********************************************>>${CEND}"
            echo
        fi

        # tmux
        if [ ! -e "$(which tmux)" ]; then
            echo "${CMSG} [ tmux install begin ] **********************************>>${CEND}"
            echo
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
                echo "${CMSG} [ libevent-${libevent_version} install success !!!] **********************************>>${CEND}"
                echo
            else
                echo "${CFAILURE} [ libevent-${libevent_version} install fail !!!] **********************************>>${CEND}"
                echo
            fi
            cd ..
            rm -rf libevent-${libevent_version}
            # tmux install
            [ ! -d tmux ] && git clone https://github.com/tmux/tmux.git
            cd tmux
            git pull
            sh autogen.sh
            CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" ./configure
            make && make install
            if [ $? -eq 0 ];then
                echo "${CMSG} [ tmux install success !!!] **********************************${CEND}"
                echo
            else
                echo "${CFAILURE} [ tmux install fail !!!] **********************************${CEND}"
                echo
            fi
            unset LDFLAGS
            # cd .. && rm -rf tmux
            if [ "${OS_BIT}" == "64" ]; then
                ln -s /usr/local/lib/libevent-2.1.so.6 /usr/lib64/libevent-2.1.so.6
            else
                ln -s /usr/local/lib/libevent-2.1.so.6 /usr/lib/libevent-2.1.so.6
            fi
        else
            echo "${CMSG} [ tmux has been  install !!!] ***********************************************>>${CEND}"
            echo
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
                echo "${CMSG} [ zsh $zsh_version install success !!!] **********************************${CEND}"
                echo
                # zsh 加入到ect shells 中
                if [ "$(grep -c /usr/local/bin/zsh /etc/shells)" -eq 0 ]; then
                    echo "/usr/local/bin/zsh" | tee -a /etc/shells
                fi
                # root用户切换为zsh
                #chsh -s /usr/local/bin/zsh
                # Oh My Zsh
                if [ -d ~/.oh-my-zsh ]; then
                    echo "${CMSG} [ You already have Oh My Zsh installed !!! ] **********************************${CEND}"
                    echo "${CRED} [ You'll need to remove $ZSH if you want to re-install !!! ] ******************${CEND}"

                else
                    cd ~
                    # sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)" && env bash
                    $script_dir/include/OhMyZsh_install.sh
                fi
                # powerline
                [ -d ~/.ohmyzsh-powerline ] && rm -rf ~/.ohmyzsh-powerline
                git clone git://github.com/jeremyFreeAgent/oh-my-zsh-powerline-theme ~/.ohmyzsh-powerline
                cd ~/.ohmyzsh-powerline && ./install_in_omz.sh
                cd ~

                [ ! -d fonts ] && git clone https://github.com/powerline/fonts.git
                cd fonts && ./install.sh
                # zsh theme
                [ -d /root/.oh-my-zsh/custom/themes ] && mkdir -p /root/.oh-my-zsh/custom/themes
                cp $script_dir/template/zsh/ak47.zsh-theme /root/.oh-my-zsh/custom/themes/
                if [ -f ~/.zshrc ] || [ -h ~/.zshrc ]; then
                    cp ~/.zshrc ~/.zshrc.pre
                    sed -i "s@^#ZSH_THEME.*@&\nZSH_THEME='ak47'@" /root/.zshrc
                    # ZSH_THEME="ak47"
                fi
                # normal 用户切换
                # id ${default_user:?} >/dev/null 2>&1
                # if [ $? -eq 0 ]; then
                #     cd /home/$default_user
                #
                #
                # fi

            else
                echo "${CFAILURE} [ zsh $zsh_version install fail !!!] **********************************${CEND}"
                echo
            fi
            cd .. && rm -rf zsh-$zsh_version
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
        echo
        echo "No need to install software from source packages."
    fi


}
