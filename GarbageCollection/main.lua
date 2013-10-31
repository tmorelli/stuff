-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here



require("highScore")
json = require("json")

display.setStatusBar( display.HiddenStatusBar )
truckHorizontalSpeed = 5
speed = 5
currentLevelSpeed = speed
movingRight = false
movingLeft = false
laneMarkers = {}
numLaneMarkers = 20
numHouses = 20
numBags = 20
laneFrameIndex = 0
leftHouses = {}
rightHouses = {}
rightBags = {}
leftBags = {}
timeForRandomHouse = 100
framesSinceLastRandomRightHouse = timeForRandomHouse
framesSinceLastRandomLeftHouse = timeForRandomHouse
points = 0
roundTime = 30.0
startRoundTime = 0
level = 1

bagsHit = 0

correctColor = 0
incorrectColor = 0

colors = {{255,0,0},{0,255,0},{0,0,255}}


bagsHitImages = {}

maxMisses = 5
missedBags = {}
totalMisses = 0
roundOverText = nil


PLAYING = 0
ROUND_OVER = 1
GAME_OVER = 2
PICKEM_DELAY = 3

state = PLAYING

saveState = {}


-----------------------------------------------------------------
function adjustTruckBounds()
	if (truck.x < 60) then
		truck.x = 60
	elseif (truck.x > 260) then
		truck.x = 260
	end
end
-----------------------------------------------------------------
function restartGame()
	level = 0
	points = 0
	gameOverText:removeSelf()
	gameOverText = nil
	startNextLevel()
	
end

-----------------------------------------------------------------
function highScoresDone()
	restartGame()
end
-----------------------------------------------------------------
function showHighScores()
	highScore.showHighScores(highScoresDone)	
end
-----------------------------------------------------------------
function touchEventListener(event )

	if (splashShown == true) then
		exitSplash()
		return
	end


	if (state == GAME_OVER and event.phase == "began") then
		showHighScores()
--		restartGame()
		return
	end
	if (event.phase == "began" or  event.phase == "moved") then
		if (event.x > 160) then
			movingRight = true
			movingLeft = false
		else
			movingLeft = true
			movingRight = false
		end
	elseif  (event.phase == "ended") then
		movingLeft = false
		movingRight = false
	end
end
-----------------------------------------------------------------
function updateLaneMarkerLocations()
	for x = 0, numLaneMarkers do
		laneMarkers[x].y = laneMarkers[x].y + speed
		if (laneMarkers[x].y > 60*(x+1)) then
			laneMarkers[x].y = 60 * x
		end
	end
end
-----------------------------------------------------------------
function initLaneMarkerLocations()
	for x = 0, numLaneMarkers do
		laneMarkers[x].x = 160
		laneMarkers[x].y = 60*x
	end
end
-----------------------------------------------------------------
function initLaneMarkers()
	for x = 0,numLaneMarkers do
		laneMarkers[x] = display.newImage("lane_marker.png")
	end
	initLaneMarkerLocations()
end
-----------------------------------------------------------------
function initHouses()
	for x = 0,numHouses do
		rightHouses[x] = display.newImage("HouseRight.png")
		rightHouses[x].y = -100
		rightHouses[x].x = 285
	end
	for x = 0,numHouses do
		leftHouses[x] = display.newImage("HouseLeft.png")
		leftHouses[x].y = -100
		leftHouses[x].x = 35
	end
end
-----------------------------------------------------------------
function initMissedBags()
	for x = 0,maxMisses-1 do
		missedBags[x] = display.newImage("bag.png")
		missedBags[x].y = 450
		missedBags[x].x = 10+20*x
		missedBags[x]:setFillColor(128,128,128)
		missedBags[x].alpha = .6
	end
end
-----------------------------------------------------------------
function initBags()
	for x = 0,numBags do
		rightBags[x] = display.newImage("bag.png")
		rightBags[x].y = -100
		rightBags[x].x = 262
		rightBags[x].name = "bag"
	end
	for x = 0,numBags do
		leftBags[x] = display.newImage("bag.png")
		leftBags[x].y = -100
		leftBags[x].x = 56
		leftBags[x].name = "bag"
	end
end
-----------------------------------------------------------------
function startNextLevel()
	level = level + 1
	levelLabel.text = "Level: "..level
	bagsHit = 0
	for x = 0,maxMisses-1 do
		missedBags[x]:setFillColor(128,128,128)
		missedBags[x].alpha = .6
	end
	totalMisses = 0

	timeForRandomHouse = 100
	framesSinceLastRandomRightHouse = timeForRandomHouse
	framesSinceLastRandomLeftHouse = timeForRandomHouse
	speed = 3+1.5*level
	currentLevelSpeed = speed
	movingRight = false
	movingLeft = false

	for x = 0,numBags do
		rightBags[x].y = -100
	end
	for x = 0,numBags do
		leftBags[x].y = -100
	end
	for x = 0,numHouses do
		rightHouses[x].y = -100
	end
	for x = 0,numHouses do
		leftHouses[x].y = -100
	end
	state = PLAYING
	startRoundTime = system.getTimer()
end
-----------------------------------------------------------------
function scalePickemPrize()
	if (pickemPrize.xScale >= 1.5) then
		scaleDirection = -1
	elseif (pickemPrize.xScale <= .5) then
		scaleDirection = 1
	end
	pickemPrize.xScale = pickemPrize.xScale + 0.1*scaleDirection
	pickemPrize.yScale = pickemPrize.yScale + 0.1*scaleDirection
	pickemPrizeTimer = timer.performWithDelay(16,scalePickemPrize)


end
-----------------------------------------------------------------
function exitPickem()
	audio.play(pooperSound)
	audio.play(pickemExitSound)

	scaleDirection = 1
	pickemPrize = display.newText(prize,110,200,nil,36)
	pickemPrizeTimer = timer.performWithDelay(16,scalePickemPrize)
	timer.performWithDelay(3000,pickemOver)


--	pickemOver()
end
-----------------------------------------------------------------
function pickemOver()
	timer.cancel(pickemPrizeTimer)

	roundOverText:removeSelf()
	roundOverText = nil
	
	pickemPrize:removeSelf()
	pickemPrize = nil
	
	roundOverInstruction:removeSelf()
	roundOverInstruction = nil
	roundOverInstruction2:removeSelf()
	roundOverInstruction2 = nil
	
	for x = 0,bagsHit-1 do
		bagsHitImages[x]:removeSelf()
		bagsHitImages[x] = nil
	end
	
	startNextLevel()
end
-----------------------------------------------------------------

function bagTouch(self,event)

--[[
		prize = 1000 * prize
		correctColor = {255,0,0}
--]]

	if (event.phase == "began" and state ~= PICKEMDELAY) then
	
		local dinkSoundChannel = audio.play(dinkSound);
		thisRoundOver = false
		bagsTouched = bagsTouched+1
		
		print("bagTouch"..bagsTouched..","..bagsHit..","..correctColor..","..incorrectColor)
		
		if (bagsTouched <= prize/1000) then
			self:setFillColor(colors[correctColor][1],colors[correctColor][2],colors[correctColor][3])
--			self:fillColor(255,0,0)
		else
			self:setFillColor(colors[incorrectColor][1],colors[incorrectColor][2],colors[incorrectColor][3])
--			self:fillColor(0,0,255)
		end	
		if ((bagsTouched == prize/1000 + 1) or (bagsTouched == bagsHit)) then
			thisRoundOver = true
		end
		

		if (thisRoundOver == true) then
			points = points+prize
			state=PICKEMDELAY
			updateMeters()
			exitPickem()
--			timer.performWithDelay(3000,pickemOver)
		end

--[[	
		if (prize == 1000) then
			self:setFillColor(255,0,0)
		elseif (prize == 2000) then
			self:setFillColor(0,255,0)
		elseif (prize == 3000) then
			self:setFillColor(0,0,255)
		else
			lastColor = color
			while (lastColor == color) do
				color = math.random(0,2)
			end
			if (color == 0) then
				self:setFillColor(255,0,0)
			elseif(color == 1) then
				self:setFillColor(0,255,0)
			else
				self:setFillColor(0,0,255)
			end
		end
		if (bagsTouched == 3 or bagsTouched >= bagsHit) then
			points = points+prize
			state=PICKEMDELAY
			updateMeters()
			timer.performWithDelay(1000,pickemOver)
		end
--]]
	end
end
-----------------------------------------------------------------
function choosePrize(_bags)
		if (bagsHit == 0) then
			return 0
		end		
		local picks = 0
		local rnd = math.random(0,100)
		if (bagsHit == 1) then
			picks = 0
		end		
		if (bagsHit == 2) then
			if (rnd < 50) then
				picks = 0
			else
				picks = 1
			end
		end				
		if (bagsHit == 3) then
			if (rnd < 50) then
				picks = 0
			elseif (rnd < 75) then
				picks = 1
			else
				picks = 2
			end
		end		
		if (bagsHit == 4) then
			if (rnd < 30) then
				picks = 0
			elseif (rnd < 50) then
				picks = 1
			elseif (rnd < 90) then
				picks = 2
			else
				picks = 3
			end
		end		
		if (bagsHit == 5) then
			if (rnd < 20) then
				picks = 0
			elseif (rnd < 40) then
				picks = 1
			elseif (rnd < 60) then
				picks = 2
			elseif (rnd < 90) then
				picks = 3
			else
				picks = 4
			end
		end		
		if (bagsHit == 6) then
			if (rnd < 20) then
				picks = 0
			elseif (rnd < 30) then
				picks = 1
			elseif (rnd < 50) then
				picks = 2
			elseif (rnd < 70) then
				picks = 3
			elseif (rnd < 90) then
				picks = 4
			else
				picks = 5
			end
		end		
		if (bagsHit == 7) then
			if (rnd < 20) then
				picks = 0
			elseif (rnd < 30) then
				picks = 1
			elseif (rnd < 40) then
				picks = 2
			elseif (rnd < 60) then
				picks = 3
			elseif (rnd < 70) then
				picks = 4
			elseif (rnd < 90) then
				picks = 5
			else
				picks = 6
			end
		end		
		if (bagsHit == 8) then
			if (rnd < 10) then
				picks = 0
			elseif (rnd < 20) then
				picks = 1
			elseif (rnd < 30) then
				picks = 2
			elseif (rnd < 40) then
				picks = 3
			elseif (rnd < 60) then
				picks = 4
			elseif (rnd < 70) then
				picks = 5
			elseif (rnd < 90) then
				picks = 6
			else
				picks = 7
			end
		end		
		if (bagsHit >= 9) then
			if (rnd < 10) then
				picks = 0
			elseif (rnd < 20) then
				picks = 1
			elseif (rnd < 30) then
				picks = 2
			elseif (rnd < 40) then
				picks = 3
			elseif (rnd < 60) then
				picks = 4
			elseif (rnd < 70) then
				picks = 5
			elseif (rnd < 80) then
				picks = 6
			elseif (rnd < 90) then
				picks = 7
			else
				picks = 8
			end
		end		
		picks = picks+1
		return picks*1000
end
-----------------------------------------------------------------
function roundOver()
	state = ROUND_OVER
	speed = 0
	bagsTouched = 0
	roundOverText = display.newText("Round Over", 0,0, nil, 24);
	roundOverText:setReferencePoint(display.TopLeftReferencePoint);
	roundOverText.x = 90;
	roundOverText.y = 80;
		
	roundOverInstruction = display.newText("Touch Bags To Reveal Color!", 0,0, nil, 18);
	roundOverInstruction:setReferencePoint(display.TopLeftReferencePoint);
	roundOverInstruction.x = 40;
	roundOverInstruction.y = 120;

	roundOverInstruction2 = display.newText("Pick Until Color Changes", 0,0, nil, 18);
	roundOverInstruction2:setReferencePoint(display.TopLeftReferencePoint);
	roundOverInstruction2.x = 55;
	roundOverInstruction2.y = 140;
		
	rowIndex = 0
	yLocation = 180	
	
	if (bagsHit == 0) then
		prize = 0
	else
		prize = choosePrize(bagsHit)
	end
	
	correctColor = math.random(1,#colors)
	incorrectColor = math.random(1,#colors)
	while (incorrectColor == correctColor) do
		incorrectColor = math.random(1,#colors)
	end
	
	

	for x = 0,bagsHit-1 do
		bagsHitImages[x] = display.newImage("bag.png")
		bagsHitImages[x].x = 100 + 30*rowIndex
		bagsHitImages[x].y = yLocation
		bagsHitImages[x].touch = bagTouch
		bagsHitImages[x]:addEventListener("touch")
		bagsHitImages[x].id = x
		rowIndex = rowIndex + 1
		if (rowIndex == 5) then
			rowIndex = 0
			yLocation = yLocation + 30
		end
	end
		
end
-----------------------------------------------------------------
function gameOver()
	state = GAME_OVER
	speed = 0
	gameOverText = display.newText("Game Over", 0,0, nil, 24);
	gameOverText:setReferencePoint(display.TopLeftReferencePoint);
	gameOverText.x = 90;
	gameOverText.y = 80;
end
-----------------------------------------------------------------
function updateMeters()

	if (pointLabel ~= nil) then
		pointLabel:removeSelf()
		pointLabel = nil
	end
	pointLabel = display.newText("Points: "..points, 0,0, nil, 24);
	pointLabel:setReferencePoint(display.BottomRightReferencePoint);
	pointLabel.x = 320;
	pointLabel.y = 40;


	if (state == PLAYING) then
		timeLeft = roundTime - math.round((system.getTimer()-startRoundTime)/1000)
	end
	
	timeLabel.text = "Time: "..timeLeft
	if (timeLeft == 0 and state ~=PICKEMDELAY and state ~= GAME_OVER) then
		roundOver()
	end
	highScore.update(points)
	
	if (highScoreLabel ~= nil) then
		highScoreLabel:removeSelf()
		highScoreLabel = nil
	end
	highScoreLabel = display.newText("Top: "..highScore.getScore(), 0,0, nil, 24);
	highScoreLabel:setReferencePoint(display.BottomRightReferencePoint);
	highScoreLabel.x = 320;
	highScoreLabel.y = 80;

end
-----------------------------------------------------------------
function initMeters()
	meterPanel = display.newImage("meter.png")
	pointLabel = display.newText("Points: "..points, 0,0, nil, 24);
	pointLabel:setReferencePoint(display.BottomRightReferencePoint);
	pointLabel.x = 320;
	pointLabel.y = 40;

	highScoreLabel = display.newText("Top: "..highScore.getScore(), 0,0, nil, 24);
	highScoreLabel:setReferencePoint(display.BottomRightReferencePoint);
	highScoreLabel.x = 320;
	highScoreLabel.y = 80;

	timeLabel = display.newText("Time: "..points, 0,0, nil, 24);
	timeLabel:setReferencePoint(display.BottomLeftReferencePoint);
	timeLabel.x = 20;
	timeLabel.y = 40;

	levelLabel = display.newText("Level: "..level, 0,0, nil, 18);
	levelLabel:setReferencePoint(display.BottomRightReferencePoint);
	levelLabel.x = 300;
	levelLabel.y = 470;

end
-----------------------------------------------------------------
function initGraphics()
	background = display.newImage("background.png")
	initLaneMarkers()
	initHouses()
	initBags()
	initMissedBags()
	truck = display.newImage("truck.png")
	truck.x = 160
	truck.y = 400
	truck.name = "truck"
	initMeters()
end

-----------------------------------------------------------------
function updateHouses()
	for x = 0,numHouses do
		if (rightHouses[x].y >= 0) then
			rightHouses[x].y = rightHouses[x].y + speed
		end
		if (rightHouses[x].y > 500) then
			rightHouses[x].y = -100
		end
	end
	for x = 0,numHouses do
		if (leftHouses[x].y >= 0) then
			leftHouses[x].y = leftHouses[x].y + speed
		end
		if (leftHouses[x].y > 500) then
			leftHouses[x].y = -100
		end
	end
end
-----------------------------------------------------------------
function updateBags()
	for x = 0,numBags do
		if (rightBags[x].y >= 0) then
			rightBags[x].y = rightBags[x].y + speed
		end
		if (rightBags[x].y > 500) then
			rightBags[x].y = -100
			bagMissed()
		end
	end
	for x = 0,numBags do
		if (leftBags[x].y >= 0) then
			leftBags[x].y = leftBags[x].y + speed
		end
		if (leftBags[x].y > 500) then
			leftBags[x].y = -100
			bagMissed()
		end
	end
end
-----------------------------------------------------------------
function placeNextRightHouse()
	for x = 0,numHouses do
		if (rightHouses[x].y < 0) then
			rightHouses[x].y = 0
			rightBags[x].y = 15
			break 
		end
	end
end
-----------------------------------------------------------------
function placeNextLeftHouse()
	for x = 0,numHouses do
		if (leftHouses[x].y < 0) then
			leftHouses[x].y = 0
			leftBags[x].y = 15
			break 
		end
	end
end
-----------------------------------------------------------------
function bagHit()
	points = points + 100 * level
	bagsHit = bagsHit + 1
	local chingChannel = audio.play(chingSound)
	updateMeters()
	updateSaveState()

end
-----------------------------------------------------------------
function bagMissed()
	if (totalMisses < maxMisses) then
		missedBags[totalMisses].alpha = 1.0
		missedBags[totalMisses]:setFillColor(255,0,0) 
		totalMisses = totalMisses+1
	end
	if (totalMisses >= maxMisses) then
		gameOver()
	end
	updateMeters()
	updateSaveState()
end
-----------------------------------------------------------------
function checkCollisions()
	if (truck.x < 80 ) then
		for x = 0,numBags do
			if (leftBags[x].y >= 390 and leftBags[x].y <= 430) then
				leftBags[x].y = -100
				bagHit()
			end
		end
	elseif (truck.x > 240) then
		for x = 0,numBags do
			if (rightBags[x].y >= 390 and rightBags[x].y <= 430) then
				rightBags[x].y = -100
				bagHit()
			end
		end
	end
end

-----------------------------------------------------------------
function playUpdate()
	if (movingRight) then
		truck.x = truck.x + truckHorizontalSpeed
	end
	if (movingLeft) then
		truck.x = truck.x - truckHorizontalSpeed	
	end
	adjustTruckBounds()
	updateLaneMarkerLocations()
	updateHouses()
	updateBags()
	framesSinceLastRandomRightHouse = framesSinceLastRandomRightHouse + 1
	framesSinceLastRandomLeftHouse = framesSinceLastRandomLeftHouse + 1
	if (framesSinceLastRandomRightHouse > timeForRandomHouse) then
		if (math.random(0,100) == 0) then
			placeNextRightHouse()
			framesSinceLastRandomRightHouse = 0
		end	
	end
	if (framesSinceLastRandomLeftHouse > timeForRandomHouse) then
		if (math.random(0,100) == 0) then
			placeNextLeftHouse()
			framesSinceLastRandomLeftHouse = 0
		end	
	end
	checkCollisions()
	updateMeters()
end
-----------------------------------------------------------------
function frameUpdate(event)
	if (state == PLAYING) then
		playUpdate()
	end
end
---------------------------------------------------------------------------
function onCollision(event)
	if (event.phase == "began") then
		if ((event.object1.name == "truck" and event.object2.name == "truck") or
			(event.object1.name == "bag" and event.object2.name == "bag")) then
			print "Collision"
		end
	end

end
-----------------------------------------------------------------
function updateSaveState()
	saveState.level = level
	saveState.totalMisses = totalMisses
	saveState.bagsHit = bagsHit
	saveState.timeLeft = roundTime - math.round((system.getTimer()-startRoundTime)/1000)
	saveState.points = points
	
	local path = system.pathForFile( "saveState.json", system.DocumentsDirectory )
	local file = io.open( path, "w" )
	local ss = json.encode(saveState)
    file:write( ss )
    io.close( file )
    file = nil
    ss = nil
end

-----------------------------------------------------------------
function showSplash()
	splashShown = true
	splashText = display.newText("Touch Left and Right To Move", 0,0, nil, 18);
	splashText:setReferencePoint(display.TopLeftReferencePoint);
	splashText.x = 30;
	splashText.y = 80;
		
	splashText2 = display.newText("Collect Bags For Points", 0,0, nil, 18);
	splashText2:setReferencePoint(display.TopLeftReferencePoint);
	splashText2.x = 58;
	splashText2.y = 120;

	splashText3 = display.newText("Extra Bonus After Each Level!", 0,0, nil, 18);
	splashText3:setReferencePoint(display.TopLeftReferencePoint);
	splashText3.x = 30;
	splashText3.y = 140;

end

-----------------------------------------------------------------
function exitSplash()
	splashShown = false
	if (splashText ~= nil) then
		splashText:removeSelf()
		splashText = nil
	end
	if (splashText2 ~= nil) then
		splashText2:removeSelf()
		splashText2 = nil
	end
	if (splashText3 ~= nil) then
		splashText3:removeSelf()
		splashText3 = nil
	end
	timer.performWithDelay(500,startGame)
end
-----------------------------------------------------------------
function startGame()
	startRoundTime = system.getTimer()
	Runtime:addEventListener("enterFrame", frameUpdate)
end
-----------------------------------------------------------------
function restoreState()

--[[
    local path = system.pathForFile( "saveState.json", system.DocumentsDirectory )
    local file = io.open( path, "r" )
    if (file ~= nil) then
	    local ss = file:read( "*a" )
   	 	saveState = json.decode(ss)
   	 	io.close( file )
    	file = nil
    	level = saveState.level-1
		bagsHit = saveState.bagsHit
		totalMisses = saveState.totalMisses
		points = saveState.points
		startNextLevel()

		for x = 0,saveState.totalMisses-1 do
			missedBags[x].alpha=1.0
		end
		bagsHit = saveState.bagsHit
		totalMisses = saveState.totalMisses
		startRoundTime = system.getTimer() - (roundTime-saveState.timeLeft) * 1000
	else
		startRoundTime = system.getTimer()
    end
--]]

	showSplash(startGame)

end

--[[
-----------------------------------------------------------------
local function onGameNetworkRequestResult( event )
    if event.type == "setHighScore" then
        -- High score has been set.
    elseif event.type == "resetAchievements" then
        -- Achievements have been reset.
    end
end
-----------------------------------------------------------------

function updateHighScore()
        gameNetwork.request( "setHighScore",
        {
            localPlayerScore = { category="GarbageCollection.01", value=points },
            listener=requestCallback
        })
        -- gameNetwork.show( "leaderboards", { leaderboard = {playerScope="Global",timeScope="AllTime"}, listener=onGameNetworkPopupDismissed } )
end
--]]


highScore.init()
initGraphics()
backgroundMusic = audio.loadStream("garbage.mp3")
backgroundMusicChannel = audio.play( backgroundMusic, { channel=1, loops=-1, fadein=5000 }  )  -- play the background music on channel 1, loop infinitely, and fadein over 5 seconds 


pooperSound = audio.loadStream("pooper.mp3")
pickemExitSound = audio.loadStream("pickemexit.mp3")

chingSound = audio.loadStream("ching.mp3")
dinkSound = audio.loadStream("dink.mp3")
Runtime:addEventListener("touch", touchEventListener)

restoreState()