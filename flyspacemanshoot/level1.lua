-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------


local composer = require( "composer" )
local scene = composer.newScene()

-- include Corona's "physics" library
local physics = require "physics"
physics.start(); physics.pause()


stars = {}
numStars = 250
bullets = {}
enemies = {}
MAX_BULLETS = 5
score = 0
energy = 100
bulletCost = 2
energyDrain = 0.01

sunTouched = nil
sun = nil

--------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW = display.contentWidth, display.contentHeight, display.contentWidth*0.5

function scene:create( event )

	-- Called when the scene's view does not exist.
	-- 
	-- INSERT code here to initialize the scene
	-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.

	local sceneGroup = self.view

	-- create a grey rectangle as the backdrop
	local background = display.newRect( 0, 0, screenW, screenH )
	background.anchorX = 0
	background.anchorY = 0
	background:setFillColor( 0 )
	

--[[
	-- make a crate (off-screen), position it, and rotate slightly
	local crate = display.newImageRect( "crate.png", 90, 90 )
	crate.x, crate.y = 160, -100
	crate.rotation = 15
	
	-- add physics to the crate
	physics.addBody( crate, { density=1.0, friction=0.3, bounce=0.3 } )
	
	-- create a grass object and add physics (with custom shape)
	local grass = display.newImageRect( "grass.png", screenW, 82 )
	grass.anchorX = 0
	grass.anchorY = 1
	grass.x, grass.y = 0, display.contentHeight
	
	-- define a shape that's slightly shorter than image bounds (set draw mode to "hybrid" or "debug" to see)
	local grassShape = { -halfW,-34, halfW,-34, halfW,34, -halfW,34 }
	physics.addBody( grass, "static", { friction=0.3, shape=grassShape } )
	
	-- all display objects must be inserted into group
	sceneGroup:insert( grass)
	sceneGroup:insert( crate )

--]]
	for i = 1,numStars do
		num = math.random( 50 )
		if (num < 40) then
			radius = .5
		else 
			radius = 1.5
		end
		
		x = math.random(500)
		y = math.random(400)
		
		speed = math.random(5)
		
		
		local newStar = display.newCircle( x, y, radius )
		newStar.speed = speed
		newStar:setFillColor(1)
		table.insert(stars,newStar)
	end

	guy = display.newImage("astronaut.png")
	guy.x = 50
	guy.y = 100
	guy.speed = 0
	guy.name = "guy"

	physics.addBody( guy )
	guy.isFixedRotation = true



	sceneGroup:insert( background )
end

function updateEnergy()
	if (energy < 0) then
		energy = 0
	end
	if (energy > 100) then
		energy = 100
	end
	energyText.text = "Energy: " .. math.floor((energy*10) / 10)
end

function updateScore()
	scoreText.text = score
end

function updateStars()
	for k,v in pairs(stars) do 
		v.x = v.x - v.speed
		if (v.x < 10) then
			v.x = v.x + 500
			v.y = math.random(400)
		end
	end
--table.insert(stars,newStar)
end


function updateGuy()
	guy.y = guy.y + guy.speed
end

function updateBullets()
	for k,v in pairs(bullets) do 
		v.x = v.x + v.speed
		if (v.x > screenW+20) then
			v:removeSelf()
			v=nil
			table.remove(bullets,k)
		end
	end
end

function addEnergy()
	print ("AddEnergy!!")
	energy = energy + 1 
	sunTouched = nil
end

function sunTouch(event)
	print ("Sun touched event!!")
	if (sunTouched == nil) then
		print ("Calling add energy")
		sunTouched = timer.performWithDelay (100,addEnergy)
	end
	return true
end

function updateSun()
	if (math.random(100) == 1) then
		if (sun == nil) then
			print ("Creating new sun")
			sun = display.newImage("sun.png")
			sun.x = screenW + 50
			sun.y = math.random(50,300)
			sun.speed = -1 * math.random(2,5)
			sun.name="sun"
			sun.touch = sunTouch
			sun:addEventListener("touch", sun)
		end
	end
	
	if (sun ~= nil) then
		print ("Sun: " .. sun.x)
		sun.x = sun.x + sun.speed
		if (sun.x < -50) then
			sun:removeSelf()
			sun = nil
		end
	end
end

function updateEnemies()
	for k,v in pairs(enemies) do 
		v.x = v.x + v.speed
		if (v.x < -40) then
			v.x = screenW+30
			v.speed = v.speed + 2
		end
		if (v.alpha <=0.0) then
			v:removeSelf()
			table.remove(enemies, k)
		end
	end
	if (math.random(100) == 1) then
		local e = display.newImage("enemy1bw.png")
		e.x = screenW + 50
		e.y = math.random(50,300)
		e.speed = -1 * math.random(1,3)
		e.name="enemy"
		table.insert(enemies,e)
		physics.addBody( e, "static" )

	end

end


function enterFrame(event)
	energy = energy - energyDrain
	updateStars()
	updateGuy()
	updateBullets()
	updateEnemies()
	updateEnergy()
	updateSun()

end

function fireBullet()
	if (#bullets < MAX_BULLETS and energy > bulletCost) then
		local b = display.newImage("bullet1bw.png")
		b.x = guy.x + 10
		b.y = guy.y - 10
		b.speed = 5
		b.name="bullet"
		table.insert(bullets,b)
		physics.addBody( b,  { density=1.0, friction=0.3, bounce=0.3 } )
		b.isFixedRotation=true

		transition.to( guy, { time=100, x=45, onComplete=nil } )
		transition.to( guy, { time=200, x=50,delay=100, onComplete=nil } )
		audio.play( laserSound )
		energy = energy - bulletCost
		
	end
end



function handleTouch(event)
	if (event.x < screenW/2) then
		if (event.phase == "began") then
			if (event.y < screenH/2) then
				guy.speed = -2
			else
				guy.speed = 2
			end
		elseif (event.phase == "ended") then
			guy.speed = 0
		end
	else
		if (event.phase == "began") then
			fireBullet()
		end
	end
end

function processBulletEnemyCollision(event)
		audio.play(shiphit1Sound)
		score = score + 100
		updateScore()
		if (event.object1.name=="bullet") then
			for k,v in pairs(bullets) do 
				if (v==event.object1) then
					v:removeSelf()
					table.remove(bullets,k)
				end
			end
		elseif (event.object2.name=="bullet") then
			for k,v in pairs(bullets) do 
				if (v==event.object2) then
					v:removeSelf()
					table.remove(bullets,k)
				end
			end
		end


		if (event.object1.name=="enemy") then
			for k,v in pairs(enemies) do 
				if (v==event.object1) then
					transition.to( v, { time=250, alpha=0.0,xScale = 0, yScale=0, onComplete=nil } )
					physics.removeBody(v)
				end
			end
		elseif (event.object2.name=="enemy") then
			for k,v in pairs(enemies) do 
				if (v==event.object2) then
					transition.to( v, { time=250, alpha=0.0,xScale = 0, yScale=0, onComplete=nil } )
					physics.removeBody(v)
				end
			end
		end


end


function handleCollision(event)
	print ("Collision" .. event.object1.name)
	if (isCollision(event,"bullet", "enemy")) then
		processBulletEnemyCollision(event)
	end
	if (isCollision(event,"enemy","guy")) then
		print ("Game Over")
		composer.gotoScene( "menu" )
	end
end


function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		-- 
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
		
		score = 0
		energy = 100
		bulletCost = 2
		energyDrain = 0.01

		sunTouched = nil
		sun = nil

		
		physics.start()
		physics.setGravity( 0, 0 )
		Runtime:addEventListener("enterFrame", enterFrame)
		Runtime:addEventListener("touch", handleTouch)
		Runtime:addEventListener("collision", handleCollision)
		backgroundMusic = audio.loadStream( "backgroundmusic.mp3" )
		backgroundMusicChannel = audio.play( backgroundMusic, {loops=-1, fadein=1000 } )
		laserSound = audio.loadSound( "gun1.mp3" )
		shiphit1Sound = audio.loadSound( "shiphit.mp3" )
		scoreText = display.newText("0", screenW-30,screenH-20, native.systemFont, 24)
		energyText = display.newText("Energy: 0", screenW/2-50,screenH-20, native.systemFont, 24)
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	
	local phase = event.phase
	
	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
		for k,v in pairs(enemies) do 
			v:removeSelf()
			table.remove(enemies, k)
		end
		if (sun ~=nil) then
			sun:removeSelf()
			sun = nil;
		end

		physics.stop()
	elseif phase == "did" then
		-- Called when the scene is now off screen
		
		Runtime:removeEventListener("enterFrame", enterFrame)
		Runtime:removeEventListener("touch", handleTouch)
		Runtime:removeEventListener("collision", handleCollision)
		audio.stop(backgroundMusicChannel)
		scoreText:removeSelf()
		energyText:removeSelf()
		for k,v in pairs(enemies) do 
			v:removeSelf()
			table.remove(enemies, k)
		end

	end	
	
end

function scene:destroy( event )

	-- Called prior to the removal of scene's "view" (sceneGroup)
	-- 
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	local sceneGroup = self.view
	
	
	
	package.loaded[physics] = nil
	physics = nil
end


function isCollision(event,name1,name2)
	if ((event.object1.name == name1 and event.object2.name == name2) or 
		(event.object1.name == name2 and event.object2.name == name1)) then
		
		return true
	end
	return false
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene