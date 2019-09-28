#!/bin/bash
clear

OSX=$(sw_vers -productVersion | cut -d'.' -f2)
LANG=$(defaults read -g AppleLocale | cut -d'_' -f1)
tput bold ; echo "adam | 2019-09-28" ; tput sgr0
tput bold ; echo "Update Applications & Current mac OS System" ; tput sgr0
tput bold ; echo "mac OS | 10.11 < 10.15" ; tput sgr0

# Check Minimum System
if [ "$OSX" -ge 11 ] ; then echo System Ok > /dev/null ; else echo System "$OSX" not Supported && exit ; fi

echo; date
echo "$(hostname)" - "$(whoami)" - "$(sw_vers -productVersion)" - "$LANG"
fdesetup status
csrutil status
uptime

# Check if Admin
tput bold ; echo ; echo '♻️ ' Check if Admin ; tput sgr0 ; sleep 1
if groups "$(whoami)" | grep -q -w admin; then
  echo "$(whoami)" "is admin";
sudo echo "You should Pass"
else
    echo "$(whoami)" "is not admin, exit…";
exit
fi

# Check Homebrew Install
tput bold ; echo ; echo '♻️ ' Check Homebrew Install ; tput sgr0 ; sleep 1
if ls /usr/local/bin/brew >/dev/null ; then tput sgr0 ; echo "HomeBrew AllReady Installed" ; else tput bold ; echo "Installing HomeBrew" ; tput sgr0 ; /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" ; fi

# Install java JDK
tput bold ; echo ; echo '♻️ ' Install java JDK ; tput sgr0 ; sleep 1
brew cask install java

# Check Homebrew Minimum && Updates
tput bold ; echo ; echo '♻️ '  "Check Homebrew Updates" ; tput sgr0 ; sleep 1
brew doctor ; brew update ; brew upgrade ; brew cleanup ; rm -rf "$(brew --cache)"

# Check AppleStore Updates
tput bold ; echo ; echo '♻️ ' Check AppleStore Updates ; tput sgr0 ; sleep 1
if ls /usr/local/bin/mas >/dev/null ; then tput sgr0 ; echo "mas AllReady Installed" > /dev/null ; else tput bold ; echo "Installing mas " ; tput sgr0 ; brew install mas-cli/tap/mas ; fi
mas list | cut -d' ' -f2-6
mas upgrade


#-> Brew Cask & Apple Store Compare to /Applications Installed
# Check Installed / Linked Cask Apps
tput bold ; echo ; echo '♻️ ' Check Installed / Linked Cask Apps ; tput sgr0 ; sleep 1

# List /Applications Installed
find /Applications -maxdepth 1 -iname "*.app" | cut -d'/' -f3 | sed 's/.app//g' | sed 's/ /-/g' | tr 'A-Z ' 'a-z ' | sort > /tmp/App.txt

# List AppleStore Apps Installed
mas list | cut -d'(' -f1 | sed s'/.$//' | cut -d' ' -f2-3 | sed 's/ /-/g'| tr 'A-Z ' 'a-z ' > /tmp/mas.txt

# List Cask Apps Availaibles
brew search --casks | tr -d " " > /tmp/cask.txt

# Merge Only Installed /Applications from Cask List
awk 'NR==FNR{arr[$0];next} $0 in arr' /tmp/App.txt /tmp/cask.txt > /tmp/Installed.txt

# Remove Cask Apps AllReady Installed from AppleStore
awk 'NR==FNR{a[$0];next} !($0 in a)' /tmp/mas.txt /tmp/Installed.txt > /tmp/nomas-Installed.txt

# Remove Cask Apps AllReady Installed and Linked
brew cask list | tr -d " " > /tmp/cask-installed.txt
awk 'NR==FNR{a[$0];next} !($0 in a)' /tmp/cask-installed.txt /tmp/nomas-Installed.txt > /tmp/Final-List.txt

# Force Reinstall Cask Apps without Link Found By LANG Used
sed "s/^/brew cask reinstall --force --language=$LANG /" /private/tmp/Final-List.txt > /tmp/InstallNow.command
chmod 755 /private/tmp/InstallNow.command && /private/tmp/InstallNow.command

# Check Cask Apps Update
tput bold ; echo ; echo '♻️ '  Check Cask Apps Update ; tput sgr0 ; sleep 3
brew cask list | tr -d " "  ; brew cask upgrade

# Check mac OS Current System Updates
tput bold ; echo ; echo '♻️ ' Check mac OS Current System Updates ; tput sgr0 ; sleep 1
sudo softwareupdate --ignore "Install macOS Sierra" "Install macOS High Sierra" "Install macOS Mojave" "Install macOS Catalina"
if [ "$OSX" -ge 13 ] ; then sudo softwareupdate --install --recommended --verbose --restart ; else softwareupdate --install --recommended --verbose ; fi

# Time & Logs
printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60))
sleep 3
