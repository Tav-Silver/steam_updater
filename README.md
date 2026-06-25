There is no global setting to change all your games on Steam to receive updates immediately when they are available.
This is very annoying since I have many games downloaded. So I took matter into my own hands, made this script and decided to share.

This is a script that alter all your games on Steam to download updates immediately and I've added some interesting
features like a counter of updated games, number of games and a total size on disk column for each library.
You can run this after every new download, it will not show the same result twice. Add the script to a macro
and have it run silently everytime you download a game, idk. Written for Windows users obviously.

## What does it do?
The script finds your Steam installation path via windows registry and pulls the libraries from libraryfolders.vdf in the Steam installation
and changes the key "AutoUpdateBehavior" from value "0" to "2" in all appmanifest_*.acf files that it finds, enabling immediate Steam updates.
The script will also gracefully restart Steam automatically if the script detects that the "Games updated" counter is bigger than 0.

## Pre-running the script/Installation:
1.  Put the files wherever you want.
2.  EDIT steam_updater.bat and change the path to where you put the script (steam_updater.ps1) file.
3.  Run the .bat file, make a shortcut to the desktop or something.

You can change this script to your liking.
