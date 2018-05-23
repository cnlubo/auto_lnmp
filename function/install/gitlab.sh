#!/bin/bash
# shellcheck disable=SC2164
#---------------------------------------------------------------------------
# @Author:                                 ak47(454331202@qq.com)
# @file_name:                              gitlab.sh
# @Desc
#----------------------------------------------------------------------------
Setup_DataBase() {

    case   ${gitlab_dbtype:?} in
        "postgreSQL")
            {
                while :; do
                    while :; do
                        read -p "Please input PostgreSQL install path (Default:${pgsqlbasepath:?}):" PgsqlPath
                        PgsqlPath="${PgsqlPath:=${pgsqlbasepath:?}}"
                        if [ ! -x $PgsqlPath/bin/psql ]; then
                            FAILURE_MSG "[ $PgsqlPath/bin/psql not exists  !!!]"
                        else
                            break
                        fi
                    done

                    while :; do
                        read -p "Please input PostgreSQL run user (Default:${pgsqluser:?}):" PgsqlUser
                        PgsqlUser="${PgsqlUser:=${pgsqluser:?}}"
                        id $PgsqlUser >/dev/null 2>&1
                        if [ $? -eq 0 ]; then
                            break
                        else
                            FAILURE_MSG "[ User $PgsqlUser not exists  !!!]"
                        fi
                    done
                    read -p "Please input PostgreSQL host (Default:localhost):" PgsqlHost
                    PgsqlHost="${PgsqlHost:=localhost}"

                    read -s -p "Please input PostgreSQL password :" PgsqlPass
                    PgsqlPass="${PgsqlPass}"
                    echo
                    export PGUSER=$PgsqlUser PGPASSWORD=$PgsqlPass \
                        PGDATABASE=template1 PGHOST=$PgsqlHost
                    pg_version=$($PgsqlPath/bin/psql -A -t -c "show server_version")
                    if [ -z $pg_version ]; then
                        FAILURE_MSG "[ PostgreSQL connect error  !!!]"
                        unset PGUSER PGPASSWORD PGDATABASE PGHOST
                    else
                        break
                    fi
                done
                #major=$(echo $pg_version | cut -d. -f1,2)
                #minor=$(echo $pg_version | cut -d. -f3)
                INFO_MSG "[ current PostgreSQL version is $pg_version ........]"
                INFO_MSG "[ Create GitLab Database ........]"

                # test Gitlab db is exists
                if [ "$($PgsqlPath/bin/psql -lqt | cut -d \| -f 1 | grep -qw 'gitlabhq_production')" ] \
                    || [ "$($PgsqlPath/bin/psql -t -d postgres -c '\du' | cut -d \| -f 1 | grep -w 'git')" ]; then
                    while :; do
                        read -n1 -p "GitLab Db and User exists Do You Want to Delete? [y/n]: " del_yn
                        if [[ ! ${del_yn} =~ ^[y,n]$ ]]; then
                            WARNING_MSG "[input error! Please only input 'y' or 'n' ....]"
                        else
                            if [ "${del_yn}" == 'y' ]; then
                                echo
                                INFO_MSG "[ Drop Gitlab User and Db ........]"
                                $PgsqlPath/bin/psql -c " DROP DATABASE  IF EXISTS gitlabhq_production;"
                                $PgsqlPath/bin/psql -c " DROP ROLE IF EXISTS git;"
                            else
                                echo
                                FAILURE_MSG "[ GitLab DataBase can not Create  !!!]" && exit 0
                            fi
                            break
                        fi
                    done
                fi
                INFO_MSG "[ Create GitLab User and Db .........]"
                gitlab_pass=`mkpasswd -s 0 -l 8`
                $PgsqlPath/bin/psql -c " CREATE USER git CREATEDB;"
                $PgsqlPath/bin/psql -c " ALTER USER git with password '$gitlab_pass';"
                $PgsqlPath/bin/psql -c " CREATE EXTENSION IF NOT EXISTS pg_trgm;"
                $PgsqlPath/bin/psql -c "CREATE DATABASE gitlabhq_production template template1 OWNER git;"
                unset PGUSER PGPASSWORD PGDATABASE PGHOST
                PGUSER='git'
                PGPASSWORD=$gitlab_pass
                PGDATABASE='gitlabhq_production'
                PGHOST=$PgsqlHost
                export PGUSER PGPASSWORD PGDATABASE PGHOST
                if $PgsqlPath/bin/psql -lqt | cut -d \| -f 1 | grep -qw $PGDATABASE ; then
                    # database exists
                    # $? is 0
                    SUCCESS_MSG "[ GitLab DataBase Create SUCCESS !!!!]"
                    WARNING_MSG "[ User git passwd:$gitlab_pass !!!!!!!]"
                else
                    # ruh-roh
                    # $? is 1
                    FAILURE_MSG "[ GitLab DataBase Create failure  !!!]"
                    unset PGUSER PGPASSWORD PGDATABASE PGHOST
                    exit 1
                fi
                unset PGUSER PGPASSWORD PGDATABASE PGHOST

            }
            ;;

        "MySql")
            {
                echo
            }
            ;;
        *)
            echo "unknow Dbtype" && exit ;;
    esac
}

Install_GitLab (){

    INFO_MSG "[ GitLab System Users .........]"
    id git >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        WARNING_MSG "[ GitLab user git already exists !!!]"
    else
        useradd git -s /usr/local/bin/zsh -d /home/git -c 'GitLab'
        default_pass=`mkpasswd -l 8`
        echo ${default_pass:?} | passwd git --stdin  &>/dev/null
        echo
        echo "${CRED}[GitLab user git passwd:${default_pass:?} !!!!! ] ****>>${CEND}"
        echo
    fi
    INFO_MSG "[ Create GitLab Database .........]"
    Setup_DataBase
    INFO_MSG "[ Download GitLab-${gitlab_verson:?}.........]"
    cd /home/git
    sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-ce.git -b v$gitlab_verson gitlab
    INFO_MSG "[ Configuration file and directory permissions ......]"
    cd /home/git/gitlab
    sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml
    # Copy the example secrets file
    sudo -u git -H cp config/secrets.yml.example config/secrets.yml
    sudo -u git -H chmod 0600 config/secrets.yml
    # Make sure GitLab can write to the log/ and tmp/ directories
    chown -R git log/ && chown -R git tmp/
    chmod -R u+rwX,go-w log/ && chmod -R u+rwX tmp/
    # Make sure GitLab can write to the tmp/pids/ and tmp/sockets/ directories
    chmod -R u+rwX tmp/pids/ && chmod -R u+rwX tmp/sockets/
    # Create the public/uploads/ directory
    sudo -u git -H mkdir public/uploads/
    # Make sure only the GitLab user has access to the public/uploads/ directory
    # now that files in public/uploads are served by gitlab-workhorse
    chmod 0700 public/uploads
    # Change the permissions of the directory where CI build traces are stored
    chmod -R u+rwX builds/
    # Change the permissions of the directory where CI artifacts are stored
    chmod -R u+rwX shared/artifacts/
    # Change the permissions of the directory where GitLab Pages are stored
    chmod -R ug+rwX shared/pages/
    # Copy the example Unicorn config
    sudo -u git -H cp config/unicorn.rb.example config/unicorn.rb
    worker_num=$(nproc)
    sed -i "s@^worker_processes.*@ worker_processes  $worker_num@" config/unicorn.rb
    # Copy the example Rack attack config
    sudo -u git -H cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb
    # Configure Git global settings for git user
    # 'autocrlf' is needed for the web editor
    sudo -u git -H git config --global core.autocrlf input
    # Disable 'git gc --auto' because GitLab already runs 'git gc' when needed
    sudo -u git -H git config --global gc.auto 0
    # Enable packfile bitmaps
    sudo -u git -H git config --global repack.writeBitmaps true
    # Enable push options
    sudo -u git -H git config --global receive.advertisePushOptions true
    #Configure Redis connection settings
    sudo -u git -H cp config/resque.yml.example config/resque.yml
    # Change the Redis socket path if you are not using the default Debian / Ubuntu configuration
    sed -i '/^production:/,+3s/\(.*\)/#&/' config/resque.yml
    cat >> config/resque.yml <<EOF

production:
 url: unix:${redissock:?}
 password: ${redispass:?}
EOF
    INFO_MSG "[Configure GitLab DB Settings ......]"
    sudo -u git cp config/database.yml.postgresql config/database.yml
    # 注释默认的数据库配置
    sed -i '/^production:/,+8s/\(.*\)/#&/' config/database.yml
    cat >> config/database.yml <<EOF

production:
  adapter: postgresql
  encoding: unicode
  database: gitlabhq_production
  pool: 10
  username: git
  password: "$gitlab_pass"
  host: $PgsqlHost
EOF
    sudo -u git -H chmod o-rwx config/database.yml
    INFO_MSG "[Install Gems ......]"
    cd /home/git/gitlab
    sudo -u git -H bundle config mirror.https://rubygems.org https://gems.ruby-china.org/
    #sudo -u git -H bundle config build.pg --with-pg-config=/usr/local/bin/pg_config
    sudo -u git -H bundle install --deployment --without development  test mysql aws kerberos --path /home/git/.gem
    INFO_MSG "[Install GitLab shell ......]"
    sudo -u git -H bundle exec rake gitlab:shell:install REDIS_URL=unix:${redissock:?} \
        RAILS_ENV=production SKIP_STORAGE_VALIDATION=true
    INFO_MSG "[Install gitlab-workhorse ......]"
    sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
    INFO_MSG "[Initialize Database and Activate Advanced Features ......]"
    sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production

}

Config_GitLab() {

    INFO_MSG "[Install Init Script ......]"
    cd /home/git/gitlab
    cp lib/support/init.d/gitlab /etc/init.d/gitlab
    cp lib/support/init.d/gitlab.default.example /etc/default/gitlab
    # if you installed GitLab in another directory or as a user other than the default
    # you should change these settings in /etc/default/gitlab. Do not edit /etc/init.d/gitlab
    # as it will be changed on upgrade.
    chkconfig --add gitlab

    INFO_MSG "[Install Gitaly ......]"
    # Fetch Gitaly source with Git and compile with Go
    sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly]" RAILS_ENV=production
    # Restrict Gitaly socket access
    chmod 0700 /home/git/gitlab/tmp/sockets/private && chown git /home/git/gitlab/tmp/sockets/private

    INFO_MSG INFO_MSG "[Set up logrotate ......]"
    cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab

    INFO_MSG "[Check Application Status ......]"
    sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production

    INFO_MSG "[Compile GetText PO files ......]"
    sudo -u git -H bundle exec rake gettext:compile RAILS_ENV=production

    INFO_MSG "[Compile Assets .....]"
    sudo -u git -H yarn install --production --pure-lockfile
    sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production

    INFO_MSG "[Start GitLab service ......]"
    service gitlab start
}

Gitlab_Install_Main() {

    GitLab_Var && GitLab_Dep_Install && Install_GitLab && Config_GitLab

}
