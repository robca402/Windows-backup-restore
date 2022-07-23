# Windows-backup-restore
Powershell scripts written to facilitate transfer of users data from one computer to another

The windows scripts can be used for migrations from an old Windows computer to a new Windows Computer. The Export script could also be used to take a backup of a user’s data before doing something to their computer, particularly if the data isn’t stored on OneDrive or another syncing service. Most of the testing of the windows scripts was on Windows 10, however some testing was done on windows 11 and some commands were tweaked for compatibility with Win 11.

The Windows backup and restore scripts do the following…

Sets power plan to prevent computer going to sleep during transfer (Unless locked by group policy)
Lists the location of the directories; Documents, Desktop, Downloads, Pictures, Music, Videos and detects if these are local, in OneDrive or on a network location
Asks whether you want to force the copy of files from OneDrive or network share e.g. The old PC has folder redirects to a network location but you want the files locally on the new computer
Checks sufficient space on the external drive for all data calculated to transfer
Creates folder on root of external drive named “$Username - $Date” e.g. bonja007 – 28.6.22
Begins copying data from
%appdata%\Microsoft\{Outlook, Templates, Signatures, Themes}
Desktop, Documents, Downloads, Pictures, Videos and Music
Edge, Chrome and Firefox bookmarks
Stores list of installed printers and mapped network shares into .txt files
Resets power plan
Calculates and tells you total size backed up out of total to transfer (to quickly identify if something may have failed)
Logs everything into X:\Script logs\
