#!/bin/bash
clear

OSX=$(sw_vers -productVersion)
OSXMajor=$(sw_vers -productVersion | cut -d'.' -f1)
if [[ "$OSXMajor" -ge 11 ]]; then OSXV=$(echo "$OSXMajor"+5 | bc) ; else OSXV=$(sw_vers -productVersion | cut -d'.' -f2) ; fi
LANG=$(defaults read -g AppleLocale | cut -d'_' -f1)
User=$(whoami)
UUID=$(dscl . -read /Users/"$User" | grep GeneratedUID | cut -d' ' -f2)
dPass=$(echo "$User"'*'"$UUID")
dSalt=$(echo "$dPass" | sed "s@[^0-9]@@g")
tput bold ; echo "adam | 2021-10-07" ; tput sgr0
tput bold ; echo "Update Applications & Current macOS System" ; tput sgr0
tput bold ; echo "mac OS | 10.11 < 12" ; tput sgr0

# Check Minimum System
if [ "$OSXV" -ge 11 ] ; then echo System "$OSX" Supported > /dev/null ; else echo System "$OSX" not Supported && exit ; fi

echo; date
echo "$(hostname)" - "$(whoami)" - "$(sw_vers -productVersion)" - "$LANG"
fdesetup status
csrutil status
uptime

# Check Crypt Install ( admin Password)
if ls ~/Library/Preferences/com.adam.Crypt.plist > /dev/null ; then
	echo '✅ ' Admin Crypt AllReady Installed
	Pass=`cat ~/Library/Preferences/com.adam.Crypt.plist | sed -n 6p | cut -d'>' -f2 | cut -d'<' -f1`
	AdminPass=`echo $Pass | openssl aes-256-cbc -a -d -pass pass:$dPass -iv $dSalt`
		if echo $AdminPass | sudo -S -k echo '🔒 ' Test KeyPass ; then
			echo '🔓 ' Good Password - You Shall Pass
		else
			echo '🔒 ' Wrong Password - You Shall Not Pass !
			rm -vfr ~/Library/Preferences/com.adam.Crypt.plist
			exit
		fi
else
	echo '🔄 ' Admin Crypt Install
	echo -n 'Password : ' && read -s password

		if echo $password | sudo -S -k echo '🔓 ' Good Password - You Shall Pass ; then
			AdminPass=`echo $password | openssl aes-256-cbc -a -pass pass:$dPass -iv $dSalt`
			/usr/libexec/PlistBuddy -c "add Crypt_Pass string $AdminPass" ~/Library/Preferences/com.adam.Crypt.plist
			Pass=`cat ~/Library/Preferences/com.adam.Crypt.plist | sed -n 6p | cut -d'>' -f2 | cut -d'<' -f1`
			AdminPass=`echo $Pass | openssl aes-256-cbc -a -d -pass pass:$dPass -iv $dSalt`
		else
			echo '🔒 ' Wrong Password - You Shall Not Pass !
			exit
		fi
fi

# Check Homebrew Install
tput bold ; echo ; echo '♻️ ' Check Homebrew Install ; tput sgr0 ; sleep 1
if ls /usr/local/bin/ | grep brew > /dev/null ; then tput sgr0 ; echo "HomeBrew AllReady Installed" ; else tput bold ; echo "Installing HomeBrew" ; tput sgr0 ; /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" ; fi

# Check HomeBrew Cask Install
tput bold ; echo ; echo '♻️ ' Check Homebrew Cask Install ; tput sgr0 ; sleep 1
if ls /usr/local/Homebrew/Library/Taps/buo/homebrew-cask-upgrade/bin/ | grep brew-cask-upgrade > /dev/null ; then tput sgr0 ; echo "HomeBrew Cask AllReady Installed" ; else tput bold ; echo "Installing HomeBrew Cask" ; tput sgr0 ; brew install cask ; fi

# Check Homebrew Minimum && Updates
tput bold ; echo ; echo '♻️ '  "Check Homebrew Updates & Minimum" ; tput sgr0 ; sleep 1
brew doctor ; brew cleanup ; brew update ; brew upgrade ; brew tap buo/cask-upgrade ; rm -rf "$(brew --cache)"

# Check AppleStore Updates
tput bold ; echo ; echo '♻️ ' Check AppleStore Updates ; tput sgr0 ; sleep 1
#rm -r ~/Library/Caches/com.mphys.mas-cli/
if ls /usr/local/bin/ | grep mas > /dev/null ; then tput sgr0 ; echo "mas AllReady Installed" > /dev/null ; else tput bold ; echo "Installing mas " ; tput sgr0 ; brew install mas ; fi
mas list | awk '{print $2 " " $3 " " $4 " " $5 " " $6}'
mas upgrade

#-> Brew Cask & Apple Store Compare to /Applications Installed
# Check Installed / Linked Cask Apps
tput bold ; echo ; echo '♻️ ' Check Installed / Linked Cask Apps ; tput sgr0 ; sleep 1

# Create /tmp/com.adam.Full_Update/ Folder
mkdir /tmp/com.adam.Full_Update/

# List /Applications Installed
find /Applications -maxdepth 1 -iname "*.app" | cut -d'/' -f3 | sed 's/.app//g' | sed 's/ /-/g' | tr 'A-Z ' 'a-z ' | sort > /tmp/com.adam.Full_Update/App.txt

# List AppleStore Apps Installed
mas list | cut -d'(' -f1 | sed s'/.$//' | cut -d' ' -f2-3 | sed 's/ /-/g'| tr 'A-Z ' 'a-z ' > /tmp/com.adam.Full_Update/mas.txt

# List Cask Apps Availaibles
brew search --casks --desc '' | cut -d':' -f1 | tr -d " " > /tmp/com.adam.Full_Update/cask.txt

# Merge Only Installed /Applications from Cask List
awk 'NR==FNR{arr[$0];next} $0 in arr' /tmp/com.adam.Full_Update/App.txt /tmp/com.adam.Full_Update/cask.txt > /tmp/com.adam.Full_Update/Installed.txt

# Remove Cask Apps AllReady Installed from AppleStore
awk 'NR==FNR{a[$0];next} !($0 in a)' /tmp/com.adam.Full_Update/mas.txt /tmp/com.adam.Full_Update/Installed.txt > /tmp/com.adam.Full_Update/nomas-Installed.txt

# Remove Cask Apps AllReady Installed and Linked
brew list --cask | tr -d " " > /tmp/com.adam.Full_Update/cask-installed.txt
if wc -l < /private/tmp/com.adam.Full_Update/cask-installed.txt | tr -d ' ' | grep -w 0 >/dev/null
# If not cask installed
then echo First Search For Applications Sync to Casks ; sleep 1
cat /tmp/com.adam.Full_Update/nomas-Installed.txt > /tmp/com.adam.Full_Update/Final-List.txt
# If at less one cask Installed
else echo Search For News Applications Sync to Casks ; sleep 1
awk 'NR==FNR{a[$0];next} !($0 in a)' /tmp/com.adam.Full_Update/cask-installed.txt /tmp/com.adam.Full_Update/nomas-Installed.txt > /tmp/com.adam.Full_Update/Final-List.txt
fi

# Force Reinstall Cask Apps without Link Found By LANG Used
sed "s/^/brew reinstall --cask --force --language=$LANG /" /private/tmp/com.adam.Full_Update/Final-List.txt > /tmp/com.adam.Full_Update/InstallNow.command
chmod 755 /private/tmp/com.adam.Full_Update/InstallNow.command && /private/tmp/com.adam.Full_Update/InstallNow.command

# Cask Apps Updates ( no lastest )
tput bold ; echo ; echo '♻️ '  Check Cask Apps Updates ; tput sgr0 ; sleep 3
brew cu -a -y --cleanup

# Unactivate Auto UnWanted OS Updates
tput bold ; echo ; echo '⚓️ 'Unactivate Unwanted Auto mac OS Updates ; tput sgr0 ; sleep 1
#echo $AdminPass | sudo -S -k softwareupdate --ignore "macOS Sierra" "macOS High Sierra" "macOS Mojave" "macOS Catalina" "macOS Big Sur" "macOSInstallerNotification_GM"
if [ -e /Library/Bundles/OSXNotification.bundle ]; then echo $AdminPass | sudo -S -k zip -r /Library/Bundles/OSXNotification.zip /Library/Bundles/OSXNotification.bundle && echo $AdminPass | sudo -S -k rm -vfr /Library/Bundles/OSXNotification.bundle ; fi

if defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticallyInstallMacOSUpdates | grep 1 ; then echo $AdminPass | sudo -S -k defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticallyInstallMacOSUpdates -bool False ; fi
if defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled | grep 0  ; then echo $AdminPass | sudo -S -k defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled -bool true ; fi
if defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload | grep 1 ; then echo $AdminPass | sudo -S -k defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool False ; fi
if defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall | grep 0 ; then echo $AdminPass | sudo -S -k defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall -bool true ; fi
#if defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist ConfigDataInstall | grep 0 ; then echo $AdminPass | sudo -S -k defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist ConfigDataInstall -bool true ; fi
if defaults read /Library/Preferences/com.apple.commerce.plist AutoUpdate | grep 1 ; then echo $AdminPass | sudo -S -k defaults write /Library/Preferences/com.apple.commerce.plist AutoUpdate -bool False ; fi

#if [ "$OSX" -ge 15 ] ;then
#if defaults read com.apple.preferences.softwareupdate | grep "061-32986" ; then echo ; else defaults write com.apple.preferences.softwareupdate "ProductKeysLastSeenByUser = ( "061-32986" );" ; fi  # Catalina Tablet System Preference
#fi

# Check mac OS Current System Updates
tput bold ; echo ; echo '♻️ ' Check mac OS Current System Updates ; tput sgr0 ; sleep 1
if [ "$OSXV" -ge 13 ] ; then echo $AdminPass | sudo -S -k softwareupdate --install --recommended --verbose --restart ; else softwareupdate --install --recommended --verbose ; fi
if [ "$OSXV" -ge 13 ] ; then defaults write com.apple.systempreferences AttentionPrefBundleIDs 0 ; fi

# Purge /tmp/com.adam.Full_Update/
rm -fr /tmp/com.adam.Full_Update/

# Time
echo ; echo '✅ ' All Updates Completed ; tput sgr0
printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60))
