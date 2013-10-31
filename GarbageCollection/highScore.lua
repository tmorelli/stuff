
require("network")
local gameNetwork = require "gameNetwork"
local loggedIntoGC = false

local json = require "json"

highScore = {}
local high=0
local usingServer = false
local usingGC = true
local serverURL = "http://cps-hccdev.cps.cmich.edu:443/"
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
                elseif (usingGC == true) then
                	setHighScoreOnGC()
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
        elseif (usingGC == true) then
        	initGC()
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
        local params={}
        params.headers = headers
        local command = {}
        command["command"] = "requestHighScore"
        local t = json.encode(command)
        event = t
        params.body = event
        params.bodyType="text"
        network.request(serverURL.."getHighScore","POST",highScoreResponse,params)
end
-----------------------------------------------------------------
function setHighScoreOnSystem()
        local headers = {}
        headers["Content-Type"] = "application/json"
        local params={}
        params.headers = headers
        local command = {}
        command["command"] = "setHighScore"
        command["highScore"] = high
        local t = json.encode(command)
        event = t
        params.body = event
        params.bodyType="text"
        network.request(serverURL.."setHighScore","POST",highScoreResponse,params)
end
-----------------------------------------------------------------
function gcSetHighScoreCallback (event)
	
--	native.showAlert( "Note", "set high callback", { "OK" } )
end
-----------------------------------------------------------------
function setHighScoreOnGC()
--	native.showAlert( "Note", "settingOn GC GC", { "OK" } )

        gameNetwork.request( "setHighScore",
        {
            localPlayerScore = { category="GarbageCollection.01", value=high },
            listener=gcSetHighScoreCallback
        })
end

-----------------------------------------------------------------
function gcRequestCallback(event)
	if (event ~= nil and event.data ~= nil and event.data[1] ~= nil) then
		high = event.data[1].value
	else
	end
end
-----------------------------------------------------------------
function requestHighScoreFromGC()
	gameNetwork.request( "loadScores",
	{
    	leaderboard =
   	 	{
        	category = "GarbageCollection.01",
        	playerScope = "Global",   -- Global, FriendsOnly
        	timeScope = "AllTime",    -- AllTime, Week, Today
        	playerCentered = true,
    	},
    	listener = gcRequestCallback
	})
end

-----------------------------------------------------------------
function initCallback( event )
    if not event.isError then
        loggedIntoGC = true
--        native.showAlert( "Success!", "", { "OK" } )
        requestHighScoreFromGC()

    else
        native.showAlert( "Failed!", event.errorMessage, {"OK"})
--        print("Error Code: ", event.errorCode)
    end
end
-----------------------------------------------------------------
function initGC()
    gameNetwork.init( "gamecenter", initCallback )
end
-----------------------------------------------------------------
function onGameNetworkPopupDismissed(event)
	highScoresDone()
end
-----------------------------------------------------------------
function highScore.showHighScores(highScoresDone)	
	highScoreDoneCallback = highScoresDone
	gameNetwork.show( "leaderboards", { leaderboard = {timeScope="AllTime", playerScope="Global"}, listener=onGameNetworkPopupDismissed } )

end

-----------------------------------------------------------------


