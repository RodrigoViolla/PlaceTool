PlaceTool = {}
PlaceTool.__index = PlaceTool

function PlaceTool:new(world)
	local placeTool = placeTool or {}
	setmetatable(placeTool, PlaceTool)

	placeTool.favorites = 
	{
		[1] = {num = 0, key = "z"},
		[2] = {num = 0, key = "x"},
		[3] = {num = 0, key = "c"},
		[4] = {num = 0, key = "v"},
		[5] = {num = 0, key = "b"},
		[6] = {num = 0, key = "n"},
		[7] = {num = 0, key = "m"}
	}	
	placeTool.world = world
	placeTool.colliders = {}
	placeTool.colliderMode = false
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
	placeTool.toolbar = 0
	placeTool.info = false
	placeTool.grid = true
	placeTool.favoritesSelect = false
	placeTool:loadColliders()

	return placeTool
end --PlaceTool:new

function PlaceTool:update(dt)
	self:moveTool(dt)
end --PlaceTool:update

function PlaceTool:draw()
	self:manageCamera()
	self:drawMap()
	self:drawColliders()
	self:drawGrid()
	self:drawTool()
	self:drawToolbars()
	self:drawUI()
end --PlaceTool:draw

function PlaceTool:keypressed(key)
	self:manageFavotites(key)
	if(key == "a")then
		self:showColliders()
	end
	if(key == "i")then
		self:showInfo()
	end
	if(key == ".")then
		self:changeToolbar(true)
	end
	if(key == ",")then
		self:changeToolbar(false)
	end
	if(key == "/" or string.find(key, "%d") ~= nil)then
		self:changeTile(true, key)
	end
	if(key == ";" or string.find(key, "%d") ~= nil)then
		self:changeTile(false, key)
	end
	if(key == "=")then
		self:changeZoom(true)
	end
	if(key == "-")then
		self:changeZoom(false)
	end
	if(key == " ")then
		self:writeTile()
	end
	if(key == "d")then
		self:deleteTile()
	end
	if(key == "escape")then
		love.event.quit()
	end
	if(key == "g")then
		self:showGrid()
	end
end --PlaceTool:keypressed

function PlaceTool:quit()
	self:saveFavorites()
	self:saveColliders()
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
			self.adjPosX = self.adjPosX+self.interval
		end
	end

	if(love.keyboard.isDown("left"))then
		if(self.adjPosX > 0)then
			self.posX = self.posX-dt*self.speed
		end
		if(self.posX < self.adjPosX-self.interval)then
			self.adjPosX = self.adjPosX-self.interval
		end
	end

	if(love.keyboard.isDown("up"))then
		if(self.adjPosY > 0)then
			self.posY = self.posY-dt*self.speed
		end
		if(self.posY < self.adjPosY-self.interval)then
			self.adjPosY = self.adjPosY-self.interval
		end
	end

	if(love.keyboard.isDown("down"))then
		self.posY = self.posY+dt*self.speed
		if(self.posY > self.adjPosY+self.interval)then
			self.adjPosY = self.adjPosY+self.interval
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
	if(self.colliderMode)then
		love.graphics.setColor(0, 255, 0)
	else
		love.graphics.setColor(0, 0, 255)
	end
	love.graphics.rectangle('line', self.adjPosX, self.adjPosY, self.sprites[self.currentImage]:getWidth()*self.scale, self.sprites[self.currentImage]:getHeight()*self.scale)
	if(not self.colliderMode)then
		love.graphics.setColor(255, 255, 255, 150)
		love.graphics.draw(self.sprites[self.currentImage], self.adjPosX, self.adjPosY, 0, 5, 5)
	end
end--PlaceTool:drawTool

--Desenha a barra de tiles e a barra de favoritos
function PlaceTool:drawToolbars()
	local alpha = 255
	if(self.colliderMode)then
		alpha = 150
	end

	--Barra de tiles
	local prevPos = self.sprites[1]:getWidth()
	for i = 1,9 do
		if(self.sprites[i+self.toolbar] ~= nil)then
				local x = (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)+prevPos*3/self.zoom)-self.sprites[1]:getWidth()*3/self.zoom
				local y = self.adjPosY-(love.graphics.getHeight()/2/self.zoom)
				
				love.graphics.setColor(255, 255, 255, alpha)
				love.graphics.draw(self.sprites[i+self.toolbar], x, y, 0, 3/self.zoom, 3/self.zoom)
				if(i+self.toolbar == self.currentImage)then
					love.graphics.setColor(0, 0, 255, alpha)
				else
					love.graphics.setColor(0, 255, 0, alpha)
				end
				love.graphics.rectangle("line", x, y, self.sprites[i+self.toolbar]:getWidth()*3/self.zoom, self.sprites[i+self.toolbar]:getHeight()*3/self.zoom)
				love.graphics.print(i, x, y, 0, 1/self.zoom)

				prevPos = prevPos+self.sprites[i+self.toolbar]:getWidth()
		end
	end
	--Barra de favoritos
	local prevPos = self.sprites[1]:getWidth()
	for i = 1,7 do
		if(self.sprites[self.favorites[i].num] ~= nil)then
				local x = (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)+prevPos*3/self.zoom)-self.sprites[1]:getWidth()*3/self.zoom
				local y = self.adjPosY+(love.graphics.getHeight()/2/self.zoom)-self.sprites[self.favorites[i].num]:getHeight()*3/self.zoom
		
				love.graphics.setColor(255, 255, 255, alpha)
				love.graphics.draw(self.sprites[self.favorites[i].num], x, y, 0, 3/self.zoom, 3/self.zoom)				
				if(self.favorites[i].num == self.currentImage)then
					love.graphics.setColor(0, 0, 255, alpha)
				else
					love.graphics.setColor(0, 255, 0, alpha)
				end
				love.graphics.rectangle("line", x, y, self.sprites[self.favorites[i].num]:getWidth()*3/self.zoom, self.sprites[self.favorites[i].num]:getHeight()*3/self.zoom)
				love.graphics.print(self.favorites[i].key:upper(), x, y, 0, 1/self.zoom)

				prevPos = prevPos+self.sprites[self.favorites[i].num]:getWidth()
		end
	end
end--PlaceTool:drawToolbars

--Desenha a interface do usuario
function PlaceTool:drawUI()
	local text = ""
	local limit = 400

	love.graphics.setColor(255, 255, 255)
	if(self.favoritesSelect)then
		text = "Pressione \"Z\", \"X\", \"C\", \"V\", \"B\", \"N\" ou \"M\" para marcar o sprite atual como favorito.\nPressione \"F\" para cancelar."
		love.graphics.printf(text, self.adjPosX-limit/2/self.zoom, self.adjPosY, limit, "center", 0,1/self.zoom,1/self.zoom, 0, 0, 0, 0)
	end

	local toolbarHeight = 0
	local toolbarWidth = 0
	for i = 1,9 do
		if(self.sprites[i+self.toolbar] ~= nil)then
			if(self.sprites[i+self.toolbar]:getHeight() > toolbarHeight)then
				toolbarHeight = self.sprites[i+self.toolbar]:getHeight()
			end

			toolbarWidth = toolbarWidth+self.sprites[i+self.toolbar]:getWidth()
		end
	end
	
	local colliderText = ""
	if(self.colliderMode)then
		love.graphics.setColor(0, 255, 0)
		colliderText = "Pressione \"A\" para desativar o modo de colisores"
	else
		love.graphics.setColor(255, 255, 255)
		colliderText = "Pressione \"A\" para ativar o modo de colisores"
	end

	if(self.info)then
		text = self.infoText
	else
		text = colliderText.."\nPressione \"I\" para mostrar comandos do teclado."
	end

	love.graphics.print(text, (self.adjPosX-(love.graphics.getWidth()/2/self.zoom))+toolbarWidth*3.1/self.zoom, self.adjPosY-(love.graphics.getHeight()/2/self.zoom),0,1/self.zoom)
end--PlaceTool:drawUI

--Deleta as cordenadas do arquivo tiles.txt de acordo com a posicao da ferramenta
function PlaceTool:deleteTile()
	if(self.colliderMode)then
		self:deleteCollider()
	else
		local x, y = self.x, self.y	
		local readFile = io.open(self.path.."/files/tiles.txt", "r")

		fileText = readFile:read('*a')
		readFile:close()
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
		if(self.favoritesSelect)then
			self.favoritesSelect = false
		else
			self.favoritesSelect = true
		end
	end

	for i, fav in ipairs(self.favorites)do
		if(key == fav.key)then
			self:makeFavorite(i)
		end
	end
end--PlaceTool:manageFavotites

--Mostra as informacoes de controles
function PlaceTool:showInfo(key)
	if(self.info)then
		self.info = false
	else
		self.info = true
	end	
end--PlaceTool:showInfo

--Muda a barra de tiles para a proxima barra
function PlaceTool:changeToolbar(next)
	if(next)then
		if(self.spritesTableSize >= self.toolbar+9)then
			self.currentImage = self.toolbar+10
			self.toolbar = self.toolbar+9
		end
	else		
		if(self.toolbar > 0)then
			self.toolbar = self.toolbar-9
			self.currentImage = self.toolbar+1
		end
	end	
end--PlaceTool:changeToolbar

--Muda o zoom da camera
function PlaceTool:changeZoom(zoom)
	if(zoom)then
		if(self.zoom < 1)then
			self.zoom = self.zoom+0.1
		end
	else
		if(self.zoom > 0.2)then
			self.zoom = self.zoom-0.1
		end
	end
end--PlaceTool:changeZoom

--Insere um tile no arquivo tiles.txt
function PlaceTool:writeTile()
	if(self.colliderMode)then
		self:createCollider(self.adjPosX, self.adjPosY)
	else
		self:writeLocation()
	end
	self:updateMap()
end--PlaceTool:writeTile

--Muda o tile selecionado para o proximo/anterior da lista
function PlaceTool:changeTile(next, key)
	if(string.find(key, "%d") ~= nil)then
		if(self.sprites[string.gsub(key, "%a+", '')+self.toolbar] ~= nil)then
				self.currentImage = string.gsub(key, "%a+", '')+self.toolbar
		end
	else
		if(next)then
			if((self.currentImage%9) == 0)then
				if(self.spritesTableSize >= self.toolbar+9)then
					self.toolbar = self.toolbar+9
				end
			end
			self:changeImg(true)
		else
			if((self.currentImage%9) == 1)then
				self.toolbar = self.toolbar-9
				if(self.toolbar < 0)then
					self.toolbar = 0
				end
			end
			self:changeImg(false)
		end
	end
end--PlaceTool:changeTile

function PlaceTool:showGrid(key)
	if(self.grid)then
		self.grid = false
	else
		self.grid = true
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
		isInList = fileText:find(tile.."+")

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

function PlaceTool:createCollider(x, y)
	local collider = {}
	collider.tileX, collider.tileY = x, y
	collider.x = x+self.sprites[self.currentImage]:getWidth()*self.scale/2
	collider.y = y+self.sprites[self.currentImage]:getHeight()*self.scale/2
	collider.body = love.physics.newBody(self.world, collider.x, collider.y) 
	collider.shape = love.physics.newRectangleShape(self.sprites[self.currentImage]:getWidth()*self.scale, self.sprites[self.currentImage]:getHeight()*self.scale) 
	collider.fixture = love.physics.newFixture(collider.body, collider.shape)

	table.insert(self.colliders, collider)
end--PlaceTool:createCollider

function PlaceTool:drawColliders()
	if(self.colliderMode)then
		for i, collider in ipairs(self.colliders)do
			love.graphics.setColor(0, 255, 0, 100)
	    	love.graphics.polygon("fill", collider.body:getWorldPoints(collider.shape:getPoints()))
		end
	end
end--PlaceTool:drawColliders

function PlaceTool:deleteCollider()
	local deletePosX = self.adjPosX+self.sprites[self.currentImage]:getWidth()*self.scale/2
	local deletePosY = self.adjPosY+self.sprites[self.currentImage]:getHeight()*self.scale/2

	for i, collider in ipairs(self.colliders)do
		if(collider.x == deletePosX and collider.y == deletePosY)then
			table.remove(self.colliders, i)
		end
	end
end--PlaceTool:deleteCollider

function PlaceTool:loadColliders()
	local file = io.open(self.path.."/files/colliders.txt", "r")
	for line in file:lines() do
		if(line ~= "")then
			local linePositions = {}
			for num in line:gmatch"%d+" do
					table.insert(linePositions, num) 
			end			
			self:createCollider(linePositions[1], linePositions[2])
		end
	end
end--PlaceTool:loadColliders

function PlaceTool:saveColliders()
	local collidersText = ""
	for i, collider in ipairs(self.colliders)do
		collidersText = collidersText..collider.tileX..","..collider.tileY.."\n"
	end

	local file = io.open(self.path.."/files/colliders.txt", "w+")
	print(io.output(file))
	io.flush()
	io.write(collidersText)
	io.close()
end --PlaceTool:saveColliders

function PlaceTool:showColliders()
	if(self.colliderMode)then
		self.colliderMode = false
	else
		self.colliderMode = true
	end
end--PlaceTool:showColliders
