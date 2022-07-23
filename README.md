# Windows-backup-restore
Powershell scripts written to facilitate transfer of users data from one computer to another

The windows scripts can be used for migrations from an old Windows computer to a new Windows Computer. The Export script could also be used to take a backup of a user’s data before doing something to their computer, particularly if the data isn’t stored on OneDrive or another syncing service. Most of the testing of the windows scripts was on Windows 10, however some testing was done on windows 11 and some commands were tweaked for compatibility with Win 11.

The Windows backup and restore scripts do the following…

1. Sets power plan to prevent computer going to sleep during transfer (Unless locked by group policy)
2. Lists the location of the directories; Documents, Desktop, Downloads, Pictures, Music, Videos and detects if these are local, in OneDrive or on a network location
3. Asks whether you want to force the copy of files from OneDrive or network share e.g. The old PC has folder redirects to a network location but you want the files locally on the new computer
4. Checks sufficient space on the external drive for all data calculated to transfer
5. Creates folder on root of external drive named “$Username - $Date” e.g. bonja007 – 28.6.22
6. Begins copying data from %appdata%\Microsoft\{Outlook, Templates, Signatures, Themes} Desktop, Documents, Downloads, Pictures, Videos and Music 
7. Edge, Chrome and Firefox bookmarks
8. Stores list of installed printers and mapped network shares into .txt files
9. Resets power plan
10. Calculates and tells you total size backed up out of total to transfer (to quickly identify if something may have failed)
11. Logs everything into X:\Script logs\


Instructions for use
1. Place both scripts on to an external drive to backup onto
2. Run Old_PC_Export.ps1 on the computer user you want to backup
3. Run New_PC_Import.ps1 on computer you want to restore user data onto
