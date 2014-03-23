-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

require("logger")
json = require("json")

truckHorizontalSpeed = 5
speed = 5
currentLevelSpeed = speed
movingRight = false
movingLeft = false
laneMarkers = {}
numLaneMarkers = 20
numHouses = 20
numBags = 15
laneFrameIndex = 0
leftHouses = {}
rightHouses = {}
rightBags = {}
leftBags = {}
timeForRandomHouse = 150
framesSinceLastRandomRightHouse = timeForRandomHouse
framesSinceLastRandomLeftHouse = timeForRandomHouse
framesSinceLastRandomHouse=timeForRandomHouse
points = 0
bonusPrize = 0
roundTime = 50.0
startRoundTime = 0
level = 1
mouseX = 0
mouseY = 0
centerLine = 238
activeBag = 0

OUYA = 1
DS4OUYA = 2
DS4NORM = 3

SWIPE_SCHEME = 1
TOUCH_SCHEME = 2

activeScheme = SWIPE_SCHEME

chooseRandomControl = true
swiping = false
swipeTimer = nil
swipeThreshold = 50

if (chooseRandomController == true) then
	controller1 = math.random(1,3)
	controller2 = math.random(1,3)
	controller3 = math.random(1,3)
	while (controller2 == controller1) do
		controller2 = math.random(1,3)
	end
	while ((controller3 == controller2) or (controller3 == controller1)) do
		controller3 = math.random(1,3)
	end
	activeController = controller1
end

currentPoints = 0
START_PRIZE = 10000
pointDecrease = 100
onTarget = false
currentBonusValue = 0
totalBonusWin = 0
BONUS_START_VALUE = 25000

leftBorder = 86
rightBorder = 390

bagsHit = 0
truckY = 600

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
WAITING_FOR_NEXT_LEVEL = 4

state = PLAYING

saveState = {}

local function stopMoving( event )
    movingRight = false
	movingLeft = false
end

local function stopSwiping (event)
	swiping = false
	bagsHitImages[activeBag].alpha = 1
	print ("Start:"..startSwipeX.." End:" .. swipeX)
	if (swipeX - startSwipeX > swipeThreshold) then
		activeBag = activeBag + 1
	elseif (startSwipeX -swipeX > swipeThreshold) then
		activeBag = activeBag - 1
	end	
	if (swipeY - startSwipeY > swipeThreshold) then		
		activeBag = activeBag + 4
	elseif (startSwipeY -swipeY > swipeThreshold) then
		activeBag = activeBag - 4
	end
	if (activeBag < 0) then
		activeBag = 0
	end
	if (activeBag > numBags) then
		activeBag = numBags
	end
	bagsHitImages[activeBag].alpha = .6
end

local function onMouseEvent( event )
	if (state == GAME_OVER) then
		restartGame()
		return
	end
	
	if (activeScheme ~= SWIPE_SCHEME) then
		return
	end

	if (splashShown == true) then
		exitSplash()
		return
	end
	
	--Touchpad swipe controls
	if (state == PLAYING) then
		if (event.x > mouseX) then
			movingRight = true
			movingLeft = false
			mouseX = event.x
		elseif (event.x < mouseX) then
			movingRight = false
			movingLeft = true
			mouseX = event.x
		else 
			movingRight = false
			movingLeft = false
		end
	end
	
	-- Touchpad swipe bonus round controls
	if (state == ROUND_OVER) then
		if (swipeTimer ~= nil) then
			timer.cancel(swipeTimer)
		end
		if (swiping == false) then
			startSwipeX = event.x
			startSwipeY = event.y
		end
		swiping = true
		swipeX = event.x
		swipeY = event.y
		swipeTimer = timer.performWithDelay(100, stopSwiping)
	end
	timer.performWithDelay(50, stopMoving)
end


-----------------------------------------------------------------
function touchEventListener(event)

	if (splashShown == true) then
		exitSplash()
		return
	end
	
	if (event.phase == "began" and state == WAITING_FOR_NEXT_LEVEL) then
		startNextLevel()
		return
	end
	
	if (activeScheme == SWIPE_SCHEME and state == ROUND_OVER) then
		bagTouch(bagsHitImages[activeBag],event)
	end
	
	
	if (activeScheme ~= TOUCH_SCHEME) then
		return
	end


	if (state == GAME_OVER and event.phase == "began") then
		restartGame()
		return
	end
	
	if (event.phase == "began" or  event.phase == "moved") then
		if (event.x > centerLine) then
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
function adjustTruckBounds()
	if (truck.x < 86) then
		truck.x = 86
	elseif (truck.x > 390) then
		truck.x = 390
	end
end
-----------------------------------------------------------------
function restartGame()
	if (chooseRandomControl == true) then
		controller1 = math.random(1,3)
		controller2 = math.random(1,3)
		controller3 = math.random(1,3)
		while (controller2 == controller1) do
			controller2 = math.random(1,3)
		end
		while ((controller3 == controller2) or (controller3 == controller1)) do
			controller3 = math.random(1,3)
		end
		activeScheme = controller1
	end
	level = 0
	points = 0
	gameOverText:removeSelf()
	gameOverText = nil
	if (loggerLabel ~= nil) then
		loggerLabel:removeSelf()
		loggerLabel = nil
	end	
	logger.init()
	
	loggerLabel = display.newText("log:"..logger.getFilename(), 0,0, nil, 24);
	loggerLabel.anchorX = 1;
	loggerLabel.anchorY = 1;
	loggerLabel.x = 900;
	loggerLabel.y = 300;	

	initNextLevel()
	
end

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
		laneMarkers[x].x = (rightBorder-leftBorder) / 2 + leftBorder
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
		rightHouses[x].x = rightBorder+35
	end
	for x = 0,numHouses do
		leftHouses[x] = display.newImage("HouseLeft.png")
		leftHouses[x].y = -100
		leftHouses[x].x = leftBorder-35
	end
end
-----------------------------------------------------------------
function initMissedBags()
	for x = 0,maxMisses-1 do
		missedBags[x] = display.newImage("bag.png")
		missedBags[x].y = truckY+50
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
		rightBags[x].x = rightBorder
		rightBags[x].name = "bag"
	end
	for x = 0,numBags do
		leftBags[x] = display.newImage("bag.png")
		leftBags[x].y = -100
		leftBags[x].x = leftBorder
		leftBags[x].name = "bag"
	end
end
-----------------------------------------------------------------
function initNextLevel()
	level = level + 1
	levelLabel.text = "Level: "..level
	
	bagsHit = 0
	for x = 0,maxMisses-1 do
		missedBags[x]:setFillColor(128,128,128)
		missedBags[x].alpha = .6
	end
	totalMisses = 0


	framesSinceLastRandomRightHouse = timeForRandomHouse
	framesSinceLastRandomLeftHouse = timeForRandomHouse
	framesSinceLastRandomHouse = timeForRandomHouse

	if (chooseRandomControl == true) then
		if (level == 2) then
			activeScheme = controller2
		elseif (level == 3) then
			activeScheme = controller3
		end
		logger.log("LevelStart"..level..",activeScheme,"..activeScheme)
	end

	displayInstructions()

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
	state = WAITING_FOR_NEXT_LEVEL
end

-----------------------------------------------------------------
function startNextLevel()
	speed = 4.5
	currentLevelSpeed = speed
	movingRight = false
	movingLeft = false
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
	pickemPrize = display.newText(totalBonusWin,110,200,nil,36)
	pickemPrizeTimer = timer.performWithDelay(16,scalePickemPrize)
	timer.performWithDelay(3000,pickemOver)

end
-----------------------------------------------------------------
function pickemOver()
	timer.cancel(pickemPrizeTimer)
	
	activeBag = 0

	roundOverText:removeSelf()
	roundOverText = nil
	
	pickemPrize:removeSelf()
	pickemPrize = nil
	
	roundOverInstruction:removeSelf()
	roundOverInstruction = nil
	roundOverInstruction2:removeSelf()
	roundOverInstruction2 = nil
	
	for x = 0,15 do
		bagsHitImages[x]:removeSelf()
		bagsHitImages[x] = nil
	end
	
	if (level == 3) then
		gameOver()
	else
		initNextLevel()
	end
end
-----------------------------------------------------------------

function bagTouch(self,event)


	if ((event.phase == "began" or event.keyName == "buttonA") and state ~= PICKEM_DELAY ) then
	
		if (self.selectable == true) then
			self.selectable = false
			local dinkSoundChannel = audio.play(dinkSound);
			thisRoundOver = false
			logger.log("BagTouched,"..self.id)
			print("bagTouch"..bagsTouched..","..numBags..","..correctColor..","..incorrectColor)
		
			self:setFillColor(255,255,255)
			totalBonusWin = totalBonusWin + currentBonusValue
			if (bonusSelectionsRemaining() <= 0) then
				thisRoundOver = true
			end

			if (thisRoundOver == true) then
				logger.log("Total bonus: "..totalBonusWin)
				points = points+totalBonusWin
				state=PICKEM_DELAY
				updateMeters()
				exitPickem()

			end
		else
			logger.log("BonnusBagNotEnabled,"..self.id)
		end
	end
end

function bonusSelectionsRemaining()
	local count = 0
	for x=0,15 do
		if (bagsHitImages[x].selectable == true) then
			count = count+1
		end
	end
	return count
end
-----------------------------------------------------------------
function roundOver()
	logger.log("RoundOver,"..points)

	state = ROUND_OVER
	speed = 0
	bagsTouched = 0
	roundOverText = display.newText("Round Over", 0,0, nil, 24);
	roundOverText.anchorX = 0;
	roundOverText.anchorY = 0;
	roundOverText.x = 90;
	roundOverText.y = 80;
		
	roundOverInstruction = display.newText("Touch Bags To Reveal Color!", 0,0, nil, 18);
	roundOverInstruction.anchorX = 0
	roundOverInstruction.anchorY = 0
	roundOverInstruction.x = 40;
	roundOverInstruction.y = 120;

	roundOverInstruction2 = display.newText("Pick Until Color Changes", 0,0, nil, 18);
	roundOverInstruction2.anchorX = 0
	roundOverInstruction2.anchorY = 0
	roundOverInstruction2.x = 55;
	roundOverInstruction2.y = 140;
		
	rowIndex = 0
	yLocation = 180	
	correctColor = math.random(1,#colors)
	onTarget = false

	bonusPrize = 0
	totalBonusWin = 0
	currentBonusValue = BONUS_START_VALUE
	for x = 0,numBags do
		bagsHitImages[x] = display.newImage("bag.png")
		bagsHitImages[x].x = 100 + 30*rowIndex
		bagsHitImages[x].y = yLocation
		if (activeScheme == TOUCH_SCHEME) then
			bagsHitImages[x].touch = bagTouch
			bagsHitImages[x]:addEventListener("touch")
		end
		bagsHitImages[x].id = x
		bagsHitImages[x].selectable = false
		
		
		rowIndex = rowIndex + 1
		if (rowIndex == 4) then
			rowIndex = 0
			yLocation = yLocation + 30
		end
	end
	local totalRandomBagsChosen = 0
	while (totalRandomBagsChosen < 5) do
		local rnd = math.random(0,numBags)
		if (bagsHitImages[rnd].selectable == false) then
			bagsHitImages[rnd]:setFillColor(colors[2][1],colors[2][2],colors[2][3])
			totalRandomBagsChosen = totalRandomBagsChosen + 1
			bagsHitImages[rnd].selectable = true
		end
	end
	
	if (activeScheme == JOYSTICK_CONTROL or activeScheme == SWIPE_SCHEME) then
		bagsHitImages[activeBag].alpha = .6
	end
end
-----------------------------------------------------------------
function gameOver()
	logger.log("Game Over")
	logger.close()
	state = GAME_OVER
	speed = 0
	gameOverText = display.newText("Game Over", 0,0, nil, 24);
	gameOverText.anchorX = 0
	gameOverText.anchorY = 0
	gameOverText.x = 90;
	gameOverText.y = 80;
	onTarget = false

end
-----------------------------------------------------------------
function updateMeters()

	if (pointLabel ~= nil) then
		pointLabel:removeSelf()
		pointLabel = nil
	end
	pointLabel = display.newText("Points: "..points, 0,0, nil, 24);
	pointLabel.anchorX = 1
	pointLabel.anchorY = 1
	pointLabel.x = 320;
	pointLabel.y = 40;


	if (state == PLAYING) then
		timeLeft = roundTime - math.round((system.getTimer()-startRoundTime)/1000)
	end
	
	timeLabel.text = "Time: "..timeLeft
	if (timeLeft == 0 and state ~=PICKEM_DELAY and state ~= GAME_OVER) then
		roundOver()
	end
end
-----------------------------------------------------------------
function initMeters()
	pointLabel = display.newText("Points: "..points, 0,0, nil, 24);
	pointLabel.anchorX = 1
	pointLabel.anchorY = 1
	pointLabel.x = 320;
	pointLabel.y = 40;

	timeLabel = display.newText("Time: "..points, 0,0, nil, 24);
	timeLabel.anchorX = 1
	timeLabel.anchorY = 1
	timeLabel.x = 20;
	timeLabel.y = 40;

	levelLabel = display.newText("Level: "..level, 0,0, nil, 18);
	levelLabel.anchorX = 1
	levelLabel.anchorY = 1
	levelLabel.x = 480;
	levelLabel.y = truckY+50;

end
-----------------------------------------------------------------
function initGraphics()
	background = display.newImage("background.png",0,0)
	background.anchorX = 0
	background.anchorY = 0
	initLaneMarkers()
	initHouses()
	initBags()
	initMissedBags()
	truck = display.newImage("truck.png")
	truck.x = centerLine
	truck.y = truckY
	truck.name = "truck"
	initMeters()
end

-----------------------------------------------------------------
function updateHouses()
	for x = 0,numHouses do
		if (rightHouses[x].y >= 0) then
			rightHouses[x].y = rightHouses[x].y + speed
		end
		if (rightHouses[x].y > 720) then
			rightHouses[x].y = -100
		end
	end
	for x = 0,numHouses do
		if (leftHouses[x].y >= 0) then
			leftHouses[x].y = leftHouses[x].y + speed
		end
		if (leftHouses[x].y > 720) then
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
		if (rightBags[x].y > 720) then
			rightBags[x].y = -100
			bagMissed()
		end
	end
	for x = 0,numBags do
		if (leftBags[x].y >= 0) then
			leftBags[x].y = leftBags[x].y + speed
		end
		if (leftBags[x].y > 720) then
			leftBags[x].y = -100
			bagMissed()
		end
	end
end
-----------------------------------------------------------------
function placeNextRightHouse()
	logger.log("PlaceNextRightHouse")
	for x = 0,numHouses do
		if (rightHouses[x].y < 0) then
			rightHouses[x].y = 0
			rightBags[x].y = 15
			currentPoints = START_PRIZE
			break 
		end
	end
end
-----------------------------------------------------------------
function placeNextLeftHouse()
	logger.log("PlaceNextLeftHouse")
	for x = 0,numHouses do
		if (leftHouses[x].y < 0) then
			leftHouses[x].y = 0
			leftBags[x].y = 15
			currentPoints = START_PRIZE
			break 
		end
	end
end
-----------------------------------------------------------------
function bagHit()
	logger.log("BagHit")
--	points = points + 100 * level
	points = points + awardPoints
	bagsHit = bagsHit + 1
	local chingChannel = audio.play(chingSound)
	updateMeters()
	updateSaveState()
	onTarget = false
end
-----------------------------------------------------------------
function bagMissed()
	logger.log("BagMissed")
	if (totalMisses < maxMisses) then
		missedBags[totalMisses].alpha = 1.0
		missedBags[totalMisses]:setFillColor(255,0,0) 
		totalMisses = totalMisses+1
	end

	updateMeters()
	updateSaveState()
end
-----------------------------------------------------------------
function checkCollisions()
	stillOnTarget = false
	if (truck.x < leftBorder+10 ) then
		for x = 0,numBags do
			if (leftBags[x].y >= truckY and leftBags[x].y <= truckY+50) then
				leftBags[x].y = -100
				bagHit()
			elseif (leftBags[x].y >= 0 ) then
				if(onTarget == false) then
					awardPoints = currentPoints
					logger.log("OnTargetLeft,"..awardPoints)
				end
				onTarget = true
				stillOnTarget = true
			end
		end
	elseif (truck.x > rightBorder-10) then
		for x = 0,numBags do
			if (rightBags[x].y >= truckY and rightBags[x].y <= truckY+50) then
				rightBags[x].y = -100
				bagHit()
			elseif (rightBags[x].y >= 0 ) then
				if(onTarget == false) then
					awardPoints = currentPoints
					logger.log("OnTargetRight,"..awardPoints)
				end
				onTarget = true
				stillOnTarget = true
			end
		end
	end
	if (stillOnTarget == false) then
		if (onTarget == true) then
			logger.log("OffTarget")
		end
		onTarget = false
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
	logger.log("Truck,"..truck.x)

	updateLaneMarkerLocations()
	updateHouses()
	updateBags()
	
	framesSinceLastRandomHouse = framesSinceLastRandomHouse + 1
	if (framesSinceLastRandomHouse > timeForRandomHouse) then
		if (math.random(0,1) == 0) then
			placeNextRightHouse()
			framesSinceLastRandomHouse	= 0	
		else
			placeNextLeftHouse()
			framesSinceLastRandomHouse	= 0	
		end
	
	end
	checkCollisions()
	updateMeters()
end
-----------------------------------------------------------------
function frameUpdate(event)
	if (state == PLAYING) then
		playUpdate()
		currentPoints = currentPoints - pointDecrease
		if (currentPoints < 0) then
			currentPoints = 0
		end
	elseif (state == ROUND_OVER) then
		currentBonusValue = currentBonusValue - pointDecrease
		if (currentBonusValue <= 0) then
			currentBonusValue = 0
		end
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
function displayInstructions()

end

-----------------------------------------------------------------
function restoreState()

	showSplash(startGame)

end

logger.init()

initGraphics()
backgroundMusic = audio.loadStream("garbage.mp3")

pooperSound = audio.loadStream("pooper.mp3")
pickemExitSound = audio.loadStream("pickemexit.mp3")

chingSound = audio.loadStream("ching.mp3")
dinkSound = audio.loadStream("dink.mp3")
Runtime:addEventListener("touch", touchEventListener)
Runtime:addEventListener("axis", onAxisEvent)
Runtime:addEventListener("mouse", onMouseEvent)
Runtime:addEventListener( "key", onKeyEvent )

loggerLabel = display.newText("log:"..logger.getFilename(), 0,0, nil, 24);
loggerLabel.anchorX = 1
loggerLabel.anchorY = 1
loggerLabel.x = 900;
loggerLabel.y = 300;
displayInstructions()

restoreState()