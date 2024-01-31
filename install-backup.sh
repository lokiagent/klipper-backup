#!/bin/sh
read -p "Do you wish to install or uninstall? (install/uninstall) " process
    case $process in
        install|Install)
            read -p "Please create an account at github.com, a repository to backup to, and a personal access token (Settings -> Developer Settings -> Personal Access Tokens) before continuing. Ready? (Y/n)" choice
                case $choice in
                    n|N) "Please set up your github account and repository and press y to continue. " ;;
                    y|Y)
                        read -p "What is your github.com usename? " github_username
                        read -p "What is your github.com email? " commit_email
                        read -p "What is your backup repository called? " github_repository
                        read -p "What branch to backup to? " branch_name
                        read -p "Please enter your personal access token: " github_token
                        break;;
                   *) echo invalid response;;
                esac

        echo "Installing klipper-backup...Downloading repository"
        git config --global http.sslVerify false
        git clone https://github.com/lokiagent/klipper-backup.git /usr/data/klipper-backup
        chmod +x /usr/data/klipper-backup/script-K1.sh 
        cat >> /usr/data/klipper-backup/.env << EOF
github_token=$github_token
github_username=$github_username
github_repository=$github_repository
branch_name=$branch_name
commit_username="$github_username"
commit_email="$commit_email"
path_klipperdata=printer_data/config/
EOF

        cp /usr/data/klipper-backup/backup_macro.cfg /usr/data/printer_data/config/backup_macro.cfg
        sed -i '12 i \[include backup_macro.cfg\]' /usr/data/printer_data/config/printer.cfg
        cat >> /usr/data/printer_data/config/moonraker.conf << EOF
[update_manager klipper-backup]
type: git_repo
channel: dev
path: /usr/data/klipper-backup
origin: https://github.com/lokiagent/klipper-backup.git
primary_branch: main
EOF
        mkdir /usr/data/config_backup
        cd /usr/data/config_backup
        git init
        read -p "Is this a new repository without any commits? (y/n) " new
            case $new in
                n|N) git -C /usr/data/config_backup pull https://$github_username:$github_token@github.com/$github_username/$github_repository.git
                     git remote add origin https://$github_username:$github_token@github.com/$github_username/$github_repository.git
                     git remote set-branches origin $branch_name
                     ;;
                y|Y) cat >> README.MD << EOF
Initial commit
EOF
                     git add README.MD 
                     git commit -m "Initial commit"
                     git branch -M $branch_name
                     git remote add origin https://$github_username:$github_token@github.com/$github_username/$github_repository.git
                     git push origin $branch_name
                     ;;
                *) echo invalid response;;
            esac

        read -p "Do you want to set up crontab to back up your config? (y/n)" cron
            case $cron in
                y|Y) mkdir /var/spool/cron
                     mkdir /var/spool/cron/crontabs
                     echo "The default is to schedule the backup every 24 hours. To change, please edit /etc/cron.d/klipper-backup.cron"
                     cat >> /etc/cron.d/klipper-backup.cron << EOF
10 5 * * * sh /usr/data/klipper-backup/script-k1.sh > /usr/data/printer_data/logs/backup.log
EOF
                     cp -f /usr/data/klipper-backup/S51crond /etc/init.d/S51crond
                     chmod +x /etc/init.d/S51crond
                     sh /etc/init.d/S51crond start
                     break;;
                *)   break;;
            esac

        echo "You can back up manually by entering KLIPPER_BACKUP in to your gcode console. Or add the macro KLIPPER_BACKUP to your gcode, or another macro to back up when run. NOTE: The backup macro requires gcode_shell_command be installed!"
        echo "Restarting Klipper service..."
        sh /etc/init.d/S55klipper_service restart
        sh /etc/init.d/S56moonraker_service restart
        exit
        ;;

        uninstall|Uninstall)
            echo "Removing klipper-backup...."
            rm -rf /usr/data/config_backup
            rm -rf /usr/data/klipper-backup
            find /etc/cron.d -name 'klipper-backup.cron' -exec rm /etc/cron.d/klipper-backup.cron
            sh /etc/init.d/S51crond stop
            rm /etc/init.d/S51crond
            rm /usr/data/printer_data/config/backup_macro.cfg
            sed -i '/\[include backup_macro.cfg\]/d' /usr/data/printer_data/config/printer.cfg
            exit
        ;;

        *) echo invalid response;;

            
