#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Sidecar
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🚙
# @raycast.packageName System

# Documentation:
# @raycast.description Toggle Sidecar
# @raycast.author Nozomi Ishii


# Raycast Example
# https://github.com/raycast/script-commands/blob/50dd2d231f4ef53d4e12c5291b6a12181e357441/commands/system/toggle-sidecar.template.applescript


use AppleScript version "2.4"
use scripting additions

set deviceName to "Nozomi’s iPad"
set menuItemName to "Add Display"
set delayTime to 0.1

tell application "System Preferences"
	reveal anchor "displaysDisplayTab" of pane id "com.apple.preference.displays"
	activate
	
	tell application "System Events"
		tell application process "System Preferences"
			tell window "Displays"

				repeat until exists of pop up button menuItemName
					delay delayTime
				end repeat

				tell pop up button menuItemName
					click

					repeat while not(exists of menu 1)
						delay delayTime
					end repeat

					tell menu item deviceName of menu 1
						click
					end tell
				end tell
			end tell
		end tell

	end tell
	quit
end tell


