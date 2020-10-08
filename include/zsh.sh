#!/bin/bash
# @Author: cnak47
# @Date: 2020-01-02 14:38:29
# @LastEditors: cnak47
# @LastEditTime: 2020-03-29 10:47:20
# @Description:
# #

install_zsh() {

    if [ ! -e "$(command -v zsh)" ]; then
        NCURSES=$(rpm -qa | grep 'ncurses-devel' | head -n1)
        if [ -z "$NCURSES" ]; then
            yum -y install ncurses-devel
        fi
        # shellcheck disable=SC2154
        cd "$script_dir"/src || exit
        # shellcheck disable=SC2034
        src_url=https://sourceforge.net/projects/zsh/files/zsh/${zsh_version:?}/zsh-$zsh_version.tar.xz/download
        [ ! -f zsh-"$zsh_version".tar.xz ] && Download_src && mv download zsh-"$zsh_version".tar.xz
        [ -d zsh-"$zsh_version" ] && rm -rf zsh-"$zsh_version"
        tar xvf zsh-"$zsh_version".tar.xz
        cd zsh-"$zsh_version" || exit
        ./configure && make && make install
        # shellcheck disable=SC2181
        if [ $? -eq 0 ]; then
            SUCCESS_MSG "zsh $zsh_version installed ....."
            # zsh 加入到ect shells 中
            if [ "$(grep -c /usr/local/bin/zsh /etc/shells)" -eq 0 ]; then
                echo "/usr/local/bin/zsh" | tee -a /etc/shells
            fi
            CHECK_ZSH_INSTALLED=$(grep -c /zsh$ /etc/shells)

            if [ "$CHECK_ZSH_INSTALLED" -ge 1 ]; then
                id "${default_user:?}" >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    default_user_exists=1
                    normal_zsh=/home/${default_user:?}/.oh-my-zsh
                else
                    default_user_exists=0
                fi

                root_zsh=/root/.oh-my-zsh
                cp /etc/passwd /etc/passwd_bak
                # root use zsh
                sed -i "s@root:/bin/bash@root:/usr/local/bin/zsh@g" /etc/passwd
                # default_user  use zsh
                if [ $default_user_exists -eq 1 ]; then
                    sed -i "s@${default_user:?}:/bin/bash@${default_user:?}:/usr/local/bin/zsh@g" /etc/passwd
                fi

                # Oh My Zsh
                if [ -d $root_zsh ] || [ -d "$normal_zsh" ]; then
                    WARNING_MSG "root or ${default_user:?} already have Oh My Zsh installed !!!"
                    WARNING_MSG "You'll need to remove $ZSH if you want to re-install !!!"
                else
                    if [ $default_user_exists -eq 1 ]; then
                        INFO_MSG "[${default_user:?}] Oh My Zsh Installing ....."
                        if [ -d "$script_dir"/src/oh-my-zsh ]; then
                            cd "$script_dir"/src/oh-my-zsh && git pull
                            cd "$script_dir"/src && cp -ax "$script_dir"/src/oh-my-zsh /home/"${default_user:?}"/.oh-my-zsh
                            chown -Rf "${default_user:?}":"${default_user:?}" /home/"${default_user:?}"/.oh-my-zsh/
                        else
                            sudo -u "${default_user:?}" -H git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git "$normal_zsh"
                        fi
                        if [ -f /home/"${default_user:?}"/.zshrc ] || [ -h /home/"${default_user:?}"/.zshrc ]; then
                            INFO_MSG "Found /home/${default_user:?}/.zshrc. Backing up to /home/${default_user:?}/.zshrc.pre-oh-my-zsh ..... "
                            sudo -u "${default_user:?}" -H mv /home/"${default_user:?}"/.zshrc /home/"${default_user:?}"/.zshrc.pre-oh-my-zsh
                        fi
                        INFO_MSG "Using the Oh My Zsh template file and adding it to /home/${default_user:?}/.zshrc ..... "
                        sudo -u "${default_user:?}" -H cp "$normal_zsh"/templates/zshrc.zsh-template /home/"${default_user:?}"/.zshrc
                        sudo -u "${default_user:?}" -H sed -i "/^export ZSH=/c export ZSH=$normal_zsh" /home/"${default_user:?}"/.zshrc

                        # INFO_MSG " Powerlevel9k theme install ..... "
                        # [ -d /home/"${default_user:?}"/.powerlevel9k ] && sudo -u "${default_user:?}" -H rm -rf /home/"${default_user:?}"/.powerlevel9k
                        # [ -d /root/.powerlevel9k ] && rm -rf /root/.powerlevel9k
                        # if [ ! -d "$script_dir"/src/powerlevel9k ]; then
                        #     sudo -u "${default_user:?}" -H git clone https://github.com/bhilburn/powerlevel9k.git /home/"${default_user:?}"/.powerlevel9k
                        # else
                        #     cd "$script_dir"/src/powerlevel9k && git pull
                        #     cd "$script_dir"/src && cp -ax "$script_dir"/src/powerlevel9k /home/"${default_user:?}"/.powerlevel9k
                        #     chown -Rf "${default_user:?}":"${default_user:?}" /home/"${default_user:?}"/.powerlevel9k/
                        # fi
                        # sudo -u "${default_user:?}" -H mkdir -p /home/"${default_user:?}"/.oh-my-zsh/custom/themes/
                        # sudo -u "${default_user:?}" -H ln -f -s /home/"${default_user:?}"/.powerlevel9k /home/"${default_user:?}"/.oh-my-zsh/custom/themes/powerlevel9k
                        INFO_MSG " Powerlevel10k theme install ..... "
                        [ -d /home/"${default_user:?}"/.powerlevel10k ] && sudo -u "${default_user:?}" -H rm -rf /home/"${default_user:?}"/.powerlevel10k
                        [ -d /root/.powerlevel10k ] && rm -rf /root/.powerlevel10k
                        if [ ! -d "$script_dir"/src/powerlevel10k ]; then
                            sudo -u "${default_user:?}" -H git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
                                /home/"${default_user:?}"/.powerlevel10k
                        else
                            cd "$script_dir"/src/powerlevel10k && git pull
                            cd "$script_dir"/src && cp -ax "$script_dir"/src/powerlevel10k /home/"${default_user:?}"/.powerlevel10k
                            chown -Rf "${default_user:?}":"${default_user:?}" /home/"${default_user:?}"/.powerlevel10k/
                        fi
                        sudo -u "${default_user:?}" -H mkdir -p /home/"${default_user:?}"/.oh-my-zsh/custom/themes/
                        sudo -u "${default_user:?}" -H ln -f -s /home/"${default_user:?}"/.powerlevel10k /home/"${default_user:?}"/.oh-my-zsh/custom/themes/powerlevel10k

                        INFO_MSG " Powerline Fonts install ..... "
                        if [ ! -d /home/"${default_user:?}"/fonts ]; then
                            if [ -d "$script_dir"/src/powerline-fonts ]; then
                                cd "$script_dir"/src/powerline-fonts && git pull
                                cd "$script_dir"/src && cp -ax "$script_dir"/src/powerline-fonts /home/"${default_user:?}"/fonts
                                chown -Rf "${default_user:?}":"${default_user:?}" /home/"${default_user:?}"/fonts
                            else
                                sudo -u "${default_user:?}" -H git clone https://github.com/powerline/fonts.git /home/"${default_user:?}"/fonts
                            fi
                        fi
                        cd /home/"${default_user:?}"/fonts || git pull
                        sudo -u "${default_user:?}" -H ./install.sh
                        cd "$script_dir" || exit

                        INFO_MSG "custom zsh theme install ..... "
                        [ ! -d /home/"${default_user:?}"/.oh-my-zsh/custom/themes ] && sudo -u "${default_user:?}" -H mkdir -p /home/"${default_user:?}"/.oh-my-zsh/custom/themes
                        sudo -u "${default_user:?}" -H cp "$script_dir"/template/zsh/ak47.zsh-theme /home/"${default_user:?}"/.oh-my-zsh/custom/themes/

                        # 修改配置文件
                        if [ -f /home/"${default_user:?}"/.zshrc ] || [ -h /home/"${default_user:?}"/.zshrc ]; then

                            sudo -u "${default_user:?}" -H cp /home/"${default_user:?}"/.zshrc /home/"${default_user:?}"/.zshrc.pre
                            # 注释原有模版
                            sudo -u "${default_user:?}" -H sed -i '\@ZSH_THEME=@s@^@\#@1' /home/"${default_user:?}"/.zshrc
                            sudo -u "${default_user:?}" -H sed -i "s@^#ZSH_THEME.*@&\nsetopt no_nomatch@" /home/"${default_user:?}"/.zshrc
                            # 设置新模版
                            sudo -u "${default_user:?}" -H sed -i "s@^#ZSH_THEME.*@&\nZSH_THEME=\"ak47\"@" /home/"${default_user:?}"/.zshrc
                            # 设置插件
                            sudo -u "${default_user:?}" -H sed -i "/^plugins=(git)/c plugins=(git z wd extract)" /home/"${default_user:?}"/.zshrc
                            # set language environment
                            sudo -u "${default_user:?}" -H sed -i "s@^# export LANG=en_US.UTF-8@&\nexport LANG=en_US.UTF-8@" /home/"${default_user:?}"/.zshrc
                        fi
                    fi
                    # root 用户
                    INFO_MSG "[root] Oh My Zsh Installing ....."

                    if [ -d "$script_dir"/src/oh-my-zsh ]; then
                        cd "$script_dir"/src/oh-my-zsh && git pull
                        cd "$script_dir"/src && cp -ax "$script_dir"/src/oh-my-zsh /root/.oh-my-zsh
                    else
                        git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git $root_zsh
                    fi

                    # INFO_MSG " Powerlevel9k theme install ..... "
                    # if [ ! -d "$script_dir"/src/powerlevel9k ]; then
                    #     git clone https://github.com/bhilburn/powerlevel9k.git /root/.powerlevel9k

                    # else
                    #     cd "$script_dir"/src/powerlevel9k && git pull
                    #     cd "$script_dir"/src && cp -ax "$script_dir"/src/powerlevel9k /root/.powerlevel9k
                    # fi

                    # mkdir -p /root/.oh-my-zsh/custom/themes/
                    # ln -s /root/.powerlevel9k /root/.oh-my-zsh/custom/themes/powerlevel9k

                    INFO_MSG " Powerlevel10k theme install ..... "
                    if [ ! -d "$script_dir"/src/powerlevel10k ]; then
                        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
                            /root/.powerlevel10k

                    else
                        cd "$script_dir"/src/powerlevel10k && git pull
                        cd "$script_dir"/src && cp -ax "$script_dir"/src/powerlevel10k /root/.powerlevel10k
                    fi

                    mkdir -p /root/.oh-my-zsh/custom/themes/
                    ln -s /root/.powerlevel10k /root/.oh-my-zsh/custom/themes/powerlevel10k

                    INFO_MSG " Powerline Fonts install ..... "
                    if [ ! -d /root/fonts ]; then
                        if [ -d "$script_dir"/src/powerline-fonts ]; then
                            cd "$script_dir"/src/powerline-fonts && git pull
                            cd "$script_dir"/src && cp -ax "$script_dir"/src/powerline-fonts /root/fonts
                        else
                            git clone https://github.com/powerline/fonts.git /root/fonts
                        fi
                    fi
                    cd /root/fonts && git pull && ./install.sh
                    cd "$script_dir" || exit

                    INFO_MSG " custom zsh theme install ....."
                    [ ! -d /root/.oh-my-zsh/custom/themes ] && mkdir -p /root/.oh-my-zsh/custom/themes
                    cp "$script_dir"/template/zsh/ak47.zsh-theme /root/.oh-my-zsh/custom/themes/
                    #fi

                    if [ -f /root/.zshrc ] || [ -h /root/.zshrc ]; then
                        INFO_MSG" Found /root/.zshrc. Backing up to /root/.zshrc.pre-oh-my-zsh ..... "
                        mv /root/.zshrc /root/.zshrc.pre-oh-my-zsh
                    fi
                    cp $root_zsh/templates/zshrc.zsh-template /root/.zshrc

                    sed -i "/^export ZSH=/c export ZSH=$root_zsh" /root/.zshrc
                    if [ -f /root/.zshrc ] || [ -h /root/.zshrc ]; then
                        cp /root/.zshrc /root/.zshrc.pre
                        # 注释原有模版
                        sed -i '\@ZSH_THEME=@s@^@\#@1' /root/.zshrc
                        sed -i "s@^#ZSH_THEME.*@&\nsetopt no_nomatch@" /root/.zshrc
                        # 设置新模版
                        sed -i "s@^#ZSH_THEME.*@&\nZSH_THEME=\"ak47\"@" /root/.zshrc
                        # 设置插件
                        sed -i "/^plugins=(git)/c plugins=(git z wd extract)" /root/.zshrc
                        # set language environment
                        sed -i "s@^# export LANG=en_US.UTF-8@&\nexport LANG=en_US.UTF-8@" /root/.zshrc
                    fi
                    SUCCESS_MSG "Oh My Zsh install success ..... "
                fi
            else
                WARNING_MSG "zsh $zsh_version is not installed!!! Please install zsh first !!!!! "
            fi
            unset CHECK_ZSH_INSTALLED
            unset normal_zsh
            unset root_zsh
        else
            FAILURE_MSG "zsh $zsh_version install failure ！！！！！"
        fi
        rm -rf "$script_dir"/src/zsh-"$zsh_version"
    else
        WARNING_MSG "zsh have already installed ！！！！！"

    fi
}
