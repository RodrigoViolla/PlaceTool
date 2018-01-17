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
		[4] = {num = 0, key = "V"},
		[5] = {num = 0, key = "B"},
		[6] = {num = 0, key = "N"},
		[7] = {num = 0, key = "M"}
	}	
	placeTool.speed = 1000
	placeTool.scale = 5
	placeTool.path = love.filesystem.getSource()
	placeTool.infoText = placeTool:loadInfo()
	placeTool.sprites = {}
	placeTool:checkTilesOrder()
	placeTool:loadSprites()
	placeTool:loadFavorites()
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
	self:changeTile(key)
	self:changeZoom(key)
	self:writeTile(key)
	self:deleteTile(key)
	self:quitEditor(key)
	self:showGrid(key)
end --PlaceTool:keypressed

function PlaceTool:quit()
	self:saveFavorites()
end--PlaceTool:quit

--Grava as cordenadas do tile no arquivo tiles.txt
function PlaceTool:writeLocation()
  local file = io.open(self.path.."/files/tiles.txt", "a")
  print(io.output(file))
  io.flush()
  io.write("\n"..self.adjPosX..","..self.adjPosY..","..self.currentImage)
  io.close()
end --PlaceTool:writeLocation

--Carrega as cordenadas dos tiles do arquivo tiles.txt e guarda em uma table
function PlaceTool:getMapPositions()
	local file = io.open(self.path.."/files/tiles.txt", "r")
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

--Muda o contador da imagem do tile atual
function PlaceTool:changeImg(asc)
	if(asc)then
		self.currentImage = self.currentImage+1
	else
		self.currentImage = self.currentImage-1
	end

	if(self.currentImage > self.spritesTableSize)then
		self.currentImage = self.spritesTableSize
	end
	if(self.currentImage < 1)then
		self.currentImage = 1
	end
end --PlaceTool:changeImg

--Move a ferramenta de desenho
function PlaceTool:moveTool(dt)
	if(love.keyboard.isDown("right"))then
		self.posX = self.posX+dt*self.speed		
		if(self.posX > self.adjPosX+self.interval)then
			self.adjPosX = self.adjPosX+self.interval;
		end
	end

	if(love.keyboard.isDown("left"))then
		if(self.adjPosX > 0)then
			self.posX = self.posX-dt*self.speed
		end
		if(self.posX < self.adjPosX-self.interval)then
			self.adjPosX = self.adjPosX-self.interval;
		end
	end

	if(love.keyboard.isDown("up"))then
		if(self.adjPosY > 0)then
			self.posY = self.posY-dt*self.speed
		end
		if(self.posY < self.adjPosY-self.interval)then
			self.adjPosY = self.adjPosY-self.interval;
		end
	end

	if(love.keyboard.isDown("down"))then
		self.posY = self.posY+dt*self.speed
		if(self.posY > self.adjPosY+self.interval)then
			self.adjPosY = self.adjPosY+self.interval;
		end
	end
end--PlaceTool:moveTool

--Gerencia a posicao e o zoom da camera
function PlaceTool:manageCamera()
	love.graphics.scale(self.zoom, self.zoom)
	love.graphics.translate(-self.adjPosX+love.graphics.getWidth()/(2*self.zoom), -self.adjPosY+love.graphics.getHeight()/(2*self.zoom))
end--PlaceTool:manageCamera

--Percorre a tabela de posicoes para desenhar o mapa
function PlaceTool:drawMap()
	for n,position in ipairs(self.mapPositions) do
		love.graphics.setColor(255, 255, 255)
		local imgPos = position.sprite*1
		love.graphics.draw(self.sprites[imgPos], position.x, position.y, 0, self.scale, self.scale)
	end
end--PlaceTool:drawMap

--Desenha o sprite da ferramenta de acordo com self.currentImage
function PlaceTool:drawTool()
	love.graphics.setColor(0, 0, 255)
	love.graphics.rectangle('line', self.adjPosX, self.adjPosY, self.sprites[self.currentImage]:getWidth()*self.scale, self.sprites[self.currentImage]:getHeight()*self.scale)
	love.graphics.setColor(255, 255, 255, 150)
	love.graphics.draw(self.sprites[self.currentImage], self.adjPosX, self.adjPosY, 0, 5, 5)
end--PlaceTool:drawTool

--Desenha a barra de tiles e a barra de favoritos
function PlaceTool:drawToolbars()
	--Barra de tiles
	local prevPos = self.sprites[1]:getWidth()
	for i = 1,9 do
		if(self.sprites[i+self.toolBar] ~= nil)then
				local x = (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)+prevPos*3/self.zoom)-self.sprites[1]:getWidth()*3/self.zoom
				local y = self.adjPosY-(love.graphics.getHeight()/2/self.zoom)
				
				love.graphics.setColor(255, 255, 255)
				love.graphics.draw(self.sprites[i+self.toolBar], x, y, 0, 3/self.zoom, 3/self.zoom)
				if(i+self.toolBar == self.currentImage)then
					love.graphics.setColor(0, 0, 255)
				else
					love.graphics.setColor(0, 255, 0, 230)
				end
				love.graphics.rectangle("line", x, y, self.sprites[i+self.toolBar]:getWidth()*3/self.zoom, self.sprites[i+self.toolBar]:getHeight()*3/self.zoom)
				love.graphics.print(i, x, y, 0, 1/self.zoom)

				prevPos = prevPos+self.sprites[i+self.toolBar]:getWidth()
		end
	end
	--Barra de favoritos
	local prevPos = self.sprites[1]:getWidth()
	for i = 1,7 do
		if(self.sprites[self.favorites[i].num] ~= nil)then
				local x = (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)+prevPos*3/self.zoom)-self.sprites[1]:getWidth()*3/self.zoom
				local y = self.adjPosY+(love.graphics.getHeight()/2/self.zoom)-self.sprites[self.favorites[i].num]:getHeight()*3/self.zoom
		
				love.graphics.setColor(255, 255, 255)
				love.graphics.draw(self.sprites[self.favorites[i].num], x, y, 0, 3/self.zoom, 3/self.zoom)				
				if(self.favorites[i].num == self.currentImage)then
					love.graphics.setColor(0, 0, 255)
				else
					love.graphics.setColor(0, 255, 0, 230)
				end
				love.graphics.rectangle("line", x, y, self.sprites[self.favorites[i].num]:getWidth()*3/self.zoom, self.sprites[self.favorites[i].num]:getHeight()*3/self.zoom)
				love.graphics.print(self.favorites[i].key, x, y, 0, 1/self.zoom)

				prevPos = prevPos+self.sprites[self.favorites[i].num]:getWidth()
		end
	end
end--PlaceTool:drawToolbars

--Desenha a interface do usuario
function PlaceTool:drawUI()
	love.graphics.setColor(0, 255, 0)
	if(self.favoritesSelect)then
		love.graphics.print("Pressione Z, X, C, V, B, N ou M para marcar o sprite atual como favorito.", self.adjPosX-love.graphics.getWidth()/4/self.zoom, self.adjPosY,0,1/self.zoom)
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
		love.graphics.setColor(255, 255, 255)
		love.graphics.print(self.infoText, (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)), self.adjPosY-(love.graphics.getHeight()/2/self.zoom)+toolBarHeight*3/self.zoom,0,1/self.zoom)
	else
		love.graphics.setColor(255, 255, 255)
		love.graphics.print("\nPressione \"i\" para mostrar comandos do teclado.", (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)), self.adjPosY-(love.graphics.getHeight()/2/self.zoom)+toolBarHeight*3/self.zoom,0,1/self.zoom)
	end
end--PlaceTool:drawUI

--Deleta as cordenadas do arquivo tiles.txt de acordo com a posicao da ferramenta
function PlaceTool:deleteTile(key)
	local x, y = self.x, self.y	
	if(key == "d")then
		local readFile = io.open(self.path.."/files/tiles.txt", "r")

		fileText = readFile:read('*a')
		readFile:close()
		print(self.adjPosX..","..self.adjPosY..",%d*")
		fileText = fileText:gsub("\n"..self.adjPosX..","..self.adjPosY..",%d+", '\n')
		fileText = fileText:gsub("\n+", '\n')
		local file = io.open(self.path.."/files/tiles.txt", "w+")
		print(io.output(file))
		io.flush()
		io.write(fileText)
		io.close()
		self:updateMap()
	end
end --PlaceTool:deleteTile

--Define a barra de favoritos
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

	if(key == "b")then
		self:makeFavorite(5)
	end

	if(key == "n")then
		self:makeFavorite(6)
	end

	if(key == "m")then
		self:makeFavorite(7)
	end
end--PlaceTool:manageFavotites

--Mostra as informacoes de controles
function PlaceTool:showInfo(key)
	if(key == "i")then
		if(self.info)then
			self.info = false
		else
			self.info = true
		end
	end
end--PlaceTool:showInfo

--Muda a barra de tiles para a proxima barra
function PlaceTool:changeToolbar(key)
	if(key == ".")then
		if(self.spritesTableSize >= self.toolBar+9)then
			self.currentImage = self.toolBar+10
			self.toolBar = self.toolBar+9
		end
	end

	if(key == ",")then

		self.toolBar = self.toolBar-9
		if(self.toolBar < 0)then
			self.toolBar = 0
		end

		self.currentImage = self.toolBar+1
	end	
end--PlaceTool:changeToolbar

--Muda o zoom da camera
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

--Insere um tile no arquivo tiles.txt
function PlaceTool:writeTile(key)
	if(key == " ")then
		self:writeLocation()
		self:updateMap()
	end
end--PlaceTool:writeTile

--Muda o tile selecionado para o proximo/anterior da lista
function PlaceTool:changeTile(key)
	if(key == "/")then
		if((self.currentImage%9) == 0)then
			if(self.spritesTableSize >= self.toolBar+9)then
				self.toolBar = self.toolBar+9
			end
		end
		self:changeImg(true)
	end

	if(key == ";")then
		if((self.currentImage%9) == 1)then
			self.toolBar = self.toolBar-9
			if(self.toolBar < 0)then
				self.toolBar = 0
			end
		end
		self:changeImg(false)
	end
	if(string.find(key, "%d") ~= nil)then
		if(self.sprites[string.gsub(key, "%a+", '')+self.toolBar] ~= nil)then
				self.currentImage = string.gsub(key, "%a+", '')+self.toolBar
		end
	end
end--PlaceTool:changeTile

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

--Desenha a grid do mapa
function PlaceTool:drawGrid()
	if(self.grid)then
		love.graphics.setColor(255, 255, 255, 100)

		--Desenha a grid vertical
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
		--Desenha a grid horizontal
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

--Checa a ordem em que os tiles serao desenhados
function PlaceTool:checkTilesOrder()
	local images = love.filesystem.getDirectoryItems("tiles")
	local tilesOrderRead = io.open(self.path.."/files/tilesOrder.txt", "r")
	local tilesOrderWrite = io.open(self.path.."/files/tilesOrder.txt", "a")
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

--Carrega as imagens de acordo com a ordem em tilesOrder
function PlaceTool:loadSprites()
	local tilesOrder = io.open(self.path.."/files/tilesOrder.txt", "r")
	local cnt = 1
	for line in tilesOrder:lines()do		
		if(love.filesystem.exists("tiles/"..line))then
			self.sprites[cnt] = love.graphics.newImage("tiles/"..line)			
			cnt = cnt+1
		else
			self:deleteImage(line)
		end		
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

--Deleta o nome do arquivo do documento tilesOrder.txt
function PlaceTool:deleteImage(tileName)
		local readFile = io.open(self.path.."/files/tilesOrder.txt", "r")

		fileText = readFile:read('*a')
		readFile:close()
		fileText = fileText:gsub(tileName, '\n')
		fileText = fileText:gsub("\n+", '\n')
		local file = io.open(self.path.."/files/tilesOrder.txt", "w+")
		print(io.output(file))
		io.flush()
		io.write(fileText)
		io.close()
end --PlaceTool:deleteImage

--Carrega a barra de favoritos
function PlaceTool:loadFavorites()
	local favorites = io.open(self.path.."/files/favorites.txt", "r")
	local cnt = 1
	for line in favorites:lines()do		
		if(self.sprites[line*1] ~= nil)then
			self.favorites[cnt].num = line*1
			cnt = cnt+1
		end
	end
end--PlaceTool:loadFavorites

--Salva a barra de favoritos no arquivo favorites.txt
function PlaceTool:saveFavorites()
  local file = io.open(self.path.."/files/favorites.txt", "w+")
  print(io.output(file))
  io.flush()
  local textFile = ""
  for i = 1,7 do
  	textFile = textFile..self.favorites[i].num.."\n"
  end
  io.write(textFile)
  io.close()
end --PlaceTool:saveFavorites

--Carrega as informacoes de comandos do teclado do arquivo controls.txt
function PlaceTool:loadInfo()
	local info = io.open(self.path.."/files/controls.txt", "r")
	
	return info:read('*a')		
end--PlaceTool:loadInfo
