# Old_PC_Export.ps1
# 14-7-2022: v1.6 Changed commands for Firefox copy/restore, should make firefox transfers more robust; Caleb Robinson
# 6-7-2022:  v1.5 Removed the copying of the taskbar icons, while it worked often, sometimes it was more of a hinderance than a help and I want the script to be consistent; Caleb Robinson
# 12-6-2022: v1.4 Reduced retry limit and wait time to 2 seconds each to prevent being caught in non-stop loop; Caleb Robinson
# 25-5-2022: v1.3 Moved log locations from root to Script logs folder. Added MT flag to robocopy to optimise speed in some scenarios; Caleb Robinson
# 5-5-2022:  v1.2 Added special location of downloads folder rather than assumed static location. Added test for special folders on network drive and prompt whether or not to copy from there.; Caleb Robinson
# 17-4-2022: v1.1 Changed from Copy-Item to robocopy for the majority of file transfers, adding compatibility for all files in paths longer than 256 characters. Changed from Get-Volume to Get-PSDrive for better compatibility with Windows 11.;  Caleb Robinson
# 12-4-2022: v1.0 Created a migration script for Windows 10 computers, copying all files onto a external drive; Caleb Robinson
# Script should be placed and run from the root directory of the external drive i.e. X:\Old_PC_Exports.ps1
# Overall this script will do the following: Set power plan, check there is sufficient space for all user data on external drive (and exit if not), create a directory on the base of current user and today's date then copies Documents, Downloads, Desktop, Music, Pictures, Videos, %appdata%\{Signatures,Outlook,Templates}, Bookmarks from Chrome, Edge and Firefox, User themes, Taskbar shortcuts, current printers installed and current shares mapped.
# All output of script will be stored in the folder Script logs e.g. X:\Script logs\Export.$HOSTNAME.$TIME.log.txt
$time = Get-Date -Format "HH.mm.ss"

## Check for log folder and create if it doesn't exist
if (Test-Path "$pwd\Script logs") {
       Write-Host "Log folder Exists..."
}
else
{
    #PowerShell Create directory if not exists
    New-Item "$pwd\Script logs" -ItemType Directory
    Write-Host "Created log directory"
}

## Create variable of the log file name

$log = "$pwd\Script logs\EXPORT.$env:COMPUTERNAME.$time.log.txt"

Start-Transcript -Append $log
""
""
## Stop watch to report total time to run
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

## Making variables with the path to the special folders - This gets around the issue if someone has their Documents folder stored on the U: or H: instead of locally on the C:
$docs = [environment]::getfolderpath("mydocuments") 
$pics = [environment]::getfolderpath("mypictures")
$desk = [environment]::getfolderpath("desktop")
$mus = [environment]::getfolderpath("mymusic")
$video = [environment]::getfolderpath("myvideos")
$down = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

"The location of Documents is:  $docs"
"The location of Downloads is:  $down"
"The location of Pictures is:  $pics"
"The Location of Desktop is:  $desk"
"The location of Music is:  $mus"
"The location of Videos is:  $video"
""
""
## To make the script more flexible, I will prompt at the start whether or not you want to force the backup of files in a directory on OneDrive (May be some fringe cases where this may be wanted)

$onedrive_documents = [environment]::getfolderpath("mydocuments") -like '*OneDrive*'
$onedrive_pictures = [environment]::getfolderpath("mypictures") -like '*OneDrive*'
$onedrive_desktop = [environment]::getfolderpath("desktop") -like '*OneDrive*'
$onedrive_music = [environment]::getfolderpath("mymusic") -like '*OneDrive*'
$onedrive_video = [environment]::getfolderpath("myvideos") -like '*OneDrive*'
$onedrive_downloads = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path -like '*OneDrive*'

if (($onedrive_desktop -eq 1) -or ($onedrive_documents -eq 1) -or ($onedrive_pictures -eq 1) -or ($onedrive_downloads -eq 1) -or ($onedrive_music -eq 1) -or ($onedrive_video -eq 1)) {
    ""
    $backup_onedrive = Read-Host -Prompt "One or more directories are stored on OneDrive. Do you want to force the backup of these files anyway? y/n"
    ""
} else {
    ""
}

## I also want to test for it being on a network path, as likely this won't want to be copied either. Though for flexibility I want to ask in case in some scenario it is wanted.

$onc_documents = [environment]::getfolderpath("mydocuments") -like '*C:\*'
$onc_pictures = [environment]::getfolderpath("mypictures") -like '*C:\*'
$onc_desktop = [environment]::getfolderpath("desktop") -like '*C:\*'
$onc_music = [environment]::getfolderpath("mymusic") -like '*C:\*'
$onc_video = [environment]::getfolderpath("myvideos") -like '*C:\*'
$onc_downloads = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path -like '*C:\*'

if (($onc_documents -eq 0) -or ($onc_pictures -eq 0) -or ($onc_desktop -eq 0) -or ($onc_music -eq 0) -or ($onc_video -eq 0) -or ($onc_downloads -eq 0)) {
    ""
    $backup_network = Read-Host -Prompt "One or more directories are not on C:\ and are likely network shares. Do you want to force the backup of these files anyway? y/n"
    ""
} else {
    ""
}

## Set the power plan when on AC power to never sleep - This ensures the PC screen doesn't lock mid-way through copying and require the user's password to unlock.
""
"Setting power plan to ensure screen stays on and PC doesn't sleep during transfer"
powercfg -change -monitor-timeout-ac 0
powercfg -change -standby-timeout-ac 0
powercfg -change -monitor-timeout-dc 0
powercfg -change -standby-timeout-dc 0
"Power plan set!"
""
"Before starting, this Script will check drive space is sufficient for migration"
""

## This makes a variable with the output of the amount of free space on the drive the script is run on. This is used below in an if/else statement to stop the script if there is not enough free space.
## Note this was using Get-Volume however had compatibility issues with Windows 11 testing. For better compatibility/future proofing leave this as Get-PSDrive.
$External = [math]::Round((Get-PSDrive $pwd.Drive.Name).Free / 1Gb,1)


## This command will print out the amount of free space on the external drive (The drive the script is run from)
"Free Space on External Drive is $External GB"
""
""

## We probably don't want to copy the files onto an external drive if the special folder is pointing to within OneDrive as it should be backed up there and will restore. Below is logic to query if the folder is in OneDrive and if not, then don't copy it. There is also an if/else statement below to force the copy of the onedrive folders based on the question at the start of the script.

if (($backup_onedrive -eq 'y') -or ($backup_onedrive -eq 'yes')) {
    $onedrive_documents = $false
    $onedrive_pictures = $false
    $onedrive_desktop = $false
    $onedrive_music = $false
    $onedrive_video = $false
    $onedrive_downloads = $false
    } else {
""
}

if (($backup_network -eq 'y') -or ($backup_network -eq 'yes')) {
    $onc_documents = $true
    $onc_pictures = $true
    $onc_desktop = $true
    $onc_music = $true
    $onc_video = $true
    $onc_downloads = $true
    } else {
""
}


## Below will check if the directory is stored in OneDrive, and if so, will report 0GB to copy, else it will calculate the size and report this and use this size in the calculation to run the rest of the script or not.

if (($onedrive_downloads -eq 1) -or ($onc_downloads -eq 0)) {
    "Downloads directory is on OneDrive or a network share and won't be copied"
    $downloads = 0
    } else {
    $downloads = (Get-ChildItem -force $down -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb
    "The size of the Downloads directory is " + [math]::Round($downloads,2) + " GB"
}

if (($onedrive_pictures -eq 1) -or ($onc_pictures -eq 0)) {
    "Pictures directory is on OneDrive or a network share and won't be copied"
    $pictures = 0
    } else {
    $pictures = (Get-ChildItem -force $pics -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb
    "The size of the Pictures directory is " + [math]::Round($pictures,2) + " GB"
}

if (($onedrive_documents -eq 1) -or ($onc_documents -eq 0)) {
    "Documents directory is on OneDrive or a network share and won't be copied"
    $documents = 0
    } else {
    $documents = (Get-ChildItem -force $docs -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb
    "The size of the Documents directory is " + [math]::Round($documents,2) + " GB"
}

if (($onedrive_desktop -eq 1) -or ($onc_desktop -eq 0)) {
    "Desktop directory is on OneDrive or a network share and won't be copied"
    $desktop = 0
    } else {
    $desktop = (Get-ChildItem -force $desk -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb
    "The size of the Desktop directory is " + [math]::Round($desktop,2) + " GB"
}

if (($onedrive_music -eq 1) -or ($onc_music -eq 0)) {
    "The music is on OneDrive or a network share and won't be copied"
    $music = 0
    } else {
    $music = (Get-ChildItem -force $mus -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb
    "The size of the Music directory is " + [math]::Round($music,2) + " GB"
}

if (($onedrive_video -eq 1) -or ($onc_video -eq 0)) {
    "Video directory is on OneDrive or a network share and won't be copied"
    $videos = 0
    } else {
    $videos = (Get-ChildItem -force $video -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb
    "The size of the Video directory is " + [math]::Round($videos,2) + " GB"
}
""

## I want to calculate the size of those appdata folders

$outlook = (Get-ChildItem -force $env:APPDATA\Microsoft\Outlook -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb
$templates = (Get-ChildItem -force $env:APPDATA\Microsoft\Templates -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb
$signatures = (Get-ChildItem -force $env:APPDATA\Microsoft\Signatures -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb
$ffsize = (Get-ChildItem -force $env:APPDATA\Mozilla\Firefox\Profiles -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb


## The total size of all user data is added togther into a new variable
$total = [math]::Round($pictures + $desktop + $documents + $downloads + $music + $outlook + $templates + $signatures + $ffsize + $videos,1)

## Total of all directories to copy
"Total size to migrate is $total GB"

if ($total -lt $External) {
""
Write-Host "Well done, there is enough space on the external drive. Migration will begin now" -ForegroundColor Green
""

## Store a variable for today's date
$todaydate = Get-Date -Format "dd.MM.yyyy"

## Store a variable with the location of the external drive and a folder named with the username and today's date
$folder = "$pwd\$env:UserName - $todaydate"

## Check if folder exists, and if not then create it
if (Test-Path $folder) {
   
    Write-Host "Folder Exists, skipping"
    # Perform Delete file from folder operation
}
else
{
    #PowerShell Create directory if not exists
    New-Item $folder -ItemType Directory
}
""

## Extract the mapped shares information and store them in a .txt file on the external drive
"Storing output of net use (mapped network shares) to shares.txt"
net use | Set-Content -Path $folder\shares.txt
""
"Mapped network drives stored"
""

## Store Installed printer in a .txt file
"Storing list of installed printers to printers.txt"
wmic printer list brief | Set-Content -Path $folder\printers.txt
""
"Printer list stored"

## Create Downloads folder and copy files into it

if (($onedrive_downloads -eq 1) -or ($onc_downloads -eq 0)) {
    ""
} else {
$null = New-Item $folder\Downloads -ItemType Directory
""
""
"Copying Downloads..."
robocopy "$down" "$folder\Downloads" /E /MT /R:2 /W:2
""
"Downloads Copied..."
""
}
## Create Documents folder and copy files into it

if (($onedrive_documents -eq 1) -or ($onc_documents -eq 0)) {
    ""
    } else {
    $null = New-Item $folder\Documents -ItemType Directory
    ""
    ""
    "Copying Documents..."
    robocopy "$docs" "$folder\Documents" /E /R:2 /W:2 /MT /XD "$docs\My Music" "$docs\My Pictures" "$docs\My Videos"
    ""
    "Documents Copied..."
}
""

## Create Desktop folder and copy files into it

if (($onedrive_desktop -eq 1) -or ($onc_desktop -eq 0)) {
    ""
    } else {
    $null = New-Item $folder\Desktop -ItemType Directory
    ""
    ""
    "Copying Desktop..."
    robocopy "$desk" "$folder\Desktop" /E /MT /R:2 /W:2
    ""
    "Desktop Copied..."
    ""
}

## Create Pictures folder and copy files into it

if (($onedrive_pictures -eq 1) -or ($onc_pictures -eq 0)) {
    ""
    } else {
    $null = New-Item $folder\Pictures -ItemType Directory
    ""
    ""
    "Copying Pictures..."
    robocopy "$pics" "$folder\Pictures" /E /MT /R:2 /W:2
    ""
    "Pictures Copied..."
    ""
}


## Create Music folder and copy files into it

if (($onedrive_music -eq 1) -or ($onc_music -eq 0)) {
    ""
    } else {
    $null = New-Item $folder\Music -ItemType Directory
    "Copying Music..."
    robocopy "$mus" "$folder\Music" /E /MT /R:2 /W:2
    ""
    "Music Copied..."
}
""
""

## Create Videos folder and copy files into it

if (($onedrive_video -eq 1) -or ($onc_video -eq 0)) {
    ""
    } else {
    $null = New-Item $folder\Videos -ItemType Directory
    ""
    ""
    "Copying Videos..."
    robocopy "$video" "$folder\Videos" /E /MT /R:2 /W:2
    ""
    "Videos Copied..."
}
""

## Create all directories for the %appdata% directories that we want to copy and restore on the new computer
$null = New-Item $folder\Appdata -ItemType Directory
$null = New-Item $folder\Appdata\Outlook -ItemType Directory
$null = New-Item $folder\Appdata\Signatures -ItemType Directory
$null = New-Item $folder\Appdata\Templates -ItemType Directory
$null = New-Item $folder\Appdata\Themes -ItemType Directory


## Copying Outlook, Templates and Signatures directories
"Copying Outlook folder in %appdata%..."
Copy-Item $env:APPDATA\Microsoft\Outlook\* -Destination $folder\Appdata\Outlook\ -PassThru -Recurse
""
"Outlook folder copied..."
""
"Copying Templates folder in %appdata%..."
Copy-Item $env:APPDATA\Microsoft\Templates\* -Destination $folder\Appdata\Templates\ -PassThru -Recurse
""
"Templates folder copied..."
""
"Copying Signatures folder in %appdata%..."
if ((Test-Path $env:APPDATA\Microsoft\Signatures) -eq 1 ) {
Copy-Item $env:APPDATA\Microsoft\Signatures\* -Destination $folder\Appdata\Signatures\ -PassThru -Recurse
""
"Signatures folder copied..."
} else {
 ""
 }
""
"Copying Themes folder in %appdata%"
Copy-Item $env:APPDATA\Microsoft\Windows\Themes\* -Destination $folder\Appdata\Themes\ -PassThru -Recurse
""
"Themes folder copied"
""
""
## NOW DISABLED -- The commands below store the taskbar shortcuts and extract the registry entry related to them which can be easily restored on the new computer 
#"Copying Taskbar shortcuts"
#$null = New-Item $folder\Taskbar -ItemType Directory
#$null = New-Item $folder\Taskbar\TaskbarItems -ItemType Directory
#Copy-Item "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*" -Destination $folder\Taskbar\TaskbarItems\ -PassThru -Recurse
#""
#reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" "$folder\Taskbar\PinnedItems.reg" /y
#"Taskbar shortcuts and registry entry copied"
#""

## Create new directory for the bookmarks 
$null = New-Item $folder\Bookmarks -ItemType Directory

## Check if bookmarks exist for edge and if so, create a directory and copy them over
$edge = Test-Path "$env:localappdata\Microsoft\Edge\User Data\Default\Bookmarks"
if ($edge -eq 0) {
    "There are no edge bookmarks to backup"
    } else {
"Backing up Microsoft Edge bookmarks"
$null = New-Item $folder\Bookmarks\Edge -ItemType Directory
Copy-Item "$env:localappdata\Microsoft\Edge\User Data\Default\Bookmarks" -Destination $folder\Bookmarks\Edge\ -PassThru
""
"Edge bookmarks copied!"
}
""

## Check if bookmarks exist for Chrome and if so, create a directory and copy them over
$chrome = Test-Path "$env:localappdata\Google\Chrome\User Data\Default\Bookmarks"
if ($chrome -eq 0 ) {
    "There are no Chrome bookmarks to backup"
    } else {
"Backing up Chrome bookmarks"
$null = New-Item $folder\Bookmarks\Chrome -ItemType Directory
Copy-Item "$env:localappdata\Google\Chrome\User Data\Default\Bookmarks" -Destination $folder\Bookmarks\Chrome\ -PassThru
""
"Chrome bookmarks copied!"
}
""

## Check if bookmarks exist for Firefox and if so, create a directory and copy them over
## I know the logic doesn't quite work out here, the first command looks for places.sqlite and if not found it would fail before it reached the Test-Path of places.sqlite. If anybody has a better idea I'm all ears! - Caleb

if ((Test-Path $env:appdata\Mozilla) -eq 0) {
    "There are no firefox bookmarks to backup"
    } else {
"Copying Firefox bookmarks"

$null = New-Item $folder\Bookmarks\Firefox -ItemType Directory
$null = New-Item $folder\Bookmarks\Firefox\Profiles -ItemType Directory

robocopy "$env:appdata\Mozilla\Firefox" "$folder\Bookmarks\Firefox" /COPY:D /E /MT /R:2 /W:2

""
"Firefox bookmarks backed up"
}
""

## This command creates a variable of the total size of the backup folder on the external drive
$copied = [math]::Round((Get-ChildItem -force $folder -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb,1)
"Copied a total of $copied GB out of $total GB to the external drive"
""
Write-Host "This script is now complete." -ForegroundColor Green
""
"Double check the files are all there as expected, then move external drive to the new PC and run the New_PC_Import.ps1"
""
"Be sure to glance over all output to ensure it worked as expected. Also remember to check other unexpected locations for data to backup manually"

""
""
"Reverting power plan"
powercfg -change -monitor-timeout-ac 10
powercfg -change -standby-timeout-ac 0
powercfg -change -monitor-timeout-dc 10
powercfg -change -standby-timeout-dc 20
""
""
$secs = $stopwatch.Elapsed.Seconds
$mins = [math]::Round($stopwatch.Elapsed.TotalMinutes)

"Total time taken to run was $mins minutes and $secs seconds"
$stopwatch.Stop()
""
""
Stop-Transcript

""
cmd /c pause

} else {
    ""
    Write-Host "There is not enough room on the external drive to complete the migration, there is only $External GB free when $total GB is required. Get a larger drive or clear data to increase free space." -ForegroundColor Red
    ""
    "Reverting power plan settings"
    powercfg -change -monitor-timeout-ac 10
    powercfg -change -standby-timeout-ac 0
    powercfg -change -monitor-timeout-dc 10
    powercfg -change -standby-timeout-dc 20
    ""
    ""
    Stop-Transcript
       ""
    cmd /c pause
    }