#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo -e "🔐 Generating ssh key... \n"

if [ -f ~/.ssh/id_rsa.pub ]; then
  echo -e "🔐 Already generated ssh key. Copied to the clipboard. \n"
  pbcopy < ~/.ssh/id_rsa.pub
  cat ~/.ssh/id_rsa.pub
  exit
fi

echo -e "\n[💡Hint]"
echo "Generating public/private rsa key pair."
echo "Enter file in which to save the key (/Users/ts/.ssh/id_rsa): 💡 Press enter"
echo "Enter passphrase (empty for no passphrase): <💡 Type Your Password>"
echo -e "Enter same passphrase again: <💡 Type Your Password> \n"

# Generate
ssh-keygen -t rsa -b 4096 -C "nozomiishii.jp@gmail.com"

# Config
chmod 600 ~/.ssh/config

# Register
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
echo -e "\n🔐 Key List %s\n$(ssh-add -l)"

echo "😼 Continue with the gh settings"
echo "[💡 Hint]"
echo "? What account do you want to log into? 💡 GitHub.com"
echo "? What is your preferred protocol for Git operations? 💡 SSH"
echo "? Upload your SSH public key to your GitHub account? 💡 $HOME/.ssh/id_rsa.pub"
echo -e "? How would you like to authenticate GitHub CLI? 💡 Login with a web browser \n"

gh auth login
gh auth status

echo "Check if it works"
echo "'ssh -T git@github.com'"

echo -e "\n[💡 Hint]"
echo "The authenticity of host 'github.com (13.114.40.48)' can't be established. RSA key fingerprint is"
echo "SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8. Are you sure you want to continue connecting (yes/no/[fingerprint])?"
echo -e "💡 yes \n"

echo -e "🎉 Generating ssh key is Complete \n\n"
