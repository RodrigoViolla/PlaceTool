require "PlaceTool"

function love.load()	
	love.graphics.setDefaultFilter("nearest", "nearest")
	world = love.physics.newWorld(0, 0)
	tool = PlaceTool:new(world)		
end

function love.update(dt)
	tool:update(dt)
end

function love.draw()	
	tool:draw()
end

function love.keypressed(key)
	tool:keypressed(key)	
end

function love.quit()
	tool:quit()
end
