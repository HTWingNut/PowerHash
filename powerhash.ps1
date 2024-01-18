#Requires -Version 7

# powerhasha256.ps1 by HTWingNut 18 Jan 2024

<#
    .SYNOPSIS
    Generates SHA256 or MD5 has values of folders and subfolders.

    .DESCRIPTION
    **** PLEASE USE WITH POWERSHELL 7 CORE - IT'S FREE AND EASY TO INSTALL ****
    https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows
    winget install --id Microsoft.Powershell --source winget
    PS> pwsh .\powerhash.ps1

    This script can be run in interactive mode just by running the .ps1 files or through command line parameters.

    Results are stored in a CSV formatted log file that include file hash, file name with relative path, file size, and
    last date modified. The first few lines contain header information to identify the file path provided, date run, 
    number of files hashed, and size of files hashed.

    File paths are shown as relative to provided file path so that you can check against any location at a later date.

    1. Generate new hashes of contents in a folder recursively with ability to assign folder and file exclusions.
       Results are stored in log file with file name "SHA256_[Root Folder Name]_[TimeDateStamp].log"
         [TimeDateStamp] in format 'yyyymmdd_HHmmss'
         [Root Folder Name] example: user specifies 'D:\Media\Linux ISO' = 'Linux_ISO'
         Log File will be: 'SHA256_Linux_ISO_20231226_132312' (referred to as [LOG FILE]). It is set to read-only.
       Excluded files will be stored in '[LOGFILE]_excluded.log' (referred to as [EXCLUDED LOG]
       [EXCLUDED LOG] is strictly a reference log file.

    2. Update existing hash log with files that have changed and/or revise exclusions.
       Results are updated in: [LOG FILE] - existing file overwritten/updated with latest files in specified folder
                               [EXCLUDED LOG] - log file will be updates/overwritten with latest revised exclusions
                               [UPDATED LOG] - log file showing details of file that were updated
       The previous [LOG FILE] will be backed up as '[LOG FILE]_previous.log' in case it needs to be referenced. 
       (Referred to as [PREVIOUS LOG]
       However, it will be overwritten with the next "UPDATE LOG FILE" command.

    3. Compare two log files which will provide:
         - Matching File Names with different hash
         - Matching File Names with different file size and/or date/time stamp
         - File names unique to log 1
         - File names unique to log 2
         - Potential files that have been renamed based on matched hashes
       These results will be stored in: '[LOG FILE]_compare.log' (referred to as [COMPARE LOG]
                                        '[LOG FILE 2]_compare.log'
                                        Above are duplicate log files but included for completeness
       [COMPARE LOG] will be overwritten next time the compare function is run. This is strictly a reference log file.

    4. Scrub a folder against an existing log file:
         - Matching File Names with different hash
         - File names unique to log
         - File names unique to folder
         - Potential File Name changes based on Hash (use with -hashnew option)
         - Files with same hash and file name but different size and/or date/time stamp
         - Files that were busy and unable to validate hash
         - Number of excluded files based on user set exclusions
       These results will be stored in: '[LOG FILE}_scrub.log' (referred to as [SCRUB LOG].
       [SCRUB LOG] will be overwritten with the next scrub run. This is strictly a reference log file.

    5. Look for File Duplicates based on matching hashes.
       Results are stored in log file '[LOG FILE]_duplicates.log'. This is strictly a reference log file.

    All results will be summarized and appended to '[LOG FILE]_history.log' (referred to as [HISTORY LOG])

    To summarize above, overall there are six reference log files associated with the main log file:
        - [LOG FILE] = Main log file, must not be manually altered
            [LOG FILE] naming convention: '[ALGO]_[Root Folder Name]_[Date Time Stamp].log'
            [ALGO] is either SHA256 or MD5 depending on selected hash algorithm used
            [Root Folder Name] example: user specifies 'D:\Media\Linux ISO' = 'Linux_ISO'
            [TimeDateStamp] in format 'yyyymmdd_HHmmss'
        - '[LOG FILE]_excluded.log'   = List of used excluded files defined during 'CREATE' or 'UPDATE' commands.
        - '[LOG FILE]_history.log'    = Maintains summary of every operation
        - '[LOG FILE]_previous.log'   = Copy of [LOG FILE] made during 'UPDATE' command
        - '[LOG FILE]_updated.log     = Results of updating log file from entries in specified folder
        - '[LOG FILE]_compare.log'    = Results of comparing two log files 'COMPARE' command
        - '[LOG FILE]_scrub.log'      = Results of 'SCRUB' command
        - '[LOG FILE]_duplicates.log' = List of duplicates files based on hash Results from 'DUPLIcATES' command.

    .PARAMETER path
    Specifies the path of the folder that will be used to generate hashes for recursively

    .PARAMETER log
    Specifies the log file path and name to import data for 'COMPARE', 'UPDATE', or 'SCRUB' functions

    .PARAMETER log2
    Specifies the second log file path and name to import data for 'COMPARE' function

    .PARAMETER excludefolders
    Specifies the FOLDER exclusion keywords. Must be input in format with single quotes around keywords and comma
    between phrases i.e. '\Windows\Temp','logs'

    .PARAMETER exludefiles
    Specifies the FILE exclusion keywords. Must be input in format with single quote around keywoards and commma
    between prhases. No wildcard '*' allowed i.e. 'thumbs.db','.htm'

    .PARAMETER create
    Switch parameter indicates to create a new hash log file based on user provided path using 'path' parameter

    .PARAMETER compare
    Switch parameter indicates to compare two hash log files based on user provided path using 'log' and 'log2' parameters

    .PARAMETER update
    Switch parameter indicates to update exsiting hash log with latest hashes and file info from user provided log
    file 'log' and folder path 'path' parameters

    .PARAMETER scrub
    Switch parameter indicates to compare/scrub exsiting log file against a user specified path using 'log' and 'path'
    parameters

    .PARAMETER hashnew
    Switch parameter indicates to hash new files found during scrub operation. This will only be used to identify
    potential file name changes based on matching hashes.

    .PARAMETER md5
    Switch parameter indicates to use MD5 hash sums rather than SHA256

    .PARAMETER help
    Switch parameter to show command line examples. To get specific parameter help, can be used in conjunction with:
    -create -update -compare -duplicates -scrub -md5 -exclude

    .PARAMETER readme
    Switch parameter 

    .EXAMPLE
    PS> pwsh .\powerhash.ps1 -create -path "D:\Media\TV Shows"

    .EXAMPLE
    PS> pwsh .\powerhash.ps1 -create -path "D:\Media\TV Shows" -md5

    .EXAMPLE
    PS> pwsh .\powerhash.ps1 -create -path "D:\Media\TV Shows" -excludefolders "'\Disney','Dora'" -excludefiles "'thumbs.db','.txt'"

    .EXAMPLE
    PS> pwsh .\powerhash.ps1 -compare -log "SHA256_FOLDER_1_20231227_102345.log" -log2 "SHA256_FOLDER_2_20231227_110123.log"
    
    .EXAMPLE
    PS> pwsh .\powerhash.ps1 -compare -log "SHA256_FOLDER_1_20231227_102345.log" -log2 "SHA256_FOLDER_2_20231227_110123.log" -duplicates

    .EXAMPLE
    PS> pwsh .\powerhash.ps1 -update -log "SHA256_FOLDER_1_20231227_102345.log" -path "D:\Media\TV Shows" -exludefolders "'\Disney','Dora'" -excludefiles "'thumbs.db','.txt'"

    .EXAMPLE
    PS> pwsh .\powerhash.ps1 -scrub -path "D:\Media\TV Shows" -log "SHA256_FOLDER_1_20231227_102345.log"

    .EXAMPLE
    PS> pwsh .\powerhash.ps1 -scrub -path "D:\Media\TV Shows" -log "SHA256_FOLDER_1_20231227_102345.log" -hashnew

    .EXAMPLE
    PS> pwsh .\powerhash.ps1 -dupicates -log "SHA256_FOLDER_1_20231227_102345.log"

#>



param (
    [string]$path = "?",
    [string]$log = "?",
    [string]$log2 = "?",
    [string]$excludefolders = "",
    [string]$excludefiles = "",

    [switch]$create = $false,
    [switch]$compare = $false,
    [switch]$update = $false,
    [switch]$duplicates = $false,
    [switch]$scrub = $false,
    [switch]$excludeclear = $false,
    [switch]$md5 = $false,
    [switch]$help = $false,
    [switch]$readme = $false,
    [switch]$version = $false,
    [switch]$exclude = $false,
    [switch]$hashnew = $false
)


function checkifphash {
    # check if log file is powerhash log file based on first line =POWERHASH SHA256= (or MD5)
    $script:isph = $false
    $phline = ((get-content "$phcheck" | Select -First 1) -split "\=",3)[1]
    if ($phline -ceq "POWERHASH $algo") { $script:isph = $true; return }
    $request = "This file does not appear to be a =POWERHASH $algo= log. Continue Anyways? [y/n]"
    if (!$countTrue) { $continue = Read-Host -prompt $request }
    if ($countTrue) { $continue = "n" }
    if ( $continue -eq "y" ) { $script:isph = $true }
}


function GenerateHash {

    if (!$countTrue) { Clear-Host }
    Write-Host ""
    Write-Host "**** GENERATE $algo HASHES ****"
    Write-Host ""

    # request path to hash
    while (!(Test-Path -LiteralPath $checksumpath -PathType Container)) { 
        $request = "Path to Generate $algo Hashes"
        $checksumpath = Read-Host -Prompt $request
        $checksumpath=($checksumpath -replace '\"','').TrimEnd('\')
        if ( $checksumpath -eq "q" ) { return }
        if ( $checksumpath -eq "") { $checksumpath="?" } 
    }

    Write-Host "Hashpath '$($checksumpath)'"
    $checksumpath_base=$(split-path $checksumpath -leaf) -replace " ","_" -replace "\:\\","_"
    
    $checksumlog = "$algo`_$checksumpath_base`_$timestamp.log"
    $historylog = "$algo`_$checksumpath_base`_$timestamp`_history.log"
    $allexcludelog = "$algo`_$checksumpath_base`_$timestamp`_excluded.log"
    
    Write-Output "" >> $timelog
    Write-Output "$(Get-Date) Generate Hashes for '$checksumpath'" >> $timelog

    $StopWatch=[system.diagnostics.stopwatch]::startnew()
    Write-Host "`n**** Calculating Number of Files: " -NoNewline
    $numfiles = [int](Get-ChildItem -Path "$checksumpath" -Recurse -File).Count
    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Host "$numfiles ($SecondsElapsed seconds)"
    Write-Output "Calculating $numfiles files $SecondsElapsed seconds" >> $timelog

    $StopWatch=[system.diagnostics.stopwatch]::startnew()
    Write-Host "`n**** Calculating Total File Size: " -NoNewline
    $filesize = [math]::Round((Get-ChildItem -Path "$checksumpath" -Recurse -File | Measure -Sum -Property Length).Sum)
    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()

    Write-Host "$filesize MB ($SecondsElapsed seconds)"
    Write-Output "Calculating $filesize MB $SecondsElapsed seconds" >> $timelog

    Write-Host ""

    if (!$CountTrue) { DO { $yn = Read-Host "Would you like to add Exclusions ? [y/n]"; if ($yn -eq 'y') { $excludeyn = $true; break }} while ( $yn -ne 'n' ) }


    # folder and file exclusion routine
    if ($excludeyn) {

        clear-host
        $yn = $true
       
        Write-Host ""
        Write-Host "**** GENERATE $algo HASHES ****"
        Write-Host ""
        Write-Host "Folder to Hash: $checksumpath"
        if (!$cmdexclude) {
            Write-Host ""
            Write-Host "Enter Keywords to Exclude for >> FOLDERS <<"
            write-Host ""
            Write-Host "(You will be prompted to enter FILE Exclusions after this.)"
            Write-Host "Entries should be surrounded by single quotes and comma between entries."
            Write-Host "Example: ('\data\media\Linux ISO','\bin','Logs') **NO WILDCARDS**"
        }

        while ($yn) {
            try {
                Write-Host ""
                if (!$cmdexclude) { $excludeFolderString = Read-Host "Enter FOLDER Exclusions" }
                $excludeFolderString = $excludeFolderString.Trim()
                if ($excludeFolderString -eq 'q') { return }
                if ($excludeFolderString -notmatch $exclusionpattern) { throw }
                if ($excludeFolderString -ne "") {
                    $excludeFolderExp = Invoke-Expression $excludeFolderString
                    $excludeFolderList = @($excludeFolderExp)
                    $excludeFolderList = ($excludeFolderList | ForEach-Object { [regex]::Escape($_) }) -join '|'
                }
            }
            catch {
                Write-Host "Your input does not meet criteria, please try again"
                $yn = $true
                $excludeFolderString = ""
                $excludeFolderExp = ""
                $excludeFolderList = ""
                continue
            }
            $yn = $false
        }

        Write-Host ""
        Write-Host "------------"
        if (!$cmdexclude) {
            Write-Host ""
            Write-Host "Enter Keywords to Exclude for >> FILES <<."
            Write-Host "Entries should be surrounded by single quotes and comma between entries."
            Write-Host "Example: ('Thumbs.db','.iso') **NO WILDCARDS**"
        }
        Write-Host ""

        $yn = $true
        while ($yn) {
            try {
                if (!$cmdexclude) { $excludeFileString = Read-Host "Enter FILE Exclusions" }
                $excludeFileString = $ExcludeFileString.Trim()
                if ($excludeFileString -eq 'q') { return }
                if ($excludeFileString -notmatch $exclusionpattern) { throw }
                if ($excludeFileString -ne "") { 
                    $excludeFileExp = Invoke-Expression $excludeFileString
                    $excludeFileList = @($excludeFileExp)
                    $excludeFileList = ($excludeFileList | ForEach-Object { [regex]::Escape($_) }) -join '|'
                }
            }
            catch {
                Write-Host "Your input does not meet criteria, please try again"
                $yn = $true
                $excludeFileString = ""
                $excludeFileExp = ""
                $excludeFileList = ""
                continue
            }
            $yn = $false
        }
    }

    if (!$CountTrue) {
        Write-Host ""
        Write-Host "********"
        Write-Host "Folder Used to Generate Hashes: '$checksumpath'"
        Write-Host "   FOLDER EXCLUSIONS: $excludeFolderString"
        Write-Host "     FILE EXCLUSIONS: $excludeFileString"
        Write-Host ""
        DO { $yn = Read-Host "Continue? [y/n]"; if ($yn -eq 'n') { return }} while ( $yn -ne 'y' )

    }
    
    Write-Host ""
    Write-Host "**** Output to file: '$($checksumlog)'"
    Write-Host "FOLDER EXCLUSIONS: $excludeFolderString"
    Write-Host "  FILE EXCLUSIONS: $excludeFileString"
    Write-Host ""

    Write-Host "**** $(Get-Date) Generating File Hashes"
    Write-Host ""

    # STart hash routine
    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    $filehash = $null
    $nohash = $null
    $count=0
    $excludecount = 0
    $hashcount = 0
    $totalhashbytes = 0
    $allexcludedheader = "$(Get-Date) LOG CREATED`nFOLDER EXCLUSIONS: $excludeFolderString`nFILE EXCLUSIONS: $excludeFileString`n"

    Get-ChildItem -Path "$checksumpath" -Recurse -File | ForEach-Object {
        $continue = $true
        $skip = $false
        $fileinfo = $_
        $FullName = $_.FullName
        $relName = $_.FullName -replace [regex]::Escape("$checksumpath"), ''
        $FileLength = $fileinfo.Length
        $LastWriteTime = $fileinfo.LastWriteTime.ToString('yyyyMMdd_HHmmss')
        $FileParent = Split-Path -Path $relName -Parent
        $FileLeaf = Split-path -Path $relName -Leaf

        $count++

        $countpad = $($count.tostring().padleft($numfiles.tostring().length))

        if ($excludeFolderString -ne "") {
            if ($FileParent -match $excludeFolderList) {
                $continue = $false
                $matches = $FileParent | Select-String -Pattern $excludeFolderList -AllMatches | ForEach-Object { $_.Matches.Value }
                $allexcluded += "$relname [PATH: $($matches -join ',')]`n"
                Write-Host "$countpad of $numfiles ** EXCLUSION: [PATH: $($matches -join ',')] $relName"
                $excludecount++ 
                $skip = $true
            }
        }

        if ($excludeFileString -ne "" -and !$skip ) {
            if ($FileLeaf -match $excludeFileList) { 
                $continue = $false
                $matches = $FileLeaf | Select-String -Pattern $excludeFileList -AllMatches | ForEach-Object { $_.Matches.Value }
                $allexcluded += "$relname [FILE: $($matches -join ',')]`n"
                Write-Host "$countpad of $numfiles ** EXCLUSION: [FILE: $($matches -join ',')] $relName"
                $excludecount++ 
            }
        }

        if ($continue) {

            Write-Host "$countpad of $numfiles $($FileLength.tostring().padleft(15)) $relName"
            $hashcount++
            $filehash = (Get-FileHash -LiteralPath $fileinfo.FullName -Algorithm $algo).Hash
            If ($filehash -eq $null) { $filehash = "0"*$algonum; $LastWriteTime = "$LastWriteTime`*"; $nohash = $nohash + "`n$relName`n" }
            $hashlist = @{
                Hash = $FileHash
                File = $relName
                Size = $FileLength
                Date = $LastWriteTime
            }
            
            $totalhashbytes += $FileLength
            $hashlist | Select-Object Hash,File,Size,Date | ConvertTo-Csv -NoTypeInformation -UseQuotes AsNeeded | Select-Object -Skip 1 | Out-File -FilePath $checksumlog -Append
        }
    }
    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()

    # output to history log
    Write-Output "**** $(Get-Date) POWERHASH $algo '$checksumlog' created from '$checksumpath'" | Out-File -Encoding utf8 -FilePath "$historylog"
    Write-Output " FOLDER EXCLUSIONS: $excludeFolderString" | Out-File -Encoding UTF8 -Append -FilePath "$historylog"
    Write-Output "   FILE EXCLUSIONS: $excludeFileString" | Out-File -Encoding UTF8 -Append -FilePath "$historylog"
    Write-Output "   Files in Folder: $numfiles  Size: $filesize ($([int64]($filesize/1MB)) MB)" | Out-File -Encoding UTF8 -Append -FilePath "$historylog"
    Write-Output "    Files Excluded: $excludecount" | Out-File -Encoding UTF8 -Append -FilePath "$historylog"
    Write-Output "Total Files Hashed: $hashcount  Size: $totalhashbytes ($([int64]($totalhashbytes/1MB)) MB)" | Out-File -Encoding UTF8 -Append -FilePath "$historylog"

    Write-Output "Hashing $filesize MB $numfiles files in $SecondsElapsed seconds" >> $timelog

    # output to hash log
    $checksumhashes = Get-Content $checksumlog
    Write-Output "=POWERHASH $algo= v$ver $(Get-Date) '$checksumpath' Files: $hashcount Size: $totalhashbytes ($([int64]($totalhashbytes/1MB)) MB)" | Out-File -FilePath "$checksumlog" -Force
    Write-Output "=EXCLUDE FOLDERS= $excludeFolderString" | Out-File -FilePath "$checksumlog" -Append
    Write-Output "=EXCLUDE FILES= $excludeFileString" | Out-File -FilePath "$checksumlog" -Append
    $checksumhashes | Out-File -FilePath "$checksumlog" -Append

    if ($nohash -ne $null) { 
        Write-Host ""
        Write-Host "****************************************************************************************************"
        Write-Host "**** The following files were not able to hash (probably busy/open)."
        Write-Host "**** Recommend running '[U]pdate File Hash' option when files are not busy."
        Write-Host "**** These will have a hash with all zeroes and a * at end of date/time stamp in the log."
        Write-Host "**** These files are stored in log '$historylog'."
        Write-Output "**** $(Get-Date) The following files were not able to hash (probably busy/open):" | Out-File -Encoding utf8 -Append -FilePath "$historylog"
        Write-Host "$nohash"
        Write-Output "$nohash" | Out-File -Encoding utf8 -Append -FilePath "$historylog"
    }

    Write-Output "`n-----------------------------------------`n" | Out-File -Encoding utf8 -Append -FilePath "$historylog"

    Set-ItemProperty $checksumlog -Name IsReadOnly -Value $true

    if ($allexcluded) { $allexcludedheader + "TOTAL FILES EXCLUDED: $excludecount`n`n" + $allexcluded | Out-File -FilePath "$allexcludelog" }
    
    Write-Host ""
    Write-Host "**** $(Get-Date) Complete"
    Write-Host ""
    Write-Host "**** Files in Folder: $numfiles Size: $filesize MB Seconds: $SecondsElapsed"
    Write-Host "**** Files Excluded: $excludecount"
    Write-Host "**** Total Files Hashed: $hashcount Size: $([int]($totalhashbytes/1MB)) MB"
    Write-Host ""
    Write-Host "**** Log file saved: '$checksumlog'"
    Write-Host ""
    if (!$countTrue) { Read-Host "Press ANY KEY to Continue..." }
    
}


function CompareHash {
    
    if (!$countTrue) { Clear-Host }
    
    Write-Host ""
    Write-Host "**** COMPARE LOG FILES ****"
    Write-Host ""
    Write-Host ""
    
    if (!$countTrue) { $script:isph = $false }

    # request log 1
    while (!(( Test-Path -LiteralPath $checksumlog1 -PathType Leaf) -and $script:isph )) { 
        $checksumlog1 = Read-Host -Prompt "Log File 1"; $checksumlog1=$checksumlog1 -replace '\"',''
        if ( $checksumlog1 -eq "q" ) { return }
        if ( $checksumlog1 -eq "") { $checksumlog1="?" } 
        if (Test-Path -LiteralPath $checksumlog1 -PathType Leaf) { 
            $phcheck = $checksumlog1
            checkifphash
        }
    }

    $checksumlog1_base = $(split-path $checksumlog1 -leaf)

    Write-Host "$(Get-Content $checksumlog1 -Encoding utf8 | select -First 1)"
    Write-Host ""
    Write-Host "Number of entries in '$checksumlog1_base': ... CALCULATING ..." -NoNewLine

    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    $log1lines = (Get-Content $checksumlog1).Length-3

    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    
    Write-Host "`rNumber of entries in '$checksumlog1_base': $log1lines lines ($SecondsElapsed seconds)"

    $excludeFolder1String = (((Get-Content "$checksumlog1" | Select-Object -Skip 1 -First 1) -Split '\=')[2]).Trim()
    $excludeFile1String = (((Get-Content "$checksumlog1" | Select-Object -Skip 2 -First 1) -Split '\=')[2]).Trim()

    Write-Host "FOLDER EXCLUSIONS: $excludeFolder1String"
    Write-Host "  FILE EXCLUSIONS: $excludeFile1String"
    
    if (!$countTrue) { $script:isph = $false }

    Write-Host ""

    # request log 2
    while (!(( Test-Path -LiteralPath $checksumlog2 -PathType Leaf) -and $script:isph )) {
        $checksumlog2 = Read-Host -Prompt "Log File 2"
        $checksumlog2=$checksumlog2 -replace '\"',''
        if ( $checksumlog2 -eq "q" ) { return }
        if ( $checksumlog2 -eq "") { $checksumlog2="?" } 
        if (Test-Path -LiteralPath $checksumlog2 -PathType Leaf) { 
            $phcheck = $checksumlog2
            checkifphash
        }
    }

    $checksumlog2_base = $(split-path $checksumlog2 -leaf)

    Write-Host "$(Get-content $checksumlog2 -Encoding utf8| select -First 1)"
    Write-Host ""
    Write-Host "Number of entries in '$checksumlog2_base': ... CALCULATING ..." -NoNewLine

    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    $log2lines = (Get-Content $checksumlog2).Length-3

    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()

    Write-Host "`rNumber of entries in '$checksumlog2_base': $log2lines lines ($SecondsElapsed seconds)"

    $excludeFolder2String = (((Get-Content "$checksumlog2" | Select-Object -Skip 1 -First 1) -Split '\=')[2]).Trim()
    $excludeFile2String = (((Get-Content "$checksumlog2" | Select-Object -Skip 2 -First 1) -Split '\=')[2]).Trim()

    Write-Host "FOLDER EXCLUSIONS: $excludeFolder2String"
    Write-Host "  FILE EXCLUSIONS: $excludeFile2String"
    Write-Host ""

    Write-Host ""
    if (!$CountTrue) { DO { $yn = Read-Host "Continue? [y/n]"; if ($yn -eq 'n') { return }} while ( $yn -ne 'y' ) }

    Write-Output "" >> $timelog
    Write-Output "$(Get-Date) Comparing '$checksumlog1_base' $log1lines lines with '$checksumlog2_base' $log2lines lines" >> $timelog
    
    Write-Host ""

    # create log name path
    $lognameinfo1 = "$((Get-Item $checksumlog1).DirectoryName)\$((get-item $checksumlog1).BaseName)"
    $lognameinfo2 = "$((Get-Item $checksumlog2).DirectoryName)\$((get-item $checksumlog2).BaseName)"

    $hclog = "$lognameinfo1`_compare.log"
    $hclog2 = "$lognameinfo2`_compare.log"

    $historylog1 = "$lognameinfo1`_history.log"
    $historylog2 = "$lognameinfo2`_history.log"
    
    $matchfile_diffhash = $null
    $groupdiff = $null
    $fileprev = $null

    Write-Host "**** START: $(Get-Date)"
    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    Write-Host "Capturing Content from '$checksumlog1_base': " -NoNewline
    $checksumlog1Content = Get-Content $checksumlog1 -Encoding UTF8 | Select -skip 3
    
    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Output "Getting content '$checksumlog1_base' $SecondsElapsed seconds" >> $timelog
    Write-Host "Complete ($SecondsElapsed seconds)"

    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    Write-Host "Capturing Content from '$checksumlog2_base': " -NoNewline

    $checksumlog2Content = Get-Content $checksumlog2 -Encoding UTF8 | Select -skip 3
    
    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Output "Getting content '$checksumlog2_base' $SecondsElapsed seconds" >> $timelog
    Write-Host "Complete ($SecondsElapsed seconds)"

    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    # process hashlogs to array
    $pct = 0
    $count = 0 
    $checksumlog1Objects = $checksumlog1content | ConvertFrom-Csv -Header Hash,File,Size,Date | ForEach-Object {
        $pct = [int](($count/$log1lines)*100)
        $count++
        Write-Host -NoNewLine "`rProcessing '$checksumlog1_base': $pct% Complete"
        $_
    }

    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Host " ($SecondsElapsed seconds)"
    Write-Output "Converting '$checksumlog1_base' to Object $SecondsElapsed seconds" >> $timelog

    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    $pct = 0
    $count = 0 
    $checksumlog2Objects = $checksumlog2content | ConvertFrom-Csv -Header Hash,File,Size,Date | ForEach-Object {
        $pct = [int](($count/$log2lines)*100)
        $count++
        Write-Host -NoNewLine "`rProcessing '$checksumlog1_base': $pct% Complete"
        $_
    }
  
    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Host " ($SecondsElapsed seconds)"
    Write-Output "Converting '$checksumlog2_base' to Object $SecondsElapsed seconds" >> $timelog

    Write-Host "Comparing '$checksumlog1_base' with '$checksumlog2_base'..."
    
    $StopWatch=[system.diagnostics.stopwatch]::startnew()
    $counteq = 0
    $countdiff = 0
    $CompareLog1Log2Obj = Compare-Object $checksumlog1Objects $checksumlog2Objects -Property Hash,File,Size,Date -IncludeEqual -PassThru | ForEach-Object { 
        if ($_.SideIndicator -eq "==" ) { $counteq++ } 
        if ($_.SideIndicator -eq "<=" -or $_.SideIndicator -eq "=>") { $countdiff++ }
        Write-Host "`r Matches: $counteq NonMatches: $countdiff" -NoNewLine
        $_
    }

    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Output "Comparing Logs $SecondsElapsed seconds" >> $timelog

    $nonMatchLogObj = $CompareLog1Log2Obj | Where-Object SideIndicator -ne '=='
    $nonMatchLog1Obj = $CompareLog1Log2Obj | Where-Object SideIndicator -eq '<='
    $nonMatchLog2Obj = $CompareLog1Log2Obj | Where-Object SideIndicator -eq '=>'

    Write-Host ""
    Write-Host "`n------------------------------------------------------------------------------`n"
    Write-Host "**** MATCHING FILE NAMES WITH DIFFERENT HASH (POSSIBLE MODIFIED OR CORRUPT - CHECK SIZE, DATE/TIME):"
    Write-Host "**** START: $(Get-Date)"


    Write-Host "Comparing '$checksumlog1_base' with '$checksumlog2_base'..."

    # set up comparison between both log files based on hash and file properties
    $counteq = 0
    $countdiff = 0
    $nonmatchhashcount = 0
    $groupdiff = Compare-Object @( $nonMatchLog1Obj | Select-Object ) @( $nonMatchLog2Obj | Select-Object ) -Property Hash,File -PassThru | Group-Object -Property File | Where-Object Count -ge 2 | ForEach-Object { $nonmatchhashcount++; Write-Host "`r Mismatches Found: $nonmatchhashcount" -NoNewline; $_ }

    $matchfile_diffhash = ForEach ($item in $groupdiff.Group) {
        if ( $item.File -ne $fileprev -and $item.File -ne "0"*$algonum ) { Write-Output "" }
        if ( $groupdiff.Hash -ne "0"*$algonum ) { Write-Output "$($item.Hash) $($item.File) $($item.Size) $($item.Date) $($item.SideIndicator)".Trim() }
        $fileprev = $item.File
    }

    Write-Host ""
    
    if ( ($groupdiff | measure-object -Character).Characters -eq 0 ) { Write-Host "NONE FOUND" }
    
    while ($false) { 
    Write-Host "`n------------------------------------------------------------------------------`n"
    Write-Host "**** FILES WITH MATCHING HASHES BUT DIFFERENT FILE NAME, SIZE, or DATE (POSSIBLE DUPLICATES):" 
    Write-Host "**** START: $(Get-Date)"

    # check for duplicates routine
       
    if ($duplicates) {

        $checksummatch = $null
        $fileprev = $null

        $StopWatch=[system.diagnostics.stopwatch]::startnew()

        $duplicatescount = 0
        $duplicatefilescount = 0
        Write-Host "`rMatches Found: $duplicatescount" -NoNewline
        $checksummatch = $CompareLog1Log2Obj | Group-Object -Property Hash | Where-Object Count -ge 2 | ForEach-Object { $duplicatescount++; Write-Host "`r Matches Found: $duplicatescount" -NoNewline; $_ }
        
        $matchhash_difffile = ForEach ($item in $checksummatch.Group) {
            if ($item.Hash -ne $fileprev -and $item.Hash -ne "0"*$algonum ) { Write-Output "" }
            if ($item.Hash -ne "0"*$algonum ) { Write-Output "$($item.Hash) $($item.File) $($item.Size) $($item.Date) $($item.SideIndicator)".Trim() }
            $duplicatefilescount++
            $fileprev = $item.Hash
        }

        $matchhashfilescount = ($matchhash_difffile | Measure-Object).Count
        
        $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
        $StopWatch.Stop()
        Write-Host " ($SecondsElapsed seconds)"
        Write-Output "Finding Duplicates $SecondsElapsed seconds" >> $timelog
    
        if ( ($checksummatch | measure-object -Character).Characters -eq 0 ) { Write-Host "`nNONE FOUND" }
    }

    if (!$duplicates) { Write-Host "`n USER OPTED NOT TO CHECK" }

    }

    Write-Host "`n------------------------------------------------------------------------------`n"
    Write-Host "**** FILES WITH MATCHING HASHES AND FILENAMES WITH DIFFERENT FILE SIZE OR DATE TIME STAMP:"
    Write-Host "**** START: $(Get-Date)"
    
    $chkfilecount = 0
    $checksumfilesamediff  = $CompareLog1Log2Obj | Group-Object -Property Hash,File | Where-Object Count -ge 2 | ForEach-Object { $chkfilecount++; Write-Host "`r Matches Found: $chkfilecount" -NoNewline; $_ }

    $fileprev = $null
    $checksumfilesame = ForEach ($item in $checksumfilesamediff.Group) {
        if ($item.File -ne $fileprev -and $item.Hash -ne "0"*$algonum ) { Write-Output "" }
        if ($item.Hash -ne "0"*$algonum ) { Write-Output "$($item.hash) $($item.file) $($item.size) $($item.date) $($item.SideIndicator)".Trim() }
        $fileprev = $item.File
    }

    Write-Host ""
    if ( ($checksumfilesame | measure-object -Character).Characters -eq 0) { Write-Host "NONE FOUND" }

    Write-Host "`n------------------------------------------------------------------------------`n"

    $uniquecount = 0
    Write-Host "Determining Unique Files to each log file ..."
    $uniquediff = Compare-Object @( $nonMatchLog1Obj | Select-Object ) @( $nonMatchLog2Obj | Select-Object ) -Property File -PassThru | ForEach-Object { $uniquecount++; Write-Host "`r Matches Found: $uniquecount" -NoNewline; $_ }
    
    Write-Host ""
    Write-Host "`n**** FILES UNIQUE TO '$checksumLog1_BASE':"

    $uniqueto1count = 0
    $uniqueto1 = $uniquediff | Where-Object { $_.SideIndicator -eq '<=' } | ForEach-object { $uniqueto1count++; Write-Output "$($_.Hash) $($_.File) $($_.Size) $($_.Date)" }

    Write-Output "" | Out-File -FilePath "$hclog" -Append
    Write-Host " Files Found: $uniqueto1count"
    Write-Host ""
    
    Write-Host "**** FILES UNIQUE TO '$checksumLOG2_BASE':"
    
    $uniqueto2count = 0
    $uniqueto2 = $uniquediff | Where-Object { $_.SideIndicator -eq '=>' } | ForEach-object { $uniqueto2count++; Write-Output "$($_.Hash) $($_.File) $($_.Size) $($_.Date)" }

    Write-Host " Files Found: $uniqueto2count"

    Write-Host "`n------------------------------------------------------------------------------`n"
    Write-Host "Determining potential renamed files..."

    $matchcount = 0
    $RenamedFileObjHash = @()
    $RenamedFile = $null

    $RenamedFileObjHash = Compare-Object @( $nonMatchLog1Obj | Select-Object ) @( $nonMatchLog2Obj | Select-Object ) -Property Hash,File,Size,Date -IncludeEqual -PassThru #| Group-Object Hash

    $renamedfilecount = 0
    $renamedFileString = $null
    $renamedFileGroupObj = @()
    $renamedFileGroupObj = $RenamedFileObjHash | Sort-Object -Property SideIndicator | Group-Object -Property Hash,Size,Date | Where-Object Count -ge 2
    $matchcount = ($renamedFileGroupObj | Measure-Object).Count

    $hashprev = $null
    $renamedFile = forEach ($item in $renamedFileGroupObj.Group) {
       if ($item.Hash -ne $hashprev) { Write-Output "" }
        $hashprev = $item.Hash
        Write-Output "$($item.hash) $($item.file) $($item.size) $($item.date) $($item.SideIndicator)".Trim()
    }

    Write-Host "Potential Renamed Files Found: $matchcount"

    Write-Host "`n------------------------------------------------------------------------------`n"

    Write-Output "**** $($datetime) COMPARE '$(split-path $checksumlog1 -leaf) <=' ($log1lines entries) VS '$(split-path $checksumlog2 -leaf) =>' ($log2lines entries)" | Out-File -FilePath "$hclog"
    Write-Output "" | Out-File  -Append -FilePath "$hclog"
    Write-Output "SUMMARY:" | Tee-Object -Append -FilePath "$hclog"
    Write-Output " Log 1: '$(split-path $checksumlog1 -leaf)' <= with $log1lines entries" | Tee-Object  -Append -FilePath "$hclog"
    Write-Output "   Log 1 Folder Exclusions: $excludeFolder1String" | Tee-Object  -Append -FilePath "$hclog"
    Write-Output "   Log 1 File Exclusions: $excludeFile1String" | Tee-Object  -Append -FilePath "$hclog"
    Write-Output " Log 2: '$(split-path $checksumlog2 -leaf)' => with $log2lines entries" | Tee-Object  -Append -FilePath "$hclog"
    Write-Output "   Log 2 Folder Exclusions: $excludeFolder2String" | Tee-Object  -Append -FilePath "$hclog"
    Write-Output "   Log 2 File Exclusions: $excludeFile2String" | Tee-Object  -Append -FilePath "$hclog"
    Write-Output " Files Failed to Match Hash: $nonmatchhashcount" | Tee-Object  -Append -FilePath "$hclog"
    Write-Output " Matching files with Different Dates: $chkfilecount" | Tee-Object  -Append -FilePath "$hclog"
    Write-Output " Files Unique to Log 1: $uniqueto1count ('$checksumlog1_base')" | Tee-Object  -Append -FilePath "$hclog"
    Write-Output " Files Unique to Log 2: $uniqueto2count ('$checksumlog2_base')" | Tee-Object  -Append -FilePath "$hclog"
    Write-Output " Potential Renamed Files: $matchcount" | Tee-Object  -Append -FilePath "$hclog"

    Write-Output "`n------------------------------------------------------------------------------`n" | Out-File  -Append -FilePath "$hclog"

    Write-Output "**** $nonmatchhashcount MATCHING FILE NAMES WITH DIFFERENT HASH (POSSIBLE MODIFIED OR CORRUPT - CHECK SIZE, DATE/TIME):" | Out-File -Append -FilePath "$hclog"
    $matchfile_diffhash | Out-File -FilePath "$hclog" -Append
    if ( ($groupdiff | measure-object -Character).Characters -eq 0 ) { Write-Output "`nNONE FOUND" | Out-File -FilePath "$hclog" -Append }
    Write-Output "`n------------------------------------------------------------------------------`n" | Out-File -FilePath "$hclog" -Append

    Write-Output "**** $uniqueto1count FILES UNIQUE TO '$checksumLOG1_BASE':" | Out-File -FilePath "$hclog" -Append
    Write-Output "" | Out-File -FilePath "$hclog" -Append
    if ( ($uniqueto1 | measure-object -Character).Characters -eq 0) { Write-Output "NONE FOUND" | Out-File -FilePath "$hclog" -Append }
    $uniqueto1 | Out-File -FilePath "$hclog" -Append
    Write-Output "" | Out-File -FilePath "$hclog" -Append

    Write-Output "------------------------------------------------------------------------------`n" | Out-File -FilePath "$hclog" -Append

    Write-Output "**** $uniqueto2count FILES UNIQUE TO '$checksumLOG2_BASE':" | Out-File -FilePath "$hclog" -Append
    Write-Output "" | Out-File -FilePath "$hclog" -Append
    if ( ($uniqueto2 | measure-object -Character).Characters -eq 0) { Write-Output "NONE FOUND" | Out-File -FilePath "$hclog" -Append }
    $uniqueto2 | Out-File -FilePath "$hclog" -Append

    Write-Output "" | Out-File -FilePath "$hclog" -Append
    Write-Output "------------------------------------------------------------------------------`n" | Out-File -FilePath "$hclog" -Append
    Write-Output "**** $matchcount POTENTIAL FILE NAME CHANGES BASED ON EQUAL HASHES BETWEEN ABOVE UNIQUE FILES FOUND:" | Out-File -FilePath "$hclog" -Append
    if (!$RenamedFile) { Write-Output "`nNONE FOUND" | Out-File -FilePath "$hclog" -Append }
    $RenamedFile | Out-File -FilePath "$hclog" -Append

    Write-Output "`n------------------------------------------------------------------------------`n" | Out-File -FilePath "$hclog" -Append

    Write-Output "**** $chkfilecount FILES WITH SAME HASH AND FILE NAME BUT DIFFERENT SIZE AND/OR DATE:" | Out-File -FilePath "$hclog" -Append
    if ( ($checksumfilesame | measure-object -Character).Characters -eq 0) { Write-Output "`nNONE FOUND" | Out-File -FilePath "$hclog" -Append }
    $checksumfilesame | Out-File -FilePath "$hclog" -Append
    Write-Output "" | Out-File -FilePath "$hclog" -Append

    Write-Output "**** $(Get-Date) COMPARE '$checksumlog1_base' with '$checksumlog2_base'" | Out-File -Encoding UTF8 -FilePath "$historyLog1" -Append
    Write-Output "**** Detailed Results in '$hclog'" | Out-File -FilePath "$historyLog1" -Append

    Write-Output " Files Failed to Match Hash: $nonmatchhashcount" | Out-File  -Append -FilePath "$historylog1"
    Write-Output " Matching files with Different Dates: $chkfilecount" | Out-File  -Append -FilePath "$historylog1"
    Write-Output " Files Unique to Log 1: $uniqueto1count ('$checksumlog1_base')" | Out-File  -Append -FilePath "$historylog1"
    Write-Output " Files Unique to Log 2: $uniqueto2count ('$checksumlog2_base')" | Out-File  -Append -FilePath "$historylog1"
    Write-Output " Potential Renamed Files: $matchcount" | Out-File  -Append -FilePath "$historylog1"

    Write-Output "`n-----------------------------------------`n" | Out-File -FilePath "$historyLog1" -Append

    if ($hclog -ne $hclog2) { Write-Output "****$(Get-Date) COMPARE '$checksumlog1_base' with '$checksumlog2_base'" | Out-File -FilePath "$historyLog2" -Append
    Write-Output "**** Detailed Results in '$hclog2'" | Out-File -FilePath "$historyLog2" -Append

    Write-Output " Files Failed to Match Hash: $nonmatchhashcount" | Out-File  -Append -FilePath "$historylog2"
    Write-Output " Matching files with Different Dates: $chkfilecount" | Out-File  -Append -FilePath "$historylog2"
    Write-Output " Files Unique to Log 1: $uniqueto1count ('$checksumlog1_base')" | Out-File  -Append -FilePath "$historylog2"
    Write-Output " Files Unique to Log 2: $uniqueto2count ('$checksumlog2_base')" | Out-File  -Append -FilePath "$historylog2"
    Write-Output " Potential Renamed Files: $matchcount" | Out-File  -Append -FilePath "$historylog2"

    Write-Output "`n-----------------------------------------`n" | Out-File -FilePath "$historyLog2" -Append
    Copy-Item "$hclog" "$hclog2" -Force
    }

    Write-Host ""
    Write-Host "*****************************************"
    Write-Host "**** $(Get-Date) Complete"
    Write-Host ""
    Write-Host "**** Detailed Results stored in both:"
    Write-Host "'$($hclog)'"
    if ($hclog -ne $hclog2) { Write-Host "'$($hclog2)'" }
    Write-Host ""
    if (!$countTrue) { Read-Host "Press ANY KEY to Continue..." }

}


function UpdateHash {
    if (!$countTrue) { Clear-Host }

    Write-Host ""
    Write-Host "**** Update HASH LOG with Updated Files ****"
    Write-Host ""
    
    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")

    if (!$countTrue) { $script:isph = $false }
    
    while (!(( Test-Path -LiteralPath $checksumlog -PathType Leaf) -and $script:isph )) { 
        $checksumlog = Read-Host -Prompt "Hashlog to update"
        $checksumlog=$checksumlog -replace '\"',''
        if ( $checksumlog -eq "q" ) { return }
        if ( $checksumlog -eq "") { $checksumlog="?" }
        if (Test-Path -LiteralPath $checksumlog -PathType Leaf) { 
            $phcheck = $checksumlog
            checkifphash
        }
    }
    $checksumlog_base = split-path $checksumlog -leaf
    $fileheader = (Get-Content $checksumlog -Encoding utf8 -First 1)

    # get size of file in log
    $pattern = 'Size:\s+(\d+)'
    $matches = [regex]::Matches($fileheader, $pattern)
    $totalsize = [int64]($matches.Groups[1].Value)

    $loglines = (Get-Content $checksumlog).Length-3
    
    if ($update) { Write-Host "Log File header '$checksumlog_base':`n" }
    
    Write-Host "$fileheader"
    Write-Host ""
    
    while (!(Test-Path -LiteralPath $filepath -PathType Container)) { 
        $filepath = Read-Host -Prompt "Path of folder with updates"
        $filepath = ($filepath -replace '\"','').TrimEnd('\')
        if ( $filepath -eq "q" ) { return }
        if ( $filepath -eq "") { $filepath="?" }
    }

    $filepath_base = Split-Path $filepath -Leaf
    
    $lognameinfo = "$((Get-Item $checksumlog).DirectoryName)\$((get-item $checksumlog).BaseName)"
    $lognamepath = "$((Get-Item $checksumlog).DirectoryName)"
    $historylog = "$lognameinfo`_history.log"
    $updatedlog = "$lognameinfo`_updated.log"
    $allexcludelog = "$lognameinfo`_excluded.log"

    $excludeFolderString_old = (((Get-Content "$checksumlog" | Select-Object -Skip 1 -First 1) -Split '\=')[2]).Trim()
    $excludeFileString_old = (((Get-Content "$checksumlog" | Select-Object -Skip 2 -First 1) -Split '\=')[2]).Trim()

    if (!($cmdexcludefolders)) { $excludeFolderString = $excludeFolderString_old }
    if (!($cmdexcludefiles)) { $excludeFileString = $excludeFileString_old }

    if (!$excludeclear) {
        $excludeFolderString = $excludeFolderString.Trim()
        if ($excludeFolderString -ne "") {
            $excludeFolderExp = Invoke-Expression $excludeFolderString
            $excludeFolderList = @($excludeFolderExp)
            $excludeFolderList = ($excludeFolderList | ForEach-Object { [regex]::Escape($_) }) -join '|'
        }

        $excludeFileString = $ExcludeFileString.Trim()
        if ($excludeFileString -ne "") {
            $excludeFileExp = Invoke-Expression $excludeFileString
            $excludeFileList = @($excludeFileExp)
            $excludeFileList = ($excludeFileList | ForEach-Object { [regex]::Escape($_) }) -join '|'
        }
    }

    $yn = $null
    if (!$CountTrue) { DO { Write-Host ""; $yn = Read-Host "Would you like to update Exclusions ? [y/n]"; if ($yn -eq 'y') { $excludeyn = $true; break }} while ( $yn -ne 'n' ) }

    if ($excludeyn) {

        if (!$countTrue) { clear-host }
        $yn = $true
        
        Write-Host ""
        Write-Host "**** UPDATE $algo HASHES ****"
        Write-Host ""
        Write-Host "Folder to Hash: $filepath"
        if (!$countTrue) {
            Write-Host "Enter Keywords to Exclude for >> FOLDERS <<"
            Write-Host "(You will be prompted to enter FILE Exclusions after this.)"
            Write-Host "Entries should be surrounded by single quotes and comma between entries."
            Write-Host "Example: ('\data\media\Linux ISO','\bin','Logs') **NO WILDCARDS**"
            write-Host ""
        }

        while ($yn) {
            try {
                if (!$cmdexclude) {
                    #https://stackoverflow.com/questions/64730383/can-i-use-existing-variables-in-powershell-read-host
                    (New-Object -ComObject WScript.Shell).SendKeys('{ESC}' * 10 + ($excludeFolderString -replace '[+%^(){}]', '{$&}') )
                    $excludeFolderString = Read-Host "Enter FOLDER Exclusions"
                }
                $excludeFolderString = $excludeFolderString.Trim()
                if ($excludeFolderString -eq 'q') { return }
                if ($excludeFolderString -notmatch $exclusionpattern) { throw }
                if ($excludeFolderString -ne "") {
                    $excludeFolderExp = Invoke-Expression $excludeFolderString
                    $excludeFolderList = @($excludeFolderExp)
                    $excludeFolderList = ($excludeFolderList | ForEach-Object { [regex]::Escape($_) }) -join '|'
                }
            }
            catch { Write-Host "Your input does not meet criteria, please try again"; $yn = $true; continue }
            $yn = $false
        }

        if (!$countTrue) {
            Write-Host "`n------------`n"
            Write-Host "Enter Keywords to Exclude for >> FILES <<."
            Write-Host "Entries should be surrounded by single quotes and comma between entries."
            Write-Host "Example: ('Thumbs.db','.iso') **NO WILDCARDS**"
            Write-Host ""
        }

        $yn = $true
        while ($yn) {
            try {
                if (!$cmdexclude) {
                    #https://stackoverflow.com/questions/64730383/can-i-use-existing-variables-in-powershell-read-host
                    (New-Object -ComObject WScript.Shell).SendKeys('{ESC}' * 10 + ($excludeFileString -replace '[+%^(){}]', '{$&}') )
                    $excludeFileString = Read-Host "Enter FILE Exclusions"
                }
                $excludeFileString = $ExcludeFileString.Trim()
                if ($excludeFileString -eq 'q') { return }
                if ($excludeFileString -notmatch $exclusionpattern) { throw }
                if ($excludeFileString -ne "") { 
                    $excludeFileExp = Invoke-Expression $excludeFileString
                    $excludeFileList = @($excludeFileExp)
                    $excludeFileList = ($excludeFileList | ForEach-Object { [regex]::Escape($_) }) -join '|'
                }
            }
            catch { Write-Host "Your input does not meet criteria, please try again"; $yn = $true; continue }
            $yn = $false
        }
    }

    Write-Host ""
    Write-Host "           Log File to be Updated: '$checksumlog_base'"
    Write-Host "Folder to Generate Updated Hashes: '$filepath'"
    Write-Host "PREVIOUS FOLDER EXCLUSIONS: $excludeFolderString_old"
    Write-Host "     NEW FOLDER EXCLUSIONS: $excludeFolderString"
    Write-Host "  PREVIOUS FILE EXCLUSIONS: $excludeFileString_old"
    Write-Host "       NEW FILE EXCLUSIONS: $excludeFileString"
    Write-Host ""
    if (!$CountTrue) { DO { $yn = Read-Host "Continue? [y/n]"; if ($yn -eq 'n') { return }} while ( $yn -ne 'y' ) }

    Write-Output "" >> $timelog
    Write-Output "$(Get-Date) Update '$checksumlog_base' from '$filepath'" >> $timelog
    
    Write-Host "**** START: $(Get-Date)"
    Write-Host "Capturing Content from '$checksumlog_base' " -NoNewline
    Write-Host "$((Get-Content $checksumlog).Length-1) Entries"

    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    #GET LOG CONTENTS
    $checksumlogcontent = Get-Content -Path $checksumlog -Encoding UTF8 | Select -Skip 3

    $pct = 0
    $checksumlogcount = 0 
    $checksumlogObjects = $checksumlogcontent | ConvertFrom-Csv -Header Hash,File,Size,Date | ForEach-Object {
        $pct = [int](($checksumlogcount/$loglines)*100)
        $checksumlogcount++
        Write-Host -NoNewLine "`rProcessing '$checksumlog_base': $pct% Complete"
        $_
    }

    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()

    Write-Host " ($SecondsElapsed seconds)"
    Write-Output "Import $((Get-Content $checksumlog).Length-1) Entries from '$checksumlog_base' $SecondsElapsed seconds" >> $timelog
    Write-Host ""
    
    $StopWatch=[system.diagnostics.stopwatch]::startnew()
    Write-Host "Capturing Contents of '$filepath' " -NoNewLine
    $filecount = (Get-ChildItem -Path $filepath -Recurse -File).Count
    Write-Host "$filecount Files"

    #GET FOLDER CONTENTS
    $FolderContents = Get-ChildItem -Path "$filepath" -Recurse -File

    $pct = 0
    $count = 0
    $NewFileObjects = $FolderContents | ForEach-Object {
        $fileinfo = $_
        $FullName = $fileinfo.FullName -replace [regex]::Escape("$filepath"), ''
        $fileSize = $fileinfo.Length
        $fileDate = $fileinfo.LastWriteTime.ToString('yyyyMMdd_HHmmss')

        [PSCustomObject]@{
            'Hash' = $null
            'File' = $FullName
            'Size' = "$fileSize"
            'Date' = "$fileDate"
        }

        $count++
        $pct = [int](($count/$filecount)*100)
        
        Write-Host -NoNewLine "`rProcessing '$filepath': $pct% Complete"
    }
    
    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()

    Write-Output "Import $filecount File Names from '$filepath' $SecondsElapsed seconds" >> $timelog
    Write-Host " ($SecondsElapsed seconds)"
    Write-Host ""

    # COUNT AND STORE EXCLUSIONS FROM LOG CONTENTS
    $logremovedcount = 0
    $excludedlog = $null
    $sizeadd = [int64]0
    $sizeminus = [int64]0
    $count = 1
    $excludedLogRemovedObj = $checksumLogObjects | ForEach-Object {
        $fhash = $_.hash
        $filen = $_.file
        $fsize = $_.size
        $fdate = $_.date
        $FileParent = Split-Path -Path $filen -Parent
        $FileLeaf = Split-path -Path $filen -Leaf
        $skip = $false

        if ($excludeFolderString -ne "") {
            if ($FileParent -match $excludeFolderList) {
                $continue = $false
                $matches = $FileParent | Select-String -Pattern $excludeFolderList -AllMatches | ForEach-Object { $_.Matches.Value }
                $excludedlog += "$fhash $filen $fsize $fdate [$($matches -join ',')]`n"
                $logremovedcount++
                $sizeminus += $fsize
                $skip = $true
                return
            }
        }

        if ($excludeFileString -ne "" -and !$skip ) {
            if ($FileLeaf -match $excludeFileList) { 
                $continue = $false
                $matches = $FileLeaf | Select-String -Pattern $excludeFileList -AllMatches | ForEach-Object { $_.Matches.Value }
                $excludedlog += "$fhash $filen $fsize $fdate [$($matches -join ',')]`n"
                $sizeminus += $fsize
                $logremovedcount++ 
                return
            }
        }

        # store remaining content as valid
        $_
    }

    # COMPARE CHECKSUMLOG REMOVING EXCLUDED ENTRIES WITH LATEST FOLDER CONTENTS

    Write-Host "$(Get-Date) Comparing Files ..."
    
    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    $counteq = 0
    $countdiff = 0
    $comparediff = @()
    $comparediff = Compare-Object @( $excludedLogRemovedObj | Select-Object ) @( $newfileobjects | Select-Object ) -Property File,Size,Date -PassThru -IncludeEqual | ForEach-Object {
        if ($_.SideIndicator -eq "==" ) { $counteq++ }
        if ($_.SideIndicator -eq "<=" -or $_.SideIndicator -eq "=>") { $countdiff++ }
        Write-Host "`rMatches: $counteq NonMatches: $countdiff" -NoNewLine
        $_
    }

    $oldfiles = $null
    $newfiles = $null
    $newlist = $null

    $oldfiles = $comparediff | where ( {$_.SideIndicator -eq '<='} )
    $newfiles = $comparediff | where ( {$_.SideIndicator -eq '=>'} )
    $newlist = $comparediff | where ( {$_.SideIndicator -eq '=='} )

    $oldfilescount = ($oldfiles | Measure-Object).Count
    $newfilescount = ($newfiles | Measure-Object).COunt

    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()

    Write-Output "Compare Contents $SecondsElapsed seconds" >> $timelog
    
    Write-Host ""
    Write-Host "**** $oldfilescount Files deleted or changed to be removed from log '$checksumlog_base':"
    Write-Host "**** $newfilescount Possible new or changed files in '$filepath' to be hashed and appended to log '$checksumlog_base':"

    # HASH NEW FILES NOT EXCLUDED

    $nohash=$null
    
    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    Write-Host "`n**** Generating New Hashes ...`n"

    $count = 0
    $newcount = 0
    $excludecount = 0
    $allexcluded = $null
    $newhash = $newfiles | ForEach-Object {
        $continue = $true
        $skip = $false
        $count++
        $countpad = $($count.tostring().padleft($newfilescount.tostring().length))
        $fullpath = "$($filepath)$($_.File)"
        $fname = $_.file
        $fsize = $_.size
        $fdate = $_.date
        $FileParent = Split-Path -Path $fname -Parent
        $FileLeaf = Split-path -Path $fname -Leaf
        
        if ($excludeFolderString -ne "") {
            if ($FileParent -match $excludeFolderList) {
                $matches = $FileParent | Select-String -Pattern $excludeFolderList -AllMatches | ForEach-Object { $_.Matches.Value }
                $allexcluded += "$fname [PATH: $($matches -join ',')]`n"
                Write-Host "$countpad of $newfilescount ** EXCLUSION: [PATH: $($matches -join ',')] $fname"
                $excludecount++ 
                $skip = $true
                return
            }
        }

        if ($excludeFileString -ne "" -and !$skip ) {
            if ($FileLeaf -match $excludeFileList) { 
                $matches = $FileLeaf | Select-String -Pattern $excludeFileList -AllMatches | ForEach-Object { $_.Matches.Value }
                $allexcluded += "$fname [FILE: $($matches -join ',')]`n"
                Write-Host "$countpad of $newfilescount ** EXCLUSION: [FILE: $($matches -join ',')] $fname"
                $excludecount++ 
                return
            }
        }

        Write-Host "$countpad of $newfilescount $($fsize.tostring().padleft(15)) $fname"

        if ($continue) {
            $newcount++
            $checksum = (Get-FileHash -LiteralPath $fullpath -Algorithm $algo).hash
            If ($checksum -eq $null) { $checksum = "0"*$algonum; $nohash = $nohash + $fname; $fdate = "$($fdate) (busy)" }
            
            [PSCustomObject]@{
                'Hash' = $checksum
                'File' = $fname
                'Size' = $fsize
                'Date' = $fdate
            }
            
            $sizeadd += $fsize
        }
    }
        
    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Output "Generating $newfilescount Hashes $SecondsElapsed seconds" >> $timelog
    
    Write-Host "`n**** Consolidating Entries..."

    $oldfiles | ForEach-Object { $sizeminus += $_.Size }

    $totalsize = $totalsize + $sizeadd - $sizeminus

    $newHashCompareObj = Compare-Object @( $oldfiles | Select-Object ) @( $newhash | Select-Object ) -Property Hash,File,Size,Date -PassThru -IncludeEqual

    # Entries Possibly Renamed Files (Same hash)
    $renamedFileString = $null
    $renamedFileGroupObj = $newHashCompareObj | Sort-Object -Property SideIndicator | Group-Object -Property Hash,Size,Date | Where-Object Count -ge 2
    $renamedFileCount = ($renamedFileGroupObj | Measure-Object).Count
    $hashprev = $null
    $renamedFileString = forEach ($item in $renamedFileGroupObj.Group) {
       if ($item.Hash -ne $hashprev) { Write-Output "" }
        $hashprev = $item.Hash
        Write-Output "$($item.hash) $($item.file) $($item.size) $($item.date) $($item.SideIndicator)".Trim()
    }

    # Same File Name Different Size and/or Date (updated)
    $updatedFileCount = 0
    $updatedFileString = $null
    $updatedFileGroupobj = $newHashCompareObj | Sort-Object -Property SideIndicator | Group-Object -Property File | Where-Object Count -ge 2 | ForEach-Object { $updatedFileCount++; $_ }
    $fileprev = $null
    $updatedFileObj = forEach ($item in $updatedFileGroupObj.Group) {

        if ($item.File -ne $fileprev) {$updatedFileString += "`n" }
        $fileprev = $item.File
        $updatedFileString += "$($item.hash) $($item.file) $($item.size) $($item.date) $($item.SideIndicator)`n"
        [PSCustomObject]@{
            'Hash' = $item.hash
            'File' = $item.file
            'Size' = $item.size
            'Date' = $item.Date
        }
    }

    # Entries Removed from Log that no longer exist in Folder
    $removedFileCount = 0
    $removedFileString = $null
    $removedFileGroupObj = Compare-Object @( $oldfiles | Select-Object ) @( $updatedFileObj | Select-Object ) -Property Hash,File -PassThru
    $removedFileCount = ($removedFileGroupObj | Where-Object { $_.SideIndicator -eq '<=' } | Measure-Object).Count
    $removedFileString = $removedFileGroupObj | ForEach-Object { if ( $_.SideIndicator -eq '<=' ) { Write-Output "$($_.hash) $($_.file) $($_.size) $($_.date)".Trim() } }

    # New Files Hashed (not updated) New File New Hash
    $newFileCount = 0
    $newFileString = $null
    $newFileGroupObj = Compare-Object @( $newhash | Select-Object ) @( $updatedFileObj | Select-Object ) -Property Hash,File -PassThru
    $newfilecount = ($newFileGroupObj | Where-Object { $_.SideIndicator -eq '<=' } | Measure-Object).Count
    $newFileString = $newFileGroupObj | ForEach-Object { if ( $_.SideIndicator -eq '<=' ) { Write-Output "$($_.hash) $($_.file) $($_.size) $($_.date)".Trim() } }

    $newlist = $newlist + $newhash

    $newlistcount = $(($newlist | Measure-Object).Count)

    $newhash_string = $newhash | ForEach-Object { Write-Output "$($_.Hash) $($_.File) $($_.Size) $($_.Date)".Trim() }

    Write-Output "**** $(Get-Date) **** Update '$checksumlog_base <=' with files from '$filepath =>' ($($oldfilescount + $logremovedcount) Removed / $newcount Added)`n" | Out-File -Encoding utf8 -Append -FilePath "$historylog"

    Write-Output "**** $(Get-Date) **** Update '$checksumlog_base <=' with files from '$filepath =>' ($($oldfilescount + $logremovedcount) Removed / $newcount Added)`n" | Out-File -Encoding utf8 -FilePath "$updatedlog"

    Write-Output "**** SUMMARY:" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"
    Write-Output "$newfilecount NEW FILES IN '$filepath' HASHED AND APPENDED TO LOG '$checksumlog_base'" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"
    Write-Output "$updatedfilecount FILES UPDATED IN '$filepath' RE-HASHED AND APPENDED TO LOG '$checksumlog_base'" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"
    Write-Output "$removedfilecount LOG ENTRIES REMOVED THAT EXIST IN '$checksumlog_base' BUT NOT IN '$filepath'" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"
    Write-Output "$renamedFileCount POTENTIAL RENAMED OR MOVED FILES (MATCHING HASH, DIFFERENT FILE NAME) IN '$filepath' NOT IN LOG '$checksumlog_base'" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"
    Write-Output "$excludecount FILES SKIPPED HASH DUE TO USER SET EXCLUSIONS" | Out-File -Encoding Utf8 -Append -FilePath "$updatedlog"
    Write-Output "$logremovedcount ENTRIES REMOVED FROM LOG DUE TO USER SET EXCLUSIONS" | Out-File -Encoding Utf8 -Append -FilePath "$updatedlog"
    Write-Output "$totalsize ($([int64]($totalsize/1MB)) MB) TOTAL BYTES OF ALL FILES IN LOG" | Out-File -Encoding Utf8 -Append -FilePath "$updatedlog"

    if ($excludeyn) {
    Write-Output "**** Exclusions List Updated:" | Out-File -Encoding UTF8 -Append -FilePath "$historylog"
    Write-Output "FOLDER EXCLUSIONS PREVIOUS: $excludeFolderString_old" | Out-File -Encoding UTF8 -Append -FilePath "$historylog"
    Write-Output "     FOLDER EXCLUSIONS NEW: $excludeFolderString" | Out-File -Encoding UTF8 -Append -FilePath "$historylog"
    Write-Output "  FILE EXCLUSIONS PREVIOUS: $excludeFileString_old" | Out-File -Encoding UTF8 -Append -FilePath "$historylog"
    Write-Output "       FILE EXCLUSIONS NEW: $excludeFileString" | Out-File -Encoding UTF8 -Append -FilePath "$historylog"
    Write-Output "" | Out-File -Encoding UTF8 -Append -FilePath "$historylog"

    Write-Output "**** Exclusions List Updated:" | Out-File -Encoding UTF8 -Append -FilePath "$updatedlog"
    Write-Output "FOLDER EXCLUSIONS PREVIOUS: $excludeFolderString_old" | Out-File -Encoding UTF8 -Append -FilePath "$updatedlog"
    Write-Output "     FOLDER EXCLUSIONS NEW: $excludeFolderString" | Out-File -Encoding UTF8 -Append -FilePath "$updatedlog"
    Write-Output "  FILE EXCLUSIONS PREVIOUS: $excludeFileString_old" | Out-File -Encoding UTF8 -Append -FilePath "$updatedlog"
    Write-Output "       FILE EXCLUSIONS NEW: $excludeFileString" | Out-File -Encoding UTF8 -Append -FilePath "$updatedlog"
    Write-Output "`n-----------------------------------------`n" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"
    }


    if (!$excludeyn) {
    Write-Output "FOLDER EXCLUSIONS: $excludeFolderString" | Out-File -Encoding Utf8 -Append -FilePath "$updatedlog"
    Write-Output "  FILE EXCLUSIONS: $excludeFileString" | Out-File -Encoding Utf8 -Append -FilePath "$updatedlog"
    Write-Output "`n-----------------------------------------`n" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"
    }

    Write-Output "$newfilecount NEW FILES IN '$filepath' HASHED AND APPENDED TO LOG '$checksumlog_base'" | Out-File -Encoding utf8 -Append -FilePath "$historylog"
    Write-Output "$newfilecount NEW FILES IN '$filepath' HASHED AND APPENDED TO LOG '$checksumlog_base':`n" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"
    if (!$newFileString) { Write-Output "NONE FOUND" | Out-file -FilePath "$updatedlog" -Append }
    Write-Output $newfilestring | Out-file -FilePath "$updatedlog" -Append

    Write-Output "`n-----------------------------------------`n" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"

    Write-Output "$updatedfilecount FILES UPDATED IN '$filepath' RE-HASHED AND APPENDED TO LOG '$checksumlog_base'" | Out-File -Encoding utf8 -Append -FilePath "$historylog"
    Write-Output "$updatedfilecount FILES UPDATED IN '$filepath =>' RE-HASHED AND APPENDED TO LOG '$checksumlog_base <=':" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"
    if (!$updatedFileString) { Write-Output "`nNONE FOUND`n" | Out-file -FilePath "$updatedlog" -Append }
    Write-Output $updatedFileString | Out-File -Encoding UTF8 -Append -FilePath "$updatedlog"

    Write-Output "-----------------------------------------`n" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"

    Write-Output "$removedfilecount LOG ENTRIES REMOVED THAT EXIST IN '$checksumlog_base' BUT NOT IN '$filepath'" | Out-File -Encoding utf8 -Append -FilePath "$historylog"
    Write-Output "$removedfilecount LOG ENTRIES REMOVED THAT EXIST IN '$checksumlog_base' BUT NOT IN '$filepath':`n" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"
    if (!$removedFileString) { Write-Output "NONE FOUND" | Out-file -FilePath "$updatedlog" -Append }
    Write-Output $removedFileString | Out-File -Encoding UTF8 -Append -FilePath "$updatedlog"

    Write-Output "`n-----------------------------------------`n" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"

    Write-Output "$renamedFileCount POTENTIAL RENAMED OR MOVED FILES (MATCHING HASH, DIFFERENT FILE NAME) IN '$filepath' NOT IN LOG '$checksumlog_base'" | Out-File -Encoding utf8 -Append -FilePath "$historylog"
    Write-Output "$renamedFileCount POTENTIAL RENAMED OR MOVED FILES (MATCHING HASH, DIFFERENT FILE NAME) IN '$filepath =>' NOT IN LOG '$checksumlog_base <=':" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"
    if (!$renamedFileString) { Write-Output "`nNONE FOUND" | Out-file -FilePath "$updatedlog" -Append }
    Write-Output $renamedFileString | Out-file -FilePath "$updatedlog" -Append

    Write-Output "`n-----------------------------------------`n" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"
    Write-Output "$excludecount FILES SKIPPED HASH DUE TO USER SET EXCLUSIONS:" | Out-File -Encoding Utf8 -Append -FilePath "$updatedlog"
    if (!$allexcluded) { Write-Output "`nNONE FOUND" | Out-file -FilePath "$updatedlog" -Append }

    Write-Output "`n-----------------------------------------`n" | Out-File -Encoding utf8 -Append -FilePath "$updatedlog"
    Write-Output "$logremovedcount ENTRIES REMOVED FROM LOG DUE TO USER SET EXCLUSIONS:`n" | Out-File -Encoding Utf8 -Append -FilePath "$updatedlog"
    if (!$excludedlog) { Write-Output "NONE FOUND" | Out-file -FilePath "$updatedlog" -Append }
    Write-Output "`nExclusion details can be found in '$allexcludelog'" | Out-file -FilePath "$updatedlog" -Append
    
    Write-Host "`n**** SUMMARY:"
    Write-Host "$newfilecount New Files Hashed"
    Write-Host "$updatedFileCount Entries Updated (newer date) and Hashed '$filepath'"
    Write-Host "$removedfilecount Entries removed"
    Write-Host "$renamedfilecount Potential Renamed/Moved Files"
    Write-Host "$excludecount Files Skipped Hash due to User Set Exclusions"
    Write-Host "$logremovedcount Entries Removed from Log due to User Set Exclusions"
    Write-Output "$excludecount FILES SKIPPED HASH DUE TO USER SET EXCLUSIONS" | Out-File -Encoding Utf8 -Append -FilePath "$historylog"
    Write-Output "$logremovedcount ENTRIES REMOVED FROM LOG DUE TO USER SET EXCLUSIONS" | Out-File -Encoding Utf8 -Append -FilePath "$historylog"
    Write-Output "$totalsize ($([int64]($totalsize/1MB)) MB) NEW TOTAL BYTES OF ALL FILES IN LOG" | Out-File -Encoding Utf8 -Append -FilePath "$historylog"
    Write-Output "PREVIOUS FOLDER EXCLUSIONS: $excludeFolderString_old" | Out-File -Encoding Utf8 -Append -FilePath "$historylog"
    Write-Output "     NEW FOLDER EXCLUSIONS: $excludeFolderString" | Out-File -Encoding Utf8 -Append -FilePath "$historylog"
    Write-Output "  PREVIOUS FILE EXCLUSIONS: $excludeFileString_old" | Out-File -Encoding Utf8 -Append -FilePath "$historylog"
    Write-Output "       NEW FILE EXCLUSIONS: $excludeFileString" | Out-File -Encoding Utf8 -Append -FilePath "$historylog"


    $checksumlogprevious = "$((Get-Item $checksumlog).DirectoryName)\$((Get-Item $checksumlog).basename)_previous.log"
    Try { Remove-Item $checksumlogprevious -Force -ErrorAction Stop } catch { }
    Copy-Item "$checksumlog" "$checksumlogprevious"
    Set-ItemProperty $checksumlogprevious -Name IsReadOnly -Value $true

    Set-ItemProperty $checksumlog -Name IsReadOnly -Value $false

    Write-Output "=POWERHASH $algo= v$ver $(Get-Date) '$filepath' Files: $newlistcount Size: $totalsize ($([int64]($totalsize/1MB)) MB)" | Out-File -FilePath $checksumlog -Force
    Write-Output "=EXCLUDE FOLDERS= $excludeFolderString" | Out-File -FilePath $checksumlog -Append
    Write-Output "=EXCLUDE FILES= $excludeFileString" | Out-File -FilePath $checksumlog -Append
    $newlist = $newlist | Select-Object Hash,@{N='FolderDepth'; E={($_.File.Split('\').Count)}},File,Size,Date | Sort-Object FolderDepth,File
    $newlist = $newlist | Select-Object Hash,File,Size,Date
    $newlist | ConvertTo-Csv -NoTypeInformation -UseQuotes AsNeeded | Select-Object -Skip 1 | Out-File -FilePath $checksumlog -Append

    if ($nohash -ne $null) { 
        Write-Host ""
        Write-Host "**** The following files were not able to hash (probably busy/open)."
        Write-Host "**** Recommend running '[U]pdate File Hash' option when files are not busy"
        Write-Host "**** These will have a hash with all zeroes and a * at end of date/time stamp in the log"
        Write-Host "**** Busy files stored in log '$(split-path $historylog -leaf)'"
        Write-Output "`n**** The following files were not able to hash (probably busy/open):" | Out-File -Encoding Utf8 -Append -FilePath "$historylog"
        Write-Host "$nohash"
        Write-Output "$nohash" | Out-File -Encoding Utf8 -Append -FilePath "$historylog"
    }

    Write-Output "`n-----------------------------------------`n" | Out-File -Encoding utf8 -Append -FilePath "$historylog"
    
    Set-ItemProperty $checksumlog -Name IsReadOnly -Value $true

    $allexcluded = "UPDATED $(Get-Date) WITH UPDATE LOG FUNCTION FROM PATH '$filepath'`nFOLDER EXCLUSIONS: $excludeFolderString`nFILE EXCLUSIONS: $excludeFileString`nTOTAL FILES EXCLUDED: $excludecount`n`n" + $allexcluded
    $allexcluded | Out-File -FilePath "$allexcludelog"

    Write-Host ""
    Write-Host "**** $(Get-Date) Complete"
    Write-Host ""
    
    Write-Host "**** Log file updated: '$checksumlog_base'"
    Write-Host ""
    if (!$countTrue) { Read-Host "Press ANY KEY to Continue..." }

}


function Scrub {
    if (!$countTrue) { Clear-Host }

    $checksum = $null
    $fname = $null
    $fsize = $null
    $fdate = $null
    $sizedate = $null
    $fsizelog = $null
    $fdatelog = $null
    $fullpath = $null
    $fbusycount = 0
    $fmissingcount = 0
    $fnonmatchcount = 0
    $loglines = 0

    Write-Host ""
    Write-Host "**** SCRUB Data ****"
    Write-Host ""
    
    if (!$countTrue) { $script:isph = $false }
    
    while (!((Test-Path -LiteralPath $checksumlog -PathType Leaf) -and $script:isph )) { 
        $checksumlog = Read-Host -Prompt "Hash Log To Validate Files"
        $checksumlog = $checksumlog -replace '\"',''
        if ( $checksumlog -eq "q" ) { return }
        if ( $checksumlog -eq "") { $checksumlog="?" }
        if (Test-Path -LiteralPath $checksumlog -PathType Leaf) { 
            $phcheck = $checksumlog
            checkifphash
        }
    }

    $checksumlog_base = split-path $checksumlog -leaf
    $fileheader = (Get-Content $checksumlog -Encoding UTF8 -First 3)
    $fileheader

    $loglines = (Get-Content $checksumlog).Length-3
    write-Host ""
    
    while (!(Test-Path -LiteralPath $filepath -PathType Container)) { 
        $filepath = Read-Host -Prompt "Path of folder to scrub"
        $filepath=($filepath -replace '\"','').TrimEnd('\')
        if ( $filepath -eq "q" ) { return }
        if ( $filepath -eq "") { $filepath="?" } 
    }

    $filepath_base = "$((Get-Item $filepath).Name)"
    $pathlogbase = "$((Get-Item $checksumlog).DirectoryName)\$((get-item $checksumlog).BaseName)"
    $scrublog = "$pathlogbase`_scrub.log"
    $scrublog_base = Split-path $scrublog -leaf

    $historylog = "$pathlogbase`_history.log"
    $excludedlog = "$pathlogbase`_excluded.log"
        
    Write-Host ""
    if (!$countTrue) {
        Write-Host "During the scrub, you can hash new files found in folder: '$filepath_base'"
        Write-Host "This can indicate possible renamed files, as long as the file contents have not changed."
        Write-Host "Selecting this option WILL NOT update the main hash log file: '$checksumlog_base'"
        Write-Host "You will have to use the 'UPDATE' function to add new file hashes to the main hash log file."
        Write-Host ""
        DO { $yn = Read-Host "Hash New File Names Found in '$filepath_base'? [y/n]"; if ($yn -eq 'y') { $hashnew = $true; break } } while ($yn -ne "n")
    }

    if (!$countTrue) {
        Write-Host ""
        DO { $yn = Read-Host "Continue? [y/n]"; if ($yn -eq 'n') { return }} while ( $yn -ne 'y' )
        Write-Host ""
    }

    Write-Output "**** $(Get-Date) SCRUB '$filepath' with '$checksumlog_base'" | Out-File -FilePath "$historylog" -Append
    Write-Output "**** Detailed Results in '$scrublog'" | Out-File -FilePath "$historylog" -Append
    
    $scrubheader = "**** $(Get-Date) POWERHASH $algo SCRUB '$filepath =>' with '$checksumlog_base <=' $loglines Entries"
    Write-Output "$scrubheader`n" | Out-File -FilePath "$scrublog"

    $excludeFolderString = ""
    $excludeFileString = ""
    $excludeFolderString = (((Get-Content "$checksumlog" | Select-Object -Skip 1 -First 1) -Split '\=')[2]).Trim()
    $excludeFileString = (((Get-Content "$checksumlog" | Select-Object -Skip 2 -First 1) -Split '\=')[2]).Trim()

    $excludeFolderString = $excludeFolderString.Trim()
        if ($excludeFolderString -ne "") { 
            $excludeFolderExp = Invoke-Expression $excludeFolderString
            $excludeFolderList = @($excludeFolderExp)
            $excludeFolderList = ($excludeFolderList | ForEach-Object { [regex]::Escape($_) }) -join '|'
        }

    $excludeFileString = $ExcludeFileString.Trim()
        if ($excludeFileString -ne "") { 
            $excludeFileExp = Invoke-Expression $excludeFileString
            $excludeFileList = @($excludeFileExp)
            $excludeFileList = ($excludeFileList | ForEach-Object { [regex]::Escape($_) }) -join '|'
        }

    Write-Host ""

    Write-Host "**** START: $(Get-Date)"
    Write-Host "Gathering Contents of '$checksumlog_base' " -NoNewline
    Write-Host "$((Get-Content $checksumlog).Length-1) Entries"

    Write-Output "" >> $timelog
    Write-Output "$(Get-Date) Scrub '$filepath_base' with log '$checksumlog_base':" >> $timelog
    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    $checksumlogcontent = Get-Content -Path $checksumlog -Encoding UTF8 | Select -Skip 3

    $pct = 0
    $count = 0 
    $logfilesObj = $checksumlogcontent | ConvertFrom-Csv -Header Hash,File,Size,Date | ForEach-Object {
        $pct = [int](($count/$loglines)*100)
        $count++
        Write-Host -NoNewLine "`rProcessing '$checksumlog_base': $pct% Complete"
        $_
    }

    Write-Host " Complete!"

    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Output "Get Log Content '$checksumlog_base' $SecondsElapsed seconds" >> $timelog

    Write-Host "`nGathering Contents of '$filepath' " -NoNewline
    $filecount = (Get-ChildItem -Path $filepath -Recurse -File).Count
    Write-Host "$filecount files"

    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    $FolderContents = Get-ChildItem -Path "$filepath" -Recurse -File

    $pct = 0
    $totalfilecount = 0
    $FolderObjects = $FolderContents | ForEach-Object {
        $fileinfo = $_
        $FullName = $fileinfo.FullName -replace [regex]::Escape("$filepath"),''
        $fileSize = $fileinfo.Length
        $fileDate = $fileinfo.LastWriteTime.ToString('yyyyMMdd_HHmmss')

        [PSCustomObject]@{
            'Hash' = $null
            'File' = $FullName
            'Size' = $fileSize
            'Date' = $fileDate
        }

        $totalfilecount++
        $pct = [int](($totalfilecount/$filecount)*100)
        
        Write-Host -NoNewLine "`rProcessing '$filepath': $pct% Complete"
    }

    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Output "Get Folder Contents '$filepath_base' $SecondsElapsed seconds" >> $timelog

    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    $count = 0
    $filesmissing = $null
    $nonmatchhash = $null
    $filesbusy = $null
    $fmissingcount = 0
    $fbusycount = 0
    $fexcludedcount = 0
    $FolderScrubObj = @()
    $logUniqueObj = @()
    $FolderScrubObj = $logfilesObj | 
        ForEach-Object {
            $count++
            $valid = $true
            $checksum = $_.Hash
            $fname = $_.File
            $fsize = $_.Size
            $fdate = $_.Date
            $fullpath = "$filepath$fname"
            $allloginfo = "$checksum $fname $fsize $fdate"
            
            $countpad = $($count.tostring().padleft($loglines.tostring().length))
            Write-Host "$countpad of $loglines $fsize $fname" -NoNewline

            if ( !(Test-Path -LiteralPath $fullpath -PathType Leaf) ) { 
                Write-Host "`r$countpad of $loglines ** MISSING ** $fname"
                write-Output "`n  MISSING: $fname" | Out-File -FilePath "$scrublog" -Append
                $filesmissing += "$allloginfo`n"
                $fmissingcount++
                $filehash = "0"*$algonum
                $valid = $false

                # if calculating hashes for files unique to folder, create new array for missing files to compare later
                if ($hashnew) { $logUniqueObj += $_ }
            }
            if ( Test-Path -LiteralPath $fullpath -PathType Leaf ) {

                $fileinfo = Get-Item -LiteralPath $fullpath
                $fsizefile = $fileinfo.Length
                $fdatefile = $fileinfo.LastWriteTime.ToString('yyyyMMdd_HHmmss')

                $fsize = $fsizefile
                $fdate = $fdatefile

                    $filehash = ""
                    $filehash = (Get-FileHash -LiteralPath $fullpath -Algorithm $algo).Hash

                    If ( $filehash -eq "" ) { 
                        Write-Host "`r$countpad of $loglines ** BUSY ** $fname"
                        Write-Output "`n     BUSY: $fname" | Out-File -FilePath "$scrublog" -Append
                        $filesbusy += "$fname $fsizefile $fdatefile`n"
                        $fbusycount++
                        $filehash = "0"*$algonum
                        $checksum = $filehash
                        $valid = $false
                        #return 
                    }

                    If ( $filehash -ne $checksum ) { 
                        Write-Host "`r$countpad of $loglines ** NOTMATCH ** $fname"
                        Write-Host " FOLDER: $filehash $fname $fsizefile $fdatefile"
                        Write-Host "    LOG: $allloginfo"
                        Write-Output "`nFOLDER: $filehash $fname $fsizefile $fdatefile" | Out-File -FilePath "$scrublog" -Append
                        Write-Output "     LOG: $allloginfo"  | Out-File -FilePath "$scrublog" -Append
                        $nonmatchhash += "$allloginfo <=`n" + "$filehash $fname $fsizefile $fdatefile =>`n`n"
                        $valid = $false
                        $fnonmatchcount++
                    }

            if ($valid) { Write-Host "`r$countpad of $loglines ** OK! ** $fname" }
        }
        
        [PSCustomObject]@{
            'Hash' = $filehash
            'File' = $fname
            'Size' = $fsize
            'Date' = $fdate
        }
    }

    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Output "Comparing Hashes with Log File $SecondsElapsed seconds" >> $timelog

    Write-Host "`n`nGenerating Report..."

    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    $counteq = 0
    $countdiff = 0
    $folderExcludedCount = 0
    $extraFilesCount = 0
    $folderUniqueCount = 0

    $folderUnique = $null
    $excludedlogfiles = $null
    $folderUniqueObj = @()

    # check for files unique to folder not in log

    if ($hashnew) { Write-Host "`nHashing New Files if Found in '$filepath_base':" }
    $FolderUniqueObj = Compare-Object $folderObjects $FolderScrubObj -Property File -PassThru | ForEach-Object {
        $fileInfo = $_
        $fhash = $_.hash
        $fname = $_.file
        $fsize = $_.size
        $fdate = $_.date
        $fullpath = "$filepath$fname"

        if ($_.SideIndicator -eq "<=") { 
            $ExtraFilesCount++
            $FileParent = Split-Path -Path $fname -Parent
            $FileLeaf = Split-path -Path $fname -Leaf
            $skip = $false

            if ($excludeFolderString -ne "") {
                if ($FileParent -match $excludeFolderList) {
                    $matches = $FileParent | Select-String -Pattern $excludeFolderList -AllMatches | ForEach-Object { $_.Matches.Value }
                    $excludedlogFiles += "$fname $fsize $fdate [$($matches -join ',')]`n"
                    $FolderExcludedcount++ 
                    $skip = $true
                }
            }

            if ($excludeFileString -ne "" -and !$skip ) {
                if ($FileLeaf -match $excludeFileList) { 
                    $matches = $FileLeaf | Select-String -Pattern $excludeFileList -AllMatches | ForEach-Object { $_.Matches.Value }
                    $excludedlogFiles += "$fname $fsize $fdate [$($matches -join ',')]`n"
                    $FolderExcludedcount++ 
                    $skip = $true
                }
            }

            if (!$skip) { 
                if (!$hashnew) {
                    $folderUniqueCount++; $folderUnique += "$fname $fsize $fdate`n"
                }

                #hash new files per user request
                if ($hashnew) {
                    Write-Host "Generating $algo hash for $fname $fsize $fdate..." -NoNewline
                    $filehash = ""
                    $filehash = (Get-FileHash -LiteralPath $fullpath -Algorithm $algo).Hash
                    $folderUniqueCount++; $folderUnique += "$filehash $fname $fsize $fdate`n"
                    Write-Host "`r$filehash $fname $fsize $fdate"
                    [PSCustomObject]@{
                        'Hash' = $filehash
                        'File' = $fname
                        'Size' = $fsize
                        'Date' = $fdate
                    }
                }
            }
        }
    }

    if ($hashnew) {
        
        $matchcount = 0
        $RenamedFileObjHash = @()
        $RenamedFile = $null
        
        $RenamedFileObjHash = Compare-Object @( $logUniqueObj | Select-Object ) @( $FolderUniqueObj | Select-Object ) -Property Hash,File,Size,Date -IncludeEqual -PassThru
        
        $renamecount = 0
        $renamedFileString = $null
        $renamedFileGroupObj = @()
        $renamedFileGroupObj = $RenamedFileObjHash | Sort-Object -Property SideIndicator | Group-Object -Property Hash,Size,Date | Where-Object Count -ge 2
        $renamecount = ($renamedFileGroupObj | Measure-Object).Count
        $hashprev = $null
        $renamedFile = forEach ($item in $renamedFileGroupObj.Group) {
            if ($item.Hash -ne $hashprev) { Write-Output "" }
            $hashprev = $item.Hash
            Write-Output "$($item.hash) $($item.file) $($item.size) $($item.date) $($item.SideIndicator)".Trim()
        }

    }

    $logVsFolderDiff = Compare-Object @( $logfilesObj | Select-Object ) @( $FolderScrubObj | Select-Object ) -Property File,Size,Date -PassThru -IncludeEqual 
    
    Write-Host ""

    # Capture file with same hash,file but different size or date
    $diffSizeDateCount = 0
    $diffSizeDateObj = $logVsFolderDiff | Group-Object -Property Hash,File | Where-Object Count -ge 2 | ForEach-Object { $DiffSizeDateCount++; $_ }

    $fileprev = $null
    $diffSizeDate = $null
    $diffSizeDate = ForEach ( $item in $diffSizeDateObj.Group ) {
        if ($item.file -ne $fileprev) { Write-Output "" }
        Write-Output "$($item.hash) $($item.file) $($item.size) $($item.date) $($item.SideIndicator)".Trim()
        $fileprev = $item.file
    }

    Write-Host "`n**** Complete!`n"

    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Output "Comparing log and folder contents $SecondsElapsed seconds" >> $timelog

    $scrubsummary =  "            Total Log Entries: $loglines`n"
    $scrubsummary += "        Total Files in Folder: $totalFileCount`n"
    $scrubsummary += "   Files Failed to Match Hash: $fnonmatchcount`n"
    $scrubsummary += "    Files Missing from Folder: $fmissingcount`n"
    $scrubsummary += "          New Files in Folder: $folderUniqueCount`n"
    $scrubsummary += "Files with Mismatch size/date: $DiffSizeDateCount`n"
    $scrubsummary += "        Files Busy not hashed: $fbusycount`n"
    $scrubsummary += "       Files Excluded by User: $FolderExcludedCount`n"
    $scrubsummary += "    Potentially Renamed Files: $renamecount`n"
    $scrubsummary += "    Folder Exclusion Keywords: $excludeFolderString`n"
    $scrubsummary += "      File Exclusion Keywords: $excludeFileString`n"
    $scrubsummary += "               Hash New Files: $(if ($hashnew) { "YES" } else { "NO" } )"

    Write-Output "$scrubsummary" | Out-File -FilePath "$historylog" -Append

    Write-Host "**** SCRUB RESULTS"
    Write-Host "  Folder: $filepath"
    Write-Host "Hash Log: $checksumlog_base"
    Write-Host ""
    Write-Host "$scrubsummary"
        
    Write-Output "$scrubheader" | Out-File -FilePath "scrub.txt"
    Write-Output "`n*********************************************************************************" | Out-File -FilePath "scrub.txt" -Append
    Write-Output "$scrubsummary`n" | Out-File -FilePath "scrub.txt" -Append
    write-Output "---------------------------------------------------------------------------------" | Out-File -FilePath "scrub.txt" -Append
    Write-Output "`n**** $fnonmatchcount MATCHING FILE NAMES WITH DIFFERENT HASH (POSSIBLE MODIFIED OR CORRUPT - CHECK SIZE, DATE/TIME):`n" | Out-File -FilePath "scrub.txt" -Append
    if (!$nonmatchhash) { Write-Output "NONE FOUND`n" | Out-File -FilePath "scrub.txt" -Append }
    if ($nonmatchhash) { $nonmatchhash | Out-File -FilePath "scrub.txt" -Append }
    
    write-Output "---------------------------------------------------------------------------------" | Out-File -FilePath "scrub.txt" -Append
    Write-Output "`n**** $fmissingcount FILES UNIQUE TO '$checksumlog_base' (i.e. MISSING FROM FOLDER):`n" | Out-File -FilePath "scrub.txt" -Append
    if (!$filesmissing) { Write-Output "NONE FOUND`n" | Out-File -FilePath "scrub.txt" -Append }
    if ($filesmissing) { $filesmissing | Out-File -FilePath "scrub.txt" -Append }
        
    write-Output "---------------------------------------------------------------------------------" | Out-File -FilePath "scrub.txt" -Append
    Write-Output "`n**** $FolderUniqueCount FILES UNIQUE TO '$filepath_base' (i.e. NEW FILES IN FOLDER NOT EXCLUDED):`n" | Out-File -FilePath "scrub.txt" -Append
    if (!$folderUnique) { Write-Output "NONE FOUND`n" | Out-File -FilePath "scrub.txt" -Append }
    if ($folderUnique) { $folderUnique | Out-File -FilePath "scrub.txt" -Append }

    if ($hashnew) {
        write-Output "---------------------------------------------------------------------------------" | Out-File -FilePath "scrub.txt" -Append
        Write-Output "`n**** $renamecount POTENTIAL FILE NAME CHANGES BASED ON EQUAL HASHES BETWEEN ABOVE UNIQUE FILES FOUND:" | Out-File -FilePath "scrub.txt" -Append
        if (!$RenamedFile) { Write-Output "`nNONE FOUND" | Out-File -FilePath "scrub.txt" -Append }
        if ($RenamedFile) { $RenamedFile | Out-File -FilePath "scrub.txt" -Append }
        Write-Output "" | Out-File -FilePath "scrub.txt" -Append
    }

    write-Output "---------------------------------------------------------------------------------" | Out-File -FilePath "scrub.txt" -Append
    Write-Output "`n**** $diffSizeDateCount FILES WITH SAME HASH AND FILE NAME BUT DIFFERENT SIZE AND/OR DATE:" | Out-File -FilePath "scrub.txt" -Append
    if (!$diffSizeDate) { Write-Output "`nNONE FOUND" | Out-File -FilePath "scrub.txt" -Append }
    if ($diffSizeDate) { $diffSizeDate | Out-File -FilePath "scrub.txt" -Append }
    
    write-Output "`n---------------------------------------------------------------------------------" | Out-File -FilePath "scrub.txt" -Append
    Write-Output "`n**** $fbusycount FILES THAT WERE BUSY IN '$filepath_base' AND COULD NOT HASH:`n" | Out-File -FilePath "scrub.txt" -Append
    if (!$filesbusy) { Write-Output "NONE FOUND`n" | Out-File -FilePath "scrub.txt" -Append }
    if ($filesbusy) { $filesbusy| Out-File -FilePath "scrub.txt" -Append }

    write-Output "---------------------------------------------------------------------------------" | Out-File -FilePath "scrub.txt" -Append
    Write-Output "`n**** $FolderExcludedCount FILES WITH USER EXCLUSION AND DID NOT HASH:`n" | Out-File -FilePath "scrub.txt" -Append
    if (!$excludedLogFiles) { Write-Output "NONE FOUND`n" | Out-File -FilePath "scrub.txt" -Append }
    if ($ExcludedLogFiles) { Write-Output "Details in '$excludedlog'"| Out-File -FilePath "scrub.txt" -Append }
    Write-Output "UPDATED $(Get-Date) WITH SCRUB LOG FUNCTION FROM PATH '$filepath'`nFOLDER EXCLUSIONS: $excludeFolderString`nFILE EXCLUSIONS: $excludeFileString`nTOTAL FILES EXCLUDED: $FolderExcludedCount`n" | Out-File -FilePath "$excludedlog" -Force
    $excludedLogFiles | Out-File -FilePath "$excludedlog" -Append
    
    Write-Output "" | Out-File -FilePath "$historylog" -Append
    Write-Output "-----------------------------------------" | Out-File -FilePath "$historylog" -Append
    Write-Output "" | Out-File -FilePath "$historylog" -Append

    Remove-Item $scrublog -Force
    Move-Item "scrub.txt" $scrublog -Force

    Write-Host ""
    Write-Host "**** DETAILED RESULTS ARE SAVED TO FILE '$scrublog_base'"
    Write-Host ""
    if (!$countTrue) { Read-Host "Press ANY KEY to Continue..." }
}


function DuplicateCheck {
    if (!$countTrue) { Clear-Host }

    Write-Host ""
    Write-Host "**** DUPLICATE FILE CHECKER ****"
    Write-Host ""

    if (!$duplicates) {
        if (!$countTrue) { $script:isph = $false }
        Write-Host "Check for file duplicates based on matching file hashes."
        Write-Host ""
        $checksumlog = "?"
        while (!(( Test-Path -LiteralPath $checksumlog -PathType Leaf) -and $script:isph )) { 
            $checksumlog = Read-Host -Prompt "Log File"; $checksumlog=$checksumlog -replace '\"',''
            if ( $checksumlog -eq "q" ) { return }
            if ( $checksumlog -eq "") { $checksumlog="?" } 
            if (Test-Path -LiteralPath $checksumlog -PathType Leaf) { 
                $phcheck = $checksumlog
                checkifphash
            }
        }
    }

    $checksumlog_base = $(split-path $checksumlog -leaf)

    $lognameinfo = "$((Get-Item $checksumlog).DirectoryName)\$((get-item $checksumlog).BaseName)"
   
    $historylog = "$lognameinfo`_history.log"
    $duplicateslog = "$lognameinfo`_duplicates.log"
    $duplicateslog_base = $(split-path $duplicateslog -leaf)

    Write-Output "`n$(Get-Date) Duplicates Check '$checksumlog_base'" >> $timelog
    
    Write-Host "$(Get-Content $checksumlog -Encoding utf8 | select -First 1)"
    Write-Host ""
    Write-Host "Number of entries in '$checksumlog_base': ... CALCULATING ..." -NoNewLine

    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    $loglines = (Get-Content $checksumlog).Length-3

    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    
    Write-Host "`rNumber of entries in '$checksumlog_base': $loglines lines ($SecondsElapsed seconds)"

    $excludeFolderString = (((Get-Content "$checksumlog" | Select-Object -Skip 1 -First 1) -Split '\=')[2]).Trim()
    $excludeFileString = (((Get-Content "$checksumlog" | Select-Object -Skip 2 -First 1) -Split '\=')[2]).Trim()

    Write-Host "FOLDER EXCLUSIONS: $excludeFolderString"
    Write-Host "  FILE EXCLUSIONS: $excludeFileString"

    Write-Host ""
    Write-Host "**** START: $(Get-Date)"
    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    Write-Host "Capturing Content from '$checksumlog_base': " -NoNewline
    $checksumlogContent = Get-Content $checksumlog -Encoding UTF8 | Select -skip 3
    
    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Output "Getting content '$checksumlog_base' $SecondsElapsed seconds" >> $timelog
    Write-Host "Complete ($SecondsElapsed seconds)"
    Write-Host ""

    $StopWatch=[system.diagnostics.stopwatch]::startnew()

    # process hashlogs to array
    $pct = 0
    $count = 0 
    $checksumlogObjects = $checksumlogcontent | ConvertFrom-Csv -Header Hash,File,Size,Date | ForEach-Object {
        $pct = [int](($count/$loglines)*100)
        $count++
        Write-Host -NoNewLine "`rProcessing '$checksumlog_base': $pct% Complete"
        $_
    }

    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Host " ($SecondsElapsed seconds)"
    Write-Output "Converting '$checksumlog_base' to Object $SecondsElapsed seconds" >> $timelog

    $fileprev = $null
    $StopWatch=[system.diagnostics.stopwatch]::startnew()
    $duplicatescount = 0
    $duplicatefilescount = 0
    $duplicatesizecount = [int64]0
    $sizeone = 0
    $hashmatch = @()
    $dupecheck = $null

    Write-Host "`rMatches Found: $duplicatescount" -NoNewline
    $hashmatch = $checksumLogObjects | Group-Object -Property Hash | Where-Object Count -ge 2 | ForEach-Object { 
        $duplicatescount++
        $sizeone = [int64]((($($_.Group.Size)) -split ' ')[0])
        $duplicatesizecount = $duplicatesizecount + $sizeone
        Write-Host "`r Matches Found: $duplicatescount  Size: $duplicatesizecount" -NoNewline
        $_ 
    }

    $sizeone = 0
    $duplicatesizeallcount = [int64]0
    $dupecheck = ForEach ($item in $hashmatch.Group) {
        if ($item.Hash -ne $fileprev -and $item.Hash -ne "0"*$algonum ) { Write-Output "" }
        if ($item.Hash -ne "0"*$algonum ) { Write-Output "$($item.Hash) $($item.File) $($item.Size) $($item.Date)".Trim() }
        $duplicatefilescount++
        $sizeone = [int64]($item.size)
        $duplicatesizeallcount = $duplicatesizeallcount + $sizeone
        $fileprev = $item.Hash
    }
   
    $SecondsElapsed=$StopWatch.Elapsed.TotalSeconds
    $StopWatch.Stop()
    Write-Host " ($SecondsElapsed seconds)"
    Write-Output "Finding Duplicates $SecondsElapsed seconds" >> $timelog
   
    if ( ($hashmatch | measure-object -Character).Characters -eq 0 ) { Write-Host "`nNONE FOUND" }
    $dupeallcountMB = ([math]::Round($duplicatesizeallcount/1MB)).ToSTring().PadLeft(9)
    $dupecountMB = ([math]::Round($duplicatesizecount/1MB)).ToSTring().PadLeft(9)
    $dupecountdiffMB = ($dupeallcountMB - $dupecountMB).ToString().PadLeft(9)

    Write-Output "**** $(Get-Date) Duplicate File Check '$checksumlog'" | Out-File -FilePath "$duplicateslog" -Force
    WRite-Output "**** Exclude Folders: $excludeFolderstring" | Out-File -FilePath "$duplicateslog" -Append
    Write-Output "****   Exclude Files: $excludeFileString" | Out-File -FilePath "$duplicateslog" -Append
    Write-Output "**** $duplicatescount GROUPS WITH MATCHING HASHES ($duplicatefilescount TOTAL FILES) BUT DIFFERENT FILE NAME, SIZE, or DATE (POSSIBLE DUPLICATES):" | Out-File -FilePath "$duplicateslog" -Append
    Write-Output "**** $dupeallcountMB MB All Files" | Out-File -FilePath "$duplicateslog" -Append
    Write-Output "**** $dupecountMB MB Files if not duplicated" | Out-File -FilePath "$duplicateslog" -Append
    Write-Output "**** $dupecountdiffMB MB Difference" | Out-File -FilePath "$duplicateslog" -Append

    $dupecheck | Out-File -FilePath "$duplicateslog" -Append

    Write-Host ""
    Write-Host "** $duplicatescount GROUPS WITH MATCHING HASHES ($duplicatefilescount TOTAL FILES) BUT DIFFERENT FILE NAME, SIZE, or DATE (POSSIBLE DUPLICATES)"
    Write-Host "** $dupeallcountMB MB All Files" | Out-File -FilePath "$duplicateslog" -Append
    Write-Host "** $dupecountMB MB Files if not duplicated" | Out-File -FilePath "$duplicateslog" -Append
    Write-Host "** $dupecountdiffMB MB Difference" | Out-File -FilePath "$duplicateslog" -Append
    write-Host "** Detailed Results can be found in '$duplicateslog_base'"
    write-Host ""

    Write-Output "**** $(Get-Date) DUPLICATES CHECK '$checksumlog_base'" | Out-File -FilePath "$historylog" -Append
    Write-Output "**** Detailed Results in '$duplicateslog'" | Out-File -FilePath "$historylog" -Append
    WRite-Output "Exclude Folders: $excludeFolderstring" | Out-File -FilePath "$historylog" -Append
    Write-Output "  Exclude Files: $excludeFileString" | Out-File -FilePath "$historylog" -Append
    Write-Output "$duplicatescount GROUPS WITH MATCHING HASHES ($duplicatefilescount TOTAL FILES) BUT DIFFERENT FILE NAME, SIZE, or DATE (POSSIBLE DUPLICATES)" | Out-File -FilePath "$historylog" -Append
    Write-Output "Size of all files: $($dupeallcountMB.Trim()) MB  --  Size of Files if not duplicated: $($dupecountMB.Trim()) MB  --  Difference: $($dupecountdiffMB.Trim()) MB" | Out-File -FilePath "$historylog" -Append

    Write-Output "" | Out-File -FilePath "$historylog" -Append
    Write-Output "-----------------------------------------" | Out-File -FilePath "$historylog" -Append
    Write-Output "" | Out-File -FilePath "$historylog" -Append

    if (!$countTrue) { Read-Host "Press ANY KEY to Continue..." }
    
}


function ErrorOut {
    Write-Host "- Run without any flags for interactive mode. SHA256 by default, use -MD5 flag for MD5 hashes."
    Write-Host "- Use double quotes around `"\path\to\folder`""
    Write-Host ""
    Write-Host "Options:"
    $spacer = ""
    if ( $algo -eq "MD5" ) { $spacer = "   " }
    Write-Host " $spacer`Create New $algo Log:  -create -path `"\path\to\folder`" (-MD5 optional for MD5 hashes)"
    write-Host "   Update Existing Log:  -update -log `"\path\to\logfile.log`" -path `"\path\to\folder`""
    Write-Host "                         -ExcludeFolders -ExcludeFiles (optional with '-Create' or '-Update')"
    Write-Host "                          Use format: `"'Linux ISO','\path\to\folder','Logs','.gif'`""
    Write-Host "                         -ExcludeClear (optional with '-Update' to clear exclusions)"
    Write-Host " Scrub Folder with Log:  -scrub -log `"\path\to\logfile.log`" -path `"\path\to\folder`" -hashnew (optional)" 
    Write-Host "      Compare two Logs:  -compare -log `"\path\to\logfile.log`" -log2 `"\path\to\logfile2.log`""
    Write-Host "  Find duplicate files:  -duplicates -log `"\path\to\logfile.log`""
    Write-Host "           Other Flags:  -help, -version "
    Write-Host "                         -readme (alone for full help file or use with below for specific command help):"
    Write-Host "                         -create, -update, -compare -duplicates, -scrub, -hashnew, -exclude, -md5"
    Write-Host "                         (i.e. pwsh .\powerhash.ps1 -readme -update)"
    Write-Host ""
}


function ReadMe {

    if ($numParams -eq 1) { $create = $update = $compare = $scrub = $duplicates = $md5 = $true }

    $checksummult = 2
    if ($algo -eq "MD5") { $checksummult = 1 }
    if ($numParams -eq 1) {
        Write-Host ""
        Write-Host "**** Welcome to POWERHASH SHA256 by HTWingNut ****"
        Write-Host ""
        Write-Host "**** PLEASE USE WITH POWERSHELL 7 CORE - IT'S FREE AND EASY TO INSTALL ****"
        Write-Host "https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows"
        Write-Host "winget install --id Microsoft.Powershell --source winget"
        Write-Host "PS> pwsh .\powerhash.ps1"
        Write-Host ""
        Write-Host "**** KNOWN ISSUES:"
        Write-Host ""
        Write-Host "https://github.com/PowerShell/PowerShell/issues/20711"
        Write-Host "A bug in PowerShell 7.4.0 with the 'Group-Object' cmdlet will throw and error with filenames that"
        Write-Host "contain curly brackets '{' or '}'. This is fixed in PowerShell Preview 7.4.0.101, and should be"
        Write-Host "implemented in a future stable PowerShell release."
        Write-Host ""
        Write-Host "This was noticed during testing of PowerHash, but no provisions will be made to circumvent this"
        Write-Host "issue in the PowerHash script since it has been addressed by PowerShell itself. So if you have any"
        Write-Host "file names that contain curly brackets, please update to the PowerShell preview version until"
        Write-Host "stable release 7.4.0 is superceded, or rename your files to remove or replace the curly brackets."
        Write-Host ""
        Write-Host ""
        Write-Host "**** POWERHASH README ****"
        Write-Host ""
        Write-Host "PowerHash was designed as a simple way to generate SHA256 hashes of files in a folder recursively,"
        Write-Host "compare two sets of hashes to validate against file corruption, and update your SHA256 hash logs"
        Write-Host "with files that have been deleted or added or modified."
        Write-Host ""
        Write-Host "PowerHash can be run in interactive mode or through command line using parameters/flags. There is"
        Write-Host "output to the console as well as log/report files that contain more detail and can be read with any"
        Write-Host "text editor."
        Write-Host ""
        Write-Host "General usage:"
        
        ErrorOut
        
        Write-Host "You can run powerhash.ps1 without any flags to run the program interactive mode, or provide flags"
        Write-Host "from the command line as noted above. They both offer the same functionality."
        Write-Host ""
        Write-Host "PowerHash makes use of PowerShell's Get-FileHash cmdlet to generate hashes and Compare-Object"
        Write-Host "cmdlet for the bulk of sorting and comparisons."
        Write-Host ""
        Write-Host "While using PowerHash there will be several log files generated depending on the function used:"
        Write-Host "      MAIN LOG FILE: '$algo_[FOLDERNAME]_[DATETIMESTAMP].log' (referred to as '[hashlog].log')"
        Write-Host "   HISTORY LOG FILE: '[hashlog]_history.log'"
        Write-Host "   UPDATED LOG FILE: '[hashlog]_updated.log'"
        Write-Host "   COMPARE LOG FILE: '[hashlog]_compare.log'"
        Write-Host "     SCRUB LOG FILE: '[hashlog]_scrub.log'"
        Write-Host "DUPLIcATES LOG FILE: '[hashlog]_duplicates.log"
        Write-Host "EXCLUSIONS LOG FILE: '[hashlog]_exclusions.log'"
        Write-Host "  PREVIOUS LOG FILE: '[hashlog]_previous.log'"
        Write-Host ""
        Write-Host "Details of these are explained below. The supporting log files will be overwritten with each successive"
        Write-Host "use of that function except for history log which maintains a summary of all functions performed on the"
        Write-Host "main log file."
        Write-Host ""
        Write-Host ""
    }

    If ($create) {
        Write-Host "**** -CREATE (Called GENERATE in Interactive Menu) ****"
        Write-Host ""
        Write-Host "YOU NEED TO CREATE A HASH LOG BEFORE YOU CAN USE ANY OTHER FUNCTION."
        Write-Host ""
        Write-Host "-CREATE will calculate $algo hashes from the specified folder recursively using the -PATH flag."
        Write-Host "This process can take a while depending on the size and amount of files that you have because it"
        Write-Host "has to generate $algo hashes for every file. This requires every file in the specified folder and"
        Write-Host "subfolder to be read in full."
        Write-Host ""
        Write-Host "The -CREATE option will generate a log file named with convention:"
        Write-Host ""
        Write-Host "$algo_[folder name specified]_[datetime stamp].log"
        Write-Host ""
        Write-Host "(i.e. User specifies `"D:\Media\Movies`" would result in log '$algo_movies_20231128_154523.log')"
        Write-Host ""
        Write-Host "This will be referred to as [hashlog].log in this readme."
        Write-Host ""
        Write-Host "File contents will be set to read only. It can easily be viewed in any text editor like notepad."
        Write-Host "The log file will contain a header indicating date created, number of files, total files, and time"
        Write-Host "to calculate the hashes."
        Write-Host ""
        Write-Host "Please do not modify the hashlog file manually as it may cause any further validations to work"
        Write-Host "incorrectly."
        Write-Host ""
        Write-Host "Each line in the log file provide the following:"
        Write-Host ""
        Write-Host "[$algo Hash],[file name relative path],[file size in bytes],[file modified date]"
        Write-Host ""
        Write-Host "Example:"
        Write-Host "$("FBEDF885CD20143EC7CA30A089AE0FB0"*$checksummult),\file.ps1,23127,20231127_223817"
        Write-Host ""
        Write-Host "If a file is busy/open then a hash likely will not be able to be calculated and will be represented"
        Write-Host "as all zeros with an asterisk next to the date/time stamp."
        Write-Host ""
        Write-Host "Example:"
        Write-Host "$("00000000000000000000000000000000"*$checksummult),\hash.log,105,20231128_163159*"
        Write-Host ""
        Write-Host "The busy file names will be recorded in the '[hashlog]_history.log' file (i.e."
        Write-Host "SHA256_movies_20231128_154234_history.log). You can use the -UPDATE flag when the file is no longer"
        Write-Host "busy so its hash can be updated in the log file."
        Write-Host ""
        
        excludeHelp
        
        Write-Host "Any time a new hash log is created it will also generate a file called '[hashlogname]_history.log'"
        Write-Host "(i.e. SHA256_movies_20231128_154523_history.log) which will track all changes. You can make notes in"
        Write-Host "here if desired as it is simply a reference document."
        Write-Host ""
        Write-Host ""
    }

    if ($update) {
        Write-Host "**** -UPDATE ****"
        Write-Host ""
        Write-Host "-UPDATE will scan the path provided with -PATH flag and compare it with the file"
        Write-Host "entries in the specified hash log using the -LOG flag. It will then update the specified SHA256"
        Write-Host "hash log file with any files that may have been updated, deleted or modified based on file name,"
        Write-Host "file size, or modified date."
        Write-Host ""
        Write-Host "This process will remove entries of deleted files, and add entries of new or modified files to the"
        Write-Host "hash log."
        Write-Host ""
        Write-Host "Details of the update will be stored in the '[hashlog]_updated.log' file. It will be overwritten"
        Write-Host "with the next 'UPDATE' command issued."
        Write-Host ""
        Write-Host "You can update folder and file keyword exclusions through the update function. They must be entered"
        Write-Host "same as in the '-CREATE' section, details are repeated here for completeness:"
        Write-Host ""
        
        excludeHelp
       
        Write-Host "A summary of changes are tracked in the '[hashlog]_history.log' file."
        write-Host ""
        Write-Host ""
    }

    if ($compare) {
        Write-Host "**** -COMPARE ****"
        Write-Host "-COMPARE will compare two hash logs for discrepencies. You must provide two log files with the"
        Write-Host "-LOG and -LOG2 flags. A report file is generated with the naming convention:"
        Write-Host "$algo`_compare_[datetimestamp].log"
        Write-Host ""
        Write-Host "The report will include:"
        Write-Host " - Files with matching file names but non-matching hashes"
        Write-Host " - Files with matching hashes but different file name, size, or date (using -DUPLICATES flag)"
        Write-Host " - Files with matching hashes and file names but different size or datetime stamp (modified?)"
        Write-Host " - Files unique to log1"
        Write-Host " - Files unique to log2"
        Write-Host ""
        Write-Host "The '-COMPARE' option can be used to validate an archive of files. Or if you"
        Write-Host "transferred a lot of files from one place to another to ensure there was no corruption."
        write-Host ""
        Write-Host "For example: You can generate a list of hashes store it with your archived data, and then generate"
        Write-Host "a new hash log at a later date and use this option to compare logs to see if any hashes are"
        Write-Host "different. It will also show any files that may be unique to either file (maybe some files were"
        Write-Host "added or deleted or purposely changed over time)."
        Write-Host ""
        Write-Host "A summary of changes are tracked in the '[hashlog]_history.log' file"
        Write-Host ""
        Write-Host ""
        }
    if ($duplicates) {
        Write-Host "-DUPLICATES flag will check for files that have matching hashes but different file names."
        Write-Host "It requires the user to specify the log path\file in double quotes with the '-log' flag."
        Write-Host ""
        Write-Host "Example: pwsh .\pwsh -duplicates -log `"$algo`_MOVIES_20231231_012345`""
        Write-Host ""
        Write-Host "Detailed results will be stored in the '[hashlog]_duplicates.log' file"
        Write-Host ""
        Write-Host "A summary of changes are tracked in the '[hashlog]_history.log' file"
        Write-Host ""
        Write-Host ""
    }
    
    if ($scrub -or $hashnew) {
        Write-Host "**** -SCRUB ****"
        Write-Host ""
        Write-Host "-SCRUB will read all entries from a [hashlog.log] file identified with the -LOG flag and validate"
        Write-Host "entries that match those hashes in the path supplied by the -PATH flag. Results will be stored in"
        Write-Host "a log file named '[hashlog]_scrub.log' (i.e. SHA256_Media_20231201_113526_scrub.log)."
        Write-Host ""
        Write-Host "THE '[hashlog]_scrub.log' FILE WILL BE OVERWRITTEN when a new scrub is run."
        Write-Host ""
        Write-Host "The '[hashlog]_scrub.log' file will provide:"
        Write-Host " - Total log entries"
        Write-Host " - Total files in folder"
        Write-Host " - Files failed to match hash"
        Write-Host " - Files missing from folder"
        Write-Host " - Potential Filename Changes (use with -hashnew flag)"
        Write-Host " - Files with mismatch date/time"
        Write-Host " - New files in folder"
        Write-Host " - Files busy not hashed,"
        Write-Host " - Files excluded by user"
        Write-Host " - Folder exclusion keyword list"
        Write-Host " - File exclusion keyword list"
        Write-Host ""
        Write-Host "The '[hashlog]_excluded.log' file will be updated if any additional files exist in the folder that"
        Write-Host "was scrubbed that contains additional excluded files."
        Write-Host ""
        Write-Host "Use the -HASHNEW flag if you would like to hash files found in the folder that do not exist in the"
        Write-Host "log (ie New Files). This will only help identify potential files that have been renamed. It will not"
        Write-Host "update the '[hashlog].log' folder. Please use '-UPDATE' function to have new files added to the log."
        Write-Host ""
        Write-Host "A summary of changes are tracked in the '[hashlog]_history.log' file"
        Write-Host ""
        Write-Host ""
    }
    if ($md5) {
        Write-Host "**** -MD5 ****"
        Write-Host ""
        Write-Host "By default SHA256 hash algorithm will be used. You can add -MD5 flag to -CREATE or -COMPARE files"
        Write-Host "with MD5 hashes instead. 'pwsh .\powerhash.ps1 -MD5' will start interactive mode using MD5 hashes"
        Write-Host "instead of SHA256."
        Write-Host ""
        Write-Host "Of course you can only update and compare SHA256 log files with SHA256 log files and MD5 log files"
        Write-Host "with MD5 log files."
        Write-Host ""
    }

    if ($exclude) { excludeHelp }
}


function excludeHelp {
    Write-Host "Folders and files can be excluded by using the -EXCLUDEFOLDERS and -EXCLUDEFILES flags by"
    Write-Host "specifying keywords/phrases."
    Write-Host ""
    Write-Host "-EXCLUDEFOLDERS and -EXCLUDEFILES can only be used with '-CREATE' or '-UPDATE' commands"
    Write-Host ""
    Write-Host "-EXCLUDECLEAR can only be used with the '-UPDATE' command"
    Write-Host ""
    Write-Host "Keywords / phrases must be surrounded by single quotes separated by a comma with the entire group"
    Write-Host "surrounded by double quotes. No wildcard '*'"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "pwsh .\powerhash.ps1 -excludefolders "'\documents','Windows'" -excludefiles "'Thumbs.db','cat'""
    Write-Host ""
    Write-Host "These keywords can be updated later by using the '-UPDATE' command along with '-EXCLUDEFOLDERS'"
    Write-Host "and'-EXCLUDEFILES' flags"
    Write-Host ""
    Write-Host "'-EXCLUDECLEAR' can be used to clear all excluded folder and file entries. To clear exclusions"
    Write-Host "while using the interactive menu just choose the 'UPDATE' option and delete existing exclusions."
    Write-Host "Either operation will initiate a scan of the folder and add any previously excluded files to"
    Write-Host "[hashlog].log."
    Write-Host ""
    Write-Host "A list of excluded files will be stored in '[hashlog]_excluded.log' for reference."
    Write-Host ""
    Write-Host "THIS '[hashlog]_excluded.log' FILE WILL BE OVERWRITTEN AND UPDATED with the latest file information"
    Write-Host "any time an '-UPDATE' or '-SCRUB' command is run."
    Write-Host ""
    Write-Host "Any files matching the keywords/phrases in -EXCLUDEFOLDERS and -EXCLUDEFILES will not be hashed or"
    Write-Host "documented in the hash log, only noted in the '[hashlog]_excluded.log' file for reference."
    Write-Host ""}


While ($true) {

    $scriptpath = "$(Split-Path $MyInvocation.MyCommand.Path)"
    CD $scriptpath

    $datetime = Get-Date
    $timestamp = $datetime.ToString("yyyyMMdd_HHmmss")
    $choice=$null
    #https://www.reddit.com/r/regex/comments/18jifp9/looking_for_regex_in_powershell_for_input/
    $exclusionpattern = "^$|^(?!.*\*)'(?! +')[^']+'(,'(?! +')[^']+')*$"

    $checksumpath="?"
    $checksumlog1 = "?"
    $checksumlog2 = "?"
    $checksumlog = "?"
    $filepath = "?"
    $cmdexclude = $false
    $cmdexcludefolders = $false
    $cmdexcludefiles = $false
    $excludeFolderString = ""
    $excludeFolderExp = ""
    $excludeFolderList = ""
    $excludeFileString = ""
    $excludeFileExp = ""
    $excludeFileList = ""
    $excludeyn = $false
    $incorrect = $false
    $timelog = "_perfpwsh.log"
    $timelog = $null
    $algo = "SHA256"
    $algonum = 64
    $ver = "2024.01.18"

    if ( $md5 ) { $algo = "MD5"; $algonum = 32 }

    $numParams = $PSBoundParameters.Count
    if ($readme) {
        Write-Host ""
        ReadMe
        Write-Host ""
        exit
    }

    $countTrue = @( $create, $update, $compare, $scrub, $duplicates | Where-Object { $_ -eq $true } ).Count

    if ( $countTrue -eq 0 ) {
        if ( $args.count -ne 0 ) { Write-Host "**** INCORRECT PARAMETER"; Write-Host ""; ErrorOut; exit }
    }

    if ( $countTrue -gt 1 ) { Write-Host "**** CONFLICTING PARAMETERS"; Write-Host ""; ErrorOut; exit }

    #error handling command line

    if ($help) { ErrorOut; Exit }

    if ($excludeclear) {
        if (!$PSBoundParameters.ContainsKey('update')) {
            Write-Host "**** '-excludeclear' must be used in conjunction with '-update' option"
            Write-Host "**** Use '-help' for more command details`n"
            Exit }
        $excludeFolderString = ""
        $excludeFolderExp = ""
        $excludeFolderList = ""
        $excludeFileString = ""
        $excludeFileExp = ""
        $excludeFileList = ""
        $cmdexcludefolders = $true
        $cmdexcludefiles = $true
        $excludeyn = $true
        $cmdexclude = $true
    }

    if ($PSBoundParameters.ContainsKey('excludefolders')) { $cmdexcludefolders = $true }
    if ($excludefolders -ne "")  {
        if ($excludeclear) { Write-Host "'-excludeclear' cannot be used with '-excludefolders'"; $incorrect = $true }
        if (!$create -and !$update) { Write-Host "'-excludefolders' must be used with either '-create' or '-update'"; $incorrect=$true }
        if ($incorrect) { Write-Host "`n**** Use '-help' for more details`n"; exit }
        if ($create -or $update) {
            if ($excludefolders -notmatch $exclusionpattern) { 
                Write-Host "**** Incorrect FOLDER Exclusion entry"
                Write-Host "**** Must be in format `"'\Linux ISO','\file\path','fat cat'`" (no wildcard asterisks)"
                Write-Host "**** Use '-help' for more command details`n"
                Exit }
            $excludeFolderString = $excludefolders
            $excludeFolderString
            $cmdexclude = $true
            $excludeyn = $true
        }
    }

    if ($PSBoundParameters.ContainsKey('excludefiles')) { $cmdexcludefiles = $true }
    if ($excludefiles -ne "")  {
        if ($excludeclear) { Write-Host "'-excludeclear' cannot be used with '-excludefiles'"; $incorrect = $true }
        if (!$create -and !$update) { Write-Host "'-excludefiles' must be used with either '-create' or '-update'"; $incorrect=$true}
        if ($incorrect) { Write-Host "`n**** Use '-help' for more details`n"; exit }
        if ($create -or $update) {
            if ($excludefiles -notmatch $exclusionpattern) {
                Write-Host "**** Incorrect FILE Exclusion entry"
                Write-Host "**** Must be in format `"'file','.gif','fat cat'`" (no wildcard asterisks)"
                Write-Host "**** Use '-help' for more command details`n"
                Exit }
            $excludeFileString = $excludefiles
            $cmdexclude = $true
            $excludeyn = $true
        }
    }


    if ($create) { 
        $checksumpath = $path
        $checksumpath=($checksumpath -replace '\"','').TrimEnd('\')
        if ( $path -eq "?" ) { Write-Host "**** '-CREATE' MISSING PARAMETER -path"; $incorrect = $true }
        if ($incorrect) { Write-Host "`n**** Use '-help' for more details`n"; exit }
        if (!(Test-Path -LiteralPath $path -PathType Container)) {
            Write-Host "**** PATH DOES NOT EXIST: -path '$path'"
            Write-Host "**** Use '-help' for more command details`n"
            Exit }
        GenerateHash
        exit
    }

    if ($compare) { 
        $checksumlog1 = $log
        $checksumlog2 = $log2
        if ( $log -eq "?" ) { Write-Host "**** '-COMPARE' MISSING PARAMETER -log"; $incorrect = $true }
        if ( $log2 -eq "?" ) { Write-Host "**** '-COMPARE' MISSING PARAMETER -log2"; $incorrect = $true }
        if ($incorrect) { Write-Host "`n**** Use '-help' for more details`n"; exit }
        if (!(Test-Path -LiteralPath $log -PathType Leaf)) {
            Write-Host "**** FILE DOES NOT EXIST: -log '$log'"
            Write-Host "**** Use '-help' for more command details`n"
            Exit }

        if (!(Test-Path -LiteralPath $log2 -PathType Leaf)) {
            Write-Host "**** FILE DOES NOT EXIST: -log2 '$log2'"
            Write-Host "**** Use '-help' for more command details`n"
            Exit }
        $phcheck = $log
        checkifphash
        if ($script:isph -eq $false) { Write-Host "** ERROR ** '$log' Does not appear to be a POWERHASH log file."; Exit }
        $phcheck = $log2
        checkifphash
        if ($script:isph -eq $false) { Write-Host "** ERROR ** '$log2' Does not appear to be a POWERHASH log file."; Exit }
        $script:isph = $true
        CompareHash
        exit
    }

    if ($update) { 
        $filepath = $path
        $checksumlog = $log
        if ( $log -eq "?" ) { Write-Host "**** '-UPDATE' MISSING PARAMETER -log"; $incorrect = $true }
        if ( $path -eq "?" ) { Write-Host "**** '-UPDATE' MISSING PARAMETER -path"; $incorrect = $true }
        if ($incorrect) { Write-Host "`n**** Use '-help' for more details`n"; exit }
        if (!(Test-Path -LiteralPath $path -PathType Container)) {
            Write-Host "**** PATH DOES NOT EXIST: -path '$path'"
            Write-Host "**** Use '-help' for more command details`n"
            Exit }
        if (!(Test-Path -LiteralPath $log -PathType Leaf)) {
            Write-Host "**** FILE DOES NOT EXIST: -log '$log'"
            Write-Host "**** Use '-help' for more command details`n"
            Exit }
        $script:isph = $true
        UpdateHash
        exit
    }

    if ($scrub) { 
        $filepath = $path
        $checksumlog = $log
        if ( $log -eq "?" ) { Write-Host "**** '-SCRUB' MISSING PARAMETER -log"; $incorrect = $true }
        if ( $path -eq "?" ) { Write-Host "**** '-SCRUB' MISSING PARAMETER -path"; $incorrect = $true }
        if ($incorrect) { Write-Host "`n**** Use '-help' for more details`n"; exit }
        if (!(Test-Path -LiteralPath $path -PathType Container)) {
            Write-Host "**** PATH DOES NOT EXIST: -path '$path'"
            Write-Host "**** Use '-help' for more command details`n"
            Exit }
        if (!(Test-Path -LiteralPath $log -PathType Leaf)) {
            Write-Host "**** FILE DOES NOT EXIST: -log '$log'"
            Write-Host "**** Use '-help' for more command details`n"
            Exit }

        $phcheck = $log
        checkifphash
        if ($script:isph -eq $false) { Write-Host "** ERROR ** '$log' Does not appear to be a POWERHASH log file."; Exit }

        $script:isph = $true
        Scrub
        exit
    }

    if ($duplicates) { 
        $duplicates = $true
        if ($log -eq "?") { Write-Host "**** '-DUPLICATES' REQUIRES LOG FILE NAME SPECIFIED WITH '-log' FLag`n"; $incorrect = $true }
        if ($incorrect) { Write-Host "`n**** Use '-help' for more details`n"; exit }
        if (!(Test-Path -LiteralPath $log -PathType Leaf)) {
            Write-Host "**** FILE DOES NOT EXIST: '$log'"
            Write-Host "**** Use '-help' for more command details`n"
            Exit }

        $phcheck = $log
        checkifphash
        if ($script:isph -eq $false) { Write-Host "`n** ERROR ** '$log' Does not appear to be a POWERHASH log file.`n"; Exit }

        $script:isph = $true
        $checksumlog = $log
        DuplicateCheck
        exit
    }

    if ($hashnew) {
        $hashnew = $true
        if (!$scrub) { Write-Host "**** '-HASHNEW' REQUIRES '-SCRUB' FLAG"; $incorrect = $true }
        if ($incorrect) { Write-Host "`n**** Use '-help' for more details`n"; exit }
    }

    if ($version) { Write-Host "=POWERHASH $algo= v$ver"; Exit }
    
    #start interactive mode
    Clear-Host

    Write-Host ""
    Write-Host "=POWERHASH $algo= by HTWingNut v$ver"
    Write-Host "Type q from any menu to return here"
    Write-HOst ""

    Write-Host "Choose from the following:"
    Write-Host " [G]enerate New $algo Hash Log"
    Write-Host " [U]pdate Hash Log"
    Write-Host " [C]ompare Hash Logs"
    Write-Host " [S]crub Folder with Log"
    Write-Host " [D]uplicate File Check"
    Write-Host " [Q]uit"
    Write-Host ""

    Do { $choice = Read-Host "CHOICE" } until ($choice -in 'g','u','c','s','d','q')

    If ( $choice -eq "g" ) { GenerateHash }
    If ( $choice -eq "u" ) { UpdateHash }
    If ( $choice -eq "c" ) { CompareHash }
    If ( $choice -eq "s" ) { Scrub }
    if ( $choice -eq "d" ) { DuplicateCheck }
    If ( $choice -eq "q" ) { exit }
    
}
