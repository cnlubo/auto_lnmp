#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              ruby.sh
# @Desc
#----------------------------------------------------------------------------

Install_Ruby() {

    if [ -f "${ruby_install_dir:?}/bin/ruby" ];then
        WARNING_MSG "[ Ruby installed !!! ]"
    else
        yum -y install zlib-devel curl-devel openssl-devel  apr-devel apr-util-devel libxslt-devel
        # shellcheck disable=SC2034
        src_url=http://cache.ruby-lang.org/pub/ruby/${ruby_major_version:?}/ruby-${ruby_version:?}.tar.gz
        INFO_MSG "[ Ruby-${ruby_version:?} installing ]"
        cd ${script_dir:?}/src
        [ ! -f ruby-${ruby_version:?}.tar.gz ] && Download_src
        [ -d ruby-${ruby_version:?} ] && rm -rf ruby-${ruby_version:?}
        tar xf  ruby-${ruby_version:?}.tar.gz && cd ruby-${ruby_version:?}
        ./configure --prefix=${ruby_install_dir:?} --disable-install-rdoc
        make -j${CpuProNum:?} && make install
        if [ -f "${ruby_install_dir:?}/bin/ruby" ];then
            # create link
            for file in ${ruby_install_dir:?}/bin/*
            do
                fname=$(basename $file)
                [ -L /usr/local/bin/$fname ] && rm -rf /usr/local/bin/$fname
                ln -s $file /usr/local/bin/$fname
            done
            for file in ${ruby_install_dir:?}/include/*
            do
                fname=$(basename $file)
                [ -L /usr/local/include/$fname ] && rm -rf /usr/local/include/$fname
                ln -s $file /usr/local/include/$fname
            done
            for file in ${ruby_install_dir:?}/lib/*
            do
                fname=$(basename $file)
                if [ ! $fname = 'pkgconfig' ]; then
                    [ -L /usr/local/lib/$fname ] && rm -rf /usr/local/lib/$fname
                    ln -s $file /usr/local/lib/$fname
                else
                    ln -s -b ${ruby_install_dir:?}/lib/pkgconfig/* /usr/local/lib/pkgconfig
                fi
            done
            Install_RubyGems
            SUCCESS_MSG "[ Ruby-${ruby_version:?} install success !!!]"

        else
            FAILURE_MSG "[ ruby install failed, Please contact the author !!!]"
            kill -9 $$
        fi
    fi
}

Install_RubyGems() {

    INFO_MSG "[ rubygems-${rubygems_version:?} installing ]"
    cd ${script_dir:?}/src
    # shellcheck disable=SC2034
    src_url=https://rubygems.org/rubygems/rubygems-${rubygems_version:?}.tgz
    [ -f rubygems-${rubygems_version:?}.tgz ] && Download_src
    [ -d rubygems-${rubygems_version:?} ] && rm -rf rubygems-${rubygems_version:?}
    tar xf  rubygems-${rubygems_version:?}.tgz && cd rubygems-${rubygems_version:?}
    ruby setup.rb
    for file in ${ruby_install_dir:?}/bin/*
    do
        fname=$(basename $file)
        [ -L /usr/local/bin/$fname ] && rm -rf /usr/local/bin/$fname
        ln -s $file /usr/local/bin/$fname
    done
    # 修改源为ruby-china
    gem sources --add https://gems.ruby-china.org/ --remove https://rubygems.org/
    gem sources -l

}
