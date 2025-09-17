#=====================================================================
#========================== CREATING HTML ============================
#=====================================================================

# define default parameter for Convert-BookmarksJsonToHTML
$programmingDIR = "H:\Programming"

# Storage
$script:lines        = [System.Collections.Generic.List[string]]::new()
$IndentUnit          = '  '     # <- two spaces per indent level (change as you like)
$script:IndentLevel  = 0


# adds the parameter but preserves indentations
function Add-Line {
    param([string]$Text, [int]$Level = $script:IndentLevel)
    # repeat the indent unit $Level times
    $script:lines.Add(("{0}{1}" -f ($IndentUnit * [Math]::Max($Level,0)), $Text))
}


# increases indentation
function Push-Indent { 
    $script:IndentLevel++ 
}


# decreases indentation
function Pop-Indent  { 
    if ($script:IndentLevel -gt 0) { 
        $script:IndentLevel-- } 
}


# encode in HTML 
function Html(
    [string]$s) { [System.Net.WebUtility]::HtmlEncode($s) 
  }


# inputfilepath  -- the bookmarks file that is taken from %localappdata%
# outfile        -- the file that is created for importing 
function Convert-BookmarksJsonToHTML([string]$InputFilePath, [string]$OutFile = "$programmingDIR\bookmarks.html") {
    $script:lines.Clear()

    
    # getting the JSON file and converting it 
    $json = Get-Content -Raw -Path $InputFilePath | ConvertFrom-Json


    function Print-Folder([object]$folder) {
        if (-not $folder) { 
            return 
        }
        $title = ""

        # if name is declared, make sure to extract its name
        if ($folder.name) {
            $title = Html $folder.name 
        }
        else {
            $title = "Unnamed Folder" 
        }


        # create a H3 tag using the extracted name and start a hierarchy since it was a folder
        Add-Line ("<DT><H3>$title</H3>")
        Add-Line "<DL><p>"
        
        Push-Indent
        # populate the inside of the folder accordingly
        # note that Print-Link will call Print-Folder if any children is a folder 
        if ($folder.children) {
            foreach ($child in $folder.children) {
                Print-Link $child
            }
        }
        Pop-Indent

        #closes the hierarchy / folder
        Add-Line "</DL><p>"
    }


    function Print-Link([object]$link) {
        if (-not $link) { 
            return 
        }
        switch($link.type) {
            'url' {
                $href = Html $link.url
                $text = Html $link.name
                Add-Line ("<DT><A HREF=""{0}"">{1}</A></DT>" -f $href, $text)
            }
            # in case a child node is a folder, create the folder wrapper 
            'folder' {
                print-folder $link
            }
            default {
                # in case type is omitted, assume it is a folder if it has children 
                if ($link.PSObject.Properties.Name -contains 'children') {
                    Print-Folder $link
                }
            }
        }


    }
 


    # Header
    Add-Line '<!DOCTYPE NETSCAPE-Bookmark-file-1>'
    Add-Line '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">'
    Add-Line '<TITLE>Bookmarks</TITLE>'
    Add-Line '<H1>Bookmarks</H1>'
    Add-Line '<DL><p>' # Opens before elements

    $roots = $json.roots

    # do not put the bookmarks bar in a seperate folder 
    $bar = $roots.bookmark_bar
    if ($bar -and $bar.children) {
        foreach ($child in $bar.children) {
            # links appear at top level since Print-Folder is not called unless a folder had been in the bookmarks bar 
            Print-Link $child      
        }
    }

    # Other Folders should be stored as folders, as they naturally did 
    if ($roots.other)  { 
        Print-Folder $roots.other 
    }
    if ($roots.synced) { 
        Print-Folder $roots.synced 
    }

    Add-Line '</DL><p>' # Closes after elements 

    # Save and also echo to console (each element is its own line)
    $script:lines | Set-Content -Path $OutFile -Encoding UTF8

}






#=====================================================================
#====== GETTING JSON FROM %APPDATA% AND CONVERTING IT TO HTML ========
#=====================================================================

$user = $env:USERNAME


# THE ROOT DIR for this script
# modify this if do not have an H drive
# in this environment, each user has a H drive
$targetDirectory = "H:\BookmarkBackups"



# default profile paths
$userChromeBM = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Bookmarks"
$userEdgeBM = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Bookmarks"

# 
$edgeUserData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\"
$edgeProfiles = Get-ChildItem $edgeUserData -Filter "Profile*"

$chromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data\"
$chromeProfiles = Get-ChildItem $chromeUserData -Filter "Profile*"


if (!(Test-Path -Path $targetDirectory)) {
    New-Item -ItemType Directory -Path $targetDirectory | Out-Null
}


Write-Host $targetDirectory
Write-Host $userChromeBM
Write-Host $userEdgeBM

$edgeProfiles

Write-Host "" 
Write-Host "Getting Profiles"
Write-Host "" 



# copying the default chrome profile
try {
    if (Test-Path $userChromeBM) {
        Write-Host "Chrome default profile exists"
        $desktopBMDir = Join-Path -Path $targetDirectory -Childpath "$user-chromeBookmarks-default"
        $choice = Read-Host "Do you want to proceed copying '$userChromeBM' to '$desktopBMDir' ? (y/n)"
        if ($choice -eq 'y') {
            if (-not (Test-Path $desktopBMDir)) {
                New-Item -ItemType Directory -Path $desktopBMDir
            }
            Copy-Item -Path $userChromeBM -Destination $desktopBMDir
            Write-Host("=============TESTING DEST PATH===============") 
            Get-ChildItem -Path $desktopBMDir
            Convert-BookmarksJsonToHTML -InputFilePath "$desktopBMDir/Bookmarks" -OutFile "$desktopBMDir/chromeBookmarksD.html"
            Remove-Item -Path "$desktopBMDir/Bookmarks" 
            Write-Host("=============DONE TESTING DEST PATH===============") 
        }
        elseif ($choice -eq 'n') {
            Write-Host "Operation canceled."
        } else {
            Write-Host "Invalid input. Please enter 'y' or 'n'."
        }
    }
    else {
	    Write-Host "No default profile exists for Chrome"
    }
}
catch {
    Write-Host "No default profile exists for Chrome" 
}

# copying the default edge profile 
try {
    if (Test-Path $userEdgeBM) {
	    Write-Host "Edge default profile exists"
        $desktopBMDir = Join-Path -Path $targetDirectory -Childpath "$user-edgeBookmarks-default"
        $choice = Read-Host "Do you want to proceed copying '$userEdgeBM' to '$desktopBMDir' ? (y/n)"
         if ($choice -eq 'y') {
            if (-not (Test-Path $desktopBMDir)) {
                New-Item -ItemType Directory -Path $desktopBMDir
            }
            Copy-Item -Path $userEdgeBM -Destination $desktopBMDir
            Write-Host("=============TESTING DEST PATH===============") 
            Get-ChildItem -Path $desktopBMDir
            Convert-BookmarksJsonToHTML -InputFilePath "$desktopBMDir/Bookmarks" -OutFile "$desktopBMDir/edgeBookmarksD.html" 
            Remove-Item -Path "$desktopBMDir/Bookmarks" 
            Write-Host("=============DONE TESTING DEST PATH===============") 
        }
        elseif ($choice -eq 'n') {
            Write-Host "Operation canceled."
        } else {
            Write-Host "Invalid input. Please enter 'y' or 'n'."
        }
    }
    else {
	    Write-Host "No default profile exists for Edge"
    }
}
catch {
    Write-Host "No default profile exists for Edge."
}


Write-Host "" 

# Microsoft Edge Profiles if they exist 
foreach ($profile in $edgeProfiles) {
	
    # getting the bookmark locations and testing
    Write-Host $profile
	$edgeProfile = Join-Path -Path $edgeUserData -ChildPath $profile
	Write-Host "Proposed path: $edgeProfile"
	Get-ChildItem $edgeProfile

   	Write-Host ""
    $edgeProfileBM = Join-Path -Path $edgeProfile -ChildPath "Bookmarks"
    Write-Host $edgeProfileBM
    #Get-Content $edgeProfileBM


    
    $choice = Read-Host "Do you want to proceed copying '$edgeProfileBM' to '$targetDirectory' ? (y/n)"
    if ($choice -eq 'y') {
        Write-Host "Proceeding..."
        try {
            $desktopBMDir = Join-Path -Path $targetDirectory -Childpath "$user-edgeBookmarks-$profile"
            if (-not (Test-Path $desktopBMDir)) {
                New-Item -ItemType Directory -Path $desktopBMDir
            }
            Copy-Item -Path $edgeProfileBM -Destination $desktopBMDir
            Write-Host("=============TESTING DEST PATH===============") 
            Get-ChildItem -Path $desktopBMDir
            Convert-BookmarksJsonToHTML -InputFilePath "$desktopBMDir/Bookmarks" -OutFile "$desktopBMDir/edgeBookmarks$profile.html" 
            Remove-Item -Path "$desktopBMDir/Bookmarks" 
            Write-Host("=============DONE TESTING DEST PATH===============") 
        }
        catch {
            Write-Error "Not working!"
        }
    } elseif ($choice -eq 'n') {
        Write-Host "Operation canceled."
    } else {
        Write-Host "Invalid input. Please enter 'y' or 'n'."
    }

    Write-Host "" 
    Write-Host ""

}

# Google Chrome profiles if they exist 
foreach ($profile in $chromeProfiles) {
    
    # getting the bookmark locations and testing
    Write-Host $profile
    $chromeProfile = Join-Path -Path $chromeUserData -ChildPath $profile
    Write-Host "Proposed path: $chromeProfile" 
    Get-ChildItem $chromeProfile

    Write-Host ""
    $chromeProfileBM = Join-Path -Path $chromeProfile -ChildPath "Bookmarks" 
    Write-Host $chromeProfileBM
    #Get-Content $chromeProfileBM


    
    
    $choice = Read-Host "Do you want to proceed copying '$chromeProfileBM' to '$targetDirectory' ? (y/n)"
    if ($choice -eq 'y') {
        Write-Host "Proceeding..."
        try {
            $desktopBMDir = Join-Path -Path $targetDirectory -Childpath "$user-chromeBookmarks-$profile"
                if (-not (Test-Path $desktopBMDir)) {
                    New-Item -ItemType Directory -Path $desktopBMDir
                }
                Copy-Item -Path $chromeProfileBM -Destination $desktopBMDir
                Write-Host("=============TESTING DEST PATH===============") 
                Get-ChildItem -Path $desktopBMDir
                Convert-BookmarksJsonToHTML -InputFilePath "$desktopBMDir/Bookmarks" -OutFile "$desktopBMDir/chromeBookmarks$profile.html" 
                Remove-Item -Path "$desktopBMDir/Bookmarks" 
                Write-Host("=============DONE TESTING DEST PATH===============") 
            }
        catch {
            Write-Error "Not working!"
        }
    } elseif ($choice -eq 'n') {
        Write-Host "Operation canceled."
    } else {
        Write-Host "Invalid input. Please enter 'y' or 'n'."
    }

    Write-Host "" 
    Write-Host ""
}