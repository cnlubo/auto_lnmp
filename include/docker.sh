#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              docker.sh
# @Desc
#----------------------------------------------------------------------------

Install_Docker() {

    INFO_MSG "[ Uninstall old versions Docker ......]"
    yum remove -y docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-selinux \
        docker-engine-selinux \
        docker-engine
    if [ ! -f /bin/docker ]; then
        INFO_MSG "[ Docker CE install ......]"
        yum install -y yum-utils device-mapper-persistent-data lvm2
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        # Enable the edge and test repositories
        # yum-config-manager --enable docker-ce-edge
        # yum-config-manager --enable docker-ce-test
        yum install -y docker-ce
        INFO_MSG "[ Start Docker ......]"
        systemctl start docker
        INFO_MSG "[ docker-compose V${docker_compose_version:?} install ......]"
        [ -f /usr/local/bin/docker-compose ] && mv /usr/local/bin/docker-compose /usr/local/bin/docker-compose.bak
        cd ${script_dir:?}/src
        curl -L https://github.com/docker/compose/releases/download/${docker_compose_version:?}/docker-compose-"$(uname -s)"-"$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        INFO_MSG "[ Install command completion for the bash or zsh shell ......]"
        if [ $SHELL = '/usr/local/bin/zsh' ] || [ $SHELL = '/bin/zsh' ]; then
            [ ! -d ~/.zsh/completion ] && mkdir -p ~/.zsh/completion
            curl -L https://raw.githubusercontent.com/docker/compose/${docker_compose_version:?}/contrib/completion/zsh/_docker-compose > ~/.zsh/completion/_docker-compose
            echo -e '\nfpath=(~/.zsh/completion $fpath)' >> ~/.zshrc
            echo 'autoload -Uz compinit && compinit -i' >> ~/.zshrc
            # reload shell
            #exec $SHELL -l
        fi

    else

        SUCCESS_MSG "[ docker is already installed ......]"
    fi
    docker --version
    docker-compose --version
    #docker volume create portainer_data
    #docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
}
