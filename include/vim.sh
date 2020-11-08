#!/bin/bash
# @Author: cnak47
# @Date: 2020-01-03 10:23:49
# @LastEditors: cnak47
# @LastEditTime: 2020-11-07 21:20:36
# @Description:
# #
install_vim() {
    # remove old vim
    OLDVIM=$(rpm -qa | grep 'vim' | head -n1)
    if [ -n "$OLDVIM" ]; then
        yum -y remove vim-common vim-filesystem
    fi
    if [ ! -e "$(command -v vim)" ]; then
        if [ -e "$(command -v python3)" ]; then
            cd "${script_dir:?}"/src || exit
            INFO_MSG " vim install begin ..... "
            yum -y install ncurses-devel perl-ExtUtils-Embed lua-devel \
                ruby-devel luajit-devel gtk2-devel \
                perl-Extutils-ParseXS perl-ExtUtils-XSpp \
                perl-ExtUtils-CBuilder ctags libXt-devel

            [ ! -d vim ] && git clone https://github.com/vim/vim.git
            cd vim && git pull
            if [ -f /opt/rh/devtoolset-8/root/usr/bin/gcc ]; then
                # shellcheck disable=SC1091
                source /opt/rh/devtoolset-8/enable
                gcc --version
            fi
            ./configure --prefix=/usr/local/vim \
                --with-features=huge \
                --enable-gui=gtk2 \
                --with-x \
                --enable-fontset \
                --enable-cscope \
                --enable-multibyte \
                --enable-python3interp=yes \
                --with-python3-command=python3 \
                --enable-luainterp \
                --enable-rubyinterp \
                --enable-perlinterp \
                --enable-multibyte \
                --enable-xim \
                --with-luajit \
                --with-compiledby="ak47"

            make CFLAGS="-O2 -D_FORTIFY_SOURCE=1" -j"${CpuProNum:?}" && make install
            # shellcheck disable=SC2181
            if [ $? -eq 0 ]; then
                SUCCESS_MSG "vim install success !!!!! "
                [ -h /usr/local/bin/vim ] && rm -rf /usr/local/bin/vim
                ln -s /usr/local/vim/bin/vim /usr/local/bin/vim
            else
                FAILURE_MSG " vim install failure !!!!! "
            fi
        else
            WARNING_MSG "python3 not exists please first install ..... "
        fi
    else
        WARNING_MSG " vim  has been  install !!!!! "
    fi

}
install_vim_plugin() {

    if [ -f /usr/local/bin/vim ] || [ -L /usr/local/bin/vim ]; then
        INFO_MSG "[ update/install plugins using Vim-plug ]"
        [ -d /opt/modules/vim ] && rm -rf /opt/modules/vim
        mkdir -p /opt/modules/vim
        mkdir -p /opt/modules/vim/autoload
        mkdir -p /opt/modules/vim/bundle
        mkdir -p /opt/modules/vim/syntax
        cp "$script_dir"/config/vim/vimrc /opt/modules/vim/
        cp "$script_dir"/config/vim/vimrc.bundles /opt/modules/vim/
        cp "$script_dir"/config/vim/filetype.vim /opt/modules/vim/
        cp "$script_dir"/config/vim/syntax/nginx.vim /opt/modules/vim/syntax/
        cp "$script_dir"/config/vim/plug.vim /opt/modules/vim/autoload
        # root user
        rm -rf /root/.vim /root/.vimrc /root/.gvimrc /root/.vimrc.bundles
        ln -s /opt/modules/vim/vimrc /root/.vimrc
        ln -s /opt/modules/vim/vimrc.bundles /root/.vimrc.bundles
        ln -s /opt/modules/vim /root/.vim
        system_shell=$SHELL
        export SHELL="/bin/sh"
        # sudo -u "${default_user:?}" -H curl -fLo "$home_path"/.vim/autoload/plug.vim --create-dirs \
        #     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

        # sudo -u "${default_user:?}" -H wget -c -P "$home_path"/.vim/autoload/ --no-check-certificate https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        vim -u /root/.vimrc.bundles +PlugUpgrade! +PlugInstall! +PlugClean! +qall
        export SHELL=$system_shell
        # default_user
        if id "${default_user:?}" >/dev/null 2>&1; then
            INFO_MSG "[ Configure ${default_user:?} vim plugin ]"
            home_path=/home/${default_user:?}
            rm -rf "$home_path"/.vim "$home_path"/.vimrc "$home_path"/.gvimrc "$home_path"/.vimrc.bundles
            chown -Rf "${default_user:?}":"${default_user:?}" /opt/modules/vim/
            sudo -u "${default_user:?}" -H ln -s /opt/modules/vim/vimrc "$home_path"/.vimrc
            sudo -u "${default_user:?}" -H ln -s /opt/modules/vim/vimrc.bundles "$home_path"/.vimrc.bundles
            sudo -u "${default_user:?}" -H ln -s /opt/modules/vim "$home_path"/.vim

        fi
        SUCCESS_MSG " vim plugins install done !!!!! "
    else

        WARNING_MSG " vim not exists please first install ..... "
    fi
}
