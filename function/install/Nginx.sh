#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              Nginx.sh
# @Desc
#----------------------------------------------------------------------------
Nginx_Dep_Configure() {

    # echo-nginx-module
    INFO_MSG "[ echo-nginx-module ]****************>>"
    cd "${script_dir:?}"/src
    [ -d echo-nginx-module ] && rm -rf echo-nginx-module
    git clone https://github.com/openresty/echo-nginx-module.git

    if [[ "${nginx_pagespeed:?}" = [yY] ]]; then
        if [ ! -f /usr/include/uuid/uuid.h ]; then
            # https://github.com/pagespeed/ngx_pagespeed/issues/1499
            yum -y install libuuid-devel
        fi
        INFO_MSG "[ ngx_pagespeed ]***************>>"
        cd "${script_dir:?}"/src
        ngx_pagespeed_file=v${pagespeed_version:?}.tar.gz
        ngx_pagespeed_dir=incubator-pagespeed-ngx-${pagespeed_version:?}
        src_url=https://github.com/apache/incubator-pagespeed-ngx/archive/$ngx_pagespeed_file
        [ ! -f "$ngx_pagespeed_file" ] && Download_src
        [ -d "$ngx_pagespeed_dir" ] && rm -rf "$ngx_pagespeed_dir"
        tar xf "$ngx_pagespeed_file"
        # shellcheck disable=SC2034
        src_url=https://dl.google.com/dl/page-speed/psol/${psol_version:?}-x$OS_BIT.tar.gz
        [ ! -f "${psol_version:?}"-x"$OS_BIT".tar.gz ] && Download_src
        mv "${psol_version:?}"-x"$OS_BIT".tar.gz "$ngx_pagespeed_dir"/ && cd "$ngx_pagespeed_dir"
        [ -d psol ] && rm -rf psol
        tar xf "${psol_version:?}"-x"$OS_BIT".tar.gz
    fi

    nginx_exportld_opt='-Wl,-E '
    if [[ "${gperftools_sourceinstall:?}" = [yY] ]]; then
        # lsof -n | grep tcmalloc >/dev/null 2>&1; echo $?
        GPERFOPT=" --with-google_perftools_module"
        #         mkdir -p /var/tmp/tcmalloc
        #         chown -R nginx:nginx /var/tmp/tcmalloc
        #         cat >"/usr/local/nginx/conf/gperftools.conf" <<GPF
        # google_perftools_profiles /var/tmp/tcmalloc;
        # GPF

        # GPERFINCLUDE_CHECK=$(grep '^include \/usr\/local\/nginx\/conf\/gperftools.conf;' /usr/local/nginx/conf/nginx.conf)

        # if [[ ! -z "$GPERFINCLUDE_CHECK" ]]; then
        #     sed -i 's/^#include \/usr\/local\/nginx\/conf\/gperftools.conf;/include \/usr\/local\/nginx\/conf\/gperftools.conf;/g' /usr/local/nginx/conf/nginx.conf
        # elif [[ -z "$GPERFINCLUDE_CHECK" ]]; then
        #     sed -i 's/pcre_jit on;/pcre_jit on; \ninclude \/usr\/local\/nginx\/conf\/gperftools.conf;/g' /usr/local/nginx/conf/nginx.conf
        # fi
        jemalloc_ld=""
    else
        GPERFOPT=""
        #sed -i 's|^include \/usr\/local\/nginx\/conf\/gperftools.conf|#include \/usr\/local\/nginx\/conf\/gperftools.conf|g' /usr/local/nginx/conf/nginx.conf
        if [ -f "/usr/local/lib/libjemalloc.so" ]; then
            jemalloc_ld='-ljemalloc'
        else
            # shellcheck disable=SC2034
            jemalloc_ld=""
        fi
    fi
    if [[ "$NGINX_STREAMSSLPREREAD" = [yY] ]]; then
        STREAM_SSLPREREADOPT=" --with-stream_ssl_preread_module"
    else
        # shellcheck disable=SC2034
        STREAM_SSLPREREADOPT=""
    fi
    # if [[ "$NGINX_SPDYPATCHED" = [yY] ]]; then
    #     NGINX_SPDY=y
    #     HTTPTWOOPT=' --with-http_spdy_module --with-http_v2_module'
    # else
    #     # shellcheck disable=SC2034
    #     NGINX_SPDY=n
    #     # shellcheck disable=SC2034
    #     HTTPTWOOPT=' --with-http_v2_module'
    # fi
    if [[ "$NGINX_SPDY" = [yY] ]]; then
        if [[ "$NGINX_SPDYPATCHED" = [yY] ]]; then
            SPDYOPT=""
        else
            SPDYOPT=" --with-http_spdy_module"
        fi
    else
        SPDYOPT=""
    fi
    REALIPOPT=' --with-http_realip_module'
    STUBSTATUSOPT=" --with-http_stub_status_module"
    SUBOPT=" --with-http_sub_module"
    ADDITIONOPT=" --with-http_addition_module"

    # if [[ "$LIBRESSL_SWITCH" = [yY] ]]; then
    #     LIBRESSLDIR=$(tar -tzf "$DIR_TMP/${LIBRESSL_LINKFILE}" 2>&1 | head -1 | cut -f1 -d"/" | grep libressl)
    #     LIBRESSLOPT=" --with-openssl=../$LIBRESSLDIR"
    #     OPENSSLOPT=""
    #     BORINGSSLOPT=""
    #     LRT='-lrt '
    # elif [[ "$BORINGSSL_SWITCH" = [yY] ]]; then
    #     LIBRESSLOPT=""
    #     OPENSSLOPT=""
    #     # LRT=""
    #     LRT='-lrt '
    #     # BORINGSSLOPT=" --with-openssl=${BORINGSSL_DIR}/boringssl"
    #     BORINGSSL_RPATH="${BORINGSSL_DIR}/boringssl/.openssl/lib:"
    #     BORINGSSL_LIBOPT="-L${BORINGSSL_DIR}/boringssl/.openssl/lib -lcrypto -lssl "
    #     BORINGSSLINC_OPT="-I${BORINGSSL_DIR}/boringssl/.openssl/include "
    #     # openresty set-misc nginx module not compatible with boringssl
    #     # https://community.centminmod.com/threads/15406/
    #     #ORESTY_SETMISC='n'
    #     #NGINX_STREAM='n'
    #     #SETMISCOPT=""
    # else

    #OPENSSLDIR=$(tar -tzf "$DIR_TMP/${OPENSSL_LINKFILE}" | head -1 | cut -f1 -d"/")
    LIBRESSLOPT=""
    BORINGSSLOPT=""
    # if [[ "$TLSONETHREE" = [yY] ]]; then
    #     if [[ "$(uname -m)" = 'x86_64' ]]; then
    #         OPENSSLOPT=" --with-openssl=../openssl-tls1.3"
    #         TLSTHREEOPT='y'
    #     else
    #         OPENSSLOPT=" --with-openssl=../openssl-tls1.3"
    #         OPENSSLOPT_B=" --with-openssl-opt=enable-tls1_3"
    #     fi
    #if [[ "$DETECTOPENSSL_ONEONE" = '1.1.1' ]]; then
    if [[ "$(uname -m)" = 'x86_64' ]]; then
        OPENSSLOPT=" --with-openssl=../$OPENSSLDIR"
        TLSTHREEOPT='y'
    else
        OPENSSLOPT=" --with-openssl=../$OPENSSLDIR"
        OPENSSLOPT_B=" --with-openssl-opt=enable-tls1_3"
    fi
    #else
    #    if [[ "$(uname -m)" = 'x86_64' ]]; then
    #        OPENSSLOPT=" --with-openssl=../$OPENSSLDIR --with-openssl-opt='enable-ec_nistp_64_gcc_128'"
    #    else
    OPENSSLOPT=" --with-openssl=../$OPENSSLDIR"
    #   fi
    #fi
    LRT=""
    # fi

    if [[ "$NGINX_ZLIBCUSTOM" = [yY] ]]; then
        ZLIBCUSTOM_DIR=$(tar -tzf "$DIR_TMP/${NGX_ZLIBLINKFILE}" 2>&1 | head -1 | cut -f1 -d"/" | grep zlib)
        ZLIBCUSTOM_OPT=" --with-zlib=../zlib-${NGINX_ZLIBVER}"
    fi
    CHECK_PCLMUL=$(gcc -c -Q -march=native --help=target | egrep '\[enabled\]|mtune|march' | grep 'mpclmul' | grep -o enabled)
    if [[ "$CLOUDFLARE_ZLIB" = [yY] && "$(cat /proc/cpuinfo | grep -o 'sse4_2' | uniq)" = 'sse4_2' && "$CHECK_PCLMUL" = 'enabled' ]]; then
        ZLIBCUSTOM_DIR="zlib-cloudflare-${CLOUDFLARE_ZLIBVER}"
        ZLIBCUSTOM_OPT=" --with-zlib=../zlib-cloudflare-${CLOUDFLARE_ZLIBVER}"
        # if using cloudflare zlib libary set the default gzip compression level higher instead of 5 set to 9
        # defaults  benchmarks show performance is still very high even with level 9 with cloudflare zlib library
        # https://community.centminmod.com/posts/64167/
        if [[ "$CLOUDFLARE_ZLIBRAUTOMAX" = [yY] && -f /usr/local/nginx/conf/nginx.conf ]]; then
            sed -i 's|gzip_comp_level .*|gzip_comp_level 9;|' /usr/local/nginx/conf/nginx.conf
        else
            if [[ "$(grep 'gzip_comp_level 9' /usr/local/nginx/conf/nginx.conf)" && -f /usr/local/nginx/conf/nginx.conf ]]; then
                sed -i 's|gzip_comp_level .*|gzip_comp_level 5;|' /usr/local/nginx/conf/nginx.conf
            fi
        fi
        if [[ "$CLOUDFLARE_ZLIBRAUTOMAX" = [yY] && -f /usr/local/src/centminmod/config/nginx/nginx.conf ]]; then
            sed -i 's|gzip_comp_level .*|gzip_comp_level 9;|' /usr/local/src/centminmod/config/nginx/nginx.conf
        else
            if [[ "$(grep 'gzip_comp_level 9' /usr/local/src/centminmod/config/nginx/nginx.conf)" && -f /usr/local/src/centminmod/config/nginx/nginx.conf ]]; then
                sed -i 's|gzip_comp_level .*|gzip_comp_level 5;|' /usr/local/src/centminmod/config/nginx/nginx.conf
            fi
        fi
        if [[ "$CLOUDFLARE_ZLIB_DYNAMIC" = [yY] ]]; then
            ZLIBCF_RPATH='/usr/local/zlib-cf/lib:'
            ZLIBCF_OPT='-L/usr/local/zlib-cf/lib '
            ZLIBCFINC_OPT='-I/usr/local/zlib-cf/include '
            ZLIBCUSTOM_OPT=" --with-zlib=../zlib-cloudflare-${CLOUDFLARE_ZLIBVER}"
        fi
        # disable clang compiler and switch to gcc compiler due to clang 3.4.2 errors when enabling
        # cloudflare zlib
        if [[ "$CLANG" = [yY] && "$CENTOS_EIGHT" -eq '8' ]]; then
            if [[ "$CLANG" = [yY] || "$CLANG_FOUR" = [yY] || "$CLANG_FIVE" = [yY] || "$CLANG_SIX" = [yY] || "$CLANG_SEVEN" = [yY] || "$CLANG_EIGHT" = [yY] ]] && [ -f /usr/bin/clang ]; then
                CLANG='y'
            fi
        elif [[ "$CLANG" = [yY] && "$CENTOS_SEVEN" -eq '7' ]]; then
            CLANG='y'
            if [[ "$CLANG_MASTER" = [yY] && -f /opt/sbin/llvm-release_master/bin/clang ]]; then
                CLANG_FOUR='n'
                CLANG_FIVE='n'
                CLANG_SIX='n'
                CLANG_MASTER='y'
            elif [[ "$CLANG_EIGHT" = [yY] && -f /opt/sbin/llvm-release_80/bin/clang ]]; then
                CLANG_FOUR='n'
                CLANG_FIVE='n'
                CLANG_SIX='n'
                CLANG_SEVEN='n'
                CLANG_EIGHT='y'
                CLANG_MASTER='n'
            elif [[ "$CLANG_SEVEN" = [yY] && -f /opt/rh/llvm-toolset-7.0/root/usr/bin/clang ]]; then
                CLANG_FOUR='n'
                CLANG_FIVE='n'
                CLANG_SIX='n'
                CLANG_SEVEN='y'
                CLANG_EIGHT='n'
                CLANG_MASTER='n'
            elif [[ "$CLANG_SEVEN" = [yY] && -f /opt/sbin/llvm-release_70/bin/clang ]]; then
                CLANG_FOUR='n'
                CLANG_FIVE='n'
                CLANG_SIX='n'
                CLANG_SEVEN='y'
                CLANG_EIGHT='n'
                CLANG_MASTER='n'
            elif [[ "$CLANG_SIX" = [yY] && -f /opt/sbin/llvm-release_60/bin/clang ]]; then
                CLANG_FOUR='n'
                CLANG_FIVE='n'
                CLANG_SIX='y'
                CLANG_MASTER='n'
            elif [[ "$CLANG_FIVE" = [yY] && -f /opt/sbin/llvm-release_50/bin/clang ]]; then
                CLANG_FOUR='n'
                CLANG_FIVE='y'
                CLANG_SIX='n'
                CLANG_MASTER='n'
            else
                CLANG_FOUR='y'
                CLANG_FIVE='n'
                CLANG_SIX='n'
                CLANG_MASTER='n'
            fi
        elif [[ "$CLANG" = [yY] && "$CENTOS_SIX" -eq '6' ]]; then
            CLANG='n'
            DEVTOOLSETEIGHT='y'
            DEVTOOLSETSEVEN='n'
        elif [[ "$CLANG" = [nN] && "$CENTOS_SIX" -eq '6' ]]; then
            CLANG='n'
            DEVTOOLSETEIGHT='y'
            DEVTOOLSETSEVEN='n'
        fi
    fi

    if [[ "$CLOUDFLARE_ZLIBRESET" = [yY] && "$CLOUDFLARE_ZLIB" != [yY] ]]; then
        # if not using Cloudflare zlib library and you previously set gzip compression level to 9, reset it back to level 5
        if [[ "$(grep 'gzip_comp_level 9' /usr/local/nginx/conf/nginx.conf)" && -f /usr/local/nginx/conf/nginx.conf ]]; then
            sed -i 's|gzip_comp_level .*|gzip_comp_level 5;|' /usr/local/nginx/conf/nginx.conf
        fi
        if [[ "$(grep 'gzip_comp_level 9' /usr/local/src/centminmod/config/nginx/nginx.conf)" && -f /usr/local/src/centminmod/config/nginx/nginx.conf ]]; then
            sed -i 's|gzip_comp_level .*|gzip_comp_level 5;|' /usr/local/src/centminmod/config/nginx/nginx.conf
        fi
    fi

}

Nginx_Dep_Install() {

    # echo -e "${CMSG}[ Openssl-${openssl_latest_version:?} ]***********************************>>${CEND}\n"
    # # openssl
    # # shellcheck disable=SC2034
    # cd ${script_dir:?}/src
    # src_url=https://www.openssl.org/source/openssl-${openssl_latest_version:?}.tar.gz
    # [ ! -f openssl-${openssl_latest_version:?}.tar.gz ] && Download_src
    # [ -d openssl-${openssl_latest_version:?} ] && rm -rf openssl-${openssl_latest_version:?}
    # tar xf openssl-${openssl_latest_version:?}.tar.gz
    echo ""

}
# ngx_dynamicfunction() {
#     if [ ! -d /usr/local/nginx/conf ]; then
#         mkdir -p /usr/local/nginx/conf
#     fi
#     if [ -d /usr/local/nginx/conf ]; then
#         # detection routine to see if Nginx supports Dynamic modules from nginx 1.9.11+
#         if [ -f "$(which figlet)" ]; then
#             figlet -ckf standard "Check Nginx Dynamic Module Support"
#         fi
#         echo
#         echo "NGX_DYNAMICCHECK nginx_configure"
#         pwd
#         dynamicmodule_file
#         if [ "$ngver" ]; then
#             DETECT_NGXVER=$(awk '/define nginx_version  / {print $3}' "/svr-setup/nginx-$ngver/src/core/nginx.h")
#             echo "$DETECT_NGXVER"
#         else
#             DETECT_NGXVER=$(awk '/define nginx_version  / {print $3}' "/svr-setup/nginx-${NGINX_VERSION}/src/core/nginx.h")
#             echo "$DETECT_NGXVER"
#         fi
#         if [[ "$DETECT_NGXVER" -ge '1011005' && "$DYNAMIC_SUPPORT" = [yY] ]]; then
#             WITHCOMPAT_OPT=' --with-compat'
#         else
#             WITHCOMPAT_OPT=""
#         fi
#     fi # check for /usr/local/nginx/conf
# }

Install_Nginx() {

    INFO_MSG "[prepare nginx install ]***************************>>"
    [ -d "${nginx_install_dir:?}" ] && rm -rf "${nginx_install_dir:?}"
    cd "${script_dir:?}"/src
    nginx_file=nginx-${nginx_install_version:?}.tar.gz
    nginx_dir=nginx-${nginx_install_version:?}
    # shellcheck disable=SC2034
    src_url=https://nginx.org/download/$nginx_file
    [ ! -f "$nginx_file" ] && Download_src
    [ -d "$nginx_dir" ] && rm -rf "$nginx_dir"
    tar xf "$nginx_file"
    cd "$nginx_dir"
    if [ "${lua_install:?}" = 'y' ]; then
        luald_opt="--with-ld-opt=-Wl,-rpath,'/usr/local/luajit/lib'"
        nginx_modules_options="--with-ld-opt=-Wl,-rpath,'/usr/local/luajit/lib'"
        nginx_modules_options=$nginx_modules_options" --add-dynamic-module=../ngx_devel_kit-${ngx_devel_kit_version:?}"
        nginx_modules_options=$nginx_modules_options" --add-dynamic-module=../lua-nginx-module-${lua_nginx_module_version:?}"
        nginx_modules_options=$nginx_modules_options" --with-stream --with-stream_ssl_module"
        nginx_modules_options=$nginx_modules_options" --with-stream_realip_module --with-stream_ssl_preread_module"
        nginx_modules_options=$nginx_modules_options" --add-module=../stream-lua-nginx-module"
        export LUAJIT_LIB=/usr/local/luajit/lib
        export LUAJIT_INC=/usr/local/luajit/include/luajit-2.1
    else
        #nginx_modules_options="--with-ld-opt=-ljemalloc"
        luald_opt=""
    fi
    if [ "${Passenger_install:?}" = 'y' ]; then
        nginx_modules_options=$nginx_modules_options" --add-module=${nginx_addon_dir:?}"
    fi

    set_nginxver=$(echo "${nginx_install_version}" | sed -e 's|\.|0|g' | head -n1)
    #nginx_exportld_opt='-Wl,-E '
    # nginx compile export symbols when mixing nginx static and dynamic compiled libraries
    ngxextra_ldgoldccopt="$ngxextra_ldgoldccopt${FLTO_OPT} -fuse-ld=gold"
    ld_opt=$nginx_exportld_opt$ngxextra_ldgoldccopt

    ./configure --prefix="${nginx_install_dir:?}" \
        --sbin-path="${nginx_install_dir:?}"/sbin/nginx \
        --conf-path="${nginx_install_dir:?}"/conf/nginx.conf \
        --error-log-path="${nginx_install_dir:?}"/logs/error.log \
        --http-log-path="${nginx_install_dir:?}"/logs/access.log \
        --pid-path="${nginx_install_dir:?}"/run/nginx.pid \
        --lock-path="${nginx_install_dir:?}"/run/nginx.lock \
        --http-client-body-temp-path="${nginx_install_dir:?}"/tmp/client/ \
        --http-proxy-temp-path="${nginx_install_dir:?}"/tmp/proxy/ \
        --http-fastcgi-temp-path="${nginx_install_dir:?}"/tmp/fcgi/ \
        --http-uwsgi-temp-path="${nginx_install_dir:?}"/tmp/uwsgi \
        --http-scgi-temp-path="${nginx_install_dir:?}"/tmp/scgi \
        --user="${run_user:?}" --group="$run_user" \
        --with-http_stub_status_module \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_sub_module \
        --with-http_random_index_module \
        --with-http_addition_module \
        --with-http_realip_module \
        --with-http_v2_module \
        --with-openssl=../"${openssl_dir:?}" \
        --with-pcre=../"${pcredir:?}" --with-pcre-jit \
        --with-zlib=../"${zlib_dir:?}" \
        --add-dynamic-module=../ngx_brotli \
        --add-dynamic-module=../echo-nginx-module \
        --add-dynamic-module=../incubator-pagespeed-ngx-"${pagespeed_version:?}" "$nginx_modules_options" \
        --with-ld-opt="$ld_opt"

    # --add-dynamic-module=../nginx-ct-${ngx_ct_version:?} $nginx_modules_options

    # close debug
    sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc
    #enabled UTF8 support
    sed -i 's@./configure --disable-shared@./configure --disable-shared --enable-utf8 --enable-unicode-properties@' objs/Makefile
    echo -e "${CMSG}[nginx install ........ ]***********************************>>${CEND}\n"
    make -j${CpuProNum:?} && make install
    if [ -e "$nginx_install_dir/conf/nginx.conf" ]; then
        echo -e "${CMSG}[Nginx installed successfully !!!]***********************************>>${CEND}\n"
        mkdir -p ${nginx_install_dir:?}/tmp/client
        Config_Nginx
        # lsof -n | grep jemalloc
    else
        echo -e "${CFAILURE}[Nginx install failed, Please Contact the author !!!]*************>>${CEND}\n"
        kill -9 $$
    fi
}

Config_Nginx() {

    if [ -e $nginx_install_dir/conf/nginx.conf ]; then
        echo -e "${CMSG}[configure nginx]****************************************************>>${CEND}\n"
        mkdir -p ${nginx_install_dir:?}/conf.d
        mv $nginx_install_dir/conf/nginx.conf $nginx_install_dir/conf/nginx.conf_bak
        [ ! -d $nginx_install_dir/conf.d ] && mkdir -p $nginx_install_dir/conf.d
        if [ ${lua_install:?} = 'y' ]; then
            cp ${script_dir:?}/template/nginx/nginx_lua_template.conf $nginx_install_dir/conf/nginx.conf
        else
            cp ${script_dir:?}/template/nginx/conf.d/default.conf $nginx_install_dir/conf.d/default.conf
            cp ${script_dir:?}/template/nginx/nginx_template.conf $nginx_install_dir/conf/nginx.conf
        fi

        if [ ${Passenger_install:?} = 'y' ]; then
            [ -f $nginx_install_dir/conf.d/default.conf ] && rm -rf $nginx_install_dir/conf.d/default.conf
            cp ${script_dir:?}/template/nginx/conf.d/redmine.conf $nginx_install_dir/conf.d/redmine.conf
            sed -i "s#@passenger_root#${passenger_root:?}#g" $nginx_install_dir/conf.d/redmine.conf
            sed -i "s#@passenger_ruby#${passenger_ruby:?}#g" $nginx_install_dir/conf.d/redmine.conf
            sed -i "s#@passenger_user#${redmine_run_user:?}#g" $nginx_install_dir/conf.d/redmine.conf
            sed -i "s#@server_name#127.0.0.1#g" $nginx_install_dir/conf.d/redmine.conf
            sed -i "s#@redmine_root#${wwwroot_dir:?}/redmine#g" $nginx_install_dir/conf.d/redmine.conf
            sed -i "s#@nginx_root#$nginx_install_dir#g" $nginx_install_dir/conf.d/redmine.conf
        fi

        sed -i "s#@run_user#${run_user:?}#g" $nginx_install_dir/conf/nginx.conf
        # sed -i "s#@worker_processes#2#g" $nginx_install_dir/conf/nginx.conf
        sed -i "s#@nginx_install_dir#$nginx_install_dir#g" $nginx_install_dir/conf/nginx.conf

        # logrotate nginx log
        cat >/etc/logrotate.d/nginx <<EOF
        $nginx_install_dir/logs/*.log {
          daily
          rotate 5
          missingok
          dateext
          compress
          notifempty
          sharedscripts
          postrotate
            [ -e $nginx_install_dir/run/nginx.pid ] && kill -USR1 \`cat $nginx_install_dir/run/nginx.pid\`
          endscript
        }
EOF
        #init script
        mkdir -p ${nginx_install_dir:?}/init.d
        cp $script_dir/template/init.d/nginx.centos ${nginx_install_dir:?}/init.d/nginx
        chmod 775 ${nginx_install_dir:?}/init.d/nginx
        sed -i "s#^nginx_basedir=.*#nginx_basedir=${nginx_install_dir:?}#1" ${nginx_install_dir:?}/init.d/nginx
        #
        #systemd
        if ([ $OS == "Ubuntu" ] && [ ${Ubuntu_version:?} -ge 15 ]) || ([ $OS == "CentOS" ] && [ ${CentOS_RHEL_version:?} -ge 7 ]); then

            [ -L /lib/systemd/system/nginx.service ] && systemctl disable nginx.service && rm -f /lib/systemd/system/nginx.service
            cp $script_dir/template/systemd/nginx.service /lib/systemd/system/nginx.service
            sed -i "s#@nginx_basedir#${nginx_install_dir:?}#g" /lib/systemd/system/nginx.service
            systemctl enable nginx.service
            echo -e "${CMSG}[starting nginx ] **************************************************>>${CEND}\n"
            systemctl start nginx.service
            echo -e "${CMSG}[start nginx OK ] **************************************************>>${CEND}\n"
        else
            [ -L /etc/init.d/nginx ] && rm -f /etc/init.d/nginx
            ln -s ${nginx_install_dir:?}/init.d/nginx /etc/init.d/nginx
            echo -e "${CMSG}[starting nginx ] **************************************************>>${CEND}\n"
            service start nginx
            echo -e "${CMSG}[start nginx OK ] **************************************************>>${CEND}\n"
        fi

    else
        echo -e "${CFAILURE}[Nginx install failed, Please Contact the author !!!]*************>>${CEND}\n"
        kill -9 $$
    fi
}

Nginx_Install_Main() {

    if [ -f "$(which figlet)" ]; then
        figlet -ckf standard "Install Nginx"
    fi
    Nginx_Var && Nginx_Base_Dep_Install && Nginx_Dep_Install && Install_Nginx
    ##&& Nginx_Base_Dep_Install
}
