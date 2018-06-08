#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              docker.sh
# @Desc
#----------------------------------------------------------------------------

Install_Docker() {

    INFO_MSG "[ docker-compose V${docker_compose_version:?} install ......]"
    [ -f /usr/local/bin/docker-compose ] && mv /usr/local/bin/docker-compose /usr/local/bin/docker-compose.bak
    cd ${script_dir:?}/src
    curl -L https://github.com/docker/compose/releases/download/${docker_compose_version:?}/docker-compose-"$(uname -s)"-"$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    INFO_MSG "[ Install command completion for the bash and zsh shell ......]"
    if [ $SHELL = '/usr/local/bin/zsh' ] || [ $SHELL = '/bin/zsh' ]; then
        [ ! -d ~/.zsh/completion ] && mkdir -p ~/.zsh/completion
        curl -L https://raw.githubusercontent.com/docker/compose/${docker_compose_version:?}/contrib/completion/zsh/_docker-compose > ~/.zsh/completion/_docker-compose
        echo -e '\nfpath=(~/.zsh/completion $fpath)' >> ~/.zshrc
        echo 'autoload -Uz compinit && compinit -i' >> ~/.zshrc
        docker-compose --version
        # reload shell
        exec $SHELL -l

    fi



}
