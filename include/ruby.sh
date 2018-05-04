#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              ruby.sh
# @Desc
#----------------------------------------------------------------------------

Install_Ruby() {

    if [ -f "${ruby_install_dir:?}/bin/ruby" ];then
        INFO_MSG "[ Ruby has been install !!! ]"
    else
        INFO_MSG "[ Ruby-${ruby_version:?} installing ]"
        yum -y install zlib-devel curl-devel openssl-devel  apr-devel apr-util-devel libxslt-devel
        # shellcheck disable=SC2034
        src_url=http://cache.ruby-lang.org/pub/ruby/2.4/ruby-${ruby_version:?}.tar.gz
        cd ${script_dir:?}/src
        [ -f ruby-${ruby_version:?}.tar.gz ] && Download_src
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
            SUCCESS_MSG "[ Ruby-${ruby_version:?} install success !!!]"

        else
            FAILURE_MSG "[ ruby install failed, Please contact the author !!!]"
            kill -9 $$
        fi
    fi


}
