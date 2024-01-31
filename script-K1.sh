#!/bin/sh -v

# Set parent directory path
parent_path=/usr/data/klipper-backup
# Set K1 directory location (Klipper and related files are not stored in /home/$user)
usrdata=/usr/data
klipperconfig=/usr/data/printer_data/config

# Initialize variables from .env file
source "$parent_path"/.env

backup_folder="config_backup"
backup_path="/usr/data/$backup_folder"

# Check for updates
[ $(git -C "$parent_path" rev-parse HEAD) = $(git -C "$parent_path" ls-remote $(git -C "$parent_path" rev-parse --abbrev-ref @{u} | \
sed 's/\// /g') | cut -f1) ] && echo -e "Klipper-backup is up to date\n" || echo -e "NEW klipper-backup version available!\n"

# Check if backup folder exists, create one if it does not
if [ ! -d "$backup_path" ]; then
    mkdir -p "$backup_path"
fi

# Git commands
cd "$backup_path"
# Check if .git exists else init git repo
if [ ! -d ".git" ]; then
    mkdir .git
    echo "[init]
    defaultBranch = "$branch_name"" >> .git/config #Add desired branch name to config before init
    git init
    # Check if the current checked out branch matches the branch name given in .env if not update to new branch
    elif [[ $(git symbolic-ref --short -q HEAD) != "$branch_name" ]]; then
    echo "New branch in .env detected, rename $(git symbolic-ref --short -q HEAD) to $branch_name branch"
    git branch -m "$branch_name"
fi

# Check if username is defined in .env
if [[ "$commit_username" != "" ]]; then
    git config user.name "$commit_username"
else
    git config user.name "$(whoami)"
    sed -i "s/^commit_username=.*/commit_username=\"$(whoami)\"/" "$parent_path"/.env
fi

# Check if email is defined in .env
if [[ "$commit_email" != "" ]]; then
    git config user.email "$commit_email"
else
    git config user.email "$(whoami)@$(hostname --long)-$(git rev-parse --short HEAD)"
    sed -i "s/^commit_email=.*/commit_email=\"$(whoami)@$(hostname --long)-$(git rev-parse --short HEAD)\"/" "$parent_path"/.env
fi

# Check if remote origin already exists and create if one does not
if [ -z "$(git remote get-url origin 2>/dev/null)" ]; then
    git remote add origin https://"$github_token"@github.com/"$github_username"/"$github_repository".git
fi

# Check if remote origin changed and update when it is
if [[ "$github_repository" != $(git remote get-url origin | sed 's/https:\/\/.*@github.com\///' | sed 's/\.git$//' | xargs basename) ]]; then
    git remote set-url origin https://"$github_token"@github.com/"$github_username"/"$github_repository".git
fi

git config advice.skippedCherryPicks false

# Check if branch exists on remote (newly created repos will not yet have a remote) and pull any new changes
if git ls-remote --exit-code --heads origin $branch_name > /dev/null 2>&1; then
    git pull origin "$branch_name"
    # Delete the pulled files so that the directory is empty again before copying the new backup
    # The pull is only needed so that the repository nows its on latest and does not require rebases or merges
    find "$backup_path" -maxdepth 1 -mindepth 1 ! -name '.git' -exec rm -rf {} \;
fi

cp -af "$klipperconfig" "$backup_path/"

cp -af "$parent_path"/.gitignore "$backup_path/.gitignore"

# Create and add Readme to backup folder
echo -e "# klipper-backup 💾 \nKlipper backup script for manual or automated GitHub backups \n\nThis backup is provided by [klipper-backup](https://github.com/Staubgeborener/klipper-backup).\n\nAdapted for Creality K1 by lokiagent." > "$backup_path/README.md"

# Individual commit message, if no parameter is set, use the current timestamp as commit message
commit_message="New backup from $(date +"%d-%m-%y")"

cd "$backup_path"
git add .
git commit -m "$commit_message"
# Check if HEAD still matches remote (Means there are no updates to push) and create a empty commit just informing that there are no new updates to push
if [[ $(git rev-parse HEAD) == $(git ls-remote $(git rev-parse --abbrev-ref @{u} 2>/dev/null | sed 's/\// /g') | cut -f1) ]]; then
    git commit --allow-empty -m "$commit_message - No new changes pushed"
fi
git push -u origin "$branch_name"

# Remove files except .git folder after backup so that any file deletions can be logged on next backup
find "$backup_path" -maxdepth 1 -mindepth 1 ! -name '.git' -exec rm -rf {} \;
