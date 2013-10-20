local json = require "json"

highScore = {}
local high=0
local usingServer = false
------------------------------------------------------
function highScore.init()
	high = 0
	initHighScore()
end
------------------------------------------------------

function highScore.getScore()
	return high
end
------------------------------------------------------

function highScore.update(score)
	if (score > high) then
		high = score
		if (usingServer == true) then
			setHighScoreOnSystem()
		else
			local path = system.pathForFile( "save.txt", system.DocumentsDirectory )
			local file = io.open( path, "w" )
			file:write( high )
			io.close( file )
			file = nil
		end
	end
end
------------------------------------------------------
function initHighScore()
	if (usingServer == true) then
		requestHighScoreFromSystem()
	else
		local path = system.pathForFile( "save.txt", system.DocumentsDirectory )
		local file = io.open( path, "r" )
		local hs = file:read( "*a" )
		if (hs == nil or #hs <= 0) then
			high = 0
		else
			high = tonumber(hs)
		end
		io.close( file )
		file = nil
	end
end
-----------------------------------------------------------------
function highScoreResponse(event )
	resp = json.decode(event.response)
	if (resp ~= nil) then
		local hs = resp["highScore"]
		high = hs
		print ("High Score Received: " .. hs)
	end
end
-----------------------------------------------------------------
function requestHighScoreFromSystem()
	local headers = {}
	headers["Content-Type"] = "application/json"
	headers["X-API-Key"] = "13b6ac91a2"
	local params={}
	params.headers = headers
	local command = {}
	command["command"] = "requestHighScore"
	local t = json.encode(command)
	event = t
	params.body = event
	params.bodyType="text"
	network.request("http://cps-hcc.cps.cmich.edu:443/getHighScore","POST",highScoreResponse,params)
end
-----------------------------------------------------------------
function setHighScoreOnSystem()
	local headers = {}
	headers["Content-Type"] = "application/json"
	headers["X-API-Key"] = "13b6ac91a2"
	local params={}
	params.headers = headers
	local command = {}
	command["command"] = "setHighScore"
	command["highScore"] = high
	local t = json.encode(command)
	event = t
	params.body = event
	params.bodyType="text"
	network.request("http://cps-hcc.cps.cmich.edu:443/setHighScore","POST",highScoreResponse,params)
end
-----------------------------------------------------------------
