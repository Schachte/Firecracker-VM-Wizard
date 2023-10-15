#!/bin/bash
read -p "Enter your GitHub email address: " email
echo "Generating a new SSH key for $email"
ssh-keygen -t ed25519 -C "$email"

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
if ! command -v xclip > /dev/null; then
    echo "xclip not found, installing..."
    sudo apt-get install -y xclip
fi

echo "Copy the below public key to your clipboard and add to Github"
cat ~/.ssh/id_ed25519.pub
echo "Your new SSH public key has been copied to the clipboard, you can now add it to your GitHub account"