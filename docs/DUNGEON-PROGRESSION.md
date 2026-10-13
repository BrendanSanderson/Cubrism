# Cubrism dungeon progression design

Status: foundation implemented in the refactor worktree, updated October 12, 2026.
Native Swift scenario checks and code review pass; full XCTest execution is
blocked by the host toolchain. Gameplay UI and live combat integration have not started.

Replace the 50 selectable stages with a repeatable dungeon explored through
generated floors. Delve Level is the permanent account difficulty score; each
floor has a hidden difficulty sampled around it. Continuing the same run offers
greater rewards and Delve Level gains while risking all loot acquired during
that run. Experience is retained on death and improves character stats up to
the character cap. Delve and generated item power remain uncapped.

## Settled decisions

- A floor contains a starting room, combat rooms, and one guaranteed final
  boss. Only ordinary combat rooms spend the encounter-point budget; the final
  boss needs no allowance or point cost.
- Clearing a floor reaches a checkpoint and adjusts account Delve Level before
  another floor can begin.
- Success increases Delve Level; failure decreases it. The ordinary-clear
  target is roughly 10 Delve points, interpreting "10 Delve per level" as
  about 10 points per completed floor.
- Progress is an overall climb with plateaus. Losses are small initially and
  become more substantial later in progression. Better gear, retained
  experience, and better play provide routes through plateaus.
- Accepted October 3: reaching Delve 10000 should take about 50 hours of
  representative active play, including failures and continuation bonuses,
  excluding idle and menu time. Keep the target configurable. The earlier
  137-hour illustrative route is superseded.
- Delve Level has no maximum. Delve 10000 is a pacing and rarity milestone,
  not an ending. Floor difficulty and generated gear power keep scaling
  beyond it. Only base rarity probabilities plateau at the accepted endpoints.
- Character level is capped at 100 for v1, with room to raise that cap later.
  XP earned at the cap contributes only to lifetime XP; it grants no further
  stats and is not banked toward future levels. If the cap increases, earning
  new levels requires new XP. This applies to excess XP from the award that
  reaches the cap as well as later awards. Earned XP remains retained on death.
- After the character cap, power growth comes from acquiring better gear:
  higher item power, better rarity, and appropriate stat combinations. There
  is no globally strongest final item while generating difficulty is uncapped.
  Distinctive item effects remain future work.
- Beyond Delve 10000, enemy scaling uses a hypothetical reference character
  that keeps leveling: reference level 200 with matching Legendary gear at
  Delve 20000. The actual player remains capped at 100. Extend the existing
  kill-time trajectory against that reference character; actual capped
  characters may take longer and survive fewer hits. Gear power also keeps
  increasing. Accepted October 4: retain the normal gear-growth curve for the
  first version, with no extra growth specifically replacing missing character
  levels. The capped player's intrinsic-stat deficit contributes additional
  difficulty. Tune the numerical curve against gear acquisition and clear rates.
- Gear should be the main source of breakthroughs through difficulty
  plateaus, with character XP providing steady support. Do not calibrate
  unlimited XP grinding as the primary intended way past every wall.
- Around Delve 2500, upward and downward adjustments should be about equal;
  beyond that point, downward adjustments should be larger. Current
  interpretation: compare baseline wins and losses at matched difficulty,
  before separate continuation and performance bonuses. The accepted baseline
  loss is `min(20, 2 + 8 * (R - 1) / 2499)`, giving +10/-10 at 2500 and
  reaching a nominal loss of 20 at 5623.75. Account Delve cannot fall below one.
- At checkpoints players can leave safely or continue with remaining health.
  Continuing improves item count, quality chances, experience, and successful
  Delve Level gains, making later floors more rewarding and more dangerous.
  Increasing rare-item chance is the primary continuation reward and should
  improve substantially more than the other bonuses.
- A run reaching ten consecutive floors should be exceptional. Interpret
  the user's "10 runs ... an amazing run" as ten floors within one run,
  consistent with the prior continuation discussion. This is a balance goal,
  not a ten-floor cap. No exact frequency or typical shorter run length is
  selected yet; do not guarantee a forced failure or impose a hidden cap.
- Accepted continuation bonuses: XP, successful Delve gains, and expected
  item count increase by 10% per additional floor, capped at +50% from floor
  six onward. Award two guaranteed items plus a third with probability twice
  that bonus, reaching three guaranteed items on floor six. Reset on a new
  run. The separate best-of-depth rarity bonus continues beyond floor six.
- Rarity has two progression sources: a strong bonus for consecutive floors
  within one run and slower growth in base chances across account progression.
  The user accepted the quadratic shape and Rare/Epic/Legendary starting
  chances of 15%/5%/1% at Delve 1. The accepted October 3 distribution sets their endpoints
  to 37.5%/15%/5% at Delve 10000, remaining capped thereafter. These are base chances before
  continuation bonuses. The formula is `start + (cap - start) * t * (2 - t)`,
  with `t = clamp((F - 1) / 9999, 0, 1)` and sampled floor difficulty `F`.
  This replaces the older Delve 500/1000 anchors and fixed 80/15/5 pool mix.
  The accepted October 3 distribution makes Rare and Uncommon converge at Delve
  10000. Holding Common, Epic, and Legendary unchanged gives 37.5% each.
  Uncommon rises from 30% to 37.5%; Common falls from 49% to 5%. This accepted
  distribution replaces the previous Rare 50% and Uncommon 25% endpoints.
- Each awarded item takes the best of `d` independent rarity draws on floor
  `d` of the same run. Starting a new run resets to one draw. Previously
  awarded loot never rerolls; every new item uses its own floor's base odds.
- Base rarity uses the saved sampled floor difficulty, matching floor enemy
  strength and generated gear power. A harder rolled floor has better base
  rarity chances until the curve reaches its caps; continuing applies its separate
  rarity bonus afterward.
- Equipment uses five rarities: Common (white), Uncommon (green), Rare (blue),
  Epic (purple), and Legendary (orange). The existing purple fourth tier is
  Epic in this design; orange Legendary is a new fifth tier. Rare-or-better
  includes Rare, Epic, and Legendary.
- Equipment rarity multiplies the entire common item's stat contribution.
  The user generally endorsed Common 1, Uncommon 1.25, Rare 1.5, Epic 2, and
  Legendary 2.5 as starting values, with comparative research requested before
  finalizing their application. The multiplier does not apply to the whole
  character stat. Include starting contributions so early rare gear benefits
  the player. Raw-stat ratios do not guarantee equivalent total-DPS ratios.
- At character level 1 and Delve 1, a full Common set supplies about one-third
  of total attack, HP, and shield. With the intrinsic starting stats retained,
  gear contributes attack 12.5, HP 50, and shield 50. A full Rare set then
  improves initial DPS and capacity by about 17%. Fit enemies to preserve
  the accepted kill and survival benchmarks. This is a starting allocation,
  not a gear-share constraint maintained across all later progression.
- The first version distinguishes rarity through stronger stats only,
  including Legendary gear. Distinctive item effects are a desired future
  addition, outside this refactor's implementation scope.
- Floor clears offer run loot. All loot acquired during the active run remains
  at risk until leaving safely at a checkpoint. Death loses all run loot and
  the failed floor grants no items.
- Run loot can be equipped at checkpoints while remaining at risk. Previously
  banked gear remains owned even if replaced temporarily by run loot.
- Earned experience is retained on death, including experience earned with run
  bonuses. It improves character stats until the cap. Abilities may be added in the future
  and are outside the initial version.
- XP rewards must rise with progression. Design earned XP and level-up costs
  together so increasing requirements do not create an accidental late-game
  grind. Reworking the existing character XP requirement curve is in scope;
  accepted pacing target is `2 + 2 * sqrt(L - 1)` active combat minutes from
  character level `L` to `L + 1`, before continuation bonuses. Reaching level
  100 from level 1 totals about 1,501 minutes (25 hours) at the reference pace.
  The curve applies to levels 1 through 99; v1 has no 100-to-101 requirement.
  Actual XP reward/cost formulas and character stat gains still need calibration.

- Performance scoring includes outcome, speed, damage avoidance, and accuracy.
  The initial good-performance bonus is at most 10 percent greater Delve Level
  gains, separate from challenge and continuation bonuses.
  Accepted weights are 40% speed, 40% accuracy, and 20% damage avoidance.
  This resolves the earlier clarification and replaces equal weighting.
- Each enemy type has a minimum Delve threshold, compared with the sampled
  floor difficulty for random eligibility. A type need not spawn as soon as it
  becomes eligible. Tune thresholds so an average-pace player makes roughly
  one new type eligible per floor while new types remain in the roster.
- Early floors should generally take one to two minutes. There is no hard
  duration cap; higher difficulties can produce floors longer than fifteen
  minutes.
- Combat benchmarks use average gear of the appropriate item power: Common
  at Delve 1, Uncommon at 1000, Rare at 2500, Epic at 5000, and Legendary at
  10000. Average means typical stat values within the named rarity.
- Accepted kill times rise linearly from two to four seconds for a reference
  ordinary enemy between Delve 1 and 5000, and thirty to sixty seconds for a
  reference boss. The intervening targets are about 2.4/36 seconds at Delve
  1000 and 3/45 seconds at 2500, using the matching rarity benchmarks above.
  The user also accepted continuation of that slope to approximately six
  seconds for an ordinary enemy and ninety seconds for a boss at Delve 10000,
  using average Legendary gear. Smoothly evolve the reference equipment
  between rarity anchors so the benchmarks introduce no difficulty jumps.
  Continue that slope beyond 10000 using the uncapped reference character:
  about ten/150 seconds at Delve 20000 for that hypothetical character.
- Incoming damage is calibrated against the green ranged enemy: ten hits to
  deplete full HP plus shields at Delve 1 with average Common gear, and five
  hits at Delve 1000 with average Uncommon gear. Interpolate between the
  anchors and hold the five-hit target thereafter against the appropriate
  reference character and loadout. Above Delve 10000 the actual level-100
  character can survive fewer than five hits because of the intrinsic-stat
  deficit. All other enemies and bosses
  scale relative to that enemy's damage. This replaces the earlier generic
  ordinary-enemy and independent boss hit-count proposals.
- Delve-based difficulty determines an encounter-point budget. Enemy point
  costs are multiplied by a tunable grouping factor for simultaneous room
  pressure. Sparse floors should contain more rooms and more enemies overall
  than dense floors at comparable difficulty.
- Use a decimal, zero-based scaling input: `(delveLevel - 1) / 100`, using the
  sampled floor difficulty for floor enemies and rewards. Re-express the
  existing stat curves for that input, with no gaps or sudden stat jumps.
  The divisor can be absorbed into curve coefficients; changing it without
  compensating coefficients changes the pace of power growth.
- A floor's hidden difficulty is normally distributed around account Delve
  Level, with a standard deviation of five percent of that account score.
  Code uses the sampled value to design the floor, without displaying that
  exact value to the player. The lower-bound policy is proposed below.
- Winning a harder sampled floor gives additional Delve progress; winning an
  easier one gives less. Dying on a harder floor loses fewer points. Compare
  the sampled difficulty with account Delve Level captured at floor entry.
  Enemy and gear numeric power scale from the sampled floor difficulty.
- Increasing maximum health above the greatest maximum already reached during
  the run grants only the newly reached capacity as current health, once.
  Returning to a previously reached maximum does not grant health again.
- Shield capacity changes use the same independent run-maximum rule, and
  shields fully recharge when entering each new floor. Ordinary shield
  regeneration continues. Resuming a floor does not trigger another refill.
- Unfinished runs span sessions, preserving health, loot risk, depth, bonuses,
  and the generated floor. Closing the app does not safely extract the player.
- Deliberately abandoning an unfinished floor counts as failure. A fresh run
  starts at full health and shields with depth and continuation bonuses reset.
- Reset existing saves for the new system. There is no legacy progression,
  inventory, equipment, or currency migration.

See [ADR 0002](adr/0002-risk-run-loot-until-leaving-a-checkpoint.md) for loot
ownership, [ADR 0003](adr/0003-generate-floors-from-difficulty-points.md) for
encounter budgeting, and [ADR 0004](adr/0004-sample-and-preserve-hidden-floor-difficulty.md)
for hidden difficulty. [ADR 0005](adr/0005-reset-legacy-saves-for-delve.md)
records the deliberate save reset. [ADR 0001](adr/0001-settle-progression-at-floor-checkpoints.md)
is superseded.

## Current game facts

Source inspection at commit 8496db6; no new runtime verification was performed.

- Each selected stage already generates a random maze with a safe start,
  ordinary rooms, and a final boss room. The first stage has three ordinary
  rooms plus a boss. See [floor generation](../Cubrism/FloorViewController.swift)
  around line 140 and [stage sizes](../Cubrism/levels.plist).
- Health and shield carry between rooms. Starting a stage or retry heals both;
  returning home also heals. See [stage startup](../Cubrism/FloorViewController.swift)
  around line 79, [player stat refresh](../Cubrism/Player.swift) around line 77,
  and [home entry](../Cubrism/HomeScene.swift) around line 17.
- Boss exits currently settle rewards and return to the home flow. Completion
  immediately saves drops into permanent inventory. See
  [completion handling](../Cubrism/FloorViewController.swift) around line 296 and
  [completion navigation](../Cubrism/CompletedViewController.swift) around line 104.
- Death currently retains roughly 83 percent of accumulated experience and
  grants no equipment. Existing inventory and equipment persist. See
  [death handling](../Cubrism/Player.swift) around line 167.
- Stage one permits three ordinary enemy types; stage two adds one, and stage
  three permits several more. Selection is random, so unlocking a type does
  not guarantee its introduction. See [enemy definitions](../Cubrism/Enemies.plist)
  and [encounter selection](../Cubrism/RoomScene.swift) around line 122.
- The global stage number couples enemy strength, enemy eligibility, experience,
  item level, currency, and rarity. Player experience level separately scales
  player stats and merchant stock. See [scaling](../Cubrism/Constants.swift) and
  [drops](../Cubrism/FloorViewController.swift) around line 371.
- Both keyboard and joystick share a cooldown-gated firing path, and each actual
  shot creates one player projectile. Shots disappear on target or wall
  contact, expiry, or room exit. Firing is possible outside combat, and
  raw contact callbacks do not prove accepted damage. See
  [player shooting](../Cubrism/Components/PlayerComponents.swift) around line 79,
  [shot contacts](../Cubrism/GameScene.swift) around line 310, and
  [room cleanup](../Cubrism/RoomScene.swift) around line 52.
- Equipment swaps currently occur at home and save immediately. Stat refresh
  also restores full health and shield, so it cannot be reused unchanged for
  checkpoint equipment or experience gains with carried health. See
  [equipment swap](../Cubrism/VendorPopUpNode.swift) around line 306 and
  [player refresh](../Cubrism/Player.swift) around line 77.
- Ordinary rooms currently spend a fixed four-point budget independently.
  Enemy definitions already have point costs and minimum stage values, but
  there is no floor-wide budget or combination surcharge. Encounters are
  generated on first room entry. See [room budgeting](../Cubrism/RoomScene.swift)
  around line 128 and [definitions](../Cubrism/Enemies.plist).
- Room count is chosen before encounters, using the selected stage's size
  range. Layout is a chain of rooms ending in a separately selected boss, which
  has no point cost. Completed-room bonuses award extra experience. See
  [layout](../Cubrism/FloorViewController.swift) around line 140 and
  [room completion](../Cubrism/RoomScene.swift) around line 169.
- Current enemy and boss stats already scale with global stage. Increasing
  both encounter budgets and these stat multipliers would increase challenge
  through two curves, so their interaction must be chosen explicitly. See
  [stat multipliers](../Cubrism/Constants.swift) around line 35.

- Final bosses share 2,000 base health, base XP, and stage-scaling formulas, but
  their damage values and mechanics differ. They spawn outside normal-room
  budgets and have no point cost or miniboss role. See
  [boss constants](../Cubrism/constants.json) around line 126 and
  [boss setup](../Cubrism/Entities/BossEntity.swift) around line 27.
- At roughly 10 Delve points per floor, a 100-point scaling band lasts about
  ten successful floors. Ten level-one boss kills and boss-room completion
  bonuses alone currently give 600 XP, enough to reach character level five.
  Calibrate XP payouts alongside the stretched enemy progression; this source
  calculation does not determine the intended future payout. See
  [room rewards](../Cubrism/RoomScene.swift) around line 169 and
  [XP thresholds](../Cubrism/Player.swift) around line 237.
- XP, gear, inventory, and stage progress are written to separate UserDefaults
  keys, without a persisted settlement ID or active run. See
  [completion saves](../Cubrism/FloorViewController.swift) around line 314,
  [player saves](../Cubrism/Player.swift) around lines 220 and 326, and
  [app lifecycle](../Cubrism/AppDelegate.swift) around line 132.
- Cubrixels are stackable inventory items, not a separate wallet. Equipment
  records have level, tier, subtype, and variant but no persistent item IDs.
  See [item schema](../Cubrism/Item.swift) and
  [equipment schema](../Cubrism/Equipment.swift) around line 189.

## Floor generation and smooth scaling

At floor entry, capture account Delve Level and run bonuses, then sample hidden
floor difficulty once. Derive the scaling level and encounter budget from that
value. Plan encounters before creating the layout, so room count, point costs,
workload, and resume state are known. Persist the sample and the plan; resuming
cannot redraw an easier floor.

The selected standard deviation is five percent of account Delve Level. At
Delve 854, that is 42.7 points: about two thirds of draws fall between 811 and
897 before applying a lower bound. Proposed minimum account and floor score:
one. Resample values below one, giving a lower-truncated normal distribution
near the minimum rather than pretending those edge draws remain symmetric.
Keep the accepted sample unrounded; do not impose an upper sampling cap.

Selected continuous input: `x = (floorDifficulty - 1) / 100`.
Delve 1 maps to zero, 51 to 0.5, 101 to 1, and 201 to 2. Delve 854 maps to
8.53. This zero-based input must not be passed unchanged into old one-based
level functions: rebase the stat curves so Delve 1 retains starting power.
Detailed formulas and examples are in
[the balance proposal](DUNGEON-BALANCE.md).

Use the fractional scaling input in rebased enemy, boss, and equipment stat
formulas; retain their curve shapes and round only where a final display or
integer output requires it. Persist item power when the item is generated,
so later account changes cannot strengthen or weaken existing items.
Raw scores such as 854 must not be passed directly into formulas expecting old
stage numbers. Apply offsets consistently to elite and boss-spawned enemies.
XP payouts, currency, rarity, and merchant gear each need deliberate routing
and calibration.

Enemy eligibility compares each minimum threshold with sampled floor
difficulty. Availability never guarantees a spawn. Calibrate thresholds in
Delve-point units, targeting new availability roughly every ordinary floor,
rather than tying introductions to 100-point stat bands. Since each floor is
sampled independently, a type available on one floor may be ineligible on a
later, easier draw; this follows the selected sampled-score rule.

## Encounter budgeting and bosses

Room cost equals summed enemy point costs times a grouping multiplier that
increases with enemy count. Tune the curve initially; specific combination
surcharges are outside the first version.

For a fixed budget and comparable enemy types, dense rooms spend more points
on concurrent pressure and yield fewer rooms and fewer enemies overall.
Lighter rooms target more rooms and enemies overall. Lower floor difficulty
can produce fewer of both because its total budget is smaller.

Guarantee exactly one final boss outside that budget, scaling its stats from
the same sampled floor difficulty. Do not add a boss allowance while the
design requires one boss from the current tier. Boss mechanics still affect
actual difficulty, so validate each boss in playtests. Defer miniboss pricing
and different final-boss tiers until those features exist.

## Progression and scoring

Proposed successful-floor gain is about 10 points times a continuation
multiplier times a challenge multiplier times (1 + 0.10 times performance).
The challenge multiplier increases gains when sampled difficulty exceeds the
account's entry Delve Level. The three modifiers remain separate so the
10-percent performance cap is meaningful.

Normalize performance between zero and one. The accepted combination is
40% speed, 40% accuracy, and 20% damage avoidance.
Measure speed using active play rather than pauses or menus, normalized to
the floor's planned content. Measure damage during the floor rather than
remaining health alone because players can enter injured.

Recommend counting actual shots fired during combat, with at most one accepted
hit per shot and no penalty for firing in empty rooms. Ordinary enemies, bosses,
and destructible hostile projectiles are valid targets. Wall impacts and
expired shots miss; shots still flying when combat ends are neutral. Record
post-defense health and shield damage separately and count both in avoidance;
regeneration does not erase damage already taken. Normalize speed and damage
to planned workload, including the boss. These are proposed measurement rules;
reference times and damage allowances require playtest calibration.

Death reduces account Delve Level, with a larger base loss later in progression
and a smaller loss when the sampled floor was harder than the entry score.
Completed floors have already updated Delve Level; death applies its own loss
rather than reverting all earlier gains. Proposed initial formulas follow.

## Proposed starting balance

The [balance proposal](DUNGEON-BALANCE.md) is the source of truth for proposed
formulas, constants, worked examples, and numerical checks. Those values are
not yet approved gameplay balance.

The selected direction is a separate, much stronger rarity incentive for
consecutive floors within one run. The accepted implementation takes the best
of one rarity draw per run floor reached. Base rarity odds also grow more
slowly with account progression; the previous constant-odds proposal is
superseded. The user accepted the quadratic shape and Rare/Epic/Legendary
starting chances of 15%/5%/1%. The full distribution accepted October 3 makes Rare and
Uncommon converge at Delve 10000; preserving the other three curves gives
37.5% each. Uncommon rises from 30%, Rare from 15%, and Common falls from
49% to 5%. Epic and Legendary still reach 15% and 5%. This accepted distribution replaces
the earlier Rare 50% and Uncommon 25% endpoints. Earlier intermediate anchors,
fixed 80/15/5 pool mix, and 7:2 lower-tier split are superseded.
Item quantity and the XP/Delve continuation multipliers are accepted: two
items growing to three, and +10% per additional floor capped at +50%. Base
XP and rating-adjustment formulas still need calibration. The run-depth
rarity bonus subsequently changes the tier mix.

The accepted gear rule fixes an existing issue: rarity currently multiplies
growth terms that can be zero at starting power. Multiplying the whole common
item contribution makes early rare gear stronger.

The [gear-rarity research](research/GEAR-RARITY.md) compares Borderlands, Path
of Exile, and Diablo IV using primary sources. It recommends retaining the
provisionally endorsed stat vector as Cubrism's own starting balance, evaluating
whole-build power. The user selected stronger stats only for the first version
and would like distinctive effects in the future. The research does not identify
a universal Borderlands rarity multiplier table.
The balance document records the nonlinear effect of Cubrism's cooldown-based
attack-speed contribution and its interaction with damage.

Exact gain/loss, XP, currency, encounter-budget, and performance formulas are
included in the balance document. They keep rating adjustment, performance,
and continuation independent; allocate XP without rewarding extra room counts;
and use the selected zero-based decimal input throughout.

The [enemy-scaling research](research/ENEMY-SCALING.md) finds the existing power
curve a reasonable candidate, with no universal industry formula to copy.
Health, damage, and encounter growth should be evaluated together against
player progression. The balance document also records the current XP formulas
so the proposed large change in base payouts can be reviewed separately.

The [drop table](DUNGEON-DROP-TABLE.md) shows the accepted five-tier distribution
at every 100 Delve through 10000. It uses the quadratic taper and the accepted
Rare/Uncommon convergence at 37.5% each.

## Loot, checkpoint stats, and resume

Keep run loot separate from permanent inventory even while equipped. Leaving
safely banks it; death discards it and removes unbanked items from equipped
slots. Previously banked gear remains available.

Propose treating newly found currency as run loot too, banking it only on safe
exit and preventing it from being spent while unbanked. Preserve item identity
and the prior banked loadout so losing equipped run loot cannot delete banked
gear or leave references to discarded items.

Use sampled floor difficulty through the scaling conversion for item power,
and continuation bonuses for drop count and quality chances. Quality
probabilities need a bounded policy rather than the existing stage-number
thresholds.

Propose using current account Delve Level through the same smooth conversion
for newly generated merchant gear, since shop purchases have no sampled floor.
Existing owned gear retains its power when Delve Level falls.

Grant only capacity newly reached above the run health maximum.
For 30/100 health with a recorded maximum of 100, raising maximum health to
150 grants 50 HP once, resulting in 80/150, and records a run health maximum
of 150. Changing maximum from 150 to 100 to 150 grants no further HP; reaching
175 later grants only 25. Clamp current health when capacity falls.

Persist the run health maximum across floors and sessions; reset it only for
a fresh run. Keep an independent equivalent record for shield capacity.
Apply checkpoint equipment and XP stat changes first, then refill shields to
the resulting maximum once when committing entry to the next floor. Persist
that transition so loading the same floor cannot refill shields again. Health
continues from its post-checkpoint value. Ordinary shield regeneration remains.
Character stat gains during combat obey the same capacity rules; refreshing
stats itself must never trigger a full heal.

A fresh run starts at full health with depth and continuation
bonuses reset. It also starts with full shields. Pausing and resuming preserves
the current run.

## Recovery and save reset

Voluntary abandonment during a floor counts as a failure: retain earned
XP, discard all run loot, and apply that floor's death loss. Safe exit remains
available at a completed-floor checkpoint. Closing or backgrounding the app
pauses the run and does not choose either outcome.

Save account progression and active-run state together in a versioned snapshot.
Use an atomic replacement and stable run, floor, item, and settlement IDs to
make XP, floor completion, extraction, death, and shield refill happen once.
Persist at combat reward/damage boundaries and lifecycle transitions; a crash
recovers the last durable state. Snapshot player and enemy state, room progress,
timers, randomness, and active projectiles together, so resume neither redraws
encounters nor refreshes health, shields, cooldowns, or boss progress. Resume
opens paused until the player continues. This is implementation work, not an
existing capability of the game.

On first launch of the new progression version, initialize a fresh account and
no active run. Reset legacy character progress, gear, inventory, currency, and
stage progress; do not translate or import them. Record the new save version so
later launches preserve new-system progress rather than resetting it again.
Scope the reset to game progress; unrelated app preferences need not change.
No saves are modified during this design discussion.

## Concrete verification scenarios

- Clear three floors, then die on floor four: lose all active-run loot, retain
  earned XP, apply the failure loss, and end the run.
- Leave safely after three floors: bank all run loot and retain XP and Delve
  Level updates.
- Equip run loot, then die: discard that gear and preserve previous banked gear.
- Resume a floor: preserve sampled difficulty, encounter plan, loot ownership,
  earned XP accounting, and run health maximum.
- Swap maximum health from 100 to 150 to 100 to 150: grant the new 50 capacity
  only once, even if the app closes between changes.
- Enter the next floor with depleted shields: recharge to the post-checkpoint
  maximum, carry remaining health, and do not recharge again on resume.
- Generate equal-budget sparse and dense floors: sparse configurations target
  more rooms and enemies, and both respect grouping costs and eligibility.
- Win a floor rolled harder than the account score: grant the selected
  challenge bonus separately from the capped performance bonus.
- Compare samples immediately below and above a former scaling boundary:
  enemy and gear power change smoothly, with no whole-level jump.
- A sample below an enemy threshold excludes it even when the account score
  is above that threshold; an eligible type still need not spawn.
- Reopen after settlement or during combat: no duplicate XP, items, score
  changes, shield recharge, or resurrected already-defeated enemies.
- Open a legacy save: start fresh under the new rules. Earn new progress and
  relaunch: retain that progress and do not repeat the reset.
- Reach character level 100 with excess XP, then earn more on a failed run:
  retain all earned lifetime XP without additional character levels, stat
  growth, or a balance available for future levels.
- Clear above Delve 10000: continue updating Delve and generating stronger
  floor enemies and item power. Retain the accepted base rarity plateau and
  the separate same-run quality bonus; impose no Delve or gear-power cap.
- Compare Delve 20000 builds: calibrate the enemy against hypothetical level
  200 plus matching Legendary gear, while the actual player remains level
  100. Do not apply the actual XP cap to the enemy's reference character or
  grant the player the hypothetical levels as hidden progression.

Test whether deliberate losses or repeated first-floor resets become better
than the intended continuation risk, and calibrate XP rewards so raw mob count
or room-count bonuses do not accidentally dominate equivalent-budget floors.

## Remaining decision frontier

The level-100 character cap, lifetime-only XP after the cap, uncapped Delve
and item power, and 50-hour representative active-play target to Delve 10000
are accepted. Ten consecutive floors remain an exceptional-run target.
Refit reference character growth and enemy stats to those decisions. Keep
accepted combat-time anchors, rating rules, starting gear share, and rarity
curves intact. Reference tables ending at 10000 must never become gameplay
limits. Endgame difficulty now explicitly uses an uncapped reference
character and the continuing kill-time slope. Accepted October 4: retain
normal continuous gear growth and the actual player's level-gap pressure,
without extra growth to replace missing intrinsic character stats. This
settles the endgame gear policy for the first version.

The [calibration pass](DUNGEON-CALIBRATION.md) now incorporates the accepted
one-third starting Common gear share. A full Rare set improves initial DPS
and capacity by about 17%. Accepted drop chances and multipliers stay fixed;
the remaining work is to validate complete progression scenarios and select
the initial numerical model for the first playable version.

1. Enemy scaling: kill times and average-gear rarity benchmarks through Delve
   10000 are selected. Fit health against smoothly evolving reference loadouts.
   Incoming-damage anchors are ten green ranged-enemy hits at Delve 1 and five
   at Delve 1000, including shields; other attacks scale by relative damage.
   The decline to five hits and subsequent five-hit plateau are selected.
   Fit that reference curve and tune encounter composition. Extend kill times
   and the hypothetical reference character beyond 10000; keep the actual
   player's XP level capped.
2. Loot: the full base rarity distribution is accepted, including
   Rare/Uncommon convergence at 37.5% each at Delve 10000. Item count and
   XP/Delve continuation bonuses are accepted at +10% per additional floor,
   capped at +50% from floor six.
   Best-of-depth rarity applies within the same run and resets on new runs. Evaluate the provisionally endorsed stat multipliers using
   the completed research and whole-build effects. Rarity uses sampled floor
   difficulty. Distinctive effects remain deferred to a future item-system pass.
3. XP calibration: the gradual time curve and roughly 25-hour reference target
   to reach character level 100 are accepted. Fit increasing XP rewards,
   level-up requirements, and character stat gains to that pace; neither the
   current exponential requirement nor the earlier 10-XP baseline is selected.
4. Rating and performance: the baseline loss curve is accepted, crossing the
   +10 win at Delve 2500 and reaching 20 at 5623.75. The 40% speed / 40%
   accuracy / 20% damage-avoidance weights and +10% cap are accepted.
   Calibrate normalization and review challenge-adjustment defaults alongside
   the complete numerical model.

See [the balance proposal](DUNGEON-BALANCE.md) for the concrete values being
reviewed. Abandonment, fresh-run recovery, decimal scaling, whole-item rarity
application, and resetting old saves are settled and are not being asked again.
The character-level pacing target and five-tier rarity order/colors are also
settled, along with the complete base rarity distribution accepted October 3.
The five-tier stat multipliers
are provisionally endorsed; comparative research is recorded and supports
using them as initial tuning values while validating whole-build effects.

The user confirmed the shared understanding on October 12 and authorized the
first implementation milestone after checkpointing the current game. The
checkpoint is the annotated tag `checkpoint/pre-delve-refactor-2026-10-12`,
published to origin at commit `578589eb731f5f74c01db0d36f58530dee254bff` on the
default branch, named `master` in this repository. The refactor worktree was
fast-forwarded to that baseline before code edits. Gameplay balance still
requires the first playable version.

The remaining coefficient work above is calibration rather than another
endgame product choice. Currency risk/settlement and merchant generation
remain explicit proposals in the loot section; they are outside the first
foundation milestone and must not be silently promoted to accepted behavior.

## First milestone: progression and run foundation

Authorized October 12, 2026. The accepted run rules are
concrete enough to implement this foundation without selecting every
remaining combat or XP tuning coefficient. Numerical tuning remains explicit
in the balance and calibration documents; it must not silently change
accepted targets or be presented as already playtested.

The first implementation milestone contains:

1. Pure Delve and reward calculations: sampled difficulty, accepted base
   rarity curves, best-of-run-depth rarity, two-to-three item counts,
   continuation factors, accepted loss curve, and accepted performance weights.
   Keep the proposed challenge ratios and uncalibrated metric normalization
   in named tuning inputs, with their status documented.
2. A run state model for entering a floor, clearing it into a checkpoint,
   continuing, extracting, dying, and deliberately abandoning. Clearing is
   settled once; continuation advances the floor and samples against updated
   account Delve. XP events are retained, while unbanked items remain owned
   by the active run until extraction. Use explicit reward inputs so the
   model does not depend on a final XP reward curve. Respect the configurable
   character cap, retain lifetime XP, and do not bank post-cap progression XP.
3. Resource transitions: carry current HP, refill shields once when entering
   each new floor, and track the run's peak capacities to avoid equipment-swap
   healing exploits. Starting a fresh run restores full resources and resets
   continuation bonuses.
4. Persistence-ready snapshots and focused checks of these rules. Verify
   duplicate settlement cannot duplicate rewards, death cannot bank run loot,
   and loading a checkpoint cannot refill resources again. Snapshot integration
   with the complete live combat state follows in the persistence milestone.

Completion evidence: deterministic calculation and transition checks pass,
including accepted probability endpoints, the +10/-10 Delve-2500 baseline,
rarity draws resetting on a new run, XP retained on death, and safe extraction
banking all pending loot once. This milestone establishes the foundation;
the full gameplay loop becomes playable after the following integration work.

Source and validation notes are recorded in [the implementation record](DUNGEON-IMPLEMENTATION.md).

## Implementation sequence after the foundation

1. Connect run snapshots to persistent account and live combat state. Verify
   interrupted writes, restored encounters, equipment ownership, and the
   one-time save reset before routing gameplay rewards through the new model.
2. Replace independent four-point room generation with a stored floor plan
   and grouping costs. Generate ordinary encounters before layout; add the
   guaranteed boss afterward. Verify eligibility, total cost, sparse/dense
   behavior, elite offsets, boss-spawned entities, and resumable combat state.
3. Replace stage selection with dungeon entry and checkpoint continue/leave.
   Record actual combat events for performance, retain XP on failure, and
   route newly generated gear through sampled or account difficulty as
   appropriate. Exercise the full loop with existing SpriteKit combat.
4. Playtest early floor duration, novelty cadence, character stat growth,
   continuation incentives, and later plateaus. Tune values from observed
   play; compare sparse and dense floors and test intentional death/reset
   strategies before retiring the old stage path.
