# klipper-backup 💾
Klipper backup script for manual or automated GitHub backups for the Creality K1

This is a backup script to create manual or automated klipper backups in a github repository. You can [see an example](https://github.com/Staubgeborener/3dprint) of what it looks like in the end.

## Install
To install the script, please first create a github account, create a new repository and generate a personal access token. 

[Here is a guide for creating the token.](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) Please remember that you can only see the token once, if you leave the page you cannot see it again and will need to generate a new token. 

Once you have a token ready ssh to your K1 and enter:
```
wget --no-check-certificate https://raw.githubusercontent.com/lokiagent/klipper-backup/main/install-backup.sh && chmod +x install-backup.sh && sh install-backup.sh
```
