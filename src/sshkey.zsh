echo "🔐 Generating ssh key... \n"


echo "email: "
read EMAIL

echo "[🔫 Troubleshooting]
Enter passphrase (empty for no passphrase): <Must type Your Password>
"
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
echo "
🔑 The generated ssh key has been copied to the clipboard.

Set up your ssh key on github
https://github.com/settings/keys


Check if it works

'ssh -T git@github.com'

[🔫 Troubleshooting]
The authenticity of host 'github.com (13.114.40.48)' can't be established. RSA key fingerprint is SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8. Are you sure you want to continue connecting (yes/no/[fingerprint])?

`yes`
"


echo "\n🎉 Completed Generating ssh key \n"
