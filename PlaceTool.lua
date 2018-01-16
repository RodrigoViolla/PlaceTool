PlaceTool = {}
PlaceTool.__index = PlaceTool

function PlaceTool:new()
	local placeTool = placeTool or {}
	setmetatable(placeTool, PlaceTool)
	
	placeTool.favorites = 
	{
		[1] = {num = 0, key = "Z"},
		[2] = {num = 0, key = "X"},
		[3] = {num = 0, key = "C"},
		[4] = {num = 0, key = "V"}
	}	
	placeTool.scale = 5
	placeTool.path = love.filesystem.getSource()
	placeTool.sprites = {}
	placeTool:checkTilesOrder()
	placeTool:loadSprites()
	placeTool.spritesTableSize = table.getn(placeTool.sprites)
	placeTool.gridSize = 16
	placeTool.interval = placeTool.gridSize*placeTool.scale
	placeTool.mapPositions = placeTool:getMapPositions()
	placeTool.adjPosX = 0
	placeTool.adjPosY = 0
	placeTool.posX = 0
	placeTool.posY = 0
	placeTool.currentImage = 1
	placeTool.zoom = 1
	placeTool.toolBar = 0
	placeTool.info = false
	placeTool.grid = true
	placeTool.favoritesSelect = false

	return placeTool
end --PlaceTool:new

function PlaceTool:update(dt)
	self:moveTool(dt)
end --PlaceTool:update

function PlaceTool:draw()
	self:manageCamera()
	self:drawMap()
	self:drawGrid()
	self:drawTool()
	self:drawToolbars()
	self:drawUI()
end --PlaceTool:draw

function PlaceTool:keypressed(key)
	self:manageFavotites(key)
	self:showInfo(key)
	self:changeToolbar(key)
	self:changeTileImage(key)
	self:changeZoom(key)
	self:writeTile(key)
	self:deleteTile(key)
	self:quitEditor(key)
	self:showGrid(key)
end --PlaceTool:keypressed

function PlaceTool:writeLocation()
  local file = io.open(self.path.."/location/tiles.txt", "a")
  print(io.output(file))
  io.flush()
  io.write("\n"..self.adjPosX..","..self.adjPosY..","..self.currentImage)
  io.close()
end --PlaceTool:writeLocation

function PlaceTool:getMapPositions()
	local file = io.open(self.path.."/location/tiles.txt", "r")
	local positions = {}
	for line in file:lines() do
		if(line ~= "")then
			local linePositions = {}
			for num in line:gmatch"%d+" do
					 table.insert(linePositions, num) 
			end
			position = {x = linePositions[1], y = linePositions[2], sprite = linePositions[3]} 
			table.insert(positions, position)
		end
	end
	
	return positions
end --PlaceTool:getMapPositions

function PlaceTool:changeImg(asc)
	if(asc)then
		self.currentImage = self.currentImage+1
	else
		self.currentImage = self.currentImage-1
	end

	if(self.currentImage > self.spritesTableSize)then
		self.currentImage = 1
	end
	if(self.currentImage < 1)then
		self.currentImage = self.spritesTableSize
	end
end --PlaceTool:changeImg

function PlaceTool:moveTool(dt)
	if(love.keyboard.isDown("right"))then
		self.posX = self.posX+dt*500		
		if(self.posX > self.adjPosX+self.interval)then
			self.adjPosX = self.adjPosX+self.interval;
		end
	end

	if(love.keyboard.isDown("left"))then
		if(self.adjPosX > 0)then
			self.posX = self.posX-dt*500
		end
		if(self.posX < self.adjPosX-self.interval)then
			self.adjPosX = self.adjPosX-self.interval;
		end
	end

	if(love.keyboard.isDown("up"))then
		if(self.adjPosY > 0)then
			self.posY = self.posY-dt*500
		end
		if(self.posY < self.adjPosY-self.interval)then
			self.adjPosY = self.adjPosY-self.interval;
		end
	end

	if(love.keyboard.isDown("down"))then
		self.posY = self.posY+dt*500
		if(self.posY > self.adjPosY+self.interval)then
			self.adjPosY = self.adjPosY+self.interval;
		end
	end
end--PlaceTool:moveTool

function PlaceTool:manageCamera()
	love.graphics.scale(self.zoom, self.zoom)
	love.graphics.translate(-self.adjPosX+love.graphics.getWidth()/(2*self.zoom), -self.adjPosY+love.graphics.getHeight()/(2*self.zoom))
end--PlaceTool:manageCamera

function PlaceTool:drawMap()
	for n,position in ipairs(self.mapPositions) do
		love.graphics.setColor(255, 255, 255)
		local imgPos = position.sprite*1
		love.graphics.draw(self.sprites[imgPos], position.x, position.y, 0, self.scale, self.scale)
	end
end--PlaceTool:drawMap

function PlaceTool:drawTool()
	love.graphics.setColor(0, 0, 255)
	love.graphics.rectangle('line', self.adjPosX, self.adjPosY, self.sprites[self.currentImage]:getWidth()*self.scale, self.sprites[self.currentImage]:getHeight()*self.scale)
	love.graphics.setColor(255, 255, 255, 150)
	love.graphics.draw(self.sprites[self.currentImage], self.adjPosX, self.adjPosY, 0, 5, 5)
end--PlaceTool:drawTool

function PlaceTool:drawToolbars()
	local prevPos = self.sprites[1]:getWidth()
	for i = 1,9 do
		if(self.sprites[i+self.toolBar] ~= nil)then
				local x = (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)+prevPos*3/self.zoom)-self.sprites[1]:getWidth()*3/self.zoom
				local y = self.adjPosY-(love.graphics.getHeight()/2/self.zoom)
				
				love.graphics.setColor(255, 255, 255)
				love.graphics.draw(self.sprites[i+self.toolBar], x, y, 0, 3/self.zoom, 3/self.zoom)
				love.graphics.setColor(0, 255, 0, 230)
				love.graphics.rectangle("line", x, y, self.sprites[i+self.toolBar]:getWidth()*3/self.zoom, self.sprites[i+self.toolBar]:getHeight()*3/self.zoom)
				love.graphics.setColor(0, 255, 0, 200)
				love.graphics.print(i, x, y, 0, 1/self.zoom)

				prevPos = prevPos+self.sprites[i+self.toolBar]:getWidth()
		end
	end

	local prevPos = self.sprites[1]:getWidth()
	for i = 1,4 do
		if(self.sprites[self.favorites[i].num] ~= nil)then
				local x = (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)+prevPos*3/self.zoom)-self.sprites[1]:getWidth()*3/self.zoom
				local y = self.adjPosY+(love.graphics.getHeight()/2/self.zoom)-self.sprites[self.favorites[i].num]:getHeight()*3/self.zoom
		
				love.graphics.setColor(255, 255, 255)
				love.graphics.draw(self.sprites[self.favorites[i].num], x, y, 0, 3/self.zoom, 3/self.zoom)
				love.graphics.setColor(0, 255, 0, 230)
				love.graphics.rectangle("line", x, y, self.sprites[self.favorites[i].num]:getWidth()*3/self.zoom, self.sprites[self.favorites[i].num]:getHeight()*3/self.zoom)
				love.graphics.setColor(0, 255, 0, 200)
				love.graphics.print(self.favorites[i].key, x, y, 0, 1/self.zoom)

				prevPos = prevPos+self.sprites[self.favorites[i].num]:getWidth()
		end
	end
end--PlaceTool:drawToolbars

function PlaceTool:drawUI()
	love.graphics.setColor(0, 255, 0)
	if(self.favoritesSelect)then
		love.graphics.print("Pressione Z, X, C ou V para marcar o sprite atual como favorito.", self.adjPosX-love.graphics.getWidth()/4/self.zoom, self.adjPosY,0,1/self.zoom)
	end

	local toolBarHeight = 0
	for i = 1,9 do
		if(self.sprites[i+self.toolBar] ~= nil)then
			if(self.sprites[i+self.toolBar]:getHeight() > toolBarHeight)then
				toolBarHeight = self.sprites[i+self.toolBar]:getHeight()
			end
		end
	end
	if(self.info)then
		local infoText = "\nUse as setas do teclado para mover o marcador"..
						 "\n1 a 9 - Muda o sprite para o sprite de numero correspondente a barra superior"..
						 "\nBarra de espaco - Grava as cordenadas no arquivo tiles.txt na pasta location"..
						 "\nESC - Sair do editor"..
						 "\nE - Muda para o proximo sprite"..
						 "\nW - Muda para o sprite anterior"..
						 "\nD - Deleta o tile atual"..
						 "\n+ - Aumenta o zoom"..
						 "\n- - Diminui o zoom"..
						 "\n> - Proxima barra de tiles"..
						 "\n< - Barra de tiles anterior"..
						 "\nI - Mostra/Esconde controles do teclado"..
						 "\nG - Mostra/Esconde a grade"..
						 "\nF - Adiciona o sprite atual como favorito"
		love.graphics.setColor(255, 255, 255)
		love.graphics.print(infoText, (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)), self.adjPosY-(love.graphics.getHeight()/2/self.zoom)+toolBarHeight*3/self.zoom,0,1/self.zoom)
	else
		love.graphics.setColor(255, 255, 255)
		love.graphics.print("\nPressione \"i\" para mostrar comandos do teclado.", (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)), self.adjPosY-(love.graphics.getHeight()/2/self.zoom)+toolBarHeight*3/self.zoom,0,1/self.zoom)
	end
end--PlaceTool:drawUI

function PlaceTool:deleteTile(key)
	local x, y = self.x, self.y	
	if(key == "d")then
		local readFile = io.open(self.path.."/location/tiles.txt", "r")

		fileText = readFile:read('*a')
		readFile:close()
		print(self.adjPosX..","..self.adjPosY..",%d*")
		fileText = fileText:gsub("\n"..self.adjPosX..","..self.adjPosY..",%d+", '\n')
		fileText = fileText:gsub("\n+", '\n')
		local file = io.open(self.path.."/location/tiles.txt", "w+")
		print(io.output(file))
		io.flush()
		io.write(fileText)
		io.close()
		self:updateMap()
	end
end --PlaceTool:deleteTile

function PlaceTool:manageFavotites(key)
	if(key == "f")then
		self.favoritesSelect = true
	end

	if(key == "z")then
		self:makeFavorite(1)
	end

	if(key == "x")then
		self:makeFavorite(2)
	end

	if(key == "c")then
		self:makeFavorite(3)
	end

	if(key == "v")then
		self:makeFavorite(4)
	end
end--PlaceTool:manageFavotites

function PlaceTool:showInfo(key)
	if(key == "i")then
		if(self.info)then
			self.info = false
		else
			self.info = true
		end
	end
end--PlaceTool:showInfo

function PlaceTool:changeToolbar(key)
	if(key == ".")then
		if(self.spritesTableSize >= self.toolBar+9)then
			self.toolBar = self.toolBar+9
		end
	end

	if(key == ",")then
		self.toolBar = self.toolBar-9
		if(self.toolBar < 0)then
			self.toolBar = 0
		end
	end	
end--PlaceTool:changeToolbar

function PlaceTool:changeZoom(key)
	if(key == "=")then
		if(self.zoom < 1)then
			self.zoom = self.zoom+0.1
		end
	end

	if(key == "-")then		
		if(self.zoom > 0.2)then
			self.zoom = self.zoom-0.1
		end
	end
end--PlaceTool:changeZoom

function PlaceTool:writeTile(key)
	if(key == " ")then
		self:writeLocation()
		self:updateMap()
	end
end--PlaceTool:writeTile

function PlaceTool:changeTileImage(key)
	if(key == "e")then
		self:changeImg(true)
	end

	if(key == "w")then
		self:changeImg(false)
	end
	if(string.find(key, "%d") ~= nil)then
		if(self.sprites[string.gsub(key, "%a+", '')+self.toolBar] ~= nil)then
				self.currentImage = string.gsub(key, "%a+", '')+self.toolBar
		end
	end
end--PlaceTool:changeTileImage

function PlaceTool:quitEditor(key)
	if(key == "escape")then
		love.event.quit()
	end
end--PlaceTool:quitEditor

function PlaceTool:showGrid(key)
	if(key == "g")then
		if(self.grid)then
			self.grid = false
		else
			self.grid = true
		end
	end
end--PlaceTool:showGrid

function PlaceTool:updateMap()
	self.mapPositions = self:getMapPositions()
end--PlaceTool:updateMap

function PlaceTool:drawGrid()
	if(self.grid)then
		love.graphics.setColor(255, 255, 255, 100)

		local prevPos = love.graphics.getWidth()/2
		while prevPos <  love.graphics.getWidth()/self.zoom do
			love.graphics.line(self.adjPosX - love.graphics.getWidth()/2+prevPos, self.adjPosY - love.graphics.getHeight()/2/self.zoom, self.adjPosX - love.graphics.getWidth()/2+prevPos, self.adjPosY + love.graphics.getHeight()/2/self.zoom)
			prevPos = prevPos+self.gridSize*self.scale
		end
		local prevPos = love.graphics.getWidth()/2
		while prevPos >  -love.graphics.getWidth()/self.zoom do
			love.graphics.line(self.adjPosX - love.graphics.getWidth()/2+prevPos, self.adjPosY - love.graphics.getHeight()/2/self.zoom, self.adjPosX - love.graphics.getWidth()/2+prevPos, self.adjPosY + love.graphics.getHeight()/2/self.zoom)
			prevPos = prevPos-self.gridSize*self.scale
		end

		local prevPos = love.graphics.getHeight()/2
		while prevPos <  love.graphics.getHeight()/self.zoom do
			love.graphics.line(self.adjPosX-love.graphics.getWidth()/2/self.zoom, self.adjPosY-love.graphics.getHeight()/2+prevPos,self.adjPosX+love.graphics.getWidth()/2/self.zoom, self.adjPosY-love.graphics.getHeight()/2+prevPos)
			prevPos = prevPos+self.gridSize*self.scale
		end
		local prevPos = love.graphics.getHeight()/2
		while prevPos >  -love.graphics.getHeight()/self.zoom do
			love.graphics.line(self.adjPosX-love.graphics.getWidth()/2/self.zoom, self.adjPosY-love.graphics.getHeight()/2+prevPos,self.adjPosX+love.graphics.getWidth()/2/self.zoom, self.adjPosY-love.graphics.getHeight()/2+prevPos)
			prevPos = prevPos-self.gridSize*self.scale
		end
	end
	love.graphics.setColor(255, 0, 0)
	love.graphics.line(0, 0, self.adjPosX+love.graphics.getWidth()/2/self.zoom, 0)
	love.graphics.line(0, 0, 0, self.adjPosY+love.graphics.getHeight()/2/self.zoom)
end--PlaceTool:drawGrid

function PlaceTool:checkTilesOrder()
	local images = love.filesystem.getDirectoryItems("tiles")
	local tilesOrderRead = io.open(self.path.."/location/tilesOrder.txt", "r")
	local tilesOrderWrite = io.open(self.path.."/location/tilesOrder.txt", "a")
	local fileText = tilesOrderRead:read('*a')
	local isInList = nil

	for cnt, tile in ipairs(images)do
		isInList = fileText:find(tile.."+");

		if(isInList == nil)then
			print(io.output(tilesOrderWrite))
	  		io.flush()
	  		io.write(tile.."\n")  
		end
	end
	io.close()
end--PlaceTool:checkTilesOrder

function PlaceTool:loadSprites()
	local tilesOrder = io.open(self.path.."/location/tilesOrder.txt", "r")
	local cnt = 1
	for line in tilesOrder:lines()do		
		if(love.filesystem.exists("tiles/"..line))then
			self.sprites[cnt] = love.graphics.newImage("tiles/"..line)			
		else
			self.sprites[cnt] = love.graphics.newImage("icons/missingTile.png")
		end
		cnt = cnt+1
	end
end--PlaceTool:loadSprites

function PlaceTool:makeFavorite(favorite)
	if(self.favoritesSelect)then
		self.favoritesSelect = false
		self.favorites[favorite].num = self.currentImage
	else
		if(self.favorites[favorite].num > 0)then
			self.currentImage = self.favorites[favorite].num
		end
	end
end