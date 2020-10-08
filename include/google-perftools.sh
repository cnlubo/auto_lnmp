#!/bin/bash
# @Author: cnak47
# @Date: 2020-03-29 10:45:02
# @LastEditors: cnak47
# @LastEditTime: 2020-03-29 16:18:29
# @Description:
# #

install_gperftools() {

    INFO_MSG "*************************************************"
    INFO_MSG "* Source Install Google Perftools"
    INFO_MSG "*************************************************"

    INFO_MSG "* download libunwind-${libunwind_version:?} "

    libunwind_file="libunwind-${libunwind_version:?}.tar.gz"
    libunwind_dir="libunwind-${libunwind_version}"
    # shellcheck disable=SC2034
    src_url=https://download.savannah.gnu.org/releases/libunwind/${libunwind_file}
    cd "${script_dir:?}"/src || return
    [ ! -f "${libunwind_file:?}" ] && Download_src

    INFO_MSG "* download gperftools-${gperftools_version:?} "

    gperftool_file="gperftools-${gperftools_version:?}.tar.gz"
    gperftool_dir="gperftools-${gperftools_version}"
    # shellcheck disable=SC2034
    src_url="https://github.com/gperftools/gperftools/releases/download/gperftools-${gperftools_version:?}/${gperftool_file:?}"
    [ ! -f "${gperftool_file:?}" ] && Download_src

    INFO_MSG "Compiling libunwind-${libunwind_version:?}"
    cd "${script_dir:?}"/src || return
    [ -d "${libunwind_dir:?}" ] && rm -rf "${libunwind_dir:?}"
    tar zxf "${libunwind_file:?}"
    cd "${libunwind_dir:?}" || exit
    ./configure && make -j"${CpuProNum:?}" && make install

    INFO_MSG "Compiling gperftools-${gperftools_version:?}"
    cd "${script_dir:?}"/src || return
    [ -d "${gperftool_dir:?}" ] && rm -rf "${gperftool_dir:?}"
    tar zxf "${gperftool_file:?}"
    cd "${gperftool_dir:?}" || exit

    ./configure --with-tcmalloc-pagesize="${tcmalloc_pagesize:?}"
    make -j"${CpuProNum:?}" && make install

}
