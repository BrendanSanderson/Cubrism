# Cubrism

The language of Cubrism's dungeon and progression design. These terms describe
the proposed dungeon direction; the game currently uses selectable levels.

## Language

**Dungeon**:
The repeatable adventure explored through generated floors at the player's
current Delve Level.
_Avoid_: World

**Floor attempt**:
One attempt to clear a generated floor, ending in a successful clear, death,
or deliberate abandonment.
_Avoid_: Run when it could mean several consecutive floors

**Run**:
A consecutive descent through one or more floors, ending on death, deliberate
abandonment, or safe exit at a checkpoint.
_Avoid_: Floor attempt, Delve Level

**Floor**:
A generated dungeon containing a starting room, combat rooms, and a boss.
_Avoid_: Level when it could mean character progression or item power

**Checkpoint**:
The boundary after a successful floor clear where loot is offered and Delve
Level is adjusted, with a choice to leave safely or continue risking run loot.
_Avoid_: Mid-floor save point

**Depth**:
The floor number reached within the current run, beginning at floor one.
_Avoid_: Player level, item level, Delve Level

**Run bonus**:
The additional loot, experience, and Delve Level gains associated with
continuing through consecutive floors in the same run.
_Avoid_: Delve Level, character level

**Delve Level**:
The permanent account difficulty score around which the next floor's hidden
difficulty is sampled, increasing on success or decreasing on failure, with
no maximum.
_Avoid_: Dungeon rating, Elo, depth, character level

**Character level**:
The character's XP-based progression, which improves intrinsic stats up to
the current character-level cap independently of Delve Level.
_Avoid_: Delve Level, depth, item power

**Lifetime XP**:
The cumulative experience earned, including experience earned at the character
cap that cannot be spent on future levels.
_Avoid_: Banked XP, run loot

**Item power**:
The strength associated with an item's generating difficulty, distinct from
its rarity and able to keep increasing after the character reaches the XP cap.
_Avoid_: Character level, rarity

**Run loot**:
Items acquired during the active run that are lost on death and become banked
loot only when the player leaves safely at a checkpoint.
_Avoid_: Banked loot, permanent inventory

**Banked loot**:
Items secured by leaving a run safely at a checkpoint and retained between runs.
_Avoid_: Run loot

**Floor difficulty**:
The hidden Delve-equivalent score sampled around the account's Delve Level to
determine the challenge and rewards of one floor.
_Avoid_: Account Delve Level, difficulty budget

**Difficulty budget**:
The floor's difficulty-point allowance derived from its hidden floor difficulty
and used to shape ordinary combat rooms, with the guaranteed final boss outside
that budget.
_Avoid_: Delve Level, floor difficulty, depth

**Scaling level**:
The continuous, zero-based measure of power growth above starting difficulty,
used to scale enemy, boss, and gear strength.
_Avoid_: Character level, raw Delve Level

**Rarity**:
An equipment quality tier—Common, Uncommon, Rare, Epic, or Legendary—that determines
the strength of the item's stat contributions at a given power level.
_Avoid_: Item power, Delve Level

**Epic**:
The purple equipment rarity above Rare and below Legendary.
_Avoid_: Legendary when referring to purple equipment

**Legendary**:
The orange equipment rarity above Epic.
_Avoid_: Epic, purple equipment

**Rare-or-better**:
The combined group of Rare, Epic, and Legendary equipment.
_Avoid_: Rare when referring to the whole group

**Reference loadout**:
A representative set of average equipment at the item power and rarity used
to define combat pacing for a given Delve difficulty.
_Avoid_: Best possible gear, the player's actual equipped gear

**Reference character**:
The hypothetical character whose intrinsic stats and reference loadout define
enemy difficulty, able to exceed the actual character-level cap in endgame.
_Avoid_: Actual character level, bonus levels, item power

**Difficulty points**:
The units used to price enemy encounters and the additional challenge of
fighting enemies together in a room.
_Avoid_: Experience, Delve Level gains

**Room cost**:
The difficulty points charged for a room's enemies and the extra challenge of
their combination.
_Avoid_: Enemy count, room count

**Minimum Delve Level**:
The lowest sampled floor difficulty at which an enemy type is eligible for
random selection.
_Avoid_: Guaranteed introduction, character level requirement

**Run health maximum**:
The highest maximum-health capacity the player has reached during the current
run, retained even after changing to gear with lower capacity.
_Avoid_: Current health, current maximum health

**Run shield maximum**:
The highest maximum-shield capacity the player has reached during the current
run, retained even after changing to gear with lower capacity.
_Avoid_: Current shield, current maximum shield
