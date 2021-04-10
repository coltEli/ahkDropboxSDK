#Include httpRequest.ahk ;https://github.com/RaptorX/AHK-ToolKit/blob/master/lib/httprequest.ahk
#include json.ahk ;https://github.com/cocobelgica/AutoHotkey-JSON
#Include base64.ahk ;https://github.com/jNizM/AHK_Scripts/blob/master/src/encoding_decoding/base64.ahk

;inspired by : https://autohotkey.com/board/topic/95288-get-started-with-the-dropbox-sdk/

class dropbox
{
	__new(key,secret)
	{
		this.APP_KEY := key		
		this.SECRET := secret		
		this._ACCESS_TOKEN := ""
	}
	GET_SPACE_USAGE()
	{			
		return this.queryDBox("https://api.dropboxapi.com/2/users/get_space_usage")
	}	
	CREATE_FOLDER(path := "", autorename := "false")
	{
		data := "{""path"":""" . path . """,""autorename"":" . autorename  . "}"	
		return this.queryDBox("https://api.dropboxapi.com/2/files/create_folder_v2",data)
	}
	DELETE(path := "")
	{	
		data := "{""path"":""" . path . """}"		
		return this.queryDBox("https://api.dropboxapi.com/2/files/delete_v2",data)
	}
	UPLOAD(src,dest := "",mode := "add") ;small files only. for large see https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-start
	{		
		header := "Dropbox-API-Arg: {""path"":""" . dest . """,""mode"":""" . mode . """}`n"
		header .= "Content-Type: application/octet-stream"	
		fileRead,data,% "*c " . src	;read binary		
		return this.queryDBox("https://content.dropboxapi.com/2/files/upload",data,header)		
	}
	DOWNLOAD(path := "",dest := "")
	{
		header := "Dropbox-API-Arg: {""path"":""" . path . """}"				
		return this.queryDBox("https://content.dropboxapi.com/2/files/download",data,header,options := "SAVE AS:" . dest)		
	}
	LIST_REVISIONS(path := "", numRevs := 10)
	{
		data := "{""path"":""" . path . """,""mode"":""path"",""limit"":" . numRevs . "}"		
		return this.queryDBox("https://api.dropboxapi.com/2/files/list_revisions",data)	
	}
	downloadPrevVersions(path,outDir := "" ,numRevs := 10)
	{		
		fileCreateDir % outDir
		revArr := json.load(this.LIST_REVISIONS(path,numRevs)).entries
		totalActualRevs := revArr._maxIndex()
		for index, data in revArr
		{		
			tooltip % "Downloading " . index . " of " . totalActualRevs
			newFN := "[" . strReplace(data.client_modified,":","-") . "] " . data.name	
			this.DOWNLOAD("rev:" . data.rev,outDir . "\" . newFN)
		}
		return true
	}
	queryDBox(url,InOutData := "",InOutHeader:= "",options := "")
	{
		loop ;try and refresh token if bad
		{
			if(inOutData && !InOutHeader) ;basic operation assume simple json command
			{
				InOutHeader .= "`nContent-Type: application/json"
			}
			InOutHeader .= "`nAuthorization: Bearer " . this.ACCESS_TOKEN ;always need this	
			HTTPRequest(url, InOutData, InOutHeader, "Method: Post`n" . options)			
			if(instr(InOutData,"invalid_access_token")) ;reset token cache to let it rebuild
			{
				fileDelete accessToken.txt 
				this._ACCESS_TOKEN := ""		
			}
			else
			{
				return InOutData
			}
		}
	}
	ACCESS_TOKEN[]
	{	
		get
		{
			if(!this._ACCESS_TOKEN)
			{	
				fileRead accessToken,accessToken.txt ;get cached token
				if(!accessToken)
				{						
					loop 
					{
						run % "https://www.dropbox.com/oauth2/authorize?client_id=" . this.APP_KEY . "&response_type=code"
						inputBox,AUTHORIZATION_CODE,Authorize!,Enter access code after you allow permissions for this app

						encodedCredentials := b64Encode(this.APP_KEY . ":" . this.SECRET)
						InOutData := "code="  . AUTHORIZATION_CODE . "&grant_type=authorization_code"		
						InOutHeader := "Authorization: Basic " . encodedCredentials
						HTTPRequest("https://api.dropbox.com/oauth2/token", InOutData, InOutHeader, "Charset: UTF-8")						
						if(instr(InOutData,"access_token")) ;cache good token
						{	
							this._ACCESS_TOKEN := json.load(InOutData).access_token						
							fileDelete accessToken.txt 
							fileAppend % this._ACCESS_TOKEN,accessToken.txt 
							break
						}
						else  ;Need to retry getting auth code
						{
							msgbox need to retry
							msgbox % InOutHeader
							msgbox % InOutData
						}			
					}									
				}
				else
				{
					this._ACCESS_TOKEN := accessToken	
				}				
			}
			return this._ACCESS_TOKEN	
		}
		set
		{
			this._ACCESS_TOKEN	:= value
		}
	}	
}	

