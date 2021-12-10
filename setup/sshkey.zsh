echo "\n🔓 Generate ssh key\n"

echo "email: "
read EMAIL
ssh-keygen -t rsa -b 4096 -C $EMAIL
eval "$(ssh-agent -s)"

touch ~/.ssh/config
cat > ~/.ssh/config << EOF
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_rsa
EOF

ssh-add -K ~/.ssh/id_rsa
pbcopy < ~/.ssh/id_rsa.pub
echo '
🔑 The generated ssh key has been copied to the clipboard.

Set up your ssh key on github
https://github.com/settings/keys


Check if it works
"ssh -T git@github.com"
'
