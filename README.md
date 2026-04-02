A simple script to alter all your games on Steam to download updates immediately, with a nice viewing list and a counter.
You can run this after every new download; it will not show the same result twice.
This was written with Windows 11 in mind. For us that have many Steam games downloaded.

The script searches your specified Steam libraries and changes the key "AutoUpdateBehavior" from value "0" to "2" in all appmanifest_*.acf files, enabling immediate Steam updates.

## Every Steam update state:
0 = Global state (One can only stupidly choose "Let Steam decide when to update" or "Only update at game launch").  
1 = Wait until I launch game  
2 = Immediately download updates  
3 = Let Steam decide when to update  

## Pre-running the script:
1.  Put the files wherever you want.
2.  EDIT steam_updater.bat and change the path to where you put the steam_immediate-update.ps1 file.
3.  EDIT steam_immediate-update.ps1 and change/add/remove the LibraryPaths to your Steam libraries at the top of the file.
4.  Run the .bat file.
5.  Reboot Steam for changes to take effect.

You can change this script to your liking.