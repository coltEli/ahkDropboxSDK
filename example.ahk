#singleInstance force
#noEnv
#include dbox.ahk

/*
4-9-2021
author: colt
inspired by this topic : https://autohotkey.com/board/topic/95288-get-started-with-the-dropbox-sdk/
*/


/*
create new app at this website
https://www.dropbox.com/developers/apps
under app settings you will find app Key and secret key 
use this app key and secret key to connect this script to the dropbox interface

during the first execution dropbox will ask for approval. Once granted, dropbox will return an access token that can be reused until it expires
access token will be stored in a text file to facilitate skipping this step in the future
*/

;connect to service
dbox := new dropbox(appKey := "someKey",secret := "someSecret")

;basic opertions
msgbox % "DROPBOX STORAGE SPACE JSON RESPONSE`n`n" . dbox.GET_SPACE_USAGE()
msgbox % "CREATE FOLDER JSON RESPONSE`n`n" . dbox.CREATE_FOLDER("/test/folder/very/deep/indeed")
msgbox % "DELETE FOLDER JSON RESPONSE`n`n" . dbox.DELETE("/test/folder/very")


;init the text file
fileDelete testUpload.txt
fileAppend ,test content,testUpload.txt
;upload it
msgbox % "UPLOAD SIMPLE TEXT FILE JSON RESPONSE`n`n" . dbox.UPLOAD("testUpload.txt","/test/MyNewFn.txt")
;edit local file
fileAppend ,`nthis is new content,testUpload.txt
;reupload changes
msgbox % "EDIT SIMPLE TEXT FILE JSON RESPONSE`n`n" .  dbox.UPLOAD("testUpload.txt","/test/MyNewFn.txt",mode := "overwrite")


;upload image from windows folder
msgbox % "UPLOAD IMAGE JSON RESPONSE`n`n" . dbox.UPLOAD("C:\Windows\Web\Wallpaper\Windows\img0.jpg","/win.jpg")
;download the image we just uploaded to localfile system
msgbox % "DOWNLOAD IMAGE JSON RESPONSE`n`n" . dbox.DOWNLOAD("/win.jpg",A_ScriptDir . "\out.jpg")

;get N revision information for a file
msgbox % "LIST_REVISIONS JSON RESPONSE`n`n" . dbox.LIST_REVISIONS("/test/MyNewFn.txt",5)
;download N revisions to single folder 
msgbox % "DOWNLOAD PREVIOUS REVISIONS RESPONSE`n`n" . dbox.downloadPrevVersions("/test/MyNewFn.txt",A_ScriptDir . "\Rev History",40)
