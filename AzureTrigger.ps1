param([byte[]] $InputBlob, $TriggerMetadata)


##Creating a parser for Z1R things
##Credit provided to Tetra at https://www.github.com/tetraly for designing, building, and making this entire thing happen in Python. This project is an homage to her

##Constants up first

# Define the Direction Enum
enum Direction {
    NORTH = -0x10
    WEST = -0x1
    NO_DIRECTION = 0
    EAST = 0x1
    SOUTH = 0x10
}

# Add a static method to handle inverse logic

class DirectionHelper {
    static [int]Inverse([int] $direction) {
        switch ($direction) {
            -0x10 {return [DIRECTION]::SOUTH} ## NORTH -> SOUTH
            0x10 { return [DIRECTION]::NORTH} ## SOUTH -> NORTH
            -0x1 { return [DIRECTION]::EAST }   ## WEST -> EAST
            0x1 { return [DIRECTION]::WEST }   ## EAST -> WEST
            default { return [DIRECTION]::NO_DIRECTION}        ## NO_DIRECTION
        }
        return [DIRECTION]::NO_DIRECTION
    }
}


# Entrance Direction Map
$global:ENTRANCE_DIRECTION_MAP = @{
    1 = [Direction]::NORTH
    2 = [Direction]::SOUTH
    3 = [Direction]::WEST
    4 = [Direction]::EAST
}

# Door Types
$global:DOOR_TYPES = @{
    0 = "Door"
    1 = "Wall"
    2 = "Walk-Through Wall"
    3 = "Walk-Through Wall"
    4 = "Bomb Hole"
    5 = "Locked Door"
    6 = "Locked Door"
    7 = "Shutter Door"
}

# WallType Enum
enum WallType {
    DOOR = 0
    SOLID_WALL = 1
    WALK_THROUGH_WALL_1 = 2
    WALK_THROUGH_WALL_2 = 3
    BOMB_HOLE = 4
    LOCKED_DOOR_1 = 5
    LOCKED_DOOR_2 = 6
    SHUTTER_DOOR = 7
}

# TileType Enum
enum TileType {
    FLOOR = 0
    BLOCK = 1
    WATER = 2
    STATUE = 3
    STAIRWAY = 4
    BLACK = 5
    BOMB_HOLE = 6
    KEY_DOOR = 7
    SHUTTER_DOOR = 8
    WALK_THROUGH_WALL = 9
    OLD_MAN = 10
}

# Wall Type Character Map
$global:WALL_TYPE_CHAR = @{
    0 = @(" ", " ")
    1 = @("-", "|")
    2 = @("=", "!")
    3 = @("=", "!")
    4 = @("B", "B")
    5 = @("K", "K")
    6 = @("K", "K")
    7 = @("S", "S")
}

# Cave Name
$global:CAVE_NAME = @{
    0x01 = "Level 1"
    0x02 = "Level 2"
    0x03 = "Level 3"
    0x04 = "Level 4"
    0x05 = "Level 5"
    0x06 = "Level 6"
    0x07 = "Level 7"
    0x08 = "Level 8"
    0x09 = "Level 9"
    0x10 = "Wood Sword Cave"
    0x11 = "Take Any"
    0x12 = "White Sword Cave"
    0x13 = "Magical Sword Cave"
    0x14 = "Any Road"
    0x15 = "White Sword Clue"
    0x16 = "Money Making Game"
    0x17 = "Door Repair"
    0x18 = "Letter Cave"
    0x19 = "Magical Sword Clue"
    0x1A = "Potion Shop"
    0x1B = "Hint Shop 1"
    0x1C = "Hint Shop 2"
    0x1D = "Shop 1"
    0x1E = "Shop 2"
    0x1F = "Shop 3"
    0x20 = "Shop 4"
    0x21 = "Medium Secret"
    0x22 = "Large Secret"
    0x23 = "Small Secret"
}

# Cave Name Short
$global:CAVE_NAME_SHORT = @{
    0x01 = "L1"
    0x02 = "L2"
    0x03 = "L3"
    0x04 = "L4"
    0x05 = "L5"
    0x06 = "L6"
    0x07 = "L7"
    0x08 = "L8"
    0x09 = "L9"
    0x10 = "Wood"
    0x11 = "Take Any"
    0x12 = "White"
    0x13 = "Mags"
    0x14 = "Any Rd."
    0x15 = "WS Clue"
    0x16 = "MMG"
    0x17 = "-20R"
    0x18 = "Letter"
    0x19 = "MS Clue"
    0x1A = "Potion"
    0x1B = "Hints 1"
    0x1C = "Hints 2"
    0x1D = "Shop 1"
    0x1E = "Shop 2"
    0x1F = "Shop 3"
    0x20 = "Shop 4"
    0x21 = "30R"
    0x22 = "100R"
    0x23 = "10R"
}

# Item Types
$global:ITEM_TYPES = @{
    0x00 = "Bombs"
    0x01 = "Wood Sword"
    0x02 = "White Sword"
    0x03 = "Magical Sword"
    0x04 = "Bait"
    0x05 = "Recorder"
    0x06 = "Blue Candle"
    0x07 = "Red Candle"
    0x08 = "Wooden Arrow"
    0x09 = "Silver Arrow"
    0x0A = "Bow"
    0x0B = "Magical Key"
    0x0C = "Raft"
    0x0D = "Ladder"
    0x0E = "Triforce"
    0x0F = "5 Rupees"
    0x10 = "Wand"
    0x11 = "Book"
    0x12 = "Blue Ring"
    0x13 = "Red Ring"
    0x14 = "Power Bracelet"
    0x15 = "Letter"
    0x16 = "Compass"
    0x17 = "Map"
    0x18 = "1 Rupee"
    0x19 = "Key"
    0x1A = "Heart Container"
    0x1B = "Triforce"
    0x1C = "Shield"
    0x1D = "Boomerang"
    0x1E = "Magical Boomerang"
    0x1F = "Blue Potion"
    0x20 = "Red Potion"
    0x22 = "Heart"
    0x3F = "Nothing"
}

# Room Types
$global:ROOM_TYPES = @{
    0x00 = "Plain"
    0x01 = "Spike Trap"
    0x02 = "Four Short"
    0x03 = "Four Tall"
    0x04 = "Aqua Room"
    0x05 = "Gleeok Room"
    0x06 = "Gohma Room"
    0x07 = "Three Rows"
    0x08 = "Reverse C"
    0x09 = "Circle Wall"
    0x0A = "Double Block"
    0x0B = "Lava Moat"
    0x0C = "Maze Room"
    0x0D = "Grid Room"
    0x0E = "Vert. Chute"
    0x0F = "Horiz. Chute"
    0x10 = "Vertical Rows"
    0x11 = "Zigzag"
    0x12 = "T Room"
    0x13 = "Vert. Moat"
    0x14 = "Circle Moat"
    0x15 = "Pointless Moat"
    0x16 = "Chevy"
    0x17 = "NSU"
    0x18 = "Horiz. Moat"
    0x19 = "Double Moat"
    0x1A = "Diamond Stair"
    0x1B = "Corridor Stair"
    0x1C = "Spiral Stair"
    0x1D = "Double Six"
    0x1E = "Single Six"
    0x1F = "Five Pair"
    0x20 = "Turnstile"
    0x21 = "Entrance Room"
    0x22 = "Single Block"
    0x23 = "Two Fireball"
    0x24 = "Four Fireball"
    0x25 = "Desert Room"
    0x26 = "Black Room"
    0x27 = "Zelda Room"
    0x28 = "Gannon Room"
    0x29 = "Triforce Room"
}

# Enemy Types
$global:ENEMY_TYPES = @{
    0x00 = ""
    0x01 = "Blue Lynel"
    0x02 = "Red Lynel"
    0x03 = "Blue Moblin"
    0x04 = "Red Moblin"
    0x05= "Blue Goriya"
0x06= "Red Goriya"
0x07= "Red Octorok"
0x08= "Red Octorok"
0x09= "Blue Octorok"
0x0A= "Blue Octorok"
0x0B= "Red Darknut"
0x0C= "Blue Darknut"
0x0D= "Blue Tektite"
0x0E= "Red Tektite"
0x0F= "Blue Lever"
0x10= "Red Lever"
0x12= "Vire" 
0x13= "Zol"
0x14= "Gel"
0x15= "Gel"
0x16= "Pols Voice"
0x17= "Like Like"
0x1A= "Peahat"
0x1B= "Blue Keese"
0x1C= "Red Keese"
0x1D= "Black Keese"
0x1E= "Armos"
0x1F= "Falling Rocks"
0x20= "Falling Rock"
0x21= "Ghini"
0x22= "Ghini"
0x23= "Blue Wizzrobe"
0x24= "Red Wizzrobe"
0x27= "Wallmaster"
0x28= "Rope"
0x2A= "Stalfos"
0x2B= "Bubble"
0x2C= "Blue Bubble"
0x2D= "Red Bubble"
0x30= "Gibdo"
0x31= "3 Dodongos"
0x32= "1 Dodongo"
0x33= "Blue Gohma"
0x34= "Red Gohma"
0x35= "Rupee Boss"
0x36= "Hungry Enemy"
0x37= "The Kidnapped"
0x38= "Digdogger (3)"
0x39= "Digdogger (1)"
0x3A= "Red Lanmola"
0x3B= "Blue Lanmola"
0x3C= "Manhandala"
0x3D= "Aquamentus"
0x3E= "The Beast"
0x41= "Moldorm"
0x42= "1 Head Gleeok"
0x43= "2 Head Gleeok"
0x44= "3 Head Gleeok"
0x45= "4 Head Gleeok"
0x46= "Gleeok Head"
0x47= "Patra (Ellipse)"
0x48= "Patra (Circle)"
0x49= "Horiz. Traps"
0x4A= "Corner Traps"
0x4B= "Hint #1"
0x4C= "Hint #2"
0x4D= "Hint #3"
0x4E= "Hint #4"
0x4F= "Bomb Upgrade"
0x50= "Hint #6"
0x51= "Mugger"
0x52= "Hint #5"
0x62= "Enemy Mix A"
0x63= "Enemy Mix B"
0x64= "Enemy Mix C"
0x65= "Enemy Mix D"
0x66= "Enemy Mix E"
0x67= "Enemy Mix F"
0x68= "Enemy Mix G"
0x69= "Enemy Mix H"
0x6A= "Enemy Mix I"
0x6B= "Enemy Mix J"
0x6C= "Enemy Mix K"
0x6D= "Enemy Mix L"
0x6E= "Enemy Mix M"
0x6F= "Enemy Mix N"
0x70= "Enemy Mix O"
0x71= "Enemy Mix P"
0x72= "Enemy Mix Q"
0x73= "Enemy Mix R"
0x74= "Enemy Mix S"
0x75= "Enemy Mix T"
0x76= "Enemy Mix U"
0x77= "Enemy Mix V"
0x78= "Enemy Mix W"
0x79= "Enemy Mix X"
0x7A= "Enemy Mix Y"
0x7B= "Enemy Mix Z"
0x7C= "Enemy Mix AA"
0x7D= "Enemy Mix BB"
0x7E= "Enemy Mix CC"
0x7F= "Enemy Mix DD"
}

$global:OVERWORLD_BLOCK_TYPES = @{
    0x00= "Bomb"  # 2nd quest level 9
    0x01= "Bomb"
    0x02= "Bomb" #2nd quest only
    0x03= "Bomb"
    0x04= "Open"
    0x05= "Bomb" # 1st quest level 9
    0x06= "Recorder" #2nd quest only
    0x07= "Bomb" 
    0x09= "Power Bracelet" #2nd quest only
    0x0A= "Open"
    0x0B= "Open"
    0x0C= "Open"
    0x0D= "Bomb"
    0x0E= "Open"
    0x0F= "Open"  # 1st quest 100 secret
    0x10= "Bomb"  
    0x11= "Power Bracelet" # 2nd quest letter cave
    0x12= "Bomb" 
    0x13= "Bomb"
    0x14= "Bomb"
    0x15= "Bomb" # 2nd quest only
    0x16= "Bomb" 
    0x18= "Ladder+Bomb" #  quest only
    0x19= "Ladder+Bomb" # 2nd quest only
    0x1A= "Open"
    0x1B= "Power Bracelet" # 2nd quest only
    0x1C= "Open"
    0x1D= "Power Bracelet"
    0x1E= "Bomb"
    0x1F= "Open"
    0x20= "Open"  # 2nd quest Grave block
    0x21= "Open" # 1st quest Grave block
    0x22= "Open" # 1Q6
    0x23= "Power Bracelet"
    0x24= "Open"
    0x25= "Open"
    0x26= "Bomb" # forgotten spot
    0x27= "Bomb" # 1st quest only
    0x28= "Candle"
    0x29= "Recorder" #2nd quest only
    0x2B= "Recorder" #2nd quest only
    0x2C= "Bomb"  # 1st quest only
    0x2D= "Bomb"
    0x2F= "Raft"
    0x30= "Recorder"  # 2nd quest level 6
    0x33= "Bomb"
    0x34= "Open"
    0x37= "Open" 
    0x3A= "Recorder"  # 2nd quest only
    0x3C= "Recorder"  # 2nd quest level 3
    0x3D= "Open"
    0x42= "Recorder" # 1st quest level 7
    0x44= "Open"
    0x45= "Raft" # 1st quest level 4
    0x46= "Candle" 
    0x47= "Candle"  # 1st quest only 
    0x48= "Candle" 
    0x49= "Power Bracelet" 
    0x4A= "Open"
    0x4B= "Candle"
    0x4D= "Candle"
    0x4E= "Open"
    0x51= "Candle"
    0x53= "Candle"  # 2nd quest only
    0x56= "Candle" 
    0x58= "Recorder"  # 2nd quest only
    0x5B= "Candle"
    0x5E= "Open"
    0x60= "Recorder"  # 2nd quest onlye
    0x62= "Candle" # 1st quest only
    0x63= "Candle"
    0x64= "Open"
    0x66= "Open" 
    0x67= "Bomb"  # 1st quest only 
    0x68= "Candle" 
    0x6A= "Candle"
    0x6B= "Candle"  # 1st quest only
    0x6C= "Candle"  # 2nd quest only
    0x6D= "Candle"  # 1st quest only
    0x6E= "Recorder"  # 2nd quest only
    0x6F= "Open" 
    0x70= "Open" 
    0x71= "Bomb"  # 1st quest only
    0x72= "Recorder" #2nd quest only
    0x74= "Open"
    0x75= "Open"
    0x76= "Bomb"
    0x77= "Open" 
    0x78= "Candle" 
    0x79= "Power Bracelet"
    0x7B= "Bomb"  # 1st quest only
    0x7C= "Bomb"
    0x7D= "Bomb"
  }

  $global:CHAR_MAP = @{
    0x00= "0"
    0x01= "1"
    0x02= "2"
    0x03= "3"
    0x04= "4"
    0x05= "5"
    0x06= "6"
    0x07= "7"
    0x08= "8"
    0x09= "9"
    0x0A= "A"
    0x0B= "B"
    0x0C= "C"
    0x0D= "D"
    0x0E= "E"
    0x0F= "F"
    0x10= "G"
    0x11= "H"
    0x12= "I"
    0x13= "J"
    0x14= "K"
    0x15= "L"
    0x16= "M"
    0x17= "N"
    0x18= "O"
    0x19= "P"
    0x1A= "Q"
    0x1B= "R"
    0x1C= "S"
    0x1D= "T"
    0x1E= "U"
    0x1F= "V"
    0x20= "W"
    0x21= "X"
    0x22= "Y"
    0x23= "Z"
    0x24= " "
    0x25= ""
    0x28= ""
    0x29= "!"
    0x2A= "'"
    0x2C= '.'
    0x2E= "?"
    0x2F= "-"
  }

# Palette Colors
$global:PALETTE_COLORS = @(
   "#7C7C7C",
"#0000FC",
"#0000BC",
"#4428BC",
"#940084",
"#A80020",
"#A81000",
"#881400",
"#503000",
"#007800",
"#006800",
"#005800",
"#004058",
"#000000",
"#000000",
"#000000",
"#BCBCBC",
"#0078F8",
"#0058F8",
"#6844FC",
"#D800CC",
"#E40058",
"#F83800",
"#E45C10",
"#AC7C00",
"#00B800",
"#00A800",
"#00A844",
"#008888",
"#000000",
"#000000",
"#000000",
"#F8F8F8",
"#3CBCFC",
"#6888FC",
"#9878F8",
"#F878F8",
"#F85898",
"#F87858",
"#FCA044",
"#F8B800",
"#B8F818",
"#58D854",
"#58F898",
"#00E8D8",
"#787878",
"#000000",
"#000000",
"#FCFCFC",
"#A4E4FC",
"#B8B8F8",
"#D8B8F8",
"#F8B8F8",
"#F8A4C0",
"#F0D0B0",
"#FCE0A8",
"#F8D878",
"#D8F878",
"#B8F8B8",
"#B8F8D8",
"#00FCFC",
"#F8D8F8",
"#000000",
"#000000"
)

##DataExtractor constants
$global:PALETTE_OFFSET = 0xB
$global:START_ROOM_OFFSET = 0x2F
$global:STAIRWAY_LIST_OFFSET = 0x34
$global:DISPLAY_OFFSET_OFFSET = 0x2D

##RomReader Constants
$global:OVERWORLD_DATA_LOCATION = 0x18400
#$global:LEVEL_1_TO_6_DATA_LOCATION = 0x18700
#$global:LEVEL_7_TO_9_DATA_LOCATION = 0x18A00
$global:LEVEL_1_TO_6_FIRST_QUEST_DATA_LOCATION = 0x18700
$global:LEVEL_7_TO_9_FIRST_QUEST_DATA_LOCATION = 0x18A00
$global:LEVEL_1_TO_6_SECOND_QUEST_DATA_LOCATION = 0x18D00
$global:LEVEL_7_TO_9_SECOND_QUEST_DATA_LOCATION = 0x19000
$global:OVERWORLD_POINTER_LOCATION = 0x18000
$global:LEVEL_1_TO_6_POINTER_LOCATION = 0x18002
$global:LEVEL_7_TO_9_POINTER_LOCATION = 0x1800E



$global:VARIOUS_DATA_LOCATION = 0x19300
$global:NES_HEADER_OFFSET = 0x10
$global:ARMOS_ITEM_ADDRESS = 0x10CF5
$global:COAST_ITEM_ADDRESS = 0x1788A
$global:WS_ITEM_ADDRESS = 0x18607
$global:TRIFORCE_COUNT_ADDRESS = 0x5F17

[boolean] $FirstHalfFirstQuest = $true
[boolean] $SecondHalfFirstQuest = $true

##Convert RomReader Class below
class RomReader {
    [string] $romPath
    [System.IO.Stream] $romStream

    RomReader ([string] $romPath) {
        $this.romPath = $romPath
        $this.romStream = [System.IO.File]::OpenRead($romPath)
    }
    ###Experimental
    RomReader ([IO.MemoryStream]$stream) {
        #$this.romStream = new-object IO.MemoryStream
        #$stream.CopyTo($this.romStream)
        $this.romStream = $stream
    }
    ####

    [array] _ReadMemory([int] $address, [int] $numBytes = 1) {
        if ($numBytes -le 0) {
            throw "num_bytes shouldn't be negative"
        }

        $this.romStream.Seek($address + $global:NES_HEADER_OFFSET, 'Begin') | Out-Null
        $buffer = New-Object byte[] $numBytes
        $this.romStream.Read($buffer, 0, $numBytes) | Out-Null
        return $buffer
    }

    [System.Collections.Generic.List[int]] _GetLevelBlockPointer([int] $address){
        $val = $this._ReadMemory($address,0x02)
        return ($val[1] * 0x100) + $val[0]
    }

    [array] GetLevelBlock([int] $levelNum) {
        if ($levelNum -eq 0) {
            return $this._ReadMemory($global:OVERWORLD_DATA_LOCATION, 0x300)
        }
        if ($levelNum -in 1..6) {
            #return $this._ReadMemory($global:LEVEL_1_TO_6_DATA_LOCATION, 0x300)
            if ($this._GetLevelBlockPointer($global:LEVEL_1_TO_6_POINTER_LOCATION) -eq 0x8700){
                $global:FirstHalfFirstQuest = $true
                return $this._ReadMemory($global:LEVEL_1_TO_6_FIRST_QUEST_DATA_LOCATION, 0x300)
            }
            elseif($this._GetLevelBlockPointer($global:LEVEL_1_TO_6_POINTER_LOCATION) -eq 0x8D00){
                $global:FirstHalfFirstQuest = $false
                return $this._ReadMemory($global:LEVEL_1_TO_6_SECOND_QUEST_DATA_LOCATION, 0x300)
            }
            else{
                throw "Error processing Level 1-6 data location"
            }
        }
        if ($levelNum -in 7..9) {
            #return $this._ReadMemory($global:LEVEL_7_TO_9_DATA_LOCATION, 0x300)
            #$loc = $this._ReadMemory($global:LEVEL_7_TO_9_POINTER_LOCATION, 0x01)[0]
            if ($this._GetLevelBlockPointer($global:LEVEL_7_TO_9_POINTER_LOCATION) -eq 0x8A00){
                $global:SecondHalfFirstQuest = $true
                return $this._ReadMemory($global:LEVEL_7_TO_9_FIRST_QUEST_DATA_LOCATION, 0x300)
            }
            elseif($this._GetLevelBlockPointer($global:LEVEL_7_TO_9_POINTER_LOCATION) -eq 0x9000){
                $global:SecondHalfFirstQuest = $false
                return $this._ReadMemory($global:LEVEL_7_TO_9_SECOND_QUEST_DATA_LOCATION, 0x300)
            }
            else{
                throw "Error processing Level 7-9 data location"
            }
        }
        return @()
    }

    [array] GetLevelInfo([int] $levelNum) {
        $start = $global:VARIOUS_DATA_LOCATION + $levelNum * 0xFC
        return $this._ReadMemory($start, 0xFC)
    }

    [array] GetOverworldItemData() {
        return @(
            ($this._ReadMemory($global:ARMOS_ITEM_ADDRESS, 1))[0],
            ($this._ReadMemory($global:COAST_ITEM_ADDRESS, 1))[0],
            ($this._ReadMemory($global:WS_ITEM_ADDRESS, 1))[0]
        )
    }

    [int] GetTriforceRequirement() {
        return ($this._ReadMemory($global:TRIFORCE_COUNT_ADDRESS, 1))[0]
    }

    [string] GetQuote([int] $num) {
        if ($num -notin 0..37) {
            throw "num is out of range (0-37)"
        }

        $lowByte = ($this._ReadMemory(0x4000 + 2 * $num, 1))[0]
        $highByte = ($this._ReadMemory(0x4000 + 2 * $num + 1, 1))[0] - 0x40
        $addr = ($highByte * 0x100) + $lowByte
        ##Write-Host ("high: {0:X}, low: {1:X}, addr: {2:X}" -f $highByte, $lowByte, $addr)

        $rawQuote = $this._ReadMemory($addr, 0x40)
        $outQuote = ""

        foreach ($val in $rawQuote) {
            $char = $val -band 0x3F
            $outQuote += $global:CHAR_MAP[$char]
            $highBits = ($val -shr 6) -band 0x03
            if ($highBits -in @(1, 2)) {
                $outQuote += " "
            }
            if ($highBits -eq 3) {
                break
            }
        }

        return $outQuote
    }

    [string] GetRandomizerVersion(){
        $bytearray = $this._ReadMemory(0x1AB16,10)
        $versionNumber = @()
        foreach ($byte in $bytearray){
            $char = $byte -band 0x3F
            $versionNumber += $global:CHAR_MAP[$char]
        }
        return ($versionNumber -join "").Trim()
    }

    [string] HexToText ([array]$hex){
        [string]$tbr = ""
        foreach($val in $hex) {
            $char = $val -band 0x3F
            if ($global:CHAR_MAP.ContainsKey($char)) {
                [string]$tbr += [string]$global:CHAR_MAP[$char]
            }
        }
        return $tbr -join ""
    }

    [string] GetRecorderText(){
        $rawquote = $this._ReadMemory(0xB000, 0x40)
            # Check if the first byte is not 8
        if ($rawQuote[0] -ne 8) {
            return ""
        }

        $recorderLen = $rawQuote[0]
        $nameLen = $rawQuote[3 + $recorderLen]
        $nameText = $rawQuote[(4 + $recorderLen)..(2 + $recorderLen + $nameLen - 1)]
    
        $fromLen = $rawQuote[5 + $recorderLen + $nameLen]
        $fromText = $rawQuote[(4 + $recorderLen + $nameLen)..(3 + $recorderLen + $nameLen + $fromLen)]

        # Convert hex values to text and return the joined string
        $name = $this.HexToText($nameText)
        $from = $this.HexToText($fromText)
        return ($name + " " + $from)
    }

    Dispose() {
        $this.romStream.Close()
        $this.romStream.Dispose()
    }
}

##DataExtractor conversion below
class DataExtractor {
    [string] $rom
    [RomReader] $romReader
    [hashtable] $data = @{}
    [hashtable] $shopData = @{}
    [bool] $isZ1R = $true
    [array] $levelInfo = @()
    [object[]] $levelBlocks = @()

    DataExtractor([string] $romPath) {
        try {
            $this.ProcessRom($romPath)
            return
        } catch {
            throw "$_.exception"
        }
    }

    ##More experimental
    DataExtractor([IO.Stream] $romPath) {
        try {
            $this.ProcessRom($romPath)
            return
        } catch {
            throw "$_.exception"
        }
    }

    [void] ProcessRom($romPath) {
        $this.romReader = [RomReader]::new($romPath)
        $this.levelInfo = new-object System.Collections.Generic.List[System.Object[]]
        $this.data = @{}
        $this.shopData = @{}

        for ($levelNum = 0; $levelNum -lt 10; $levelNum++) {
            $currentlevelInfo = $this.romReader.GetLevelInfo($levelNum)
            $this.levelInfo += , @($currentlevelInfo)
            $vals = $currentlevelInfo[0x34..0x3D]
            if ($vals[-1] -in 0..4) { continue }
            $this.isZ1R = $false
        }

        $this.levelBlocks = @()
        foreach ($levelNum in @(0, 1, 7)) {
            $this.levelBlocks += , $this.romReader.GetLevelBlock($levelNum)
        }

        $this.ProcessOverworld()
        for ($levelNum = 1; $levelNum -lt 10; $levelNum++) {
            $this.ProcessLevel($levelNum)
        }
    }

    [int] GetRoomData([int] $levelNum, [int] $byteNum) {
        $foo = switch ($levelNum) {
            0 { 0 }
            { $_ -in 1..6 } { 1 }
            { $_ -in 7..9 } { 2 }
            default { throw "Invalid level number" }
        }
        return $this.levelBlocks[$foo][$byteNum]
    }

    [Direction] GetLevelEntranceDirection([int] $levelNum) {
        if (-not $this.isZ1R) {
            return [Direction]::SOUTH
        }
        $stairwayList = $this._GetRawLevelStairwayRoomNumberList($levelNum)
        $lastStair = $stairwayList[-1]
        return $global:ENTRANCE_DIRECTION_MAP[[int]$lastStair]
    }

    [int] GetLevelStartRoomNumber([int] $levelNum) {
        return $this.levelInfo[$levelNum][$global:START_ROOM_OFFSET]
    }

    [array] GetLevelStairwayRoomNumberList([int] $levelNum) {
        $stairwayList = $this._GetRawLevelStairwayRoomNumberList($levelNum)
        if ($this.isZ1R) {
            $stairwayList.RemoveAt($stairwayList.Count - 1)
        }
        return $stairwayList
    }

    [System.Collections.Generic.List[int]] _GetRawLevelStairwayRoomNumberList([int] $levelNum) {
        $vals = $this.levelInfo[$levelNum][$global:STAIRWAY_LIST_OFFSET..($global:STAIRWAY_LIST_OFFSET + 9)]
        $stairwayList = @()
        foreach ($val in $vals) {
            if ($val -ne 0xFF) {
                $stairwayList += $val
            }
        }
        if ($levelNum -eq 3 -and $stairwayList.Count -eq 0) {
            $stairwayList += 0x0F
        }
        return $stairwayList
    }

    [void] ProcessOverworld() {
        for ($shopType = 0x10; $shopType -lt 0x24; $shopType++) {
            $baseIndex = 4 * 0x80 + 3 * ($shopType - 0x10)
            $priceIndex = 4 * 0x80 + 3 * ($shopType - 0x10) + 0x14 * 3
            $this.shopData[$shopType] = @(
                ($this.levelBlocks[0][$baseIndex] -band 0x3F),
                ($this.levelBlocks[0][$baseIndex + 1] -band 0x3F),
                ($this.levelBlocks[0][$baseIndex + 2] -band 0x3F),
                $this.levelBlocks[0][$priceIndex],
                $this.levelBlocks[0][$priceIndex + 1],
                $this.levelBlocks[0][$priceIndex + 2]
            )
        }

        $this.data[0] = @{}
        for ($screenNum = 0; $screenNum -lt 0x80; $screenNum++) {
            if (($this.GetRoomData(0, $screenNum + 5 * 0x80) -band 0x80) -gt 0) {
                continue
            }
            $destination = $this.GetRoomData(0, $screenNum + 1 * 0x80) -shr 2
            if ($destination -eq 0) { continue }
            $x = $screenNum % 0x10
            $y = 8 - [math]::Floor($screenNum / 0x10)

            $blockType = 'Tell Tetra what block type this is'
            if ($global:OVERWORLD_BLOCK_TYPES.ContainsKey($screenNum)) {
                $blockType = $global:OVERWORLD_BLOCK_TYPES[$screenNum]
            }
            $this.data[0][$screenNum] = @{
                screen_num = "{0:x}" -f $screenNum
                col = $x
                x_coord = $x + 0.5
                row = $y
                y_coord = $y - 0.5
                cave = "{0:x}" -f $destination
                block_type = $blockType
            }
            if ($global:CAVE_NAME.ContainsKey($destination)) {
                $this.data[0][$screenNum]['cave_name'] = $global:CAVE_NAME[$destination]
            }
            if ($global:CAVE_NAME_SHORT.ContainsKey($destination)) {
                $this.data[0][$screenNum]['cave_name_short'] = $global:CAVE_NAME_SHORT[$destination]
            }
        }
    }

    [void] ProcessLevel([int] $levelNum) {
        ##$this._VisitRoom($levelNum, $this.GetLevelStartRoomNumber($levelNum), $this.GetLevelEntranceDirection($levelNum))
        #$roomsToVisit = @(@(
        #    ($this.GetLevelStartRoomNumber($levelNum)),
        #    ($this.GetLevelEntranceDirection($levelNum))
        #))

        $this.data[$levelNum] = @{}
        [System.Collections.Generic.List[System.Object]]$roomsToVisit = ,@(($this.GetLevelStartRoomNumber($levelNum)),$this.GetLevelEntranceDirection($levelNum))

        while ($true) {
            # Pop the last room and direction from the list
            $roomInfo = $roomsToVisit[-1]
            $roomsToVisit.RemoveAt(($roomsToVisit.count-1))
            $roomNum = $roomInfo[0]
            $direction = $roomInfo[1]
    
            # Visit the room and get new rooms to visit
            $newRooms = $this._VisitRoom($levelNum, $roomNum, $direction)
            if ($newRooms) {
                $roomsToVisit += $newRooms
            }
            if ($roomsToVisit.Count -eq 0) {
                break
            }
            if($roomsToVisit.count -gt 600) {
                throw "This is an invalid ROM"
            }
        }

        $stairwayNum = 1
        $stairwayRoomNumbers = $this.GetLevelStairwayRoomNumberList($levelNum)

    foreach ($stairwayRoomNum in $stairwayRoomNumbers) {
        $leftExit = $this.GetRoomData($levelNum, $stairwayRoomNum) % 0x80
        $rightExit = $this.GetRoomData($levelNum, $stairwayRoomNum + 0x80) % 0x80

        # Ignore rooms in the stairway list that don't connect to the current level
        if (-not ($this.data[$levelNum].ContainsKey($leftExit) -and $this.data[$levelNum].ContainsKey($rightExit))) {
            continue
        }

        if (-not ($this._HasStairway($levelnum, $leftexit)) -and -not ($this._HasStairway($levelnum, $rightexit))) {
            continue
        }

        if ($leftExit -eq $rightExit) { # Item stairway
            $itemType = [int]($this.GetRoomData($levelNum, $stairwayRoomNum + (4 * 0x80)) % 0x1F)
            $this.data[$levelNum][$leftExit]['stair_info'] = $global:ITEM_TYPES[$itemType]
            $this.data[$levelNum][$leftExit]['stair_tooltip'] = $global:ITEM_TYPES[$itemType]
        } else { # Transport stairway
            $this.data[$levelNum][$leftExit]['stair_info'] = "Stair #$stairwayNum"
            $this.data[$levelNum][$rightExit]['stair_info'] = "Stair #$stairwayNum"
            $this.data[$levelNum][$leftExit]['stair_tooltip'] = "Stairway #$stairwayNum"
            $this.data[$levelNum][$rightExit]['stair_tooltip'] = "Stairway #$stairwayNum"
            $stairwayNum++
        }
    }
    }
    [int] GetLevelDisplayOffset([int]$level_num) {
        return ($this.levelInfo[$level_num][$global:DISPLAY_OFFSET_OFFSET] - 3)
    }

    [array] _VisitRoom([int]$levelNum, [int] $roomNum, [Nullable[Direction]]$fromDir = $null) {

        # Check if room has already been processed
        if ($this.data[$levelNum].ContainsKey($roomNum)) {
            return $null
        }
        if ($roomnum -lt 0 -or $roomnum -ge 0x80) {
            return $null
        }

        $tbr = @()
    
        # Calculate room coordinates
        $x = ($roomNum + ($this.GetLevelDisplayOffset($levelNum))) % 0x10
        $y = 8 - [math]::Floor($roomNum / 0x10)
    
        # Fetch enemy details
        $enemyNum = $this._GetEnemyNum($levelNum, $roomNum)
        $enemyType = $this._GetEnemyType($levelNum, $roomNum)
    
        # Initialize room data
        $this.data[$levelNum][$roomNum] = @{
            col                = $x
            x_coord            = $x - 0.5
            row                = $y
            y_coord            = $y - 0.5
            room_num           = "{0:X}" -f $roomNum
            stair_info         = ""
            stair_tooltip      = "None"
            room_type          = $this._GetRoomType($levelNum, $roomNum)
            enemy_num_tooltip  = "{0:x}" -f $enemyNum
            enemy_type_tooltip = $enemyType
            enemy_info         = $this._GetEnemyText($levelNum, $roomNum)
            item_info          = $this._GetItemText($levelNum, $roomNum)
        }
    
        # Iterate through directions and process walls
        $directions = @([Direction]::NORTH, [Direction]::EAST, [Direction]::SOUTH, [Direction]::WEST)
        foreach ($direction in $directions) {
            $wallType = $this._GetWallType($levelNum, $roomNum, $direction)
    
            if ($wallType -eq [WallType]::SOLID_WALL) {
                $directionText = @{
                    ([Direction]::NORTH) = "north"
                    ([Direction]::SOUTH) = "south"
                    ([Direction]::WEST)  = "west"
                    ([Direction]::EAST)  = "east"
                }
                $directionX = @{
                    ([Direction]::NORTH) = -0.5
                    ([Direction]::SOUTH) = -0.5
                    ([Direction]::WEST)  = -1
                    ([Direction]::EAST)  = 0
                }
                $directionY = @{
                    ([Direction]::NORTH) = 0
                    ([Direction]::SOUTH) = -1
                    ([Direction]::WEST)  = -0.5
                    ([Direction]::EAST)  = -0.5
                }
                if ($this.data[$levelNum].ContainsKey($roomNum + [int]$direction)) {
                    $this.data[$levelNum][$roomNum]["$($directionText[$direction]).color"] = "red"
                }
                $this.data[$levelNum][$roomNum]["$($directionText[$direction]).wall.x"] = $x + $directionX[$direction]
                $this.data[$levelNum][$roomNum]["$($directionText[$direction]).wall.y"] = $y + $directionY[$direction]
                $this.data[$levelNum][$roomNum]["$($directionText[$direction]).wall_type"] = $global:DOOR_TYPES[$wallType]
            } else {
                $directionText = @{
                    ([Direction]::NORTH) = "north"
                    ([Direction]::SOUTH) = "south"
                    ([Direction]::WEST)  = "west"
                    ([Direction]::EAST)  = "east"
                }
                $directionX = @{
                    ([Direction]::NORTH) = -0.5
                    ([Direction]::SOUTH) = -0.5
                    ([Direction]::WEST)  = -0.95
                    ([Direction]::EAST)  = -0.05
                }
                $directionY = @{
                    ([Direction]::NORTH) = -0.05
                    ([Direction]::SOUTH) = -0.95
                    ([Direction]::WEST)  = -0.5
                    ([Direction]::EAST)  = -0.5
                }
                $color = @{
                    ([WallType]::BOMB_HOLE)        = "blue"
                    ([WallType]::LOCKED_DOOR_1)   = "orange"
                    ([WallType]::LOCKED_DOOR_2)   = "orange"
                    ([WallType]::WALK_THROUGH_WALL_1) = "purple"
                    ([WallType]::WALK_THROUGH_WALL_2) = "purple"
                    ([WallType]::SHUTTER_DOOR)    = "brown"
                    ([WallType]::DOOR)            = "black"
                }
                $this.data[$levelNum][$roomNum]["$($directionText[$direction]).x"] = $x + $directionX[$direction]
                $this.data[$levelNum][$roomNum]["$($directionText[$direction]).y"] = $y + $directionY[$direction]
                $this.data[$levelNum][$roomNum]["$($directionText[$direction]).color"] = $color[$wallType]
                $this.data[$levelNum][$roomNum]["$($directionText[$direction]).wall_type"] = $global:DOOR_TYPES[$wallType]
            }
             # Add connected rooms to visit
            if (-not ($fromDir -and $direction -eq $fromDir)) {
            if ($wallType -ne [WallType]::SOLID_WALL) {
                ##$tbr += @(@($roomNum + [int]$direction, [DirectionHelper]::Inverse($direction))) Original
                $tbr += ,@((($roomNum + [int]$direction), [DirectionHelper]::Inverse($direction)))
            }
        }
        }
    
    
        # Check for stairways
        if (-not ($this._HasStairway($levelNum, $roomNum))) {
            return $tbr
        }
        foreach ($stairwayRoomNum in ($this.GetLevelStairwayRoomNumberList($levelNum))) {
            $leftExit = $this.GetRoomData($levelNum,$stairwayRoomNum) % 0x80
            $rightExit = $this.GetRoomData($levelNum, ($stairwayRoomNum + 0x80)) % 0x80
    
            if($leftExit -eq $roomNum -and $rightExit -eq $roomNum){
                break
            }
            elseif ($leftExit -eq $roomNum -and $rightExit -ne $roomNum) {
                $tbr += ,@(($rightExit, [Direction]::NO_DIRECTION))
                break
            } elseif ($rightExit -eq $roomNum -and $leftExit -ne $roomNum) {
                $tbr += ,@(($leftExit, [Direction]::NO_DIRECTION))
                break
            }
        }
        return $tbr
    }

    [WallType] _GetWallType([int]$LevelNum, [int]$RoomNum, [Direction] $Direction){
        $offset = if ($Direction -in @([Direction]::EAST, [Direction]::WEST)) { 0x80 } else { 0x00 }
        $bitsToShift = if ($Direction -in @([Direction]::NORTH, [Direction]::WEST)) { 32 } else { 4 }

        $wallType = [math]::Floor($this.GetRoomData($LevelNum, $RoomNum + $offset) / $bitsToShift) % 0x08
        return $wallType
    }

    [Boolean] _HasStairway([int]$LevelNum, [int]$RoomNum){
        $RoomTypeCode = $this.GetRoomData($LevelNum, $RoomNum + 3 * 0x80) -band 0x3F

        # Spiral Stair, Narrow Stair, and Diamond Stair rooms always have a stairway
        if ($RoomTypeCode -in 0x1A, 0x1B, 0x1C) {
            return $true
        }

        $directions = @([Direction]::NORTH, [Direction]::EAST, [Direction]::SOUTH, [Direction]::WEST)
        foreach ($direction in $directions) {
            if ($this._GetWallType($levelnum, $roomnum, $direction) -eq [WallType]::SHUTTER_DOOR) {
                return $false
            }
        }

        # Check if "Movable block" bit is set in a room_type that has a middle row pushblock
        if ($RoomTypeCode -in 0x01, 0x06, 0x07, 0x08, 0x09, 0x10, 0x0A, 0x0C, 0x0D, 0x11, 0x1F, 0x22) {
            if (($this.GetRoomData($LevelNum, $RoomNum + 3 * 0x80) -shr 6) -band 0x01 -gt 0) {
                return $true
            }
        }
    return $false
    }
    
    [string] _GetRoomType([int]$LevelNum, [int]$RoomNum) {
        $Code = $this.GetRoomData($LevelNum, $RoomNum + 3 * 0x80)
        while ($Code -ge 0x40) {
            $Code -= 0x40
        }
        if ($global:ROOM_TYPES.ContainsKey($Code)) {
            return $global:ROOM_TYPES[$Code]
        }
        return "ERROR CODE $([System.Convert]::ToString($Code, 16))"
    }

    [int] _GetEnemyNum([int]$LevelNum, [int]$RoomNum){
        $Code = [math]::Floor($this.GetRoomData($LevelNum, $RoomNum + 2 * 0x80) / 64)
        switch ($Code) {
            0 { return 3 }
            1 { return 5 }
            2 { return 6 }
            3 { return 8 }
            default { return -1 }
        }
        return -1
    }

    [string] _GetEnemyText([int]$LevelNum, [int]$RoomNum) {
        $Code = $this.GetRoomData($LevelNum, $RoomNum + 2 * 0x80)
        while ($Code -ge 0x40) {
            $Code -= 0x40
        }
        if ($this.GetRoomData($LevelNum, $RoomNum + 3 * 0x80) -ge 0x80) {
            $Code += 0x40
        }

        $NumText = ""
        if (($Code -le 0x30 -or $Code -ge 0x62) -and $Code -ne 0x00) {
            $NumText = "$($this._GetEnemyNum($LevelNum, $RoomNum)) "
        }
        if ($global:ENEMY_TYPES.ContainsKey($Code)) {
            return "$NumText$($global:ENEMY_TYPES[$Code])"
        }
        return "ERROR CODE $([System.Convert]::ToString($Code, 16))"
    }

    [string] _GetEnemyType([int]$LevelNum, [int]$RoomNum) {
        $Code = $this.GetRoomData($LevelNum, $RoomNum + 2 * 0x80)
        while ($Code -ge 0x40) {
            $Code -= 0x40
        }
        if ($this.GetRoomData($LevelNum, $RoomNum + 3 * 0x80) -ge 0x80) {
            $Code += 0x40
        }
        if ($global:ENEMY_TYPES.ContainsKey($Code)) {
            return $global:ENEMY_TYPES[$Code]
        }
        return "E $([System.Convert]::ToString($Code, 16))"
    }

    [string] _GetItemText([int]$LevelNum, [int]$RoomNum) {
        $Code = $this.GetRoomData($LevelNum, $RoomNum + 4 * 0x80)
        while ($Code -ge 0x20) {
            $Code -= 0x20
        }
        if ($Code -eq 0x03) {
            return ""
        }
        $IsDrop = ([math]::Floor($this.GetRoomData($LevelNum, $RoomNum + 5 * 0x80) / 4) % 0x02) -eq 1
        return "$(if ($IsDrop) { 'D ' } else { '' })$($global:ITEM_TYPES[$Code])"
    }
    [array] GetLevelColorPalette([int]$LevelNum){
        $Vals = $this.level_info[$LevelNum][$global:PALETTE_OFFSET..($global:PALETTE_OFFSET + 7)]
        $RGBs = @()
        foreach ($Val in $Vals) {
            $RGBs += $global:PALETTE_COLORS[$Val]
        }
        return $RGBs
    }

    [array] GetOverworldItems() {
        $Result = @()
        foreach ($Item in $this.romreader.GetOverworldItemData()) {
            $thisitem = $global:ITEM_TYPES[[int]$Item]
            $Result += $thisitem
        }
        return $Result
    }

    [int] GetTriforceRequirement(){
        return $this.romreader.GetTriforceRequirement();
    }

    [System.Collections.Generic.List[string]] PrintQuotes() {
        $quotelist = new-object System.Collections.Generic.List[string]
        for ($a = 0; $a -lt 38; $a++) {
            $quote = $this.romReader.GetQuote($a)
            $quotelist.add($quote)
        }
        return $quotelist
    }
    [string] GetRecorderText() {
        return $this.romReader.GetRecorderText()
    }
    [string] GetRandomizerVersion() {
        return $this.romReader.GetRandomizerVersion()
    }

}

# Instantiate DataExtractor
# $extractor = [DataExtractor]::new("path_to_rom_file")

##insert function below to look at an Azure file store

#region Evaluating MSSQL in Azure

##Variables:
$sqlconnectionString = $env:SQLConnectionString
$azureblobconnectionString = $env:azureblobconnectionstring
$global:AzureStorageContainer = $null
$global:ctx = $null
function invoke-sql{
    <#
    .SYNOPSIS
    Excutes a SQL Query against the target database
    
    .DESCRIPTION
    This function will enable the ability to perform SQL queries against a database provided and return a response
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    param( [string] $connectionString,
            [string] $sqlCommand
          )
        Try {
            $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
            $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
            $command.CommandTimeout = 600
            $connection.Open()
    
            $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
            $dataset = New-Object System.Data.DataSet
            $adapter.Fill($dataSet) | Out-Null
    
            $connection.Close()
            return $dataSet.Tables
        }
        catch {
            Write-host $_.Exception
        }
}

$global:BaseSQLScript = @"

BEGIN TRANSACTION;

BEGIN TRY

    [ROMSINSERT]
    [LEVELROOMSINSERT]
    [OVERWORLDLOCATIONS]
    [OVERWORLDSHOPSINSERT]
    [OVERWORLDSHOPITEMSINSERT]
    [OVERWORLDITEMSINSERT]
    [QUOTESINSERT]
    [RECORDERINSERT]

    COMMIT TRANSACTION;
    PRINT 'Transaction committed successfully!';
END TRY

BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Transaction rolled back due to an error!';
    SELECT ERROR_MESSAGE() as ErrorMessage;
END CATCH;
"@

#endregion

#Region Azure Storage Management
function Connect-AzureBlobStorage {
    param (

    )
    if ($null -eq $global:AzureStorageContainer) {
        if ($null -eq $global:ctx) {
            $global:ctx = New-AzStorageContext -ConnectionString $azureblobconnectionstring
        }
        $cont = Get-AzStorageContainer -Context $global:ctx -Name "z1rroms"
        $global:AzureStorageContainer = $cont
        If ($null -eq $global:AzureStorageContainer){
            Write-Host "The storage container was not instantiated"
        }
    }
}

function Get-AzureBlobStream {
    param (
        [string]$FileName
    )
    Connect-AzureBlobStorage
    Write-Host "About to download file $($FileName)"
    Write-host $global:AzureStorageContainer.CloudBlobContainer
    $client = $global:AzureStorageContainer.CloudBlobContainer.GetBlockBlobReference($FileName)
    #$file = $client.DownloadText()
    #$stream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($file))
    $memoryStream = [IO.MemoryStream]::new()
    $client.DownloadToStream($memoryStream)

    return $memoryStream
}

function Get-AllAzureBlobFileNames {
    param (

    )
    Connect-AzureBlobStorage
    $blobArray = $global:AzureStorageContainer.CloudBlobContainer.ListBlobs() | ?{!$_.Name.Contains("ERROR")}
    Return $blobArray
}

function Delete-AzureBlob {
    param (
        $FileName
    )
    Connect-AzureBlobStorage
    $blob = $global:AzureStorageContainer.CloudBlobContainer.GetBlockBlobReference($filename)
    $blob.DeleteIfExists()
}

function Delete-AzureErrorBlobs {
    param (
    )
    Connect-AzureBlobStorage
    $blobs = $global:AzureStorageContainer.CloudBlobContainer.ListBlobs() | ?{$_.Name.Contains("ERROR")}
    foreach ($blob in $blobs) {Delete-AzureBlob -Filename $blob.name }
}


function Rename-AzureBlob {
    param (
        $FileName
    )

    Connect-AzureBlobStorage
    $blob = $global:AzureStorageContainer.CloudBlobContainer.GetBlockBlobReference($filename)
    try {
        $success = Copy-AzStorageBlob -srcblob $filename -SrcContainer $blob.Container.Name -DestContainer $blob.Container.Name -DestBlob $($($blob.Name).replace("nes","ERROR")) -Context $global:ctx -Force
        if ($success) { Delete-AzureBlob -FileName $blob.name }
    }
    catch {
        Write-Host $_.Exception
    }
}


#EndRegion

#Region Actual Database Population

function Get-LocalFileName {
    param (
        [string]$filePath
    )
    return [System.IO.Path]::GetFileName($filePath)
}

function Get-SeedandFlagsFromFileName {
    param (
        [string]$fileName
    )
    $array = $fileName.split('_')
    $thisObj = [ordered]@{
        seed = $array[1]
        flags = $array[2].split('.')[0]
        ext = $array[2].split('.')[1]
    }
    return $thisObj
}

function Get-SeedandFlags {
    param (
        [string]$filePath
    )
    $fileName = Get-LocalFileName -filePath $filePath
    $newObj = Get-SeedandFlagsFromFileName -fileName $fileName
    Return $newObj
}

function Create-SQLQuery {
    param (
        [DataExtractor]$dataextractor,
        $saf
    )
    $thisSQLSCRIPT = $global:BaseSQLScript

    $triforceRequirement = $dataextractor.GetTriforceRequirement()
    $version = $dataextractor.GetRandomizerVersion()
    $SQLINSERTQUERY = @"
    INSERT INTO ROMS (seed, Flags, RandomizerVersion, TriforcesToEnter9)
    VALUES('$($saf.seed)', '$($saf.flags)','$($version)',$($triforceRequirement));
    DECLARE @NewROMID INT = SCOPE_IDENTITY();
"@
    $thisSQLSCRIPT = $thisSQLSCRIPT.Replace("[ROMSINSERT]",$SQLINSERTQUERY)

    $levelScriptBlock = ""
    for ($level =1; $level -lt 10; $level++){
        foreach ($room in $dataextractor.data[$level].Keys){
            $roomData = $dataextractor.data[$level][$room]
            $roomScript = "INSERT INTO LEVELROOMS (RomID, LevelNum, [Location], RoomType, Enemies, ItemDrop, Staircase, WestWall, EastWall, NorthWall, SouthWall) "
            ##Newstuff here
            $leveltoprocess = 1
            if (!$global:FirstHalfFirstQuest -and ($level -eq 2 -OR $level -eq 4)) {
                $leveltoprocess = $level+1
            }
            elseif (!$global:FirstHalfFirstQuest -and ($level -eq 3 -OR $level -eq 5)) {
                $leveltoprocess = $level-1
            }
            elseif (!$global:SecondHalfFirstQuest -and ($level -eq 7)) {
                $leveltoprocess = $level+1
            }
            elseif (!$global:SecondHalfFirstQuest -and ($level -eq 8)) {
                $leveltoprocess = $level-1
            }
            else {
                $leveltoprocess = $level
            }

            $roomScript += "VALUES(@NewROMID,$($leveltoprocess),'$($roomData.room_num)','$($roomData.room_type)','$($roomData.enemy_info)','$($roomData.item_info)','$($roomData.stair_info)','$($roomData."west.wall_type")','$($roomData."east.wall_type")','$($roomData."north.wall_type")','$($roomData."south.wall_type")'); "
            $levelScriptBlock += $roomScript
        }
    }
    $thisSQLSCRIPT = $thisSQLSCRIPT.Replace("[LEVELROOMSINSERT]",$levelScriptBlock)

    $OWScriptBlock = ""
    foreach ($screen in $dataextractor.data[0].Keys){
        $screendata = $dataextractor.data[0][$screen]
        $screenScript = "INSERT INTO OverworldLocations (RomID, Position, [Type], Blocker) "
        $screenScript += "VALUES(@NewROMID,'$($screendata.screen_num)','$($screendata.cave_name)','$($screendata.block_type)'); "
        $OWScriptBlock += $screenScript
    }
    $thisSQLSCRIPT = $thisSQLSCRIPT.Replace("[OVERWORLDLOCATIONS]",$OWScriptBlock)

    $OWShopsScriptBlock = ""
    $shoptypes = 0x1D, 0x1E, 0x1F, 0x20, 0x1A

    foreach ($shoptype in $shoptypes){
        $shopname = $CAVE_NAME[$shoptype]
        $shopscript = "INSERT INTO OverworldShops (RomID, ShopType) "
        $shopscript += "VALUES(@NewROMID,'$($shopname)'); "
        $OWShopsScriptBlock += $shopscript
    }

    $thisSQLSCRIPT = $thisSQLSCRIPT.Replace("[OVERWORLDSHOPSINSERT]",$OWShopsScriptBlock)

    $OWShopPriceScriptBlock = ""
    for ($n=0;$n -lt $shoptypes.Count;$n++){
        $shoptype = $shoptypes[$n]
        $caveName = $CAVE_NAME[$shoptype]
        $itemarray = @()
        for ($i = 0; $i -lt 3; $i++) {
            $itemType = $ITEM_TYPES[$dataextractor.shopdata[$shoptype][$i]]
            $itemPrice = $dataextractor.shopdata[$shoptype][$i + 3]
            $itemarray += [ordered]@{
                ItemType = $itemType
                Price = $itemPrice
            }
        }
        $variablename = "@ShopID$($n)"
        $pricescript = "DECLARE $variablename INT; "
        $pricescript += "SELECT $variablename = Id FROM OverworldShops WHERE RomID = @NewROMID AND ShopType = '$($caveName)'; "
        $pricescript += "INSERT INTO OverworldShopItems (OverworldShopID, Name, Item1, Item1Price, Item2, Item2Price, Item3, Item3Price) "
        $pricescript += "VALUES($variablename,'$($caveName)','$($itemarray[0].ItemType)',$($itemarray[0].Price),'$($itemarray[1].ItemType)',$($itemarray[1].Price),'$($itemarray[2].ItemType)',$($itemarray[2].Price)); "
        $OWShopPriceScriptBlock += $pricescript
    }

    $thisSQLSCRIPT = $thisSQLSCRIPT.Replace("[OVERWORLDSHOPITEMSINSERT]",$OWShopPriceScriptBlock)

    $QuotesScriptBlock = ""
    $quotes = $dataextractor.PrintQuotes()
    foreach ($quote in $quotes){
        $quotescript = "INSERT INTO Quotes (RomID, Quote) "
        $quotescript += "VALUES(@NewROMID,'$($quote.replace("'","''"))'); "
        $QuotesScriptBlock += $quotescript
    }

    $thisSQLSCRIPT = $thisSQLSCRIPT.Replace("[QUOTESINSERT]",$QuotesScriptBlock)

    $recText = $dataextractor.GetRecorderText()
    $recorderscriptblock = "INSERT INTO RecorderTunes (RomID, TuneText) "
    $recorderscriptblock += "VALUES(@NewROMID,'$($recText.replace("'","''"))'); "

    $thisSQLSCRIPT = $thisSQLSCRIPT.Replace("[RECORDERINSERT]",$recorderscriptblock)

    $overworldItems = $dataextractor.GetOverworldItems()

    $overworldScriptBlock = "INSERT INTO OverworldItems (RomID, Armos, Coast, WSItem) "
    $overworldScriptBlock += "VALUES(@NewROMID, '$($overworldItems[0])','$($overworldItems[1])','$($overworldItems[2])'); "

    $thisSQLSCRIPT = $thisSQLSCRIPT.Replace("[OVERWORLDITEMSINSERT]",$overworldScriptBlock)

    return $thisSQLSCRIPT
}


#EndRegion

function Process-SingleROMFromFile {
    param (
        [string]$RomPath
    )
    $saf = Get-SeedandFlags -filePath $romPath

    $dataextractor = [DataExtractor]::new($romPath)
    $sqlquery = Create-SQLQuery -dataextractor $dataextractor -saf $saf
    $sqlResponse = Invoke-Sql -connectionString $sqlconnectionString -sqlCommand $sqlquery
    return $sqlresponse
}

function Process-MultipleROMsFromFile{
    param(
        [array]$listofROMs
    )
    foreach ($rom in $listofroms) {
        Write-Host (Process-SingleROMFromFile -RomPath $rom)
    }
}

function global:Process-SingleROMFromAzure {
    param (
        [string]$FileName
    )
    $saf = Get-SeedandFlagsFromFileName -fileName $FileName
    $stream = Get-AzureBlobStream -FileName $FileName
    $dataextractor = [DataExtractor]::new($stream)
    $sqlquery = Create-SQLQuery -dataextractor $dataextractor -saf $saf
    $sqlResponse = Invoke-Sql -connectionString $sqlconnectionString -sqlCommand $sqlquery
    $stream.dispose()
    return $sqlresponse
}

function global:Process-FromAzure {
    param (
        [string]$FileName
    )
    $saf = Get-SeedandFlagsFromFileName -fileName $FileName
    if (!$saf.ext.tolower().contains("nes")){
        
    }
    Write-Host "About to look for file $($filename)"
    $stream = Get-AzureBlobStream -FileName $FileName
    $sqlresponse = $null
    $dataextractor = [DataExtractor]::new($stream)
    $sqlquery = Create-SQLQuery -dataextractor $dataextractor -saf $saf
    try {
        $sqlResponse = Invoke-Sql -connectionString $sqlconnectionString -sqlCommand $sqlquery
        if ($sqlresponse.ItemArray.count -gt 0) {
            Write-Host "Could not process ROM $($_.filename)"
            Write-Host $output.ItemArray[0]
            Rename-AzureBlob -FileName $FileName
        }
        else {
            Write-Host "Successfully processed ROM $($filename)"
            Delete-AzureBlob -FileName $filename
        }
    }
    catch {
        write-host $_.Exception
    }
    $stream.dispose()
}

function global:Process-FromAzureStream {
    param (
        [string]$FileName,
        [System.IO.MemoryStream]$stream
    )
    $saf = Get-SeedandFlagsFromFileName -fileName $FileName
    if (!$saf.ext.tolower().contains("nes")){
        Write-Host "Not a valid file of $($filename)"
        return
    }
    Write-Host "About to look for file $($filename)"
    $sqlresponse = $null
    $dataextractor = [DataExtractor]::new($stream)
    $sqlquery = Create-SQLQuery -dataextractor $dataextractor -saf $saf
    try {
        $sqlResponse = Invoke-Sql -connectionString $sqlconnectionString -sqlCommand $sqlquery
        if ($sqlresponse.ItemArray.count -gt 0) {
            Write-Host "Could not process ROM $($filename)"
            #Write-Host $output.ItemArray[0]
            Rename-AzureBlob -FileName $FileName
        }
        else {
            Write-Host "Successfully processed ROM $($filename)"
            Delete-AzureBlob -FileName $filename
        }
    }
    catch {
        write-host $_.Exception
    }
    $stream.dispose()
}

function Process-MultipleROMsFromAzure {
    param (
        [array]$listofRoms
    )
    foreach ($rom in $listofRoms) {
        try {
            Write-Host (Process-SingleROMFromAzure -FileName $rom)
        }
        catch {

        }
    }
}

function Process-AllROMsFromAzureStorage {
    param (
    )
    $listofRoms = Get-AllAzureBlobFileNames
    $listofRoms | ForEach-Object {
        $output = Process-SingleROMFromAzure -FileName $_.Name
        if ($output.ItemArray.count -gt 0) {
            Write-Host "Could not process ROM $($_.name)"
            Write-Host $output.ItemArray[0]
            Rename-AzureBlob -FileName $_.Name
        }
        else {
            Write-Host "Successfully processed ROM $($_.name)"
            Delete-AzureBlob -FileName $_.name
        }
    }
}

$filenamestring = $TriggerMetadata.Name
$blobStream = New-Object System.IO.MemoryStream(,$inputblob)
Process-FromAzureStream -FileName $filenamestring -stream $blobStream
