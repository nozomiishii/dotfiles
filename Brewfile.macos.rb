instance_eval(File.read("./Brewfile"))

#
# Brew
#
# Dependency manager for Cocoa projects https://cocoapods.org/
brew "cocoapods"

# The scalable code generator that saves you time. https://www.hygen.io/
tap "jondot/tap"
brew "hygen"

# Simple command line interface for the Mac App Store. https://github.com/mas-cli/mas
brew "mas"

# A CLI for configuring 'Night Shift' on macOS https://github.com/smudge/nightlight
tap "smudge/smudge"
brew "nightlight"

#
# Cask
#
# Tools for building Android applications https://developer.android.com/studio
cask "android-studio"

# FreeMacSoft AppCleaner https://freemacsoft.net/appcleaner/
cask "appcleaner"

# Virtual Audio Driver https://existential.audio/blackhole/
cask "blackhole-2ch"

# Free and open-source 3D creation suite. https://www.blender.org
cask "blender"

# Lock/unlock Apple computers using the proximity of a bluetooth low energy device https://github.com/ts1/BLEUnlock
cask "bleunlock"

# Screen Saver by Pedro Carrasco. https://github.com/pedrommcarrasco/Brooklyn
cask "brooklyn"

# Web browser focusing on privacy https://brave.com/
cask "brave-browser"

# Automated testing of webapps for Google Chrome https://sites.google.com/chromium.org/driver/
cask "chromedriver"

# Color picking application. https://colorsnapper.com
cask "colorsnapper"

# Voice and text chat software. https://discord.com
cask "discord"

# .NET is a free, cross-platform, open source developer platform https://dotnet.microsoft.com/
cask "dotnet-sdk"

# Tool for using an iPad as a second display https://www.duetdisplay.com/
cask "duet"

# Automated organization https://www.noodlesoft.com/
cask "hazel"

# Keyboard customizer. https://pqrs.org/osx/karabiner
cask "karabiner-elements"

# Automation software https://www.keyboardmaestro.com/main/
cask "keyboard-maestro"

# Interface for reading and syncing eBooks. https://www.amazon.com/gp/digital/fiona/kcp-landing-page
cask "kindle"

# Preview and audit Kindle eBooks https://www.amazon.com/Kindle-Previewer/b?ie=UTF8&node=21381691011
cask "kindle-previewer"

# Collaboration platform for API development. https://www.postman.com
cask "postman"

# VPN client focusing on security https://protonvpn.com/
cask "protonvpn"

# Jetbrains PyCharm Community Edition https://www.jetbrains.com/pycharm/
cask "pycharm-ce"

# Messaging app with a focus on speed and security https://macos.telegram.org/
cask "telegram"

# Management tool for Unity. https://unity3d.com/get-unity/download
cask "unity-hub"

# Multimedia player. https://www.videolan.org/vlc
cask "vlc"

# Private Messenger https://wickr.com/me/
cask "wickrme"

# Graphical network analyzer and capture tool https://www.wireshark.org
cask "wireshark"

# Video communication and virtual meeting platform https://www.zoom.us/
cask "zoom"

# NOT WORKING ON M1 MAC
# hosted hypervisor for x86 virtualization https://www.virtualbox.org/
cask "virtualbox" if system '[ "$(uname -m)" = "x86_64" ]'

# Oracle VirtualBox Extension Pack https://www.virtualbox.org/
cask "virtualbox-extension-pack" if system '[ "$(uname -m)" = "x86_64" ]'

#
# mas
#
if OS.mac?
  # Apple's integrated development environment for macOS. https://developer.apple.com/xcode/
  # mas "Xcode", id: 497799835
end
