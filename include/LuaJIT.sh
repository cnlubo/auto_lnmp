#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              LuaJIT.sh
# @Desc
#----------------------------------------------------------------------------

Install_LuaJIT() {

    if [ -d /usr/local/luajit ];then
        SUCCESS_MSG "[ LuaJIT has been install ...... ]"
    else
        echo -e "${CMSG}[ LuaJIT-${LuaJIT_version:?} instal begin ] *********************>>${CEND}\n"
        cd ${script_dir:?}/src
        [ -d luajit-2.0 ] && rm -rf luajit-2.0
        git clone http://luajit.org/git/luajit-2.0.git
        cd luajit-2.0 && git checkout v${LuaJIT_version:?}
        make && make install PREFIX=/usr/local/luajit
        [ -f /etc/ld.so.conf.d/luajit.conf ] && rm -rf /etc/ld.so.conf.d/luajit.conf
        echo "/usr/local/luajit/lib" > /etc/ld.so.conf.d/luajit.conf && ldconfig -v
        if [ $? -eq 0 ];then
            #echo "${CMSG} [ LuaJIT-${LuaJIT_version:?} install success ! ] **********************************>>${CEND}"
            # echo -e "${CMSG}[ Lua CJSON ${Lua_CJSON_version:?} install ] *********************>>${CEND}\n"
            # cd ${script_dir:?}/src
            # # shellcheck disable=SC2034
            # src_url=https://www.kyne.com.au/~mark/software/download/lua-cjson-${Lua_CJSON_version:?}.tar.gz
            # [ ! -f lua-cjson-${Lua_CJSON_version:?}.tar.gz ] && Download_src
            # [ -d lua-cjson-${Lua_CJSON_version:?} ] && rm -rf lua-cjson-${Lua_CJSON_version:?}
            # tar xf lua-cjson-${Lua_CJSON_version:?}.tar.gz && cd lua-cjson-${Lua_CJSON_version:?}
            echo "${CMSG} [ openresty lua-cjson install ] **********************************>>${CEND}"
            cd ${script_dir:?}/src
            [ -d lua-cjson ] && rm -rf lua-cjson
            git clone https://github.com/openresty/lua-cjson.git && cd lua-cjson
            cp Makefile Makefile.bak
            sed -i "s@^PREFIX =.*@PREFIX =             /usr/local/luajit@" Makefile
            sed -i "s@^LUA_INCLUDE_DIR ?=.*@LUA_INCLUDE_DIR ?=   /usr/local/luajit/include/luajit-2.1@" Makefile
            make && make install
        else
            echo "${CFAILURE}[ LuaJIT-${LuaJIT_version:?} install failed, Please contact the author !!!] ****************************>>${CEND}"
            kill -9 $$
        fi
    fi
}
