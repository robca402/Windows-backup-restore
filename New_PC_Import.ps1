# New_PC_Import.ps1
# 14-7-2022: v1.6 Changed commands for Firefox copy/restore, should make firefox transfers more robust; Caleb Robinson
# 6-7-2022:  v1.5 Removed the importing of the taskbar icons, while it worked often, sometimes it was more of a hinderance than a help and I want the script to be consistent; Caleb Robinson
# 12-6-2022: v1.4 Reduced retry limit and wait time to 2 seconds each to prevent being caught in non-stop loop; Caleb Robinson
# 25-5-2022: v1.3 Moved log location from root to Script logs folder. Added MT flag to robocopy to increase performance in some scenarios; Caleb Robinson
# 5-5-2022:  v1.2.1 Added test for Downloads path based on change to the export script.; Caleb Robinson
# 2-5-2022:  v1.2 Added transfer summary to end of script for quick identification of issues. Various minor spelling and error message wording changes.; Caleb Robinson
# 29-4-2022: v1.1 Fixed Signatures not copying over correctly; Caleb Robinson
# 13-4-2022: v1.0 Created a migration script for Windows 10 computers, copying files from the external drive and onto the new PC; Caleb Robinson
# Script should be placed and run from the root directory of the external drive i.e. X:\New_PC_Import.ps1
# All output of script will be stored in the folder Script logs e.g. X:\Script logs\Import.$HOSTNAME.$TIME.log.txt

## Create a variable for the time and begin logging all output from the script
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

Start-Transcript -Append "$pwd\Script logs\Import.$env:COMPUTERNAME.$time.log.txt"
""
""
## Stop watch to report total time to run
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

## Below gives some info to start and prompts for the folder to restore from and whether or not you want to restore bookmarks
Write-Host "Before the script starts it needs to know the folder that the backup was stored in. Please enter the folder on the external storage and copy/paste the file path into this prompt" -ForegroundColor Green
$source = Read-Host -Prompt "Paste the path to the backup folder here"
Write-Host "The entered path was $source"
$answer = Read-Host -Prompt "Was this path correct and would you like to continue? y/n"
""

if (($answer -eq 'y') -or ($answer -eq 'yes')) {

## Set the power plan when on AC power to never sleep - This ensures the PC doesn't go to sleep mid-way through copying and require the user's password to unlock.
""
"You can choose if you want to restore all browser bookmarks or not, you probably don't want to if the user has sync set up on their browser of choice"
$bookmarks = Read-Host -Prompt "Do you want to restore all browser bookmarks? y/n"
""
""
"Setting power plan to ensure computer doesn't sleep during transfer"
powercfg -change -monitor-timeout-ac 0
powercfg -change -standby-timeout-ac 0
powercfg -change -monitor-timeout-dc 0
powercfg -change -standby-timeout-dc 0
"Power plan set!"
""

## Check free space on C:\ and ensure the backup will fit. Highly unlikely that it won't but good to have a check in place anyway
"Checking size of backup to restore"
Start-Sleep 3
$backup_size = [math]::Round((gci -force $source -Recurse -File -ErrorAction SilentlyContinue | measure Length -s).sum / 1Gb,1)
$cdrive = [math]::Round((Get-PSDrive C).Free / 1Gb,1)
"The C:\ has $cdrive GB free and the restore requires $backup_size GB"

## If/else statement to stop the script if the backup won't fit
if ($cdrive -gt $backup_size) {

## Create variables of the special paths to easily transfer to the correct place
$docs = [environment]::getfolderpath("mydocuments")
$pics = [environment]::getfolderpath("mypictures")
$desktop = [environment]::getfolderpath("desktop")
$music = [environment]::getfolderpath("mymusic")
$video = [environment]::getfolderpath("myvideos")
$downloads = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

""
Write-Host "There is enough space for the transfer to continue" -ForegroundColor Green
""

## Copy the 6 main user directories (only if present, if they were stored on onedrive they won't have been copied)
""
if ((Test-Path $source\Downloads) -eq 1) {
"User folder 1 of 6: Copying Downloads folder..."
robocopy "$source\Downloads" "$downloads" /E /MT /R:2 /W:2
$sizeofdownloads = [math]::Round((gci -force $downloads -Recurse -File -ErrorAction SilentlyContinue | measure Length -s).sum / 1Gb,1)
""
"Downloads folder copied"
""
""
} else {
    "User folder 1 of 6: No Downloads folder present to restore"
    $sizeofdownloads = 0
}


if ((Test-Path $source\Documents) -eq 1) {
    "User folder 2 of 6: Copying Documents folder..."
    robocopy "$source\Documents" "$docs" /E /MT /R:2 /W:2
    ""
    $sizeofdocs = [math]::Round((gci -force $docs -Recurse -File -ErrorAction SilentlyContinue | measure Length -s).sum / 1Gb,1)
    "Documents folder copied"
    ""
} else {
    "User folder 2 of 6: No Documents folder present to restore"
    $sizeofdocs = 0
    }

if ((Test-Path $source\Desktop) -eq 1) {
    "User folder 3 of 6: Copying Desktop folder"
    ""
    robocopy "$source\Desktop" "$desktop" /E /MT /R:2 /W:2
    $sizeofdesktop = [math]::Round((gci -force $desktop -Recurse -File -ErrorAction SilentlyContinue | measure Length -s).sum / 1Gb,1)
    ""
    "Desktop folder copied"
    ""
} else {
    "User folder 3 of 6: No Desktop folder present to restore"
    $sizeofdesktop = 0
    }

if ((Test-Path $source\Pictures) -eq 1) {
    "User folder 4 of 6: Copying Pictures folder..."
    ""
    robocopy "$source\Pictures" "$pics" /E /MT /R:2 /W:2
    $sizeofpics = [math]::Round((gci -force $pics -Recurse -File -ErrorAction SilentlyContinue | measure Length -s).sum / 1Gb,1)
    ""
    "Pictures folder copied"
} else {
    "User folder 4 of 6: No Pictures folder present to restore"
    $sizeofpics = 0
    }
""

if ((Test-Path $source\Videos) -eq 1) {
    "User folder 5 of 6: Copying Videos folder"
    ""
    robocopy "$source\Videos" "$video" /E /MT /R:2 /W:2
    $sizeofvideo = [math]::Round((gci -force $video -Recurse -File -ErrorAction SilentlyContinue | measure Length -s).sum / 1Gb,1)
    ""
    "Videos folder copied"
    } else {
    "User folder 5 of 6: No Videos folder present"
    $sizeofvideo = 0
    }


""
if ((Test-Path $source\Music) -eq 1) {
    "User folder 6 of 6: Copying Music folder"
    ""
    robocopy "$source\Music" "$music" /E /MT /R:2 /W:2
    $sizeofmusic = [math]::Round((gci -force $music -Recurse -File -ErrorAction SilentlyContinue | measure Length -s).sum / 1Gb,1)
    ""
    } else {
    "User folder 6 of 6: No Music folder present"
    $sizeofmusic = 0
    }
""

## Next step is the restore the %appdata% directories, with a check of the signatures folder which doesn't exist on the old computer if the user doesn't use signatures on outlook.
""
"Copying Outlook folder..."
robocopy "$source\Appdata\Outlook" "$env:APPDATA\Microsoft\Outlook" /E /MT /R:2 /W:2
""
"Outlook folder copied"
""
""
""
"Copying Templates folder..."
robocopy "$source\Appdata\Templates" "$env:APPDATA\Microsoft\Templates" /E /MT /R:2 /W:2
""
"Templates folder copied"
""
""
if ((Test-Path $source\Appdata\Signatures) -eq 1) {
    "Copying Signatures folder..."
    robocopy "$source\Appdata\Signatures" "$env:APPDATA\Microsoft\Signatures" /E /MT /R:2 /W:2
    "Signatures folder copied"
    } else {
    "No signatures folder present... Moving on"
    }

""
"Copying windows theme folder..."
robocopy "$source\Appdata\Themes" "$env:APPDATA\Microsoft\Windows\Themes" /E /MT /R:2 /W:2
""
"Theme folder copied. This may take some time to engage. A log off/log in should force it up update"
""
""

## NOW DISABLED -- Next step is the restore the taskbar shortcuts
#"Restoring taskbar shortcuts.."
#Copy-Item $source\Taskbar\TaskbarItems\* -Destination "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\" -PassThru -Recurse
#REGEDIT /S "$source\Taskbar\PinnedItems.reg"
#""
#"Taskbar shortcuts restored"

## Next step is the restore the bookmarks. If the user uses browser sync this step won't be needed. This was asked at the start of the script and the code below will honor the answer.
## The backup script checked for the existence of bookmarks for Chrome, Firefox, and Edge. If they didn't exist they weren't copied. So this does the same check and if they weren't copied then it moves on.

if (($bookmarks -eq 'y') -or ($bookmarks -eq 'yes')) {
    

    ## Check if chrome bookmarks exist and if so, restore them.
    if ((Test-Path $source\Bookmarks\Chrome\Bookmarks) -eq 1) {
        "Copying Chrome bookmarks.."
        robocopy "$source\Bookmarks\Chrome" "$env:LOCALAPPDATA\Google\Chrome\User Data\Default" "Bookmarks"
        ""
        "Copied Chrome bookmarks"
        } else {
        ""
        "There are no Chrome bookmarks to restore"
        }
    ""
    ""
    ## Check if edge bookmarks exist and if so, restore them.
    if ((Test-Path $source\Bookmarks\Edge\Bookmarks) -eq 1) {
        "Copying Edge bookmarks.."
        robocopy "$source\Bookmarks\Edge" "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default" "Bookmarks"
        ""
        "Copied Edge bookmarks"
        } else {
        ""
        "There are no Edge bookmarks to restore"
        }
    ""
    ""
    ## The location for firefox bookmarks is a little tough as it's a dynamic path with a randomly generated profile name within it. This creates a variable with the path of the directory containing places.sqlite already. This won't work unless Firefox creates this before any bookmarks are made.. which I don't know if it does or not yet.
    if ((Test-Path $source\Bookmarks\Firefox\profiles.ini) -eq 1) {
        $firefox1 = Test-Path "C:\Program Files\Mozilla Firefox\firefox.exe"
        $firefox2 = Test-Path "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
        if ($firefox1 -eq 1) {
            $mozilla_location = "C:\Program Files\Mozilla Firefox\firefox.exe"
            } 
            elseif ($firefox2 -eq 1) {
                $mozilla_location = "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
                }
            else
                {mozilla_location = "Firefox is not installed on this PC"}
        Start-Process -FilePath "$mozilla_location"
        Start-Sleep 5
        Stop-Process -Name "Firefox"
        if ((Test-Path $env:appdata\Mozilla) -eq 0) {
    "Firefox is not installed on this computer and bookmarks cannot be restored"
    } else {
        
        "Copying Firefox Bookmarks"
        Robocopy "$source\Bookmarks\Firefox" "$env:APPDATA\Mozilla\Firefox" /E /MT /COPY:D /R:2 /W:2
        "Firefox Bookmarks copied"
        
        }
        } else {
        ""
        ""
        "There are no Firefox bookmarks to restore"
        }


    } else {
    "Bookmarks were chosen not to be restored."
    }
    ""
    ""
    ""
Write-Host "This is the end of the script, all files should be restored now" -ForegroundColor Green
""
Write-Host "Check through the script output to check for any errors" -ForegroundColor Green

$outlook = (Get-ChildItem -force $env:APPDATA\Microsoft\Outlook -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb
$templates = (Get-ChildItem -force $env:APPDATA\Microsoft\Templates -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb
$signatures = (Get-ChildItem -force $env:APPDATA\Microsoft\Signatures -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb
$ffsize = (Get-ChildItem -force $env:APPDATA\Mozilla\Firefox\Profiles -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -s).sum / 1Gb

$total_transferred = [math]::Round($sizeofdownloads + $sizeofdesktop + $sizeofdocs + $sizeofpics + $sizeofmusic + $outlook + $templates + $signatures + $ffsize + $sizeofvideo,1)

""
Write-Host "Total size transferred was $total_transferred GB out of $backup_size GB" -ForegroundColor Green
""
## NOW DISABLED AS PER v1.5 -- Restart explorer.exe to refresh taskbar icons
#taskkill /f /im explorer.exe
#start explorer.exe
""
} else {
    ""
    "There is not enough room to fit the backup. You will need to manually resolve this"
    ""
    Stop-Transcript
    ""
    ""
    $secs = $stopwatch.Elapsed.Seconds
    $mins = [math]::Round($stopwatch.Elapsed.TotalMinutes)

    "Total time taken to run was $mins minutes and $secs seconds"
    $stopwatch.Stop()
    ""
    ""
    "Restoring power profile"
    powercfg -change -monitor-timeout-ac 20
    powercfg -change -standby-timeout-ac 0
    powercfg -change -monitor-timeout-dc 10
    powercfg -change -standby-timeout-dc 20
    ""
    cmd /c pause
    }

## On the new computer they will be using we should return the power profile back to something sensible, at least for turning off the screen on ac.
""
"Restoring power profile"
powercfg -change -monitor-timeout-ac 20
powercfg -change -standby-timeout-ac 0
powercfg -change -monitor-timeout-dc 10
powercfg -change -standby-timeout-dc 20
""

## We also want to set the computer lid close on AC power to "Do Nothing"

powercfg -setacvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0

""
""
$secs = $stopwatch.Elapsed.Seconds
$mins = [math]::Round($stopwatch.Elapsed.TotalMinutes)

Write-Host "Total time taken to run was $mins minutes and $secs seconds" -ForegroundColor Green
$stopwatch.Stop()
""
Stop-Transcript
""
cmd /c pause
} else {
    Write-Host "Script aborted as the incorrect path was selected. Nothing has been changed on the target PC and the script will exit now." -ForegroundColor Red
    ""
    Stop-Transcript
    ""
    cmd /c pause
    }
