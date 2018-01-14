PlaceTool = {}
PlaceTool.__index = PlaceTool

function PlaceTool:new()
	local tool = tool or {}
	setmetatable(tool, PlaceTool)

	tool.sprites = {
				 [1] = love.graphics.newImage("Tiles/WoodGround.png"),
		   		 [2] = love.graphics.newImage("Tiles/FrontWall.png"),
		   		 [3] = love.graphics.newImage("Tiles/LeftWall.png"),
		   		 [4] = love.graphics.newImage("Tiles/RightWall.png"),
		   		 [5] = love.graphics.newImage("Tiles/LeftWallCorner.png"),
		   		 [6] = love.graphics.newImage("Tiles/RightWallCorner.png"),
		   		 [7] = love.graphics.newImage("Tiles/Carpet.png"),
		   		 [8] = love.graphics.newImage("Tiles/Ground.png"),
		   		 [9] = love.graphics.newImage("Tiles/GroundCornerRight.png"),
		   		[10] = love.graphics.newImage("Tiles/GroundCornerLeft.png"),
		   		[11] = love.graphics.newImage("Tiles/Table.png"),
		   		[12] = love.graphics.newImage("Tiles/MiniCarpet.png"),
		   		[13] = love.graphics.newImage("Tiles/BigCarpet.png"),
		   		[14] = love.graphics.newImage("Tiles/Decoration1.png"),
		   		[15] = love.graphics.newImage("Tiles/Decoration2.png"),
		   		[16] = love.graphics.newImage("Tiles/Decoration3.png"),
		   		[17] = love.graphics.newImage("Tiles/Decoration4.png"),
		   		[18] = love.graphics.newImage("Tiles/Decoration5.png"),
		   		[19] = love.graphics.newImage("Tiles/Decoration6.png"),
		   		[20] = love.graphics.newImage("Tiles/Chair1.png"),
		   		[21] = love.graphics.newImage("Tiles/Chair2.png"),
		   		[22] = love.graphics.newImage("Tiles/Wardrobe.png"),
		   		[23] = love.graphics.newImage("Tiles/WardrobeRight.png"),
		   		[24] = love.graphics.newImage("Tiles/WardrobeLeft.png"),
		   		[25] = love.graphics.newImage("Tiles/ChairRight.png"),
		   		[26] = love.graphics.newImage("Tiles/ChairLeft.png"),
		   		[27] = love.graphics.newImage("Tiles/Picture1.png"),
		   		[28] = love.graphics.newImage("Tiles/Picture2.png"),
		   		[29] = love.graphics.newImage("Tiles/Picture3.png")
			   }
	tool.favorites = {
				[1] = {num = 0, key = "Z"},
				[2] = {num = 0, key = "X"},
				[3] = {num = 0, key = "C"},
				[4] = {num = 0, key = "V"}
			   }
	tool.scale = 5
	tool.gridSize = 16
	tool.adjPosX = 0
	tool.adjPosY = 0
	tool.posX = 0
	tool.posY = 0
	tool.interval = tool.sprites[1]:getWidth()*tool.scale
	tool.currentImage = 1
	tool.zoom = 1
	tool.spritesTableSize = table.getn(tool.sprites)
	tool.toolBar = 0
	tool.info = false
	tool.grid = true
	tool.favoritesSelect = false
	tool.file = io.open("location/tiles.txt", "r")
	tool.mapPositions = tool:getMapPositions()

	return tool
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
	self:makeFavorite(key)
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
  local file = io.open("location/tiles.txt", "a")
  print(io.output(file))
  io.flush()
  io.write("\n"..self.adjPosX..","..self.adjPosY..","..self.currentImage)
  io.close()
end --PlaceTool:writeLocation

function PlaceTool:getMapPositions()
	local positions = {}
	for line in self.file:lines() do
		local lineX, lineY, lineSprite = "","",""
		local separatorCnt = 0
		if(line ~= "")then
			for ch in line:gmatch"." do
			    if(ch ~= ",")then    
			        if(separatorCnt == 0)then
			            lineX = lineX..ch
			        end
			        if(separatorCnt == 1)then
			            lineY = lineY..ch
			        end
			        if(separatorCnt == 2)then
			            lineSprite = lineSprite..ch
			        end
			    else
			        separatorCnt = separatorCnt+1
			    end
			end
			position = {x = lineX, y = lineY, sprite = lineSprite} 
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

function PlaceTool:deleteTile(key)
	local x, y = self.x, self.y	
	if(key == "d")then
		local readFile = io.open("location/tiles.txt", "r")

		fileText = readFile:read('*a')
		readFile:close()
		print(self.adjPosX..","..self.adjPosY..",%d*")
		fileText = fileText:gsub("\n"..self.adjPosX..","..self.adjPosY..",%d+", '\n')
		fileText = fileText:gsub("\n+", '\n')
		local file = io.open("location/tiles.txt", "w+")
		print(io.output(file))
		io.flush()
		io.write(fileText)
		io.close()
		self:updateMap()
	end
end --PlaceTool:deleteTile

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
		
				love.graphics.draw(self.sprites[i+self.toolBar], x, y, 0, 3/self.zoom, 3/self.zoom)
				love.graphics.rectangle("line", x, y, self.sprites[i+self.toolBar]:getWidth()*3/self.zoom, self.sprites[i+self.toolBar]:getHeight()*3/self.zoom)
				love.graphics.print(i, x, y, 0, 1/self.zoom)

				prevPos = prevPos+self.sprites[i+self.toolBar]:getWidth()
		end
	end

	local prevPos = self.sprites[1]:getWidth()
	for i = 1,4 do
		if(self.sprites[self.favorites[i].num] ~= nil)then
				local x = (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)+prevPos*3/self.zoom)-self.sprites[1]:getWidth()*3/self.zoom
				local y = self.adjPosY+(love.graphics.getHeight()/2/self.zoom)-self.sprites[self.favorites[i].num]:getHeight()*3/self.zoom
		
				love.graphics.draw(self.sprites[self.favorites[i].num], x, y, 0, 3/self.zoom, 3/self.zoom)
				love.graphics.rectangle("line", x, y, self.sprites[self.favorites[i].num]:getWidth()*3/self.zoom, self.sprites[self.favorites[i].num]:getHeight()*3/self.zoom)
				love.graphics.print(self.favorites[i].key, x, y, 0, 1/self.zoom)

				prevPos = prevPos+self.sprites[self.favorites[i].num]:getWidth()
		end
	end
end--PlaceTool:drawToolbars

function PlaceTool:drawUI()
	love.graphics.setColor(255, 0, 0)
	love.graphics.line(0, 0, self.adjPosX+love.graphics.getWidth()/2/self.zoom, 0)
	love.graphics.line(0, 0, 0, self.adjPosY+love.graphics.getHeight()/2/self.zoom)

	love.graphics.setColor(0, 255, 0)
	if(self.favoritesSelect)then
		love.graphics.print("Pressione Z, X, C ou V para marcar o sprite atual como favorito.", self.adjPosX-love.graphics.getWidth()/4/self.zoom, self.adjPosY,0,1/self.zoom)
	end
	
	if(self.info)then
		love.graphics.setColor(255, 255, 255)
		love.graphics.print("\nUse as setas do teclado para mover o marcador"..
							"\n1 a 9 - Muda o sprite para o sprite de numero correspondente a barra superior"..
							"\nQ - Grava as cordenada no arquivo tiles.txt na pasta location"..
							"\nESC - Sair do editor"..
							"\nE - Muda o para o proximo sprite"..
							"\nW - Muda para o sprite anterior"..
							"\nD - Deleta o tile atual"..
							"\n+ - Aumenta o zoom"..
							"\n- - Diminui o zoom"..
							"\n> - Proxima barra de tiles"..
							"\n< - Barra de tiles anterior"..
							"\nI - Mostra/Esconde controles do teclado"..
							"\nG - Mostra/Esconde a grade"..
							"\nF - Adiciona o sprite atual como favorito", (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)), self.adjPosY-(love.graphics.getHeight()/2/self.zoom)+self.sprites[1]:getWidth()*3/self.zoom,0,1/self.zoom)
	else
		love.graphics.setColor(255, 255, 255)
		love.graphics.print("Pressione \"i\" para mostrar comandos do teclado.", (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)), self.adjPosY-(love.graphics.getHeight()/2/self.zoom)+self.sprites[1]:getWidth()*3/self.zoom,0,1/self.zoom)
	end

end--PlaceTool:drawUI

function PlaceTool:makeFavorite(key)
	if(key == "f")then
		self.favoritesSelect = true
	end

	if(key == "z")then
		if(self.favoritesSelect)then
			self.favoritesSelect = false
			self.favorites[1].num = self.currentImage
		else
			if(self.favorites[1].num > 0)then
				self.currentImage = self.favorites[1].num
			end
		end
	end
	if(key == "x")then
		if(self.favoritesSelect)then
			self.favoritesSelect = false
			self.favorites[2].num = self.currentImage
		else
			if(self.favorites[2].num > 0)then
				self.currentImage = self.favorites[2].num
			end
		end
	end
	if(key == "c")then
		if(self.favoritesSelect)then
			self.favoritesSelect = false
			self.favorites[3].num = self.currentImage
		else
			if(self.favorites[3].num > 0)then
				self.currentImage = self.favorites[3].num
			end
		end
	end
	if(key == "v")then
		if(self.favoritesSelect)then
			self.favoritesSelect = false
			self.favorites[4].num = self.currentImage
		else
			if(self.favorites[4].num > 0)then
				self.currentImage = self.favorites[4].num
			end
		end
	end

end--PlaceTool:makeFavorite

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
		self.toolBar = self.toolBar+9
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
		self.zoom = self.zoom+0.1
	end
	if(key == "-")then
		self.zoom = self.zoom-0.1
		if(self.zoom < 0.2)then
			self.zoom = 0.1
		end
	end
end--PlaceTool:changeZoom

function PlaceTool:writeTile(key)
	if(key == "q")then
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

function PlaceTool:updateMap()
	self.file = io.open("location/tiles.txt", "r")
	self.mapPositions = self:getMapPositions()
end--PlaceTool:updateMap

function PlaceTool:quitEditor(key)
	if(key == "escape")then
		love.event.quit()
	end
end--PlaceTool:quitEditor

function PlaceTool:drawGrid()
	if(self.grid)then
		love.graphics.setColor(255, 255, 255, 100)
		local prevPos = self.adjPosX-love.graphics.getWidth()*self.gridSize

		while prevPos <  love.graphics.getWidth()/self.zoom do
			love.graphics.line(self.adjPosX - love.graphics.getWidth()/2+prevPos, self.adjPosY - love.graphics.getHeight()/2/self.zoom, self.adjPosX - love.graphics.getWidth()/2+prevPos, self.adjPosY + love.graphics.getHeight()/2/self.zoom)
			prevPos = prevPos+self.gridSize*self.scale
		end

		local prevPos = self.adjPosY-love.graphics.getWidth()*self.gridSize+60
		while prevPos <  love.graphics.getHeight()/self.zoom do
			love.graphics.line(self.adjPosX-love.graphics.getWidth()/2/self.zoom, self.adjPosY-love.graphics.getHeight()/2+prevPos,self.adjPosX+love.graphics.getWidth()/2/self.zoom, self.adjPosY-love.graphics.getHeight()/2+prevPos)
			prevPos = prevPos+self.gridSize*self.scale
		end
	end
end--PlaceTool:drawGrid

function PlaceTool:showGrid(key)
	if(key == "g")then
		if(self.grid)then
			self.grid = false
		else
			self.grid = true
		end
	end
end--PlaceTool:showGrid