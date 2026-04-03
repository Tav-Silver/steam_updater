There is no global setting to change all your games on Steam to receive updates immediately when they are available. 
Often I see Steam scheduling the updates to when I usually have my computer off, totally useless. 
I'm not gonna spend hours changing from "Let Steam decide" to getting updates on all my games, totally useless.
So I took matter into my own hands, made this script and decided to share.

A simple script to alter all your games on Steam to download updates immediately, with a nice viewing list and a counter.
You can run this after every new download; it will not show the same result twice.
Written for Windows and for us that have many Steam games downloaded.

The script searches your specified Steam libraries and changes the key "AutoUpdateBehavior" from value "0" to "2" in all
appmanifest_*.acf files in \SteamLibrary\steamapps, enabling immediate Steam updates.

## Steam update states:
0 = Global state (One can only stupidly choose "Let Steam decide when to update" or "Only update at game launch").  
1 = Wait until I launch game  
2 = Immediately download updates  
3 = Let Steam decide when to update  

## Pre-running the script/Installation:
1.  Put the files wherever you want.
2.  EDIT steam_updater.bat and change the path to where you put the steam_immediate-update.ps1 file.
3.  EDIT steam_immediate-update.ps1 and change/add/remove the LibraryPaths to your Steam libraries at the top of the file.
4.  Run the .bat file.
5.  Reboot Steam to see the changes.

You can change this script to your liking.
