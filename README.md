There is no global setting to change all your games on Steam to receive updates immediately when they are available.  
Often I see Steam scheduling the updates to when I usually have my computer off and I'm not gonna
click on hundreds of games from "Let Steam decide" to getting updates immediately, totally useless.
So I took matter into my own hands, made this script and decided to share.

A simple script to alter all your games on Steam to download updates immediately, with a counter of total and updated games for each library.
You can run this after every new download; it will not show the same result twice.
Written for Windows and for us that have many Steam games downloaded.

The script finds your Steam installation path via windows registry and pulls the libraries from libraryfolders.vdf
and changes the key "AutoUpdateBehavior" from value "0" to "2" in all appmanifest_*.acf files that it finds, enabling immediate Steam updates.

## Pre-running the script/Installation:
1.  Put the files wherever you want.
2.  EDIT steam_updater.bat and change the path to where you put the steam_updater.ps1 file.
3.  Run the .bat file, make a shortcut out of it or something.
4.  Reboot Steam to see the changes.

You can change this script to your liking.
