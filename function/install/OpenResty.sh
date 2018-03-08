#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              OpenResty.sh
# @Desc
#----------------------------------------------------------------------------

OpenResty_Dep_Install(){

    # 依赖安装
    #yum -y install readline-devel pcre-devel openssl-devel gcc
    echo ""


}

Install_OpenResty(){

    echo -e "${CMSG}[create user and group ]***********************************>>${CEND}\n"

    grep ${run_user:?} /etc/group >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        groupadd $run_user
    fi
    id $run_user >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        useradd -g $run_user  -M -s /sbin/nologin $run_user
    fi

    echo -e "${CMSG}[prepare OpenResty install ]***********************************>>${CEND}\n"
    [ -d ${openresty_install_dir:?} ] && rm -rf ${openresty_install_dir:?}
    cd ${script_dir:?}/src
    # shellcheck disable=SC2034
    src_url=https://openresty.org/download/openresty-${openresty_version:?}.tar.gz
    [ ! -f openresty-${openresty_version:?}.tar.gz ] && Download_src
    [ -d openresty-${openresty_version:?} ] && rm -rf openresty-${openresty_version:?}
    tar xvf openresty-${openresty_version:?}.tar.gz
    cd openresty-${openresty_version:?}

    # if [ ${lua_install:?} = 'y' ]; then
    #     nginx_modules_options="--with-ld-opt='-Wl,-rpath,/usr/local/luajit/lib' --add-module=${script_dir:?}/src/ngx_devel_kit-${ngx_devel_kit_version:?} --add-module=${script_dir:?}/src/lua-nginx-module-${lua_nginx_module_version:?}"
    #     export LUAJIT_LIB=/usr/local/luajit/lib
    #     export LUAJIT_INC=/usr/local/luajit/include/luajit-2.1
    #
    # else
    #     nginx_modules_options=''
    # fi
    nginx_modules_options=" --add-module=${script_dir:?}/src/ngx_brotli --add-module=${script_dir:?}/src/incubator-pagespeed-ngx-${pagespeed_version:?}"

    ./configure --prefix=${openresty_install_dir:?} \
        --sbin-path=${openresty_install_dir:?}/sbin/nginx \
        --conf-path=${openresty_install_dir:?}/conf/nginx.conf \
        --error-log-path=${openresty_install_dir:?}/logs/error.log \
        --http-log-path=${openresty_install_dir:?}/logs/access.log \
        --pid-path=${openresty_install_dir:?}/run/nginx.pid  \
        --lock-path=${openresty_install_dir:?}/run/nginx.lock \
        --user=$run_user --group=$run_user \
        --with-http_stub_status_module \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_sub_module \
        --with-http_random_index_module \
        --with-http_addition_module \
        --with-http_realip_module  \
        --with-http_v2_module \
        --with-http_iconv_module \
        --with-stream=dynamic \
        --http-client-body-temp-path=${openresty_install_dir:?}/tmp/client/ \
        --http-proxy-temp-path=${openresty_install_dir:?}/tmp/proxy/ \
        --http-fastcgi-temp-path=${openresty_install_dir:?}/tmp/fcgi/ \
        --http-uwsgi-temp-path=${openresty_install_dir:?}/tmp/uwsgi \
        --http-scgi-temp-path=${openresty_install_dir:?}/tmp/scgi \
        --with-ld-opt="-ljemalloc" --with-openssl=${script_dir:?}/src/openssl-${openssl_version:?} \
        --with-pcre=${script_dir:?}/src/pcre-${pcre_version:?} --with-pcre-jit \
        --with-zlib=${script_dir:?}/src/zlib-${zlib_version:?} \
        --with-luajit $nginx_modules_options
        # --with-http_postgres_module \
    # close debug
    # sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc
    #打开UTF8支持
    # sed -i 's@./configure --disable-shared@./configure --disable-shared --enable-utf8 --enable-unicode-properties@' objs/Makefile
    echo -e "${CMSG}[OpenResty install ........ ]***********************************>>${CEND}\n"
    make -j${CpuProNum:?} && make install
    if [ -e "$openresty_install_dir/conf/nginx.conf" ]; then
        echo -e "${CMSG}[OpenResty installed successfully !!!]***********************************>>${CEND}\n"
        mkdir -p ${openresty_install_dir:?}/tmp/client
    else
        echo -e "${CFAILURE}[OpenResty install failed, Please Contact the author !!!]*************>>${CEND}\n"
        kill -9 $$
    fi

}

Config_OpenResty(){

    echo ""
}

OpenResty_Install_Main() {
    Nginx_Var && Nginx_Base_Dep_Install
    # && OpenResty_Dep_Install && Install_OpenResty && Config_OpenResty
}
