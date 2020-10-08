#!/bin/bash
# @Author: cnak47
# @Date: 2018-04-30 23:59:11
# @LastEditors: cnak47
# @LastEditTime: 2020-04-06 10:16:14
# @Description:
# #

Install_LuaJIT() {

    if [ -d /usr/local/luajit ]; then
        SUCCESS_MSG "[ LuaJIT has been install ...... ]"
    else

        INFO_MSG "*************************************************"
        INFO_MSG "* luaJIT-${LuaJIT_version:?}install"
        INFO_MSG "*************************************************"
        cd "${script_dir:?}"/src || exit
        [ -d luajit-2.0 ] && rm -rf luajit-2.0
        git clone http://luajit.org/git/luajit-2.0.git
        cd luajit-2.0 && git checkout v"${LuaJIT_version:?}"
        # enable GC64 mode in LuaJIT builds on 64bit systems
        # https://blog.openresty.com/en/luajit-gc64-mode/
        make -j"${CpuProNum:?}" XCFLAGS='-DLUAJIT_ENABLE_GC64'
        make install PREFIX=/usr/local/luajit
        [ -f /etc/ld.so.conf.d/luajit.conf ] && rm -rf /etc/ld.so.conf.d/luajit.conf
        echo "/usr/local/luajit/lib" >/etc/ld.so.conf.d/luajit.conf && ldconfig -v
        if [ $? -eq 0 ]; then
            INFO_MSG " [ openresty lua-cjson install ] *********>>"
            cd "${script_dir:?}"/src || exit
            [ -d lua-cjson ] && rm -rf lua-cjson
            git clone https://github.com/openresty/lua-cjson.git
            cd lua-cjson && cp Makefile Makefile.bak
            sed -i "s@^PREFIX =.*@PREFIX =             /usr/local/luajit@" Makefile
            sed -i "s@^LUA_INCLUDE_DIR ?=.*@LUA_INCLUDE_DIR ?=   /usr/local/luajit/include/luajit-2.1@" Makefile
            make -j"${CpuProNum:?}" && make install
        else
            FAILURE_MSG "[ LuaJIT-${LuaJIT_version:?} install failed, Please contact the author !!!] *******>>"
            kill -9 $$
        fi
    fi
}

install_openresty_luajit2() {

    if [ -d /usr/local/luajit ]; then
        SUCCESS_MSG "[ LuaJIT has been install ...... ]"
    else

        INFO_MSG "************************************************************"
        INFO_MSG "* OpenResty's LuaJIT luaJIT-${luajit_openresty_ver?}"
        INFO_MSG "************************************************************"
        cd "${script_dir:?}"/src || exit
        [ -d luajit2 ] && rm -rf luajit2
        git clone https://github.com/openresty/luajit2.git
        cd luajit2 && git checkout v"${luajit_openresty_ver:?}"
        # enable GC64 mode in LuaJIT builds on 64bit systems
        # https://blog.openresty.com/en/luajit-gc64-mode/
        make -j"${CpuProNum:?}" XCFLAGS='-DLUAJIT_ENABLE_GC64'
        make install PREFIX=/usr/local/luajit
        #if [ $? -eq 0 ]; then
        if make install PREFIX=/usr/local/luajit; then
            [ -f /etc/ld.so.conf.d/luajit.conf ] && rm -rf /etc/ld.so.conf.d/luajit.conf
            echo "/usr/local/luajit/lib" >/etc/ld.so.conf.d/luajit.conf
            ldconfig -v
            MAJVER=$(awk -F "=  " '/MAJVER=  / {print $2}' Makefile)
            MINVER=$(awk -F "=  " '/MINVER=  / {print $2}' Makefile)
            RELVER=$(awk -F "=  " '/RELVER=  / {print $2}' Makefile)
            PREREL=$(awk -F "=  " '/PREREL=  / {print $2}' Makefile)
            INFO_MSG "luijit-${MAJVER}.${MINVER}.${RELVER}${PREREL}"
            INFO_MSG " [ openresty lua-cjson install ] *********>>"
            cd "${script_dir:?}"/src || exit
            [ -d lua-cjson ] && rm -rf lua-cjson
            git clone https://github.com/openresty/lua-cjson.git
            cd lua-cjson && cp Makefile Makefile.bak
            sed -i "s@^PREFIX =.*@PREFIX =             /usr/local/luajit@" Makefile
            sed -i "s@^LUA_INCLUDE_DIR ?=.*@LUA_INCLUDE_DIR ?=   /usr/local/luajit/include/luajit-2.1@" Makefile
            make -j"${CpuProNum:?}" && make install
        else
            FAILURE_MSG "[ LuaJIT-${luajit_openresty_ver:?} install failed, Please contact the author !!!] *******>>"
            kill -9 $$
        fi
    fi
}
