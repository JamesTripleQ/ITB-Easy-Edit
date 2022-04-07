
-- increase max cached surfaces
-- for surface dense uis
sdlext.surface_cache_max = 1024

local path = GetParentPath(...)

local vanillaCorporations = { "Corp_Grass", "Corp_Desert", "Corp_Snow", "Corp_Factory" }
local difficulties = { DIFF_EASY, DIFF_NORMAL, DIFF_HARD }

local islands = { "archive", "rst", "pinnacle", "detritus" }
local islandNames = { "Archive", "R.S.T.", "Pinnacle", "Detritus" }
local tileTypes = { TERRAIN_FOREST, TERRAIN_SAND, TERRAIN_ICE, TERRAIN_ACID }
local islandShifts = { Point(14,5), Point(16,15), Point(17,12), Point(18,15), Point(0,0) }

local corporations = { "archive", "rst", "pinnacle", "detritus" }
local ceos = { "dewey", "jessica", "zenith", "vikram" }
local missionLists = corporations
local bossLists = corporations

local tilesets = { "grass", "sand", "snow", "acid", "lava", "volcano", "vine", "hologram" }
local climate = { "", "", "", "", "Scorching", "Fiery", "Lush", "Holograpic" }
local rainChance = { 0, 0, 0, 0, 0, 0, 70, 30 }
local environmentChance = { 0, 0, 0, 0, 0, 0, { [TERRAIN_FOREST] = 60 }, 0 }

local mechList = {
	"PunchMech", "TankMech", "ArtiMech",
	"JetMech", "RocketMech", "PulseMech",
	"LaserMech", "ChargeMech", "ScienceMech",
	"ElectricMech", "WallMech", "RockartMech",
	"JudoMech", "DStrikeMech", "GravMech",
	"FlameMech", "IgniteMech", "TeleMech",
	"GuardMech", "MirrorMech", "IceMech",
	"LeapMech", "UnstableTank", "NanoMech",
}

local UNIT_EXCLUSION = {
	"Pawn",
	"PawnTable",

	"SlugBoss",
	"SlugEgg1",
	"Slug1",
	"Slug2",
}

local WEAPON_EXCLUSION = {
}

local MISSION_EXCLUSION = {
	"Mission",
	"Mission_Test",
	"Mission_Auto",
	"Mission_Battle",
	"Mission_Infinite",
	"Mission_Tutorial",
	"Mission_Critical",
	"Mission_MineBase",
	"Mission_Final",
	"Mission_Final_Cave",
	"Mission_Boss",

	"Mission_Sandstorm",
	"Mission_SlugBoss",
}

local STRUCTURE_EXCLUSION = {
	
}

local function registerWeapon(weapon_id)
	if list_contains(WEAPON_EXCLUSION, weapon_id) then
		return
	end

	local base = _G[weapon_id]
	local weapon = modApi.weapons:get(weapon_id)

	weapon = weapon or modApi.weapons:add(weapon_id)
	weapon:copy(base)
	weapon.__Id = weapon_id
	weapon.Name = GetText(weapon_id.."_Name") or base.Name
	weapon.Description = GetText(weapon_id.."_Description") or base.Description
	weapon:lock()
end

local function registerWeapons()
	for weapon_id, _ in pairs(modApi.weaponDeck) do
		registerWeapon(weapon_id)
	end
end

local units = modApi.units
local unitImages = modApi.unitImage
local isValidUnit = units._class.isValid
local function registerUnit(unit_id)
	if list_contains(UNIT_EXCLUSION, unit_id) then
		return
	end

	local base = _G[unit_id]
	local unit = units:get(unit_id)

	if base.Name == "Unnamed Pawn" or base.Name == "PawnTable" then
		base.Name = GetText(unit_id)
	end

	if isValidUnit(base) then
		unit = unit or units:add(unit_id, base)
		unit:lock()

		units:addSoundBase(unit)
	end

	unitImageId = base.Image
	unitImage = unitImages:get(unitImageId)

	if unitImage == nil then
		unitImage = unitImages:add(unitImageId)
		unitImage.Name = unitImageId
		unitImage.Image = base.Image
		unitImage.ImageOffset = base.ImageOffset
		unitImage:lock()
	end

	for _, weaponId in ipairs(base.SkillList) do
		registerWeapon(weaponId)
	end
end

local function registerUnits()
	for unit_id, unit in pairs(_G) do
		local isUnit = true
			and type(unit) == 'table'
			and type(unit.Name) == 'string'
			and type(unit.Class) == 'string'
			and type(unit.Image) == 'string'
			and type(unit.ImageOffset) == 'number'
			and type(unit.Health) == 'number'
			and type(unit.MoveSpeed) == 'number'
			and type(unit.SkillList) == 'table'

		if isUnit then
			registerUnit(unit_id)
		end
	end
end

local function registerMission(mission_id)
	if list_contains(MISSION_EXCLUSION, mission_id) then
		return
	end

	local base = _G[mission_id]
	local mission = modApi.missions:get(mission_id)

	mission = mission or modApi.missions:add(mission_id)
	mission:copy(base)
	mission:lock()

	local appendLoc = string.format("img/strategy/mission/%s.png", mission_id)
	local filename = string.format("%simg/mission/%s.png", path, mission_id)

	if modApi:fileExists(filename) then
		modApi:appendAsset(appendLoc, filename)
	end

	local appendLoc = string.format("img/strategy/mission/small/%s.png", mission_id)
	local filename = string.format("%simg/mission/small/%s.png", path, mission_id)

	if modApi:fileExists(filename) then
		modApi:appendAsset(appendLoc, filename)
	end
end

local function registerMissions()
	for i, _ in ipairs(corporations) do
		local corp_id = vanillaCorporations[i]
		local base = _G[corp_id]

		local function addMissions(missionTable)
			for _, mission_id in ipairs(missionTable) do
				registerMission(mission_id)
			end
		end

		addMissions(base.Missions_High)
		addMissions(base.Missions_Low)
		addMissions(base.Bosses)
		addMissions(base.UniqueBosses)
	end

	for mission_id, mission in pairs(_G) do
		local isMission = true
			and type(mission) == 'table'
			and type(mission.Name) == 'string'
			and type(mission.MapList) == 'table'
			and type(mission.MapTags) ~= 'nil'
			and type(mission.MapVetoes) == 'table'

		if isMission then
			registerMission(mission_id)
		end
	end
end

local function registerStructure(structure_id)
	if list_contains(STRUCTURE_EXCLUSION, structure_id) then
		return
	end

	local base = _G[structure_id]
	local structure = modApi.structures:get(structure_id)

	structure = structure or modApi.structures:add(structure_id)
	structure.Name = GetText(structure_id.."_Name")
	structure:copy(base)
	structure:lock()
end

local function registerStructures()
	for i, _ in ipairs(corporations) do
		local corp_id = vanillaCorporations[i]
		local base = _G[corp_id]

		local function addStructures(structureTable)
			for _, structure_id in ipairs(structureTable) do
				registerStructure(structure_id)
			end
		end

		addStructures(base.PowAssets)
		addStructures(base.TechAssets)
		addStructures(base.RepAssets)
	end

	for structure_id, structure in pairs(_G) do
		local isStructure = true
			and type(structure) == 'table'
			and type(structure.Image) == 'string'
			and type(structure.Reward) == 'number'
			and structure.Reward >= 0
			and structure.Reward <= 2
			and structure_id:find("^Mission") == nil
			and structure.nonStructure ~= true

		if isStructure then
			registerStructure(structure_id)
		end
	end
end

local function registerIslands()
	for i, id in ipairs(islands) do
		local island = modApi.island:add(id)
		local n = i-1

		island:copyAssets({_id = tostring(n)})
		island.name = islandNames[i]
		island.shift = islandShifts[i]
		island.magic = Island_Magic[i]
		island.regionData = {}
		island.network = {}

		if i <= 4 then
			for k = 0, 7 do
				table.insert(island.regionData, Region_Data[string.format("island_%s_%s", n, k)])
			end

			for k = 0, 7 do
				table.insert(island.network, _G["Network_Island_".. n][tostring(k)])
			end
		end

		island:lock()
	end
end

local function registerCorporations()
	for i, id in ipairs(corporations) do
		local corp = modApi.corporation:add(id)
		local corp_id = vanillaCorporations[i]
		local base = _G[corp_id]

		corp:copy(base)
		corp.Name = GetText(corp_id.."_Name")
		corp.Description = GetText(corp_id.."_Description")
		corp:lock()
	end
end

local function registerCEOs()
	for i, id in ipairs(ceos) do
		local ceo = modApi.ceo:add(id)
		local corp_id = vanillaCorporations[i]
		local base = _G[corp_id]

		ceo:copyAssets({_id = "ceo_"..corporations[i]})
		ceo:copy(base)
		ceo.CEO_Name = GetText(corp_id.."_CEO_Name")
		ceo:lock()
	end
end

local function registerTilesets()
	modApi:appendAsset(
		"img/strategy/corp/lava_env.png",
		path.."img/env/lava_env.png")
	modApi:appendAsset(
		"img/strategy/corp/volcano_env.png",
		path.."img/env/volcano_env.png")
	modApi:appendAsset(
		"img/strategy/corp/vine_env.png",
		path.."img/env/vine_env.png")
	modApi:appendAsset(
		"img/strategy/corp/hologram_env.png",
		path.."img/env/hologram_env.png")
	modApi:copyAsset(
		"img/combat/tiles_grass/building_sheet_vines.png",
		"img/combat/tiles_vine/building_sheet.png")

	-- temporarily override GetRealDifficulty
	-- while extracting environmentChance for
	-- vanilla tilesets
	local oldGetDifficulty = GetRealDifficulty
	local difficulty
	function GetRealDifficulty()
		return difficulty
	end

	for i, id in ipairs(tilesets) do
		local corp_id = vanillaCorporations[i]

		if corp_id then
			local tileset = modApi.tileset:add(id)
			tileset.name = upper_first(id)
			-- fill in missing conveyor assets
			tileset:copyAssets({_id = "acid"}, false)

			tileset.climate = GetText(corp_id.."_Environment")
			tileset.rainChance = getRainChance(id)
			tileset.environmentChance = {}

			for _, diff in ipairs(difficulties) do
				difficulty = diff
				tileset.environmentChance[diff] = {}

				for _, tileType in ipairs(tileTypes) do
					tileset.environmentChance[diff][tileType] = getEnvironmentChance(id, tileType)
				end
			end
		else
			local tileset = modApi.tileset:add(id)
			tileset.name = upper_first(id)
			-- set missing locations
			tileset:copyAssets(tileset)
			-- fill in missing assets
			tileset:copyAssets({_id = "grass"}, false)
			tileset:copyAssets({_id = "acid"}, false)

			tileset.climate = climate[i]
			tileset.rainChance = rainChance[i]
			tileset.environmentChance = environmentChance[i]
		end
	end

	GetRealDifficulty = oldGetDifficulty

	function getRainChance(sectorType)
		local tileset = modApi.tileset:get(sectorType)
		local noDataFound = not tileset or not tileset.getRainChance

		if noDataFound then
			return 0
		end

		return tileset:getRainChance()
	end

	function getEnvironmentChance(sectorType, tileType)
		local tileset = modApi.tileset:get(sectorType)
		local noDataFound = not tileset or not tileset.getEnvironmentChance

		if noDataFound then
			return 0
		end

		return tileset:getEnvironmentChance(tileType, GetDifficulty())
	end

	modApi.events.onTilesetChanged:subscribe(function(newTileset, oldTileset)
		local oldTileset = modApi.tileset:get(oldTileset)
		local newTileset = modApi.tileset:get(newTileset)

		oldTileset:onDisabled()
		newTileset:onEnabled()
	end)
end

function pickEnemies(categories, enemies, islandNumber, timesPicked)
	timesPicked = timesPicked or {}
	local result = {}
	local choices = {}
	local excluded = {}

	local exclusiveReversed = {}
	for i, v in ipairs(ExclusiveElements) do
		exclusiveReversed[v] = i
	end

	local function isUnlocked(unit)
		local lock = IslandLocks[unit] or 4
		return islandNumber == nil or islandNumber >= lock or Game:IsIslandUnlocked(lock-1)
	end

	local function addExclusions(unit)
		if ExclusiveElements[unit] then
			excluded[ExclusiveElements[unit]] = true
		end
		if exclusiveReversed[unit] then
			excluded[exclusiveReversed[unit]] = true
		end
	end

	local function getEnemyChoices(category)
		if type(category) ~= 'string' then
			return {}
		end

		if choices[category] and #choices[category] > 0 then
			return choices[category]
		end

		local leastPicked = INT_MAX

		choices[category] = {}
		enemies[category] = enemies[category] or {}
		for _, enemy in ipairs(enemies[category]) do
			if isUnlocked(enemy) and not excluded[enemy] then
				table.insert(choices[category], enemy)
			end
		end

		shuffle_list(choices[category])
		table.sort(choices[category], function(a,b)
			return (timesPicked[a] or 0) > (timesPicked[b] or 0)
		end)

		return choices[category]
	end

	for _, category in ipairs(categories) do
		local enemyChoices = getEnemyChoices(category)
		local choice = "Scorpion"

		for i = #enemyChoices, 1, -1 do
			if not excluded[enemyChoices[i]] then
				choice = enemyChoices[i]
				table.remove(enemyChoices, i)

				break
			end
		end

		timesPicked[choice] = (timesPicked[choice] or 0) + 1
		addExclusions(choice)
		table.insert(result, choice)
	end

	Assert.Equals(6, #result, "Result")

	return result
end

local function registerEnemyLists()
	local id = "vanilla"
	local enemyList = modApi.enemyList:add(id)
	enemyList.name = "Vanilla"
	enemyList.enemies = copy_table(EnemyLists)
	enemyList:lock()

	for i, corp_id in ipairs(vanillaCorporations) do
		local corp = _G[corp_id]
		corp.Enemies = copy_table(EnemyLists)
		corp.EnemyCategories = copy_table(enemyList.categories)
	end

	local oldStartNewGame = startNewGame
	function startNewGame()
		oldStartNewGame()

		local timesPicked = {}
		for i, corp_id in ipairs(vanillaCorporations) do
			local corp = _G[corp_id]
			local enemies = corp.Enemies
			local categories = corp.EnemyCategories

			GAME.Enemies[i] = pickEnemies(categories, enemies, i, timesPicked)
		end
	end
end

local function registerBossLists()
	for i, id in ipairs(corporations) do
		local bossList = modApi.bossList:add(id)
		local corp_id = vanillaCorporations[i]
		local base = _G[corp_id]

		bossList:copy(base)
		bossList.name = base.Bark_Name
		bossList:lock()
	end
end

local function registerMissionLists()
	for i, id in ipairs(corporations) do
		local missionList = modApi.missionList:add(id)
		local corp_id = vanillaCorporations[i]
		local base = _G[corp_id]

		missionList:copy(base)
		missionList.name = base.Bark_Name
		missionList:lock()
	end
end

local function registerStructureLists()
	local structureList = modApi.structureList:add("vanilla")
	structureList:copy(Corp_Default)
	structureList.name = "Vanilla"
	structureList:lock()
end

local function registerIslandComposites()
	for i = 1, 4 do
		local id = islands[i]
		local islandComposite = modApi.islandComposite:add(id)
		islandComposite.name = islandNames[i]
		islandComposite.island = islands[i]
		islandComposite.corporation = corporations[i]
		islandComposite.ceo = ceos[i]
		islandComposite.tileset = tilesets[i]
		islandComposite.missionList = missionLists[i]
		islandComposite.bossList = bossLists[i]
		islandComposite.enemyList = "vanilla"
		islandComposite.structureList = "vanilla"

		islandComposite:lock()
	end
end

local function registerIcons()
	local icons = {
		"delete",
		"reset",
		"delete_small",
		"reset_small",
		"warning_small",
	}

	for _, name in ipairs(icons) do
		local appendLoc = string.format("img/ui/easyEdit/%s.png", name)
		local filename = string.format("%simg/icons/%s.png", path, name)
		modApi:appendAsset(appendLoc, filename)
	end
end

local function registerFinalEnemyList()
	local enemyList = modApi.enemyList:add("finale")

	enemyList.name = "Finale"
	enemyList.categories = { "Enemies" }
	enemyList.enemies = { Enemies = {} }

	enemyList:addEnemy("Firefly", "Enemies")
	enemyList:addEnemy("Hornet", "Enemies")
	enemyList:addEnemy("Scarab", "Enemies")
	enemyList:addEnemy("Scorpion", "Enemies")
	enemyList:addEnemy("Crab", "Enemies")
	enemyList:addEnemy("Beetle", "Enemies")
	enemyList:addEnemy("Digger", "Enemies")
	enemyList:addEnemy("Blobber", "Enemies")
	enemyList:addEnemy("Jelly_Lava", "Enemies") -- jelly x3
	enemyList:addEnemy("Jelly_Lava", "Enemies")
	enemyList:addEnemy("Jelly_Lava", "Enemies")

	local oldGetSpawnList = GameObject.GetSpawnList
	function GameObject:GetSpawnList(island, ...)
		local result = oldGetSpawnList(self, island, ...)

		if island == 5 then -- final island!
			local enemyList = modApi.enemyList:get("finale")
			result = copy_table(enemyList.enemies.Enemies)
		end

		return result
	end
end

local function registerFinalBossList()
	local bossList_phase1 = modApi.bossList:add("finale1")
	local bossList_phase2 = modApi.bossList:add("finale2")
	bossList_phase1.name = "Finale I"
	bossList_phase2.name = "Finale II"

	bossList_phase1:addBoss("Mission_ScorpionBoss")
	bossList_phase1:addBoss("Mission_FireflyBoss")
	bossList_phase1:addBoss("Mission_HornetBoss")

	bossList_phase2:addBoss("Mission_BeetleBoss")
	bossList_phase2:addBoss("Mission_FireflyBoss")
	bossList_phase2:addBoss("Mission_HornetBoss")
end

local function markRegisteredAsVanilla()
	local function markAsVanilla(indexedList)
		for _, indexedEntry in pairs(indexedList._children) do
			indexedEntry._vanilla = true
		end
	end

	markAsVanilla(modApi.units)
	markAsVanilla(modApi.unitImage)
	markAsVanilla(modApi.weapons)
	markAsVanilla(modApi.missions)
	markAsVanilla(modApi.structures)
	markAsVanilla(modApi.corporation)
	markAsVanilla(modApi.tileset)
	markAsVanilla(modApi.structureList)
	markAsVanilla(modApi.enemyList)
	markAsVanilla(modApi.bossList)
	markAsVanilla(modApi.missionList)
	markAsVanilla(modApi.island)
	markAsVanilla(modApi.islandComposite)
end

local function markRegisteredAsMod(modId)
	local function markAsMod(indexedList)
		for _, indexedEntry in pairs(indexedList._children) do
			if not indexedEntry:isVanilla() and indexedEntry.mod == nil then
				indexedEntry.mod = modId
			end
		end
	end

	markAsMod(modApi.units)
	markAsMod(modApi.unitImage)
	markAsMod(modApi.weapons)
	markAsMod(modApi.missions)
	markAsMod(modApi.structures)
	markAsMod(modApi.corporation)
	markAsMod(modApi.tileset)
	markAsMod(modApi.structureList)
	markAsMod(modApi.enemyList)
	markAsMod(modApi.bossList)
	markAsMod(modApi.missionList)
	markAsMod(modApi.island)
	markAsMod(modApi.islandComposite)
end

local function lockEverything()
	local function lockChildren(indexedList)
		for _, indexedEntry in pairs(indexedList._children) do
			indexedEntry:lock()
		end
	end

	lockChildren(modApi.ceo)
	lockChildren(modApi.corporation)
	lockChildren(modApi.units)
	lockChildren(modApi.tileset)
	lockChildren(modApi.island)
	lockChildren(modApi.islandComposite)
	lockChildren(modApi.structureList)
	lockChildren(modApi.enemyList)
	lockChildren(modApi.bossList)
	lockChildren(modApi.missionList)
end

local function onModInitialized(modId)
	registerUnits()
	registerWeapons()
	registerMissions()
	registerStructures()
	markRegisteredAsMod(modId)
end

local function onModsInitialized()
	lockEverything()
	easyEdit.savedata:init()
end

registerUnits()
registerWeapons()
registerMissions()
registerStructures()
registerIslands()
registerCorporations()
registerCEOs()
registerTilesets()
registerEnemyLists()
registerBossLists()
registerMissionLists()
registerStructureLists()
registerIslandComposites()
registerIcons()
registerFinalEnemyList()
registerFinalBossList()
markRegisteredAsVanilla()

modApi.events.onModInitialized:subscribe(onModInitialized)
modApi.events.onModsInitialized:subscribe(onModsInitialized)
