global mainCachePath, userCachePath, userHomePath, cleanUserSize, countFileUser, cleanSizeTotalText, countFileTotal, cleanSizeTotalText, logPath

set logPath to "/tmp/clean.log"
set homeFolderPath to "/Users/" & short user name of (system info)
set paths to {"/Library/Caches", homeFolderPath & "/Library/Caches", homeFolderPath & "/.cache"}

on fnDate()
	set currentDate to current date
	set yearStr to text -4 thru -1 of ("0000" & (year of currentDate) as text)
	set monthStr to text -2 thru -1 of ("0" & (month of currentDate as integer) as text)
	set dayStr to text -2 thru -1 of ("0" & (day of currentDate as text))
	set hoursStr to text -2 thru -1 of ("0" & (hours of currentDate as text))
	set minutesStr to text -2 thru -1 of ("0" & (minutes of currentDate as text))
	set secondsStr to text -2 thru -1 of ("0" & (seconds of currentDate as text))
	return yearStr & monthStr & dayStr & hoursStr & minutesStr & secondsStr
end fnDate

on fnLog(msg)
	do shell script "echo '[" & fnDate() & "] " & msg & "' >> " & logPath
end fnLog

on fnNotif(msg)
	display notification msg with title "Cache Cleaner" sound name "default"
end fnNotif

on fnCancel()
	fnNotif("Operation canceled by user")
end fnCancel

on showInputBox(prompt, boxTitle)
	display dialog prompt default answer "" buttons {"Cancel", "OK"} default button 2 Â
		with title boxTitle with icon note
	set inputValue to text returned of result
	return inputValue
end showInputBox

try
	fnNotif("Checking, please wait...")
on error errStr number errNum
	if errNum = -128 then
		fnCancel()
		return
	else
		set err to "Error: " & errStr
		fnLog(err)
		return
	end if
end try

on fnCalcPathSize(path)
	set cleanSize to (do shell script "find " & quoted form of path & " -type f -exec stat -f '%z' {} + 2>/dev/null | awk '{ total += $0 } END { print total }'") as text
	set countFiles to (do shell script "find " & quoted form of path & " -type f | wc -l | awk '{print $1}'") as number
	return {size:cleanSize, total:countFiles}
end fnCalcPathSize

on humanSize(value)
	set numericValue to value as number

	if numericValue ³ 1.073741824E+9 then -- 1 GB or more
		set unit to "GB"
		set divisor to 1.073741824E+9
	else if numericValue ³ 1048576 then -- 1 MB or more
		set unit to "MB"
		set divisor to 1048576
	else if numericValue ³ 1024 then -- 1 KB or more
		set unit to "KB"
		set divisor to 1024
	else -- Less than 1 KB
		set unit to "B"
		set divisor to 1
	end if

	set formattedSize to (numericValue / divisor) as text
	if "," is in formattedSize then
		set decimalIndex to offset of "," in formattedSize
		set formattedSize to text 1 thru (decimalIndex + 2) of formattedSize
	end if

	return formattedSize & " " & unit
end humanSize


on fnCalc(paths)
	set cleanSize to 0
	set countFile to 0

	repeat with path in paths
		set pathSize to fnCalcPathSize(path)
		set cleanSize to cleanSize + (size of pathSize)
		set countFile to countFile + (total of pathSize)
	end repeat

	set countFileTotal to countFile
	set cleanSizeTotalText to humanSize(cleanSize)

	fnNotif("Files found: " & countFile & " (" & cleanSizeTotalText & ")")
end fnCalc

fnCalc(paths)

fnConfirmDialog("Confirm delete " & countFileTotal & " files (" & cleanSizeTotalText & ")?", paths)

on fnCleanPath(path)
	try
		do shell script "rm -rf " & path & "/*"
	on error errMsg
		set err to "Error: " & errMsg
		fnLog(err)
	end try
end fnCleanPath

on fnRun(paths)
	fnNotif("Cleaning-up, please wait...")

	tell application "Finder"
		empty the trash
	end tell

	repeat with path in paths
		fnCleanPath(path)
	end repeat

	fnNotif("Success! Claimed " & cleanSizeTotalText & " of disk space")
end fnRun

on fnConfirmDialog(txt, paths)
	try
		set ageDialog to display dialog txt buttons {"Cancel", "Yes"} default button 1 with icon caution
		set buttonResponse to button returned of ageDialog
		if buttonResponse is equal to "Yes" then
			set button returned of ageDialog to ""
			fnRun(paths)
		else
			fnCancel()
		end if
	on error errMsg number errNum
		if errNum = -128 then
			fnNotif("Operation canceled by user")
		else
			set err to "Error: " & errMsg
			fnLog(err)
		end if
	end try
end fnConfirmDialog
