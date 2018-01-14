require "PlaceTool"

function love.load()	
	love.graphics.setDefaultFilter("nearest", "nearest")
	tool = PlaceTool:new()		
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

