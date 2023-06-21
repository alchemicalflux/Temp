#-------------------------------------------------------------------------------
#  File:           Test.ps1 
#  Project:        AlchemicalFlux Utilities
#  Description:    Git hook for pre-commit processing of .cs file headers.
#  Copyright:      ©2023 AlchemicalFlux. All rights reserved.
#  
#  Last commit by: alchemicalflux 
#  Last commit at: 2023-06-20 18:26:56 
#-------------------------------------------------------------------------------

# Requires -Version 3.0
$ErrorActionPreference = "Stop"

# Constants
$headerStart = "#-------------------------------------------------------------------------------"
$headerEnd =   "#-------------------------------------------------------------------------------"
$currentYear = Get-Date -Format "yyyy"
$user = & git config user.name
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$filePrefix =         "File:           Test.ps1 
$projectPrefix =      "Project:        "
$descriptionPrefix =  "Description:    "
$copyrightPrefix =    "Copyright:      "
$userPrefix =         "Last commit by: alchemicalflux 
$datePrefix =         "Last commit at: 2023-06-20 18:26:56 

$projectPostfix =     "YourProjectName  # You should replace this with your project name"
$descriptionPostfix = "YourDescription  # You should replace this with your description"
$copyrightPostfix =   "YourName/YourCompany. All rights reserved.  # You should replace this with your copyright details"

# Find all .cs files and loop over them
Get-ChildItem -Recurse -Filter *.ps1 | ForEach-Object {
    $fileName = $_.Name
    $content = Get-Content $_.FullName -Raw
	
	$fileValue = "$fileName "
	$copyrightValue = "©$currentYear "
	$userValue = "$user "
	$dateValue = "$date "

    # Add the new header if it is missing
    if (-not ($content -match "$headerStart*")) {
		$fileHeader =        "$filePrefix$fileValue"
		$projectHeader =     "$projectPrefix$projectPostfix"
		$descriptionHeader = "$descriptionPrefix$descriptionPostfix"
		$copyrightHeader =   "$copyrightPrefix$copyrightValue$copyrightPostfix"
		$userHeader =        "$userPrefix$userValue"
		$dateHeader =        "$datePrefix$dateValue"
		
		$newHeader = 
@"
$headerStart
#  $fileHeader
#  $projectHeader
#  $descriptionHeader
#  $copyrightHeader
#  
#  $userHeader
#  $dateHeader
$headerEnd
"@			
		
		$content = $newHeader + $content
    }
	
	# Update the file name to match
	$content = $content -replace "(?<=$filePrefix).*", $fileValue
	
	# Update copyright if single year is out of date
	if($content -match "©(\d{4}) ") {
		$oldYear = $Matches[1]
		if($oldYear -ne $currentYear) {
			$content = $content -replace "©$oldYear ", "©$oldYear-$currentYear "
		}
	}
	
	# Update latest copyright if double-year setup is out of date
	if($content -match "©(\d{4})-(\d{4}) ") {
		$oldYear = $Matches[1]
		$newYear = $Matches[2]
		if($newYear -ne $currentYear) {
			$content = $content -replace "©$oldYear-$newYear ", "©$oldYear-$currentYear "
		}
	}	
	
	# Update the user to match the committor
	$content = $content -replace "(?<=$userPrefix).*", $userValue
	
	# Update the commit date and time
	$content = $content -replace "(?<=$datePrefix).*", $dateValue

	# Save all of the changes to the file
    Set-Content -Path $_.FullName -Value $content -NoNewLine

	# Stage the file for commit
	& git add $_.FullName
}