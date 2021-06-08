#!/bin/sh

echo "Setting up tools..."
sudo echo "You must have sudo permission to run this script."

# https://brew.sh/
echo "homebrew (for dasel):"
if test ! -d /home/linuxbrew
then
    echo "" | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
	|| exit 1
fi

if test -z "$HOMEBREW_BREW_FILE"
then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" \
	|| exit 2
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bash_profile \
	|| exit 3
fi
sudo apt-get install -y build-essential \
    || exit 4
brew install gcc \
    || exit 5

# https://daseldocs.tomwright.me/installation
echo "dasel:"
brew install dasel \
    || exit 2

echo "ruby (for mustache):"
sudo apt-get install -y ruby \
    || exit 3

# https://linux.die.net/man/1/mustache
sudo gem install mustache \
    || exit 4

echo ""
echo "SUCCESS setting up tools."
echo ""
echo "*** IMPORTANY *** Update your environment: . ~/.bash_profile"
echo ""

exit 0
