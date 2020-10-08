#!/bin/bash
# @Author: cnak47
# @Date: 2019-12-28 16:52:11
# @LastEditors: cnak47
# @LastEditTime: 2020-02-03 16:51:07
# @Description:
# #
install_git() {

    if [ "${OS}" == "CentOS" ]; then
        INFO_MSG " git${git_version:?} install ....."
        cd "${script_dir:?}"/src || exit
        # shellcheck disable=SC2034
        src_url=https://www.kernel.org/pub/software/scm/git/git-$git_version.tar.gz
        [ -d git-"$git_version" ] && rm -rf git-"$git_version"
        [ ! -f git-"$git_version".tar.gz ] && Download_src
        tar xf git-"$git_version".tar.gz
        cd git-"${git_version:?}" || exit
        # 安装依赖
        yum -y install gcc curl-devel expat-devel perl-devel
        [ -d /usr/local/git ] && rm -rf /usr/local/git
        export LIBRARY_PATH="/usr/local/openssl11/lib/:/usr/local/software/sharelib/lib/"
        make prefix=/usr/local/git all && make prefix=/usr/local/git install
        # shellcheck disable=SC2181
        if [ $? -eq 0 ]; then
            INFO_MSG "git$git_version install success ....."
            rm -rf /usr/bin/git* && ln -s /usr/local/git/bin/* /usr/bin/
        else
            FAILURE_MSG " git$git_version install fail ....."
        fi
        cd .. && rm -rf git-"$git_version"
    fi
}

install_git_main() {
    install_git

}
