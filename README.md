# PlaceTool
Ferramenta para criação de mapas em Love2D.<br><br>

ADICIONAR TILES<br><br>

Todos os arquivos presentes no diretorio PlaceTool/tiles serão adicionados ao editor.<br>
IMPORTANTE: Os arquivos não podem conter espaços no nome.<br><br>

TECLAS<br><br>
  Use as setas do teclado para mover a tela<br>
  1 a 9 - Muda o sprite para o sprite de numero correspondente a barra superior<br>
  "A" - Ativa/Desativa o modo de colliders<br>
  "BOTÃO ESQUERDO DO MOUSE" - Desenha o tile atual<br>
  "BOTÃO DIREITO DO MOUSE" - Deleta o tile atual<br>
  "ESC" - Sair do editor<br>
  "/" - Muda para o proximo sprite<br>
  ";" - Muda para o sprite anterior<br>
  "." - Proxima barra de tiles<br>
  "," - Barra de tiles anterior<br>
  "I" - Mostra/Esconde controles do teclado<br>
  "G" - Mostra/Esconde a grade<br>
  "F" - Adiciona o sprite atual como favorito<br>
  "D" - Aumenta a velocidade da ferramenta<br>
  "S" - Diminui a velocidade da ferramenta<br>
  "SHIFT ESQUERDO"+"BOTÃO DIREITO DO MOUSE" - Copia tile atual<br><br>
  
EXEMPLO PARA USO DO MAPA EM JOGOS:<br>

```lua
Map = {}
Map.__index = Map

function Map:new(world, debug, path, scale)
	local map = map or {}
	setmetatable(map, Map)

	map.world = world
	map.colliders = {}
	map.scale = scale
	map.debug = debug
	map.path = path
	map.sprites = {}
	map:loadSprites()
	map.spritesTableSize = table.getn(map.sprites)
	map.mapPositions = map:loadMapPositions()
	map:loadColliders()

	return map
end --Map:new

function Map:draw()
	self:drawMap()
	self:drawColliders()
end --Map:draw

--Carrega as cordenadas dos tiles do arquivo tiles.txt e guarda em uma table
function Map:loadMapPositions()
	local file = io.open(self.path.."/tiles.txt", "r")
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
end --Map:loadMapPositions

--Percorre a tabela de posicoes para desenhar o mapa
function Map:drawMap()
	for n,position in ipairs(self.mapPositions) do
		love.graphics.setColor(255, 255, 255)
		local imgPos = position.sprite*1
		love.graphics.draw(self.sprites[imgPos], position.x, position.y, 0, self.scale, self.scale)
	end
end--Map:drawMap

--Carrega as imagens de acordo com a ordem em tilesOrder
function Map:loadSprites()
	local tilesOrder = io.open(self.path.."/tilesOrder.txt", "r")
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
end--Map:loadSprites

function Map:drawColliders()
	if self.debug then
		for i, collider in ipairs(self.colliders)do
			love.graphics.setColor(0, 255, 0, 100)
	    	love.graphics.polygon("fill", collider.body:getWorldPoints(collider.shape:getPoints()))
		end
	end
end--Map:drawColliders

function Map:loadColliders()
	local file = io.open(self.path.."/colliders.txt", "r")
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
end--Map:loadColliders

function Map:createCollider(x, y)
	local collider = {}
	local scaleX = self.sprites[1]:getWidth()*self.scale
	local scaleY = self.sprites[1]:getHeight()*self.scale

	collider.tileX, collider.tileY = x, y
	collider.x = x+self.sprites[1]:getWidth()*self.scale/2
	collider.y = y+self.sprites[1]:getHeight()*self.scale/2
	collider.body = love.physics.newBody(self.world, collider.x, collider.y)
	collider.shape = love.physics.newRectangleShape(scaleX, scaleY)
	collider.fixture = love.physics.newFixture(collider.body, collider.shape)
	
	table.insert(self.colliders, collider)
end--PlaceTool:createCollider

```
