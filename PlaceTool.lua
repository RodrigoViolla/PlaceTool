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
	placeTool.keys =
	{
		left = {key = "left", desc = "SETA PARA A ESQUERDA"},
		right = {key = "right", desc = "SETA PARA A DIREITA"},
		up = {key = "up", desc = "SETA PARA CIMA"},
		down = {key = "down", desc = "SETA PARA BAIXO"},
		delete = {key = "2", desc = "BOTÃO DIREITO DO MOUSE"},
		colliderMode = {key = "a", desc = "A"},
		nextTile = {key = "/", desc = "/"},
		previousTile = {key = ";", desc = ";"},
		nextToolbar = {key = ".", desc = "."},
		previousToolbar = {key = ",", desc = ","},
		favorite = {key = "f", desc = "F"},
		grid = {key = "g", desc = "G"},
		info = {key = "i", desc = "I"},
		exit = {key = "escape", desc = "ESC"},
		draw = {key = "1", desc = "BOTÃO ESQUERDO DO MOUSE"},
		highSpeed = {key = "=", desc = "+"},
		lowSpeed = {key = "-", desc = "-"},
		shift = {key = "lshift", desc = "SHIFT ESQUERDO"}
	}
	placeTool.world = world
	placeTool.colliders = {}
	placeTool.colliderMode = false
	placeTool.copy = false
	placeTool.speed = 50000
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
	placeTool.mapPositions = placeTool:loadMapPositions()
	local lastPosition = placeTool:loadLastPosition()
	placeTool.adjPosX = lastPosition.x*1
	placeTool.adjPosY = lastPosition.y*1
	self.adjMouseX = 0
	self.adjMouseY = 0
	placeTool.posX = lastPosition.x*1
	placeTool.posY = lastPosition.y*1
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
	if love.mouse.isDown(self.keys.draw.key) then
		self:writeTile()
	end

	if love.keyboard.isDown(self.keys.shift.key) then
		self.copy = true
	else
		self.copy = false
	end

	if love.mouse.isDown(self.keys.delete.key) then
		if not self.copy then
			self:deleteTile()
		end
	end
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
	if key == self.keys.colliderMode.key then
		self:showColliders()
	end
	if key == self.keys.info.key then
		self:showInfo()
	end
	if key == self.keys.nextToolbar.key then
		self:changeToolbar(true)
	end
	if key == self.keys.previousToolbar.key then
		self:changeToolbar(false)
	end
	if key == self.keys.nextTile.key or string.find(key, "%d") ~= nil then
		self:changeTile(true, key)
	end
	if key == self.keys.previousTile.key or string.find(key, "%d") ~= nil then
		self:changeTile(false, key)
	end
	if key == self.keys.exit.key then
		love.event.quit()
	end
	if key == self.keys.grid.key then
		self:showGrid()
	end
	if key == self.keys.highSpeed.key then
		self:changeSpeed(true)
	end
	if key == self.keys.lowSpeed.key then
		self:changeSpeed(false)
	end
end --PlaceTool:keypressed

function PlaceTool:mousepressed(mx,my,button)
	if button == 1 then
		if self:isMouseHoverToolbar() ~= 0 then
			self.currentImage = self:isMouseHoverToolbar()
		end
	end
	if button == 2 and self.copy then
		self:copyTile()
	end
end--PlaceTool:mousepressed

function PlaceTool:wheelmoved(x, y)
	if y > 0 then
		self:changeZoom(true)
	else
		self:changeZoom(false)
	end
end--PlaceTool:wheelmoved

function PlaceTool:quit()
	self:saveFavorites()
	self:saveColliders()
	self:saveLastPosition()
	self:saveMapPositions()
end--PlaceTool:quit

--Grava as cordenadas do tile no arquivo tiles.txt
function PlaceTool:writeLocation()
	local exists = false
	local writePosition = {x = self.adjMouseX, y = self.adjMouseY, sprite = self.currentImage}
	
	for i, position in ipairs(self.mapPositions)do
		if writePosition.x == position.x and writePosition.y == position.y and writePosition.sprite == position.sprite then
		exists = true
		end
	end

	if not exists then
		table.insert(self.mapPositions, writePosition)
	end
end --PlaceTool:writeLocation

--Carrega as cordenadas dos tiles do arquivo tiles.txt e guarda em uma table
function PlaceTool:loadMapPositions()
	local file = io.open(self.path.."/files/map/tiles.txt", "r")
	local positions = {}
	for line in file:lines() do
		if line ~= "" then
			local linePositions = {}
			for num in line:gmatch"%d+" do
					table.insert(linePositions, num)
			end
			position = {x = linePositions[1], y = linePositions[2], sprite = linePositions[3]}
			table.insert(positions, position)
		end
	end
	file:close()

	return positions
end --PlaceTool:loadMapPositions

function PlaceTool:saveMapPositions()
	local file = io.open(self.path.."/files/map/tiles.txt", "w+")
	local textFile = ""

	for i, position in ipairs(self.mapPositions)do
		textFile = textFile.."\n"..position.x..","..position.y..","..position.sprite
	end

	file:flush()
	file:write(textFile)
	file:close()
end--PlaceTool:saveMapPositions

--Muda o contador da imagem do tile atual
function PlaceTool:changeImg(asc)
	if asc then
		self.currentImage = self.currentImage+1
	else
		self.currentImage = self.currentImage-1
	end

	if self.currentImage > self.spritesTableSize then
		self.currentImage = self.spritesTableSize
	end
	if self.currentImage < 1 then
		self.currentImage = 1
	end
end --PlaceTool:changeImg

--Move a ferramenta de desenho
function PlaceTool:moveTool(dt)
	--Movendo a camera
	local x, y = love.mouse.getPosition()
	local margin = 10

	if love.keyboard.isDown(self.keys.right.key) or x >= love.graphics.getWidth()-margin then
		self.posX = self.posX+dt*self.speed * dt
		if self.posX > self.adjPosX+self.interval/2 then
			self.adjPosX = self.adjPosX+self.interval
		end
	end

	if love.keyboard.isDown(self.keys.left.key) or x <= margin then
		if self.adjPosX > 0 then
			self.posX = self.posX-dt*self.speed * dt
		end
		if self.posX < self.adjPosX-self.interval/2 then
			self.adjPosX = self.adjPosX-self.interval
		end
	end
	
	if love.keyboard.isDown(self.keys.up.key) or y <= margin then
		if self.adjPosY > 0 then
			self.posY = self.posY-dt*self.speed * dt
		end
		if self.posY < self.adjPosY-self.interval/2 then
			self.adjPosY = self.adjPosY-self.interval
		end
	end

	if love.keyboard.isDown(self.keys.down.key) or y >= love.graphics.getHeight()-margin then
		self.posY = self.posY+dt*self.speed * dt
		if self.posY > self.adjPosY+self.interval/2 then
			self.adjPosY = self.adjPosY+self.interval
		end
	end
	--Movendo a ferramenta
	local x, y = love.mouse.getPosition()
	
	x = (x/self.zoom)-love.graphics.getWidth()/2/self.zoom+self.adjPosX
	y = (y/self.zoom)-love.graphics.getHeight()/2/self.zoom+self.adjPosY

	if x > self.adjMouseX+self.interval then
			self.adjMouseX = self.adjMouseX+self.interval
	end

	if x < self.adjMouseX then
		self.adjMouseX = self.adjMouseX-self.interval
	end

	if y < self.adjMouseY then
		self.adjMouseY = self.adjMouseY-self.interval
	end

	if y > self.adjMouseY+self.interval then
		self.adjMouseY = self.adjMouseY+self.interval
	end
	if self.adjMouseX < 0 then
		self.adjMouseX = 0
	end
	if self.adjMouseY < 0 then
		self.adjMouseY = 0
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
	local width = self.sprites[self.currentImage]:getWidth()
	local height = self.sprites[self.currentImage]:getHeight()
	if self.colliderMode then
		love.graphics.setColor(0, 255, 0)
	else
		love.graphics.setColor(255, 255, 255, 150)
		love.graphics.draw(self.sprites[self.currentImage], self.adjMouseX, self.adjMouseY, 0, 5, 5)
		love.graphics.setColor(0, 0, 255)
	end
	love.graphics.rectangle('line', self.adjMouseX, self.adjMouseY, width*self.scale, height*self.scale)
end--PlaceTool:drawTool

--Desenha a barra de tiles e a barra de favoritos
function PlaceTool:drawToolbars()
	local alpha = 255
	if self.colliderMode then
		alpha = 150
	end
	--Barra de tiles
	local prevPos = self.sprites[1]:getWidth()
	for i = 1,9 do
		if self.sprites[i+self.toolbar] ~= nil then
				local spriteWidth = self.sprites[i+self.toolbar]:getWidth()
				local spriteHeight = self.sprites[i+self.toolbar]:getHeight()
				local x = (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)+prevPos*3/self.zoom)-self.sprites[1]:getWidth()*3/self.zoom
				local y = self.adjPosY-(love.graphics.getHeight()/2/self.zoom)
				
				love.graphics.setColor(255, 255, 255, alpha)
				love.graphics.draw(self.sprites[i+self.toolbar], x, y, 0, 3/self.zoom, 3/self.zoom)
				if i+self.toolbar == self.currentImage then
					love.graphics.setColor(0, 0, 255, alpha)
				else
					love.graphics.setColor(0, 255, 0, alpha)
				end
				love.graphics.rectangle("line", x, y, spriteWidth*3/self.zoom, spriteHeight*3/self.zoom)
				love.graphics.print(i, x, y, 0, 1/self.zoom)

				prevPos = prevPos+spriteWidth
		end
	end
	--Barra de favoritos
	local prevPos = self.sprites[1]:getWidth()
	for i = 1,7 do
		if self.sprites[self.favorites[i].num] ~= nil then
				local spriteWidth = self.sprites[self.favorites[i].num]:getWidth()
				local spriteHeight = self.sprites[self.favorites[i].num]:getHeight()
				local x = (self.adjPosX-(love.graphics.getWidth()/2/self.zoom)+prevPos*3/self.zoom)-self.sprites[1]:getWidth()*3/self.zoom
				local y = self.adjPosY+(love.graphics.getHeight()/2/self.zoom)-spriteHeight*3/self.zoom

				love.graphics.setColor(255, 255, 255, alpha)
				love.graphics.draw(self.sprites[self.favorites[i].num], x, y, 0, 3/self.zoom, 3/self.zoom)
				if self.favorites[i].num == self.currentImage then
					love.graphics.setColor(0, 0, 255, alpha)
				else
					love.graphics.setColor(0, 255, 0, alpha)
				end
				love.graphics.rectangle("line", x, y, spriteWidth*3/self.zoom, spriteHeight*3/self.zoom)
				love.graphics.print(self.favorites[i].key:upper(), x, y, 0, 1/self.zoom)

				prevPos = prevPos+spriteWidth
		end
	end
end--PlaceTool:drawToolbars

--Desenha a interface do usuario
function PlaceTool:drawUI()
	local text = ""
	local limit = 400

	love.graphics.setColor(255, 255, 255)
	if self.favoritesSelect then
		text = "Pressione \""..
			self.favorites[1].key:upper().."\", \""..
			self.favorites[2].key:upper().."\", \""..
			self.favorites[3].key:upper().."\", \""..
			self.favorites[4].key:upper().."\", \""..
			self.favorites[5].key:upper().."\", \""..
			self.favorites[6].key:upper().."\" ou \""..
			self.favorites[7].key:upper()..
			"\" para marcar o sprite atual como favorito.\nPressione \""..
			self.keys.favorite.desc:upper().."\" para cancelar."
		love.graphics.printf(text, self.adjPosX-limit/2/self.zoom, self.adjPosY, limit, "center", 0,1/self.zoom,1/self.zoom, 0, 0, 0, 0)
	end

	local toolbarHeight = 0
	local toolbarWidth = 0
	for i = 1,9 do
		if self.sprites[i+self.toolbar] ~= nil then
			if self.sprites[i+self.toolbar]:getHeight() > toolbarHeight then
				toolbarHeight = self.sprites[i+self.toolbar]:getHeight()
			end

			toolbarWidth = toolbarWidth+self.sprites[i+self.toolbar]:getWidth()
		end
	end
	
	local colliderText = ""
	if self.colliderMode then
		love.graphics.setColor(0, 255, 0)
		colliderText = "Pressione \""..self.keys.colliderMode.key:upper().."\" para desativar o modo de colisores"
	else
		love.graphics.setColor(255, 255, 255)
		colliderText = "Pressione \""..self.keys.colliderMode.key:upper().."\" para ativar o modo de colisores"
	end

	if self.info then
		text = self.infoText
	else
		text = colliderText.."\nPressione \""..self.keys.info.key:upper().."\" para mostrar comandos do teclado."
	end

	local posX = (self.adjPosX-(love.graphics.getWidth()/2/self.zoom))

	love.graphics.print(text, posX+toolbarWidth*3.1/self.zoom, self.adjPosY-(love.graphics.getHeight()/2/self.zoom),0,1/self.zoom)

	text = "Velocidade: "..self.speed/1000
	love.graphics.print(text, posX, self.adjPosY+love.graphics.getHeight()/2/self.zoom-15/self.zoom,0,1/self.zoom)
end--PlaceTool:drawUI

--Deleta as cordenadas do arquivo tiles.txt de acordo com a posicao da ferramenta
function PlaceTool:deleteTile()
	if self.colliderMode then
		self:deleteCollider()
	else
		for i, position in ipairs(self.mapPositions)do
			if position.x*1 == self.adjMouseX and position.y*1 == self.adjMouseY then
				table.remove(self.mapPositions, i)
			end
		end
	end
end --PlaceTool:deleteTile

--Define a barra de favoritos
function PlaceTool:manageFavotites(key)
	if key == self.keys.favorite.key then
		if self.favoritesSelect then
			self.favoritesSelect = false
		else
			self.favoritesSelect = true
		end
	end

	for i, fav in ipairs(self.favorites)do
		if key == fav.key then
			self:makeFavorite(i)
		end
	end
end--PlaceTool:manageFavotites

--Mostra as informacoes de controles
function PlaceTool:showInfo(key)
	if self.info then
		self.info = false
	else
		self.info = true
	end
end--PlaceTool:showInfo

--Muda a barra de tiles para a proxima barra
function PlaceTool:changeToolbar(next)
	if next then
		if self.spritesTableSize > self.toolbar+9 then
			self.currentImage = self.toolbar+10
			self.toolbar = self.toolbar+9
		end
	else
		if self.toolbar > 0 then
			self.toolbar = self.toolbar-9
			self.currentImage = self.toolbar+1
		end
	end
end--PlaceTool:changeToolbar

--Muda o zoom da camera
function PlaceTool:changeZoom(zoom)
	if zoom then
		if self.zoom < 1 then
			self.zoom = self.zoom+0.1
		end
	else
		if self.zoom > 0.2 then
			self.zoom = self.zoom-0.1
		end
	end
end--PlaceTool:changeZoom

--Insere um tile no arquivo tiles.txt
function PlaceTool:writeTile()
	if self:isMouseHoverToolbar() == 0 then
		if self.colliderMode then
			self:createCollider(self.adjMouseX, self.adjMouseY)
		else
			self:writeLocation()
		end
	end
end--PlaceTool:writeTile

--Muda o tile selecionado para o proximo/anterior da lista
function PlaceTool:changeTile(next, key)
	if string.find(key, "%d") ~= nil then
		if self.sprites[string.gsub(key, "%a+", '')+self.toolbar] ~= nil then
				self.currentImage = string.gsub(key, "%a+", '')+self.toolbar
		end
	else
		if next then
			if self.currentImage%9 == 0 then
				if self.spritesTableSize >= self.toolbar+9 then
					self.toolbar = self.toolbar+9
				end
			end
			self:changeImg(true)
		else
			if self.currentImage%9 == 1 then
				self.toolbar = self.toolbar-9
				if self.toolbar < 0 then
					self.toolbar = 0
				end
			end
			self:changeImg(false)
		end
	end
end--PlaceTool:changeTile

function PlaceTool:showGrid(key)
	if self.grid then
		self.grid = false
	else
		self.grid = true
	end
end--PlaceTool:showGrid

function PlaceTool:updateMap()
	self.mapPositions = self:loadMapPositions()
end--PlaceTool:updateMap

--Desenha a grid do mapa
function PlaceTool:drawGrid()
	if self.grid then
		love.graphics.setColor(255, 255, 255, 100)

		--Desenha a grid vertical
		local prevPos = love.graphics.getWidth()/2
		while prevPos < love.graphics.getWidth()/self.zoom do
			local posX = self.adjPosX - love.graphics.getWidth()/2+prevPos
			local posY1 = self.adjPosY - love.graphics.getHeight()/2/self.zoom
			local posY2 = self.adjPosY + love.graphics.getHeight()/2/self.zoom

			love.graphics.line(posX, posY1, posX, posY2)
			prevPos = prevPos+self.gridSize*self.scale
		end

		local prevPos = love.graphics.getWidth()/2
		while prevPos > -love.graphics.getWidth()/self.zoom do
			local posX = self.adjPosX - love.graphics.getWidth()/2+prevPos
			local posY1 = self.adjPosY - love.graphics.getHeight()/2/self.zoom
			local posY2 = self.adjPosY + love.graphics.getHeight()/2/self.zoom

			love.graphics.line(posX, posY1, posX, posY2)
			prevPos = prevPos-self.gridSize*self.scale
		end
		--Desenha a grid horizontal
		local prevPos = love.graphics.getHeight()/2
		while prevPos < love.graphics.getHeight()/self.zoom do
			local posX1 = self.adjPosX-love.graphics.getWidth()/2/self.zoom
			local posX2 = self.adjPosX+love.graphics.getWidth()/2/self.zoom
			local posY = self.adjPosY-love.graphics.getHeight()/2+prevPos

			love.graphics.line(posX1, posY, posX2, posY)
			prevPos = prevPos+self.gridSize*self.scale
		end

		local prevPos = love.graphics.getHeight()/2
		while prevPos > -love.graphics.getHeight()/self.zoom do
			local posX1 = self.adjPosX-love.graphics.getWidth()/2/self.zoom
			local posX2 = self.adjPosX+love.graphics.getWidth()/2/self.zoom
			local posY = self.adjPosY-love.graphics.getHeight()/2+prevPos

			love.graphics.line(posX1, posY , posX2, posY)
			prevPos = prevPos-self.gridSize*self.scale
		end
	end
	love.graphics.setColor(255, 0, 0)
	love.graphics.line(0, 0, self.adjPosX+love.graphics.getWidth()/2/self.zoom, 0)
	love.graphics.setColor(0, 255, 0)
	love.graphics.line(0, 0, 0, self.adjPosY+love.graphics.getHeight()/2/self.zoom)
end--PlaceTool:drawGrid

--Checa a ordem em que os tiles serao desenhados
function PlaceTool:checkTilesOrder()
	local isInList = nil
	local images = love.filesystem.getDirectoryItems("tiles")
	local tilesOrderRead = io.open(self.path.."/files/map/tilesOrder.txt", "r")
	local fileText = tilesOrderRead:read('*a')
	tilesOrderRead:close()

	for cnt, tile in ipairs(images)do
		isInList = fileText:find("\n"..tile)

		if isInList == nil then
			fileText = fileText..tile.."\n"
		end
	end
	
	local tilesOrderWrite = io.open(self.path.."/files/map/tilesOrder.txt", "w+")
	tilesOrderWrite:flush()
	tilesOrderWrite:write(fileText)
	tilesOrderWrite:close()
end--PlaceTool:checkTilesOrder

--Carrega as imagens de acordo com a ordem em tilesOrder
function PlaceTool:loadSprites()
	local tilesOrder = io.open(self.path.."/files/map/tilesOrder.txt", "r")
	local cnt = 1
	for line in tilesOrder:lines()do
		if line ~= "" then
			if love.filesystem.exists("tiles/"..line) then
				self.sprites[cnt] = love.graphics.newImage("tiles/"..line)
				cnt = cnt+1
			else
				self:deleteImage(line)
			end
		end
	end
	tilesOrder:close()
end--PlaceTool:loadSprites

function PlaceTool:makeFavorite(favorite)
	if self.favoritesSelect then
		self.favoritesSelect = false
		self.favorites[favorite].num = self.currentImage
	else
		if self.favorites[favorite].num > 0 then
			self.currentImage = self.favorites[favorite].num
		end
	end
end

--Deleta o nome do arquivo do documento tilesOrder.txt
function PlaceTool:deleteImage(tileName)
		local readFile = io.open(self.path.."/files/map/tilesOrder.txt", "r")
		fileText = readFile:read('*a')
		readFile:close()
		fileText = fileText:gsub(tileName, '\n')
		fileText = fileText:gsub("\n+", '\n')
		local file = io.open(self.path.."/files/map/tilesOrder.txt", "w+")
		file:flush()
		file:write(fileText)
		file:close()
end --PlaceTool:deleteImage

--Carrega a barra de favoritos
function PlaceTool:loadFavorites()
	local favorites = io.open(self.path.."/files/favorites.txt", "r")
	local cnt = 1
	for line in favorites:lines()do
		if self.sprites[line*1] ~= nil then
			self.favorites[cnt].num = line*1
			cnt = cnt+1
		end
	end
	favorites:close()
end--PlaceTool:loadFavorites

--Salva a barra de favoritos no arquivo favorites.txt
function PlaceTool:saveFavorites()
	local file = io.open(self.path.."/files/favorites.txt", "w+")
	file:flush()
	local textFile = ""
	for i = 1,7 do
		textFile = textFile..self.favorites[i].num.."\n"
	end
	file:write(textFile)
	file:close()
end --PlaceTool:saveFavorites

--Carrega as informacoes de comandos do teclado do arquivo controls.txt
function PlaceTool:loadInfo()
	local info = io.open(self.path.."/files/controls.txt", "r")
	local text = info:read('*a')

	text = text:gsub("draw", "\""..self.keys.draw.desc.."\"")
	text = text:gsub("exit", "\""..self.keys.exit.desc.."\"")
	text = text:gsub("colliderMode", "\""..self.keys.colliderMode.desc.."\"")
	text = text:gsub("nextTile", "\""..self.keys.nextTile.desc.."\"")
	text = text:gsub("previousTile", "\""..self.keys.previousTile.desc.."\"")
	text = text:gsub("delete", "\""..self.keys.delete.desc.."\"")
	text = text:gsub("nextToolbar", "\""..self.keys.nextToolbar.desc.."\"")
	text = text:gsub("previousToolbar", "\""..self.keys.previousToolbar.desc.."\"")
	text = text:gsub("info", "\""..self.keys.info.desc.."\"")
	text = text:gsub("grid", "\""..self.keys.grid.desc.."\"")
	text = text:gsub("favorite", "\""..self.keys.favorite.desc.."\"")
	text = text:gsub("highSpeed", "\""..self.keys.highSpeed.desc.."\"")
	text = text:gsub("lowSpeed", "\""..self.keys.lowSpeed.desc.."\"")
	text = text:gsub("shift", "\""..self.keys.shift.desc.."\"")

	info:close()

	return text
end--PlaceTool:loadInfo

function PlaceTool:createCollider(x, y)
	local collider = {}
	local scaleX = self.sprites[self.currentImage]:getWidth()*self.scale
	local scaleY = self.sprites[self.currentImage]:getHeight()*self.scale

	collider.tileX, collider.tileY = x, y
	collider.x = x+self.sprites[self.currentImage]:getWidth()*self.scale/2
	collider.y = y+self.sprites[self.currentImage]:getHeight()*self.scale/2
	collider.body = love.physics.newBody(self.world, collider.x, collider.y)
	collider.shape = love.physics.newRectangleShape(scaleX, scaleY)
	collider.fixture = love.physics.newFixture(collider.body, collider.shape)

	local exists = false

	for i, coll in ipairs(self.colliders)do
		if collider.x == coll.x and collider.y == coll.y then
			exists = true
		end
	end

	if not exists then
		table.insert(self.colliders, collider)
	end
end--PlaceTool:createCollider

function PlaceTool:drawColliders()
	if self.colliderMode then
		for i, collider in ipairs(self.colliders)do
			love.graphics.setColor(0, 255, 0, 100)
	    	love.graphics.polygon("fill", collider.body:getWorldPoints(collider.shape:getPoints()))
		end
	end
end--PlaceTool:drawColliders

function PlaceTool:deleteCollider()
	local deletePosX = self.adjMouseX+self.sprites[self.currentImage]:getWidth()*self.scale/2
	local deletePosY = self.adjMouseY+self.sprites[self.currentImage]:getHeight()*self.scale/2

	for i, collider in ipairs(self.colliders)do
		if collider.x == deletePosX and collider.y == deletePosY then
			table.remove(self.colliders, i)
		end
	end
end--PlaceTool:deleteCollider

function PlaceTool:loadColliders()
	local file = io.open(self.path.."/files/map/colliders.txt", "r")
	for line in file:lines() do
		if line ~= "" then
			local linePositions = {}
			for num in line:gmatch"%d+" do
					table.insert(linePositions, num)
			end
			self:createCollider(linePositions[1], linePositions[2])
		end
	end
	file:close()
end--PlaceTool:loadColliders

function PlaceTool:saveColliders()
	local collidersText = ""
	for i, collider in ipairs(self.colliders)do
		collidersText = collidersText..collider.tileX..","..collider.tileY.."\n"
	end

	local file = io.open(self.path.."/files/map/colliders.txt", "w+")
	file:flush()
	file:write(collidersText)
	file:close()
end --PlaceTool:saveColliders

function PlaceTool:showColliders()
	if self.colliderMode then
		self.colliderMode = false
	else
		self.colliderMode = true
	end
end--PlaceTool:showColliders

function PlaceTool:changeSpeed(asc)
	if asc then
		self.speed = self.speed+10000
	else
		self.speed = self.speed-10000
	end

	if self.speed <= 0 then
		self.speed = 10000
	end
end--PlaceTool:changeSpeed

function PlaceTool:loadLastPosition()
	local file = io.open(self.path.."/files/lastPosition.txt", "r")
	local position = {}
	for line in file:lines() do
		if line ~= "" then
			local linePositions = {}
			for num in line:gmatch"%d+" do
					table.insert(linePositions, num)
			end
			position = {x = linePositions[1], y = linePositions[2]}
			file:close()
			return position
		end
	end
	file:close()
	return nil
end--PlaceTool:loadLastPosition

function PlaceTool:saveLastPosition()
	local file = io.open(self.path.."/files/lastPosition.txt", "w+")
	local textFile = self.adjPosX..","..self.adjPosY

	file:flush()
	file:write(textFile)
	file:close()
end--PlaceTool:saveLastPosition

function PlaceTool:isMouseHoverToolbar()
	local mx, my = love.mouse.getPosition()
	local prevPos = 0

	for i = 1,9 do
		if self.sprites[i+self.toolbar] ~= nil then
			local x = prevPos
			local y = 0

			if mx >= x and mx <= x + self.sprites[i+self.toolbar]:getWidth()*3 then
				if my >= y and my < y + self.sprites[i+self.toolbar]:getHeight()*3 then
				return i+self.toolbar
				end
			end

			prevPos = prevPos+self.sprites[i+self.toolbar]:getWidth()*3
		end
	end

	return 0
end--PlaceTool:isMouseHoverToolbar

function PlaceTool:copyTile()
	for n, tile in ipairs(self.mapPositions) do
		if tile.x*1 == self.adjMouseX and tile.y*1 == self.adjMouseY and self.currentImage*1 ~= tile.sprite*1 then
			self.currentImage = tile.sprite*1
			break
		end
	end
end--PlaceTool:copyTile
