# PowerHash
A PowerShell Hashing Script

<b>**** Welcome to POWERHASH SHA256 by HTWingNut ****</b>

<b>**** REQUIRES POWERSHELL 7 CORE - IT'S FREE AND EASY TO INSTALL ****</b>    
https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows  

    winget install --id Microsoft.Powershell --source winget

<b>**** KNOWN ISSUES:</b>  

https://github.com/PowerShell/PowerShell/issues/20711  
A bug in PowerShell 7.4.0 with the 'Group-Object' cmdlet will throw and error with filenames that contain curly brackets '{' or '}'. This is fixed in PowerShell Preview 7.4.0.101, and should be implemented in a future stable PowerShell release. This was noticed during testing of PowerHash, but no provisions will be made  to circumvent this issue in the PowerHash script since it has been addressed by PowerShell itself. So if you have any file names that contain curly brackets, please update to the PowerShell preview version until stable release 7.4.0 is superceded, or rename your files to remove or replace the curly brackets.


<b>**** POWERHASH README ****</b>

PowerHash was designed as a simple way to generate SHA256 hashes of files in a folder recursively, compare two sets of hashes to validate against file corruption, and update your SHA256 hash logs with files that have been deleted or added or modified.

POWERHASH can:  

- Generate SHA256 (or MD5) hashes of files in a folder recursively
- Create a Folder and File exceptions list using keywords/phrases that will omit these folders or files from the checksum operations
- Update an existing SHA256 log file with only files that have changed and/or been deleted so a full hash of all files does not need to be completed
- Scrub a folder against an existing POWERHASH log file
- Compare two hash log files for discrepencies (so you can hash two locations then scrub them based on resultant log file)
- Find duplicate files based on matching hashes

PowerHash can be run in interactive mode or through command line using parameters/flags. There is output to the console as well as log/report files that contain more detail and can be read with any text editor.

General usage:  
- Run without any flags for interactive mode. SHA256 by default, use -MD5 flag for MD5 hashes.
- Use double quotes around "\path\to\folder"

Command Line Options:  

     Create New SHA256 Log: -create -path "\path\to\folder" (-MD5 optional for MD5 hashes)
    
       Update Existing Log: -update -log "\path\to\logfile.log" -path "\path\to\folder"
    
                Exclusions: -ExcludeFolders -ExcludeFiles (optional with '-Create' or '-Update')
                             Use format: "'Linux ISO','\path\to\folder','Logs','.gif'"
                            -ExcludeClear (optional with '-Update' to clear exclusions)
    
     Scrub Folder with Log: -scrub -log "\path\to\logfile.log" -path "\path\to\folder"
    
          Compare two Logs: -compare -log "\path\to\logfile.log" -log2 "\path\to\logfile2.log"
    
           Duplicate Check: -duplicates -log "\path\to\logfile.log"
    
               Other Flags: -help -version
                            -readme alone for full help file or use with below for specific command help:
                            -create, -update, -compare -duplicates, -scrub, -exclude, -md5
                            (i.e. pwsh .\powerhash.ps1 -readme -update)

You can run powerhash.ps1 without any flags to run the program interactive mode, or provide flags from the command line as noted above. They both offer the same functionality.

PowerHash makes use of PowerShell's Get-FileHash cmdlet to generate hashes and Compare-Object cmdlet for the bulk of sorting and comparisons.

While using PowerHash there will be several log files generated depending on the function used:  

          MAIN LOG FILE: 'SHA256_[FOLDERNAME]_[DATETIMESTAMP].log' (referred to as '[hashlog].log')  
       HISTORY LOG FILE: '[hashlog]_history.log'  
       UPDATED LOG FILE: '[hashlog]_updated.log'  
       COMPARE LOG FILE: '[hashlog]_compare.log
         SCRUB LOG FILE: '[hashlog]_scrub.log'  
    DUPLICATES LOG FILE: '[hashlog]_duplicates.log'  
    EXCLUSIONS LOG FILE: '[hashlog]_exclusions.log'  
      PREVIOUS LOG FILE: '[hashlog]_previous.log'  
      

Details of these are explained below.

<b>**** -CREATE ****</b>  

YOU NEED TO CREATE A HASH LOG BEFORE YOU CAN USE ANY OTHER FUNCTION.

-CREATE will calculate SHA256 hashes from the specified folder recursively using the -PATH flag. This process can take a while depending on the size and amount of files that you have because it has to generate SHA256 hashes for every file. This requires every file in the specified folder and subfolder to be read in full.

The -CREATE option will generate a log file named with convention:

    SHA256_[folder name specified]_[datetime stamp].log

(i.e. User specifies "D:\Media\Movies" would result in log 'SHA256_movies_20231128_154523.log')

This will be referred to as [hashlog].log in this readme.

File contents will be set to read only. It can easily be viewed in any text editor like notepad. The log file will contain a header indicating date created, number of files, total files, and time to calculate the hashes.

Please do not modify '[hashlog].log' file manually as it may cause any further validations to work incorrectly.

Each line in the log file provide the following:

    [64 Character SHA256 Hash],[file name relative path],[file size in bytes],[file modified date]

Example:  

    0FBEDF885CD20143EC7CA30A089AE0FB0FBEDF885CD20143EC7CA30A089AE0FB,\file.ps1,23127,20231127_223817

If a file is busy/open then a hash likely will not be able to be calculated and will be represented as all zeros with an asterisk next to the date/time stamp.

Example:  

    0000000000000000000000000000000000000000000000000000000000000000,\hash.log,105,20231128_163159*

The busy file names will be recorded in the '[hashlogname]_history.log' file (i.e. SHA256_movies_20231128_154234_history.log). You can use the -UPDATE flag when the file is no longer busy so its hash can be updated in the log file.

Folders and files can be excluded by using the -EXCLUDEFOLDERS and -EXCLUDEFILES flags by specifying keywords/phrases.

-EXCLUDEFOLDERS and -EXCLUDEFILES can only be used with '-CREATE' or '-UPDATE' commands

-EXCLUDECLEAR can only be used with the '-UPDATE' command

Keywords / phrases must be surrounded by single quotes separated by a comma with the entire group surrounded by double quotes. No wildcard '*'

    Example: pwsh .\powerhash.ps1 -excludefolders "'\documents','Windows'" -excludefiles "'Thumbs.db','.tmp','cat'"

These keywords can be updated later by using the '-UPDATE' command along with '-EXCLUDEFOLDERS' and'-EXCLUDEFILES' flags

'-EXCLUDECLEAR' can be used to clear all excluded folder and file entries. To clear exclusions while using the interactive menu just choose the 'UPDATE' option and delete existing exclusions. Either operation will initiate a scan of the folder and add any previously excluded files to [hashlog].log.

A list of excluded files will be stored in '[hashlog]_excluded.log' for reference.

THIS '[hashlog]_excluded.log' FILE WILL BE OVERWRITTEN AND UPDATED with the latest file information any time an '-UPDATE' or '-SCRUB' command is run.

Any files matching the keywords/phrases in -EXCLUDEFOLDERS and -EXCLUDEFILES will not be hashed or documented in '[hashlog].log', only noted in the '[hashlog]_excluded.log' file for reference.

Any time a new hash log is created it will also generate a file called '[hashlogname]_history.log' (i.e. SHA256_movies_20231128_154523_history.log) which will track all changes. You can make notes in here if desired as it is simply a reference document.

<b>**** -UPDATE ****</b>  

-UPDATE will scan the path provided with -PATH flag and compare it with the file entries in the specified hash log using the -LOG flag. It will then update the specified SHA256 hash log file with any files that may have been updated, deleted or modified based on file size or modified date.

This process will remove entries of deleted files, and add entries of new or modified files to the hash log. The '[hashlog].log' header will be modified to show #Update info. The original hash log file header info will always remain to the left of #Update. Recent changes will be shown after the '#Update' portion of the header.

You can update folder and file keyword exclusions through the update function. They must be entered same as in the '-CREATE' section, details are repeated here for completeness:

Folders and files can be excluded by using the -EXCLUDEFOLDERS and -EXCLUDEFILES flags.

-EXCLUDEFOLDERS and -EXCLUDEFILES can be used with '-CREATE' or '-UPDATE' command

-EXCLUDECLEAR can only be used with the '-UPDATE' command

Keyword / phrases must be surrounded by single quotes separated by a comma with the entire group surrounded by double quotes. No wildcard '*'

Example: -excludefolders "'\documents','Windows'" -excludefiles "'Thumbs.db','.tmp','cat'"

These keywords can be updated later by using the '-UPDATE' command along with '-EXCLUDEFOLDERS' and'-EXCLUDEFILES' flags

'-EXCLUDECLEAR' can be used to clear all excluded folder and file entries and scan the folder and update the log accordingly. To clear exclusions from the interactive menu just choose the 'UPDATE' option and delete existing exclusions.

A list of excluded files will be stored in '[hashlog]_excluded.log' for reference.

THIS LOG FILE WILL BE OVERWRITTEN AND UPDATED with the latest file information any time an '-UPDATE' or '-SCRUB' command is run.

Any files matching the keywords/phrases in -EXCLUDEFOLDERS and -EXCLUDEFILES will not be hashed or documented in '[hashlog].log', only noted in the excluded log for reference.

All changes are tracked in the '[hashlog]_updated.log' file. This file will be overwritten when the next 'UPDATE' function is run.


<b>**** -COMPARE ****</b>  

-COMPARE will compare two hash logs for discrepencies. You must provide two log files with the -LOG and -LOG2 flags. A report file is generated with the naming convention: '[hashlog]_compare.log'

The report will include:  
 - Files with matching file names but non-matching hashes
 - Files with matching hashes but different file name, size, or date (using -DUPLICATES flag)
 - Files with matching hashes and file names but different size or datetime stamp (modified?)
 - Files unique to log1
 - Files unique to log2

The -COMPARE option can be used to validate an archive of files. Or if you transferred a lot of files from one place to another to ensure there was no corruption.

For example: You can generate a list of hashes, store it with your archived data, and then generate a new hash log at a later date and use this option to compare logs to see if any hashes are different. It will also show any files that may be unique to either file (maybe some files were added or deleted or purposely changed over time).


<b>**** -DUPLICATES ****</b>  

-DUPLICATES flag will check for files that have matching hashes but different file names. It requires the user to specify the log path\file in double quotes with the '-log' flag.

Example: pwsh .\pwsh -duplicates -log "SHA256_MOVIES_20231231_012345"


<b>**** -SCRUB ****</b>  

-SCRUB will read all entries from '[hashlog].log' file identified with the -LOG flag and validate entries that match those hashes in the path supplied by the -PATH flag. Results will be stored in a log file named '[hashlog]_scrub.log' (i.e. SHA256_Media_20231201_113526_scrub.log)

THE '[hashlog]_scrub.log' FILE WILL BE OVERWRITTEN when a new scrub is run.

The '[hashlog]_scrub.log' file will provide:  
 - Total log entries
 - Total files in folder
 - Files failed to match hash
 - Files missing from folder
 - Files with mismatch date/time
 - New files in folder
 - Files busy not hashed,
 - Files excluded by user
 - Folder exclusion keyword list
 - File exclusion keyword list

The '[hashlog]_excluded.log' file will be updated if any additional files exist in the folder that was scrubbed that contains additional excluded files.

You can use the -HASHNEW flag if you would like to hash files found in the folder that do not exist in the log (ie New Files). This will only help identify potential files that have been renamed. It will not update the '[hashlog].log' folder. Please use -UPDATE function to have new files added to the log.


<b>**** -MD5 ****</b>  

By default SHA256 hash algorithm will be used. You can add -MD5 flag to -CREATE or -COMPARE files with MD5 hashes instead.  
'pwsh .\powerhash.ps1 -MD5' will start interactive mode using MD5 hashes instead of SHA256.  
Of course you can only update and compare SHA256 log files with SHA256 log files and MD5 log files with MD5 log files.

