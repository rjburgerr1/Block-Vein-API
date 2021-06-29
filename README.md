**Welcome to the Block Vein API**
API for computercraft written in lua. For use with turtles to mine veins of blocks.



**Why do I need this API?**
- If you require the functionality of having a turtle mine a continuous, unbroken vein of blocks.

**Potential uses of this API:**
- In your mining programs
- To farm trees
- To harvest any naturally generated blocks (sand, dirt, etc...)

**What does this API effectively do?**
- Compares blocks around a turtle against a given list of blocks to mine. If the blocks scanned matches the list of blocks to mine, the turtle will mine the blocks. Afterwards, the turtle will move into the space left by the mined blocks and check for more. After exhausting all mined paths, the turtle will return to place it started at.

**How can I take control of this API?**
- The core function call to make:
  - .scanAdjBlocks(fuelCheck, inventoryCheck)
    - This function call includes two optional parameters.
    - fuelCheck takes a function that the user creates for their own specific program. This will run everytime
      the turtle moves.
    - inventoryCheck takes a function that the user creates for their own specific program. This will run
      everytime the turtle mines a block.
- Other useful functions:
  - .setBlocksToMine(blockMetadata, metadataTableIndex)
    - Function to set blockTagsToMine or blockNamesToMine table
      Required for people using this API. Call this function to set the blocks the turtle should mine.
      Arguments:
        blockMetadata - the tags/names/subnames of blocks to mine.
Usage: Input a table or string containing block metadata.
Accepted Metadata = "minecraft:logs" or {"minecraft:logs"} or "log, leaves" or "dirt" or "spruce" or {"spru", "log", "sand"} or etc...
        metadataTableIndex - The type of metadata you've used to input your blocks to mine.
      -Usage: Input the type of metadata you're setting.
        - Accepted Indexes = 1, 2
        - Metadata Index Definition: 1 - Name metadata
                                     2 - Tag metadata
  - Users also have access to the .backIntoVein() and backOutOfVein(checkVeinBlocks) functions
      - Calling these functions are optional. They are for use in a user's own programs,
      - usually for when the turtle needs to refuel or when the turtle's inventory is full.
      - checkVeinBlocks is a boolean that should likely be false in a user's program

**How do I use this API?**
In a turtle terminal run this command
pastebin get bxsJUwq1 blockVein

In a user program:
os.loadAPI("blockVein")
- From here you use the blockVein functions inside your program.
E.g. blockVein.scanAdjBlocks(usersFuelCheckingFunction, usersFuelCheckingFunction)

Code on Pastebin - https://pastebin.com/bxsJUwq1
