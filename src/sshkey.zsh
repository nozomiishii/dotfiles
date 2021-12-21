echo "🔐 Generating ssh key... \n"


if [ -f ~/.ssh/id_rsa.pub ]; then
  echo "🔐 Already generated ssh key. Copied to the clipboard. \n"
  pbcopy < ~/.ssh/id_rsa.pub
  cat ~/.ssh/id_rsa.pub
  exit
fi

echo "\n[💡Hint]"
echo "Generating public/private rsa key pair."
echo "Enter file in which to save the key (/Users/ts/.ssh/id_rsa): 💡 Press enter"
echo "Enter passphrase (empty for no passphrase): <💡 Type Your Password>"
echo "Enter same passphrase again: <💡 Type Your Password> \n"


# Generate
ssh-keygen -t rsa -b 4096 -C "nozomiishii.jp@gmail.com"


# Config
touch ~/.ssh/config
cat > ~/.ssh/config << EOF
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_rsa
EOF
chmod 600 ~/.ssh/config


# Register
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
echo "\n🔐 Key List $(ssh-add -l) \n"


cat ~/.ssh/id_rsa.pub
pbcopy < ~/.ssh/id_rsa.pub

echo "\n🔐 The generated ssh key has been copied to the clipboard."
echo "Set up your ssh key on github"
echo "https://github.com/settings/keys \n"
echo "Check if it works"
echo "'ssh -T git@github.com'"
echo "\n[💡 Hint]"
echo "The authenticity of host 'github.com (13.114.40.48)' can't be established. RSA key fingerprint is"
echo "SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8. Are you sure you want to continue connecting (yes/no/[fingerprint])?"
echo "💡 yes \n"


echo "🎉 Generating ssh key is Complete \n\n"
