on run argv
	if (count of argv) = 2 then
		set fromFile to (item 1 of argv) as POSIX file
		set exportFileName to (item 2 of argv) as POSIX file
		-- set exportDir to (item 3 of argv) as POSIX file
		set exportDir to do shell script "dirname " & quoted form of (item 2 of argv)
	else
		-- display dialog "need 2 arguments for input and output"
		error number -128
	end if

set appFile to POSIX file "/Applications/FineReader OCR Pro.app"

using terms from application "FineReader OCR Pro"
   set langList to {English, Latin}
   set saveType to same files as source
end using terms from

using terms from application "FineReader OCR Pro"
   set toFile to POSIX path of (exportFileName)
   set retainLayoutWordLayout to as editable copy
   set keepPageNumberHeadersAndFootersBoolean to yes
   set keepLineBreaksAndHyphenationBoolean to yes
   set keepPageBreaksBoolean to yes
   set pageSizePageSizeEnum to automatic
   set increasePaperSizeToFitContentBoolean to yes
   set keepImageBoolean to yes
   set imageOptionsImageQualityEnum to high quality
   set keepTextAndBackgroundColorsBoolean to yes
   set highlightUncertainSymbolsBoolean to yes
   set keepPageNumbersBoolean to yes
   set useMRCBoolean to yes
end using terms from

WaitWhileBusy()

tell application "FineReader OCR Pro"
   set hasdoc to has document
   if hasdoc then
       close document
   end if
end tell

WaitWhileBusy()

HideFineReader()

tell application "FineReader OCR Pro"
   set auto_read to auto read new pages false
end tell

tell application "Finder"
   open fromFile ¬
       using appFile
end tell

delay 5

WaitWhileBusy()

HideFineReader()

tell application "FineReader OCR Pro"
   export to pdf toFile ¬
       ocr languages enum langList ¬
       saving type saveType ¬
       keep pictures keepImageBoolean ¬
       image quality imageOptionsImageQualityEnum ¬
       use mrc useMRCBoolean ¬
       keep text and background colors keepTextAndBackgroundColorsBoolean
end tell

WaitWhileBusy()

HideFineReader()

MoveFilesFromSandbox(exportDir)

tell application "FineReader OCR Pro"
   export to txt (toFile & ".txt") ¬
       ocr languages enum langList ¬
       saving type saveType
end tell

WaitWhileBusy()

HideFineReader()

MoveFilesFromSandbox(exportDir)

tell application "FineReader OCR Pro"
   auto read new pages auto_read
   close document
   quit
end tell

end run

on MoveFilesFromSandbox(exportDir)
   -- moving exported file if FineReader is sandboxed --
   tell application "FineReader OCR Pro"
      set sandb to is sandboxed
   end tell

   if sandb then

      tell application "FineReader OCR Pro"
          set outputDir to get output dir
      end tell

      --set POSIX_exportFile to ((outputDir as string) & exportFileName)
      set POSIX_exportDir to POSIX file exportDir

      tell application "Finder"
          set the_files to files of folder outputDir
          repeat with this_file in the_files
              duplicate this_file to POSIX_exportDir replacing yes
          end repeat
      end tell

   end if
   -- END moving exported file --
end MoveFilesFromSandbox

on WaitWhileBusy()
   repeat while IsMainApplicationBusy()
   end repeat
end WaitWhileBusy

on IsMainApplicationBusy()
   tell application "FineReader OCR Pro"
      set resultBoolean to is busy
   end tell
   return resultBoolean
end IsMainApplicationBusy

on HideFineReader()
   -- tell application "System Events" to tell process "FineReader OCR Pro" to set visible to false
   do shell script "( for i in `seq 1 20`; do osascript -e 'tell application \"System Events\" to tell process \"FineReader OCR Pro\" to set visible to false'; sleep 1; done ) &"
end HideFineReader
