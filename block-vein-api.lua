--[[
	Block Vein API for usage in various block harvesting programs for turtles.
	Examples of different types of use for this API: Tree harvester, Strip Miner, Sand harvester
	How does the API work?
	-	API Users will call blockVein.setBlocksToMine(string | table). 
		Calling this function will provide the turtle with (partial) block names or block tags to mine.
		...More info on this function can be found down below
	-	Users also have access to the blockVein.backIntoVein() and blockVein.backOutOfVein(checkVeinBlocks) functions
		Calling these functions are optional. They are for use in a user's own programs, 
		usually for when the turtle needs to refuel or when the turtle's inventory is full. 
	- 	The core function call for this API is blockVein.scanAdjBlocks(fuelCheck, inventoryCheck)
		Call this function with your own fuelCheck and InventoryCheck function, these are optional. 
	-	When the function is called, the turtle inspects the block in front of it, if the block matches the given list of blocks to mine, 
		it will mine that block and move into the block-space, and continue to check all blocks around the block-space. If the turtle
		finds a block that matches any block in the list of blocks to mine, it will repeat the previous steps.
	-	1. Inspect block in front of turtle, if successful, continue to step 2, if fail, check adjacent blocks.
		2. Check block's metadata against list of acceptable blocks to mine
		3. Mine block
		4. Move into block-space left behind
		5. Turtle repeats steps 1-4 for all blocks surrounding previously mined block.
		6. Turtle returns to original block
]]--

-- To see block metadata (names, tags), press F3 + H in game to show "Advanced Tooltips". 
-- Hover over blocks in inventory or JEI to see metadata. First string listed is the name. e.g. "minecraft:spruce_logs" for Spruce Logs
-- Every other string listed under the name are tags.

local blockTagsToMine = {} -- List of metadata to include in your turtles blockvein.
-- e.g. blockTagsToMine = {"minecraft:logs"} will mine all logs for all trees assuming their metadata includes the string "minecraft:logs"
-- as trees should.

local blockNamesToMine = {} -- List of names, or substrings of names for blocks to mine.
-- e.g. blockNamesToMine = {"log"} will mine any block with a name containing "log". i.e. Spruce Log, Oak Log, etc...

-- Table for turtle movement functions
local moveFunctions = {[1] = turtle.forward, [2] = turtle.back,[3] = turtle.turnLeft, [4] = turtle.turnRight, [5] = turtle.up, [6] = turtle.down}

-- Table filled by turtle movement functions ordered to back out of a block-vein
local unwindBlockVein = {}

-- Table filled by turtle movement functions ordered to send the turtle back into the block-vein
local windBlockVein = {}

-- Default skip function
local function skip()
-- Empty for optional parameter later on
end

-- Function to dig, created to be sand/gravel/etc resistant
local function dig(digFunction, detectFunction, inventoryCheck)
	while detectFunction() do
		digFunction()
		sleep(0.4)
	end
	inventoryCheck()
end

-- Function to move the turtle in or out of a vein
local function move(moveType, windMove, unwindMove, fuelCheck)
	windMove = windMove or nil
	unwindMove = unwindMove or nil
	-- moveType will be the argument of the turtles actual movement. This will either match windMove or unwindMove, but not always the same one.
	-- This is why we define what move is the wind move and which unwinds the turtle from the block vein
	moveType()

	if (windMove ~= nil) then --Only need to check if one of these are nil since they will both be defined or both be nil
		table.insert(windBlockVein, windMove)
		table.insert(unwindBlockVein, unwindMove) 
	end
	fuelCheck()
end


-- Function to set blockTagsToMine or blockNamesToMine table
-- Required for people using this API. Call this function to set the blocks the turtle should mine.
-- Arguments:
--		blockMetadata - the tags/names/subnames of blocks to mine.
-- 			Usage: Input a table or string containing block metadata.
-- 			Accepted Metadata = "minecraft:logs" or {"minecraft:logs"} or "log, leaves" or "dirt" or "spruce" or {"spru", "log", "sand"}
--		metadataTableIndex - The type of metadata you've used to input your blocks to mine.
-- 			Usage: Input the type of metadata you're setting.
-- 			Accepted Indexes = 1, 2
--			Metadata Index Definition: 1 - Name metadata
-- 									   2 - Tag metadata
function setBlocksToMine(blockMetadata, metadataTableIndex)
	local metadataTable
	if (metadataTableIndex == 1) then
		metadataTable = blockNamesToMine 
	elseif (metadataTableIndex == 2) then
		metadataTable = blockTagsToMine
	else 
		error("Wrong Table Index Used. Try 1 or 2")
	end

	if (type(blockMetadata) == "table") then
		for _,value in pairs(blockMetadata) do
			table.insert(metadataTable, value)
		end
	else
		for value in string.gmatch(blockMetadata, "([^,]+)") do
			table.insert(metadataTable, value )
		end
	end
end

-- Function to inspect a block, either above, below, or in front of a turtle.
-- Returns block information
local function scan(inspectFunction)
    local success, blockInfo = inspectFunction()
    if success then
        return blockInfo
    end 
end

-- Function to compare block in front of turtle to the blockTagsToMine and blockNamesToMine tables
local function blockCheck(blockInfo)
    if (blockInfo ~= nil) then
        for k in pairs(blockInfo["tags"]) do
            for i = 1,#blockTagsToMine do
                if (k == blockTagsToMine[i]) then
                    return true
                end
            end
        end
        for i = 1,#blockNamesToMine do
            if (string.find(blockInfo["name"], blockNamesToMine[i])) then
                return true
            end
        end
    end
end

-- Function to return to where the turtle left off inside the vein of blocks it was mining
-- Use this function when you want the turtle to return after refueling or when the turtle emptied it's inventory
-- and needs to return to inside a vein.
-- In the user's own program, write inventory/refuel function(s) that 
-- hook into this function to get the turtle back to a position that the user's program is not aware of. 
function backIntoVein()
	for i = 1, #windBlockVein do
		move(windBlockVein[i], nil, nil, skip) 
	end
end

-- Function to remove redundant 360° turns in the move order tables
local function remove360s()
	if (#unwindBlockVein >= 4) then
		local flag = 0
		for i = 1, #unwindBlockVein do
			if (unwindBlockVein[i] == moveFunctions[4]) then
				flag = flag + 1
			else
				flag = 0
			end
			if (flag == 4) then
				for j = 0,3 do
					table.remove(unwindBlockVein, i-j)
					table.remove(windBlockVein, i-j)
				end
				remove360s()
				break
			end
		end
	end
end

-- Function to back the turtle out of the vein it's currently in.
-- Use this function when you want the turtle to refuel or when the inventory is full
-- In the user's own program, write inventory/refuel function(s) that 
-- hook into this function to get the turtle to a position that the user's program is aware of. 
function backOutOfVein(checkVeinBlocks)
	remove360s()
	for i = #unwindBlockVein, 1, -1 do
		-- Save move for break checking
		local move = unwindBlockVein[i]

		-- When the turtle exhausts the current path it will continue to look for more blocks on different paths
		move(unwindBlockVein[i])

		-- Removes the exhausted path from the wind and unwind block vein tables if not checking veinBlocks as the turtle exits the vein
		if (checkVeinBlocks == false) then
			table.remove(unwindBlockVein) 
			table.remove(windBlockVein) 
		end	

		 -- If the turtle is about to go back, go back and then break into recursively checking for more blocks
		 if ((move == moveFunctions[2]  or move == moveFunctions[5] or move == moveFunctions[6])and checkVeinBlocks == false)  then
			break -- Breaks back somewhere into recursive calls of scanAdjBlocks function
		 end
		
	end
end

-- Function to scan adjacent blocks
function scanAdjBlocks(fuelCheck, inventoryCheck)
	-- Functions will be skipped if no function is passed in API call
	fuelCheck = fuelCheck or skip 
	inventoryCheck = inventoryCheck or skip
	-- Check block in front of turtle. If block matches blocksToMine, mine block, move into block-space. Start scanning again
	-- If block doesn't match, turnLeft and try inspecting again. Repeat for all directions
    for _ = 1, 4 do
        if blockCheck(scan(turtle.inspect)) then
            dig(turtle.dig, turtle.detect, inventoryCheck)
            move(moveFunctions[1], moveFunctions[1], moveFunctions[2], fuelCheck )
            scanAdjBlocks(fuelCheck, inventoryCheck)
        end
		move(moveFunctions[3], moveFunctions[3], moveFunctions[4], skip)
    end
    if blockCheck(scan(turtle.inspectDown)) then
		dig(turtle.digDown, turtle.detectDown, inventoryCheck)
		move(moveFunctions[6], moveFunctions[6], moveFunctions[5], fuelCheck)
        scanAdjBlocks(fuelCheck, inventoryCheck)
    end
    if blockCheck(scan(turtle.inspectUp)) then
		dig(turtle.digUp, turtle.detectUp, inventoryCheck)
		move(moveFunctions[5], moveFunctions[5], moveFunctions[6], fuelCheck)
        scanAdjBlocks(inventoryCheck, fuelCheck)
    end
    backOutOfVein(false) -- False argument as the turtle is completely done with the vein
end