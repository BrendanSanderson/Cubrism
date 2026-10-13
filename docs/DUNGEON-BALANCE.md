# Dungeon balance proposal

Status: numerical proposal with accepted decisions, updated October 4, 2026.
Not implemented. Complete base rarity distribution accepted October 3, 2026.
Continuation XP, successful Delve gain, and item-count bonuses are also
accepted. The revised baseline loss curve crosses the +10 win at Delve 2500
and caps at 20. Performance weights are accepted at 40% speed, 40% accuracy,
and 20% damage avoidance.
Starting Common gear supplies about one-third of total attack, HP, and shield;
the character supplies the other two-thirds.
Latest accepted direction: about 50 hours of representative active play to
Delve 10000, including failures and continuation bonuses, excluding idle and
menus; keep this tunable. Character level caps at 100 for v1; subsequent XP
counts only toward lifetime XP, with no bank for a future cap increase.
Delve and item power have no maximum. Gear drives breakthroughs, including
all further power growth after the character cap. Ten consecutive floors in
one run should be exceptional. The old 137-hour route with character levels
above 100 must not become the implementation default.
The [main design](DUNGEON-PROGRESSION.md) records accepted behavior. The decimal
input, priority of rare loot, five-tier rarity order/colors, and whole-item
rarity application are selected. Previously selected Rare/Epic/Legendary caps
were 50%/15%/5%. The accepted October 3 distribution makes Rare and Uncommon
converge at 37.5% each, retaining Epic at 15% and Legendary at 5%. These are
base chances before continuation bonuses. The prior
80/15/5 pool mix is superseded by the accepted starting chances
of 15% Rare, 5% Epic, and 1% Legendary at Delve 1. The user selected gradual
growth and the displayed quadratic curve. The 1/1.25/1.5/2/2.5 stat
multipliers are a provisionally endorsed
starting point; the requested comparison with other loot games is recorded
below and supports validating whole-build effects. Other
constants and formulas below remain recommendations for review.

## Inputs and stat growth

- `R`: account Delve Level captured at floor entry, minimum 1, no maximum.
- `F`: hidden floor difficulty, sampled once from `Normal(R, 0.05 * R)`.
  Proposed boundary handling: redraw samples below 1. Persist the accepted draw.
- `x = (F - 1) / 100`: selected zero-based decimal scaling input.
- `d`: floor number in this run, starting at 1; `c = d - 1` completed floors.
- `b = 0.10 * min(c, 5)`: accepted continuation bonus for XP, successful Delve
  gains, and expected item count, capped at 0.50 from run floor six onward.
- `clamp(v, lo, hi) = min(hi, max(lo, v))`.

Do not round `R`, `F`, or `x` during calculations. Rebase the current one-based
stat curves so `x = 0` gives the original starting multipliers:

| Stat multiplier | Formula |
| --- | --- |
| Enemy health and damage | `(1 + x / 4)^1.4` |
| Boss health | `(1 + x / 3)^1.4` |
| Boss main damage | `(1 + x / 3)^1.3` |
| XP power curve | `(1 + x / 7)^2.5` |
| Gear's player-derived term, exponent `p` | `(1 + x / 5)^p` |

These are algebraic translations of the current curves in
[Constants.swift](../Cubrism/Constants.swift) and
[Player.swift](../Cubrism/Player.swift), not new growth shapes. Character XP
level remains a separate one-based input for character stats and XP thresholds,
capped at 100 in v1. Do not clamp `F` or `x` to that cap or to Delve 10000.

The [enemy-scaling research](research/ENEMY-SCALING.md) compares this power
curve with linear, exponential, and authored progression using primary sources.
The curve family is a reasonable candidate, but the coefficients and using the
same curve for both HP and damage remain under review. Choose combat pacing
targets before approving simultaneous health, damage, and encounter growth.

The user accepted the increasing kill-time table through Delve 10000 and
specified the reference loadout's rarity: average Common gear at Delve 1,
Uncommon at 1000, Rare at 2500, Epic at 5000, and Legendary at 10000. Interpret
average as typical stat values within that rarity at the appropriate item
power, rather than best rolls or the mean rarity of a random drop. Character
level and its stat contribution still need calibration alongside XP; these
equipment benchmarks do not imply a one-to-one character-level/Delve mapping.

### Selected combat-time anchors

The user accepted two seconds at Delve 1, four seconds at Delve 5000, and
about six seconds at Delve 10000 for a reference ordinary enemy. Boss targets
at those points are thirty, sixty, and ninety seconds. Preserve enemy-type
differences around that reference; these are not identical targets for every
enemy. The benchmark measures sustained effective hits; travel, missed shots,
dodging downtime, and boss invulnerability add elapsed time.

The accepted table uses linear interpolation between the selected time
anchors. This is a target-time curve, not a direct enemy-HP multiplier:

```text
ordinaryReferenceSeconds(F) = 2 + 2 * (F - 1) / 4999
bossReferenceSeconds(F) = 30 + 30 * (F - 1) / 4999
# Continue the same slope beyond Delve 10000; displayed times are rounded.
```

| Sampled Delve | Average reference gear | Reference enemy | Reference boss | Time status |
| --- | --- | ---: | ---: | --- |
| 1 | Common | 2.0 s | 30.0 s | Accepted |
| 1000 | Uncommon | 2.4 s | 36.0 s | Accepted |
| 2500 | Rare | 3.0 s | 45.0 s | Accepted |
| 5000 | Epic | 4.0 s | 60.0 s | Accepted |
| 10000 | Legendary | 6.0 s | 90.0 s | Accepted |

All five gear benchmarks and their displayed ordinary-enemy and boss kill
times are selected. Continue the same trajectory beyond Delve 10000. The
user clarified that enemies should scale against an uncapped hypothetical
character: Delve 20000 corresponds to reference character level 200 with
matching Legendary gear, even though the actual player remains level 100.

For the endgame extension, use `referenceCharacterLevel(F) = F / 100` for
`F >= 10000`. This joins reference level 100 at Delve 10000 and reaches 200
at 20000, without changing the existing `x = (F - 1) / 100` gear-power input.
Below 10000, the proposed calibrated reference route remains separate from
actual XP progression. Actual character level is never substituted into enemy
calibration. Base rarity probabilities plateau independently.

Thus the continuing target at Delve 20000 is about ten seconds per ordinary
enemy and 150 seconds per boss for the hypothetical level-200 reference.
An actual level-100 character with the same items can take longer. The
five-green-hit survival reference also belongs to the hypothetical build;
it is not a guarantee for the capped character. This supersedes the previous
candidate that kept the enemy's reference character capped at 100 indefinitely.

Recommended calibration method: interpolate the reference gear contributions
continuously between these rarity anchors, then evaluate the complete combat
formulas to obtain reference DPS. Actual equipment retains discrete rarity.
The provisionally endorsed gear coefficients at the anchors are 1, 1.25, 1.5,
2, and 2.5; interpolating the benchmark avoids a sudden difficulty jump at
Delve 1000, 2500, 5000, or 10000. This does not imply linear DPS growth, given
the interaction between damage and firing speed.

These are balance benchmarks used to fit health curves. Enemy strength is
determined by sampled floor difficulty rather than the actual equipped gear;
above-benchmark equipment should beat the target time and below-benchmark
equipment should take longer under otherwise comparable conditions. The
rarity milestones specify reference equipment, not drop guarantees, unlock
thresholds, or automatic gear upgrades. Check retained-loot progression
against these milestones when tuning rarity, item count, and extraction risk.
Incoming damage uses the separate green-enemy benchmark below.

### Selected incoming-damage anchors

The green ranged enemy is `Range`, confirmed by its sprite assignment in
[EnemyEntity.swift](../Cubrism/Entities/EnemyEntity.swift) and green asset.
Using the same average reference loadouts, the user selected ten green
projectile hits to deplete full HP plus shields at Delve 1 and five at Delve
1000. Scale every other enemy and boss attack relative to this damage
reference. There is no independently selected boss hit-count target.

Measure effective damage after mitigation with no healing or shield
regeneration during this isolated benchmark. The user accepted the gradual
decline to five hits, then holding that target beyond Delve 1000. Use linear
interpolation between the anchors:

```text
greenHitsToDefeat(F) = 10 - 5 * clamp((F - 1) / 999, 0, 1)
effectiveGreenHit = (referenceMaxHP + referenceMaxShield) / greenHitsToDefeat(F)
rawGreenHit = effectiveGreenHit + referenceFlatArmour
rawAttack(F, attack) = rawGreenHit * authoredDamageRatio(attack)
```

The five-hit target continues above Delve 1000. Raw enemy damage still grows
with the reference build's HP, shield, and armour; holding the hit count does
not freeze damage stats. Longer fights and encounter composition provide
further pressure. Continuing below full health retains its increased risk.

These targets fit a curve against reference equipment and character stats.
They never use the actual player's equipment, current HP, or current shields
to set enemy strength. Continuing with depleted health retains its risk.

Representative authored baseline ratios from
[constants.json](../Cubrism/constants.json), relative to a green shot's 25 raw
damage at legacy level 1, are:

| Attack | Raw damage ratio |
| --- | ---: |
| Green ranged projectile | 1x |
| Melee / dash contact | 2x |
| Tracking projectile / suicide contact | 4x |
| Triple-shot projectile | 0.75x per projectile |
| Ring projectile | 0.5x per projectile |
| Generator projectile / contact / electricity | 1x / 2x / 0.4x |
| Dragon projectile / contact / breath | 2x / 1x / 0.4x |
| Golem projectile / contact / ground effect | 2x / 4x / 1x |

Ratios are per damage event, before mitigation and integer truncation, not
whole-volley or whole-ability damage. Preserve timing, projectile count, and
effect tick behavior separately. Dragon's damageable fireball entity has its
own 4x contact ratio. Flat armour means effective post-mitigation damage ratios
are not exactly these raw ratios.

The current pipeline in [Player.swift](../Cubrism/Player.swift) subtracts
`defence / 10`, clamps damage to zero, drains shields, and spills remaining
damage into HP. Damage is first truncated to an integer by attack creation;
calibration must account for that truncation or retain fractional damage to
hit exact targets. Current ordinary and boss damage curves differ, so their
ratios drift with level. Recommended implementation: use the authored baseline
ratios with one calibrated damage curve, replacing that legacy drift.

### Legacy curve conversion examples

| Sampled Delve | Decimal input `x` | Enemy multiplier | Boss health multiplier |
| --- | ---: | ---: | ---: |
| 1 | 0.00 | 1.000 | 1.000 |
| 51 | 0.50 | 1.179 | 1.241 |
| 101 | 1.00 | 1.367 | 1.496 |
| 201 | 2.00 | 1.764 | 2.045 |
| 854 | 8.53 | 4.946 | 6.586 |

The `/ 100` is a choice of units. For example, the enemy formula can instead be
written `(1 + (F - 1) / 400)^1.4`. Removing `/ 100` from `x` without changing
downstream coefficients would accelerate progression by a factor of 100 along
the input axis. Recommend keeping the explicit conversion for readable tuning.

## Rarity is the main continuation reward

### Accepted five-tier system

| Tier | Name | Color |
| --- | --- | --- |
| 1 | Common | White |
| 2 | Uncommon | Green |
| 3 | Rare | Blue |
| 4 | Epic | Purple |
| 5 | Legendary | Orange |

The existing tier-four artwork is purple, while the old shard catalog calls it
Legendary. The user selected Epic for purple and a new orange Legendary tier
above it. Use the five-tier names in the redesign. Rare-or-better means tiers
3, 4, and 5 together. Use raw sampled Delve directly; no second stat-scaling
conversion applies to rarity probabilities.

### Accepted gradual curve and endpoints

The user previously selected gradual growth and caps of **50% Rare, 15% Epic, and 5%
Legendary**. These are percentages of all awarded equipment items, not shares
within Rare-or-better. The accepted graph uses them as base
caps before the accepted same-run continuation rarity bonus. The accepted
October 3 distribution below supersedes Rare's endpoint with 37.5%.

The starting chances are **15% Rare, 5% Epic, and 1% Legendary**, totaling
21% Rare-or-better. The user raised Epic's starting chance from 3% to 5%.
These starting odds supersede the older 10% total at Delve 500 and 20% total
at Delve 1000, both of which would require chances to fall as Delve increases.
The fixed 80/15/5 conditional mix is likewise superseded.

The preceding exponential candidate only approached its caps. At Delve 10000
it gave 49.5078% Rare, 13.7352% Epic, and 4.5784% Legendary. After the user
flagged those endpoint numbers, the accepted replacement reaches all three caps exactly at Delve 10000,
with zero slope there.

| Sampled Delve | Common | Uncommon | Rare | Epic | Legendary | Rare-or-better |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 49% | 30% | 15% | 5% | 1% | 21% |
| 10000 and beyond | 5% | 37.5% | 37.5% | 15% | 5% | 57.5% |

Accepted October 3, 2026: Rare and Uncommon converge at the
same chance at Delve 10000. Keeping Common, Epic, and Legendary unchanged
leaves 75% to split equally, giving the accepted endpoint of 37.5% each.
Uncommon rises from 30% and Rare rises from 15%, using the same quadratic
taper. This replaces the preceding Uncommon 30%-to-25% and Rare 15%-to-50%
trial. Common still falls from 49% to 5%. The user explicitly locked in the
full displayed distribution, including its quadratic taper and plateau.

### Accepted gradual formula

Use the saved sampled floor difficulty `F`. A quadratic taper gives exact
endpoints, continuously decreasing gains, and a smooth join to the plateau:

```text
t = clamp((F - 1) / 9999, 0, 1)
growth = t * (2 - t)
baseRare      = 0.15 + (0.375 - 0.15) * growth
baseEpic      = 0.05 + (0.15 - 0.05) * growth
baseLegendary = 0.01 + (0.05 - 0.01) * growth
q = baseRare + baseEpic + baseLegendary
# Accepted convergence, October 3, 2026
baseUncommon  = 0.30 + (0.375 - 0.30) * growth
baseCommon    = 1 - q - baseUncommon
```

The five base outcomes sum to 100% for every sampled difficulty. Rare remains
below Uncommon until they meet at exactly 10000, with zero slope there;
both then stay at 37.5%. Rare-or-better now reaches 57.5% instead of 70%.

The quadratic shape and starting chances remain unchanged. The accepted
distribution revises the Rare and Uncommon endpoints, superseding the previous trial.
Earlier straight-line and exponential graph snapshots are also superseded.
The [interval table](DUNGEON-DROP-TABLE.md) uses the accepted formula.

### Continuing the same run

The selected direction is a strong rarity bonus for continuing consecutive
floors and a slower increase in base odds across account progression. The
accepted implementation draws an item's rarity `d` times on run floor `d`
within the same run and keeps the best result. It awards one item, not `d` items. There is no hard cap
on rarity draws; the improvement naturally diminishes toward one. Code may
sample the equivalent categorical distribution directly.

For the five base probabilities `p[1...5]`, define cumulative probabilities:

```text
C[0] = 0
C[k] = sum(p[1...k])
P(tier k at depth d) = C[k]^d - C[k-1]^d
```

For the floor's actual base probabilities this becomes:

```text
P(Common)    = baseCommon^d
P(Uncommon)  = (1 - q)^d - baseCommon^d
P(Rare)      = (1 - baseEpic - baseLegendary)^d - (1 - q)^d
P(Epic)      = (1 - baseLegendary)^d - (1 - baseEpic - baseLegendary)^d
P(Legendary) = 1 - (1 - baseLegendary)^d
```

Best-of-depth shifts more of the pool upward. The accepted Rare/Epic/Legendary
endpoints of 37.5%/15%/5% apply to base probabilities; accepted continuation
can exceed them.
These expressions use the actual base probabilities without assuming fixed shares.
For any base cumulative threshold chance `p`, `chanceAtDepth = 1-(1-p)^d`.
Do not roll five independent outcomes or add overlapping cumulative chances.

The rarity probabilities below use the accepted same-run rule. Item count
and XP/Delve continuation bonus columns were accepted October 3. Hold the Delve 1 base
distribution fixed to isolate depth alone
(21% Rare-or-better, 6% Epic-or-better, 1% Legendary):

| Run floor | Rare-or-better | Epic-or-better | Legendary | Expected items | XP / Delve continuation bonus |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 21.00% | 6.00% | 1.00% | 2.0 | 0% |
| 2 | 37.59% | 11.64% | 1.99% | 2.2 | 10% |
| 3 | 50.70% | 16.94% | 2.97% | 2.4 | 20% |
| 5 | 69.23% | 26.61% | 4.90% | 2.8 | 40% |
| 6 | 75.69% | 31.01% | 5.85% | 3.0 | 50% |
| 10 | 90.53% | 46.14% | 9.56% | 3.0 | 50% |

Each newly awarded item uses its own floor's inputs and is generated once.
Previously collected items never reroll when continuing. A new run always
resets to one rarity draw, regardless of prior floors or wins in other runs. These are per-item probabilities before extraction risk; death
still loses all unbanked loot. No additional pity guarantee is proposed.

## Item count and the strength of rare gear

Accepted October 3: two guaranteed equipment items per completed floor, plus one extra
item with probability `2 * b`. Because `0 <= b <= 0.50`, that probability is
always valid. Expected count is `2 * (1 + b)`: floor two awards either two or
three items, never a fractional item. From floor six onward, award three
items per clear. These bonuses reset on a new run; the accepted best-of-depth
rarity bonus keeps growing beyond floor six. Currency is a separate proposed
floor-clear award; its formula was not settled by this continuation decision.

Expected Rare-or-better items per clear are:

```text
expectedRareItems(d, p) = 2 * (1 + b) * (1 - (1 - p)^d)
```

At a fixed base chance of 21%, this grows from 0.42 on floor one to 1.94 on
floor five, about 4.6 times as much, compared with 1.4 times the XP. This
comparison excludes death risk, floor duration, and changes in sampled difficulty.

The whole bag is more generous than a single-item probability suggests.
Holding the revised Delve 1 base Legendary chance fixed at 1% across all
floors, conditional on clearing every floor and extracting, the example gives
about a 31.7% chance of at least one Legendary by floor five and 79.6% by floor
ten. These isolate continuation and item count; they are not predicted
extraction rates and omit changing floor difficulty.
For base threshold chance `p_i` on floor `i`, define `q_i = (1 - p_i)^i`;
then the exact chance
of at least one qualifying item in the extracted bag is:

```text
1 - product over i = 1...d of [q_i^2 * (1 - 2*b_i + 2*b_i*q_i)]
```

This includes the random extra-item count on each floor and keeps prior loot
at the odds it originally received. If Legendary gear should be less frequent
even for successful long runs, lower its base probability while preserving
the strong depth incentive.

Accepted gear stat application:

Accepted October 3: at character level 1 and Delve 1, a full Common set
contributes attack 12.5, HP 50, and shield 50 alongside intrinsic attack 25,
HP 100, and shield 100. Thus gear supplies one-third of these starting totals.
Recalibrate enemy HP and damage to preserve the accepted kill/survival targets.
The current calibration retains existing growth terms as a tunable first pass;
one-third is not enforced as a permanent ratio at later levels or Delves.
See [the calibration](DUNGEON-CALIBRATION.md) for the revised formulas.

```text
rarityMultiplier = [1.00, 1.25, 1.50, 2.00, 2.50] for tiers [1, 2, 3, 4, 5]
# Provisionally endorsed starting values; validate whole-build effects in tuning.
gearStat(x, tier, type, variant) =
    commonGearStat(x, type, variant) * rarityMultiplier[tier]
```

`commonGearStat` means the tier-one formula with the rebased decimal input
and starting contributions revised to the accepted gear-share target. Apply the multiplier to the whole
equipment contribution, not the whole character stat. A Rare item grants
50% more of that equipment stat than a Common item of the same power/type.
A stat absent from an item stays absent. The user generally endorsed the
1/1.25/1.5/2/2.5 vector and requested guidance from games such as Borderlands
before finalizing its use. Epic retains the purple tier's prior 2x target;
Legendary is 25% stronger than Epic in each scaled item contribution. This is
not a claim that total character DPS or survivability rises by those ratios.

This is a deliberate accepted change to the current tier calculation: current
equipment often multiplies only growth terms that are zero at starting power,
so an early rare item can be almost indistinguishable from a common one. The
uniform rule also replaces Special Pulsar's separate linear tier multiplier;
its common attack-speed contribution remains `(x + 1) / 25`, then receives
the rarity multiplier. Existing random type/variant selection can remain.

### Guidance from other loot games

The [rarity research](research/GEAR-RARITY.md) found no verified universal
Borderlands same-level rarity multiplier table. Official Borderlands examples
show individually tuned weapon behavior and build effects; Path of Exile and
Diablo IV provide examples of rarity controlling modifier capacity or powers.
These support evaluating an item's complete combat effect, but do not establish
our numeric ladder as an industry standard.

Recommendation: keep 1/1.25/1.5/2/2.5 as the first stat-based tuning vector,
then measure representative complete builds at each power and expected rarity.
The user selected stronger stats only for this refactor, including Legendary
gear, and wants distinctive effects as a future addition. They are outside
the first version's scope. When added, tune ordinary stats alongside each
effect instead of stacking an unrestricted effect on top of 2.5x.

The current attack-speed contribution is specifically a cooldown reduction:
`cooldown = max(0.05, 0.5 - 0.02 * speedContribution)`, with theoretical firing
rate `1 / cooldown`. See [Player.swift](../Cubrism/Player.swift) and
[constants.json](../Cubrism/constants.json). Its nonlinear response makes a
shared rarity input insufficient to guarantee equal power growth across stats.
For an illustrative build with base attack 25, item attack 25, and speed
contribution 5, ideal DPS is `50 / 0.4 = 125`. Multiplying both item contributions
by 2.5 gives `87.5 / 0.25 = 350`, or 2.8x DPS. This is arithmetic under the current
equations, not a forecast of an actual generated loadout. Damage and speed are
currently spread across separate equipment types but combine in a loadout.

Assess the speed response separately when tuning the base stat formulas, and
check flat damage prevention and shield recovery against the enemy curve too.
Enemy HP should use the agreed average-gear reference loadouts at each rarity anchor,
not adapt to the individual player's equipped gear. Finding better gear should
still create the intended temporary advantage and allow a Delve breakthrough.

Persist each item's generated power and rarity. Losing Delve Level does not
weaken owned gear. Merchant power uses `x = (accountDelve - 1) / 100`; it has no
continuation rarity draws. Merchant stock and pricing remain a separate tuning
surface; this proposal does not grant the dungeon's quality bonus to purchases.

### Accepted endgame gear policy

Accepted October 4, 2026: continue the normal Common-gear growth curves with sampled floor
difficulty and apply the same rarity multipliers. Keep actual character stats
capped at 100; do not add intrinsic levels through an invisible progression
system. Higher-Delve gear remains usable at the character cap, and replacing
items is the source of further stat growth. This does not introduce a new
rarity above Legendary or change accepted drop chances.

Add no extra gear growth specifically to replace the character stats lost
to the cap. The intrinsic-stat deficit contributes endgame pressure while
higher-power gear remains the route to further power growth. Against the uncapped reference, the
current curve yields an actual level-100, matching-Legendary kill time of
about 11.04 seconds at Delve 20000, versus the reference's 10.00 seconds;
green-hit capacity is about 4.43 versus five. The deficit is measurable but
not an automatic loss of half the build's power. Gear supplies most stats
at that point. See [the endgame comparison](DUNGEON-CALIBRATION.md) for later
values and assumptions. Extra growth replacing missing intrinsic stats was
considered and not selected for the first version.

The retained numerical gear curve is initial balance subject to tuning. Its cooldown-reduction
term reaches a floor at high item power, so the relative level-gap pressure
does not necessarily grow forever. Test attack speed, armour, and damage
together before claiming a permanently widening endgame deficit.

## Delve gains and losses

Let `P` be performance between zero and one. Proposed success gain:

```text
gain = 10 * (F / R) * (1 + b) * (1 + 0.10 * P)
```

The ten-percent cap applies only to the performance factor. Difficulty and
continuation are separate. A matched floor with no performance bonus grants
10 on floor one, 11 on floor two, and 15 from floor six onward. Perfect
performance changes those to 11, 12.1, and 16.5.

Accepted October 3: upward and downward adjustments should
be about equal around Delve 2500, with larger downward adjustments beyond
that point. Interpret this as matched difficulty before continuation and
performance bonuses. Those separate success bonuses remain in force.

Accepted baseline loss formula, with the proposed challenge adjustment:

```text
baseLoss = min(20, 2 + 8 * (R - 1) / 2499)
loss = baseLoss * (R / F)
newDelve = max(1, currentDelve - loss)
```

The accepted curve retains the earlier starting loss of 2 and ceiling of 20,
but places the +10/-10 crossover at Delve 2500. It supersedes the old loss
curve that reached 20 by Delve 2000. The user accepted the displayed loss
table, including the linear interpolation and retained ceiling.

| Account Delve | Base win | Base loss magnitude |
| --- | ---: | ---: |
| 1 | +10 | 2 |
| 1000 | +10 | 5.20 |
| 2500 | +10 | 10 |
| 5000 | +10 | 18.00 |
| 5623.75 and beyond | +10 | 20 |

These are nominal values at matched difficulty before bonuses and the
account minimum of one. In particular, an account at one cannot lose rating.
Run depth does not multiply losses: carried health and all unbanked loot
already provide the escalating cost. There is no partial-clear loss discount.
These loss-modifier defaults remain part of the starting formula proposal.
At Delve 2500, a first-floor win is +10 before performance and a loss is -10;
a floor-six win is +15 before performance while its loss is still -10.
Thus the crossover describes baseline rewards, not equal adjustments at
every run depth.

At account Delve 854 on floor one, before performance:

| Sampled difficulty | Win gain | Death loss |
| --- | ---: | ---: |
| 800 | +9.37 | -5.05 |
| 854 | +10.00 | -4.73 |
| 900 | +10.54 | -4.49 |

At late progression with matched difficulty, no performance bonus, and no
continuation bonus, +10/-20 requires about a two-thirds clear rate to maintain
the score. With the maximum continuation bonus, +15/-20 breaks even at about
57%. These are conditional examples, not predicted player win rates; changes
in gear and skill should move players through the resulting plateau.

## Encounter budget

Revised candidate floor budget and proposed room costs:

```text
combatBudget = 12 * (1 + x)^0.1
roomCost = sum(enemyBasePoints) * (1 + 0.25 * (enemyCount - 1))
```

The budget exponent 0.1 is a calibration candidate for the accepted 50-hour
active-play goal. It replaces the earlier square-root candidate in the current
study; see [calibration](DUNGEON-CALIBRATION.md) for assumptions and sensitivity.
The coefficient is not accepted gameplay balance. Budget remains uncapped.

Only ordinary combat rooms spend this budget. Guarantee one final boss outside
it. All final-boss stats use the same `x`. Retain affordable nonempty rooms,
allow an unspendable remainder, and do not force an empty locked room. Current
enemy point costs are the starting data; future composition tuning can adjust
them without changing the formula.

For equal one-point enemies, pairs cost 2.5 and groups of four cost 7. At a
35-point budget, fourteen pairs give 28 mobs in 14 rooms, while five groups of
four give 20 mobs in 5 rooms. This verifies the selected sparse/dense relation.
Budget growth is intentionally gentler than stat growth. It is not a floor
duration guarantee; early one-to-two-minute pacing still requires playtests.

## XP and currency

### Current game: combat XP and character level-up costs

These are the existing implementation's formulas, before any Delve changes.
Here `N` is the legacy numeric enemy level or stage, and `L` is character XP
level. Neither is a raw Delve score.

```text
M(N) = ((N + 6) / 7)^2.5

ordinary enemy kill XP = floor(baseXP * M(enemyLevel) * gapAdjustment)
gapAdjustment = 1                               if L <= enemyLevel
gapAdjustment = 2 / (L - enemyLevel + 1)          otherwise

boss kill XP = floor(50 * M(globalStage))
completed room XP = floor(10 * M(globalStage))

XP needed from character level L to L+1:
floor((L + 300 * 2^(L / 4)) / 4)
```

The last expression is equivalent to the nested floors in
[Player.expToLevel](../Cubrism/Player.swift) at line 237. Costs are per next
level, not cumulative totals:

| Character level | XP to next level |
| --- | ---: |
| 1 | 89 |
| 2 | 106 |
| 5 | 179 |
| 10 | 426 |
| 20 | 2,405 |

The exponential part roughly doubles the required XP every four character
levels. The current payout curve instead grows as a power of enemy/stage
level. These are separate pacing controls.

Base ordinary enemy XP is 5, 7.5, or 10 by type; Dragon fireballs award none.
A one-level character advantage leaves kill XP unchanged; gaps of two and
three multiply it by two-thirds and one-half. Boss XP has no gap reduction.
Every kill and room award truncates separately, so 7.5 becomes 7.

The floor's XP total adds enemy kills and room bonuses, including a separate
boss-room bonus. At stage one the boss plus its room gives 60 XP before any
ordinary encounters. A concrete stage-one example with twelve 5-XP enemies,
three ordinary rooms, and one boss totals `12*5 + 3*10 + 50 + 10 = 150` XP,
assuming no level-gap penalty. Actual generated compositions vary.

Success permanently grants all accumulated floor XP. Death currently grants
`floor(accumulatedXP / 1.2)`, about 83.33%. The accepted new design retains
100% of earned XP on death. Source references:
[multiplier](../Cubrism/Constants.swift) line 44,
[enemy scaling](../Cubrism/Entities/EnemyEntity.swift) line 193 and gap adjustment
line 328, [boss scaling](../Cubrism/Entities/BossEntity.swift) line 142,
[kill and room accumulation](../Cubrism/RoomScene.swift) line 169,
[success](../Cubrism/FloorViewController.swift) line 314, and
[death](../Cubrism/Player.swift) line 167.

### Joint design of earned XP and level-up requirements

The user requires earned XP to increase with progression and explicitly raised
reworking level-up requirements. Treat these as a paired pacing decision. The
useful quantity is `XP required / expected XP earned per active minute`, not
the size of either number by itself.

The existing curves diverge substantially at higher levels. For illustration,
compare character level with an equal numeric legacy enemy/stage level and
hold encounter content constant:

| Numeric level | XP required for next character level | Current reward multiplier |
| --- | ---: | ---: |
| 10 | 426 | 7.90 |
| 20 | 2,405 | 26.59 |
| 50 | 434,458 | 181.02 |

From 10 to 50, requirements rise about 1,020 times while that reward multiplier
rises about 23 times. Their ratio becomes about 44.5 times less favorable.
This isolates the curve mismatch; it is not a measured floor-count or playtime
forecast, because actual stage composition, combat speed, and character/Delve
relationships also change. Long term, exponential requirements outgrow a
power-law reward curve.

Recommended direction: use compatible, moderate power curves for both rewards
and requirements, and fit their coefficients to target leveling times. Keep
the formula structure conceptually separate:

```text
earned XP = rewardForSampledDifficulty * plannedWorkload * continuationBonus

At design time:
XP cost at character level L =
    expected XP per active minute at reference difficulty for L
    * target active minutes for the next level
```

The second relationship is a calibration method for fixed curves or a fixed
table, not a runtime adjustment to an individual's speed or equipment. Actual
XP rewards depend on the content faced. Raising character level must not make
the same trivial floor automatically pay proportionally more XP.

`plannedWorkload` refers to generated combat content, not elapsed time, so
waiting in a room earns nothing. Include workload exactly once: a reward
formula calibrated for a complete floor already includes its reference
workload and must not receive the full factor again. Equivalent-budget sparse
and dense floors should offer comparable total XP. Longer planned floors can
award more XP without making every longer floor take proportionally longer
to earn a character level.

Accepted on October 1, 2026: gradually increasing time per character level
using this reference pacing target:

```text
targetMinutes(L) = 2 + 2 * sqrt(L - 1)
```

Here `L` is character XP level, and the result is active combat minutes for
the next level at appropriately challenging reference content, before
continuation bonuses. It is not Delve Level or run depth.

| Character level | Target minutes to next level |
| --- | ---: |
| 1 | 2.0 |
| 5 | 6.0 |
| 10 | 8.0 |
| 25 | 11.8 |
| 50 | 16.0 |
| 99 | 21.8 |
| 100 | Capped; lifetime XP only |

Summing the 99 level-ups from character level 1 through 99 gives
`sum(L=1...99, targetMinutes(L)) = 1501.026145...` minutes, approximately
25 hours and 1 minute of active combat to reach level 100. The user accepted
the curve, this reference total, and the v1 cap at 100. There is no 100-to-101
cost. Excess XP from reaching the cap and subsequent XP count toward lifetime
XP only, including continuation bonuses; they do not grow stats or bank for
future levels if the cap is raised.

The curve increases gradually across the 99 available level-ups. The base 2
controls the first level, and the coefficient 2 controls subsequent slowdown.
Continuation bonuses and faster clears can reduce actual time; menus and
downtime add to wall-clock playtime. This is a reference tuning target rather
than a guarantee for every player. Use it to calibrate fixed XP costs and
increasing content rewards; never grant XP simply for time spent or adjust
costs live to force each player to match the target.

Actual XP coefficients remain open. Character stat gain per level must be
calibrated alongside this pace; faster levels with unchanged large stat gains
could outpace enemy progression. Character level, Delve Level, and generated
gear power are distinct quantities and must not be assumed to rise together
one-for-one during calibration.

### Earlier floor-payout candidate: not selected

The earlier candidate for total XP available for a full clear was:

```text
floorXP = 10 * (1 + x / 7)^2.5 * (1 + b)
```

This preserves the algebraic shape of the payout multiplier, but changes
reward allocation and base payout substantially. Ten XP is for an entire
starting floor in this proposal, compared with at least 60 from the old
starting boss and boss room alone. Slower character leveling is an independent
pacing proposal, not a required consequence of introducing Delve. Neither the
constant 10 nor retaining the existing exponential costs is selected. Revisit
both through the joint pacing design above.

Allocate 60% across ordinary combat rooms in proportion to actual room cost,
then among each room's enemies by their base point costs. The final boss
awards the remaining 40%. Boss summons and destructible projectiles grant no
additional XP. Remove the old extra room-clear XP award from this path.
This gives equal-budget floors comparable XP regardless of room or mob count.
Keep fractional earned XP until display; rounding every small kill would erase
much of the reward. XP remains earned on death, including continuation bonuses.
The constant 10 stretches character growth alongside the new Delve curve;
playtests must verify that retained XP still provides useful progress.

A deterministic calculation with matched difficulty, +10 Delve per clear, and
a fresh run each floor reaches character level 2 after 10 clears, level 3
after 20, level 7 after 50, and level 14 after 100. The next-floor Delve scores
are 101, 201, 501, and 1001 respectively. This is an arithmetic pacing example,
not a simulation of combat or deaths.

Propose currency at a floor clear:

```text
currency = floor(10 * (1 + x) * (1 + b) * U)
U = one persisted uniform draw between 0.8 and 1.2
```

Currency is run loot and cannot be spent until banked. Equipment rarity is
independent of performance score; the main prize for continuing is quality,
and the separate performance bonus increases Delve progress only.

## Performance measurement

Accepted October 3: speed and accuracy each contribute 40%, while damage
avoidance contributes 20%. This resolves the earlier ambiguous wording and
supersedes equal weighting. Individual metric normalization still requires
calibration; the combined performance bonus remains capped at +10%.

```text
P = 0.40 * speed + 0.40 * accuracy + 0.20 * avoidance
referenceDPS = 50 * (1 + x / 4)^1.4
targetSeconds = totalPlannedEnemyAndBossHP / referenceDPS
              + 2 * ordinaryCombatRoomCount
speed = clamp(1.5 - activeCombatSeconds / targetSeconds, 0, 1)
damageAllowance = (entryMaxHealth + entryMaxShield) * targetSeconds / 60
avoidance = clamp(1 - actualDamageTaken / damageAllowance, 0, 1)
accuracy = acceptedHits / resolvedCombatShots
```

Use actual planned enemy HP including elite offsets and the final boss. Boss
HP in the time estimate does not create a boss point budget. The 50-DPS
reference is anchored to the existing base 25 attack at about two shots per
second. The reference loadout scales with difficulty, not the player's chosen
gear, so intentionally entering with weak gear cannot lower the time target.
The constants 50, 2, and 60 are proposed calibration values, not measured
equivalence between different enemy mechanics.

This reference-DPS expression predates the selected increasing-rarity loadout
and the selected increasing time-to-kill targets. Recalibrate it using those
reference builds before adopting the performance formula; player equipment
must not dynamically set an easier scoring target during an individual run.

Active combat time runs while combat is live; exclude pause, menus, cleared
rooms, and safe-room travel. Count one accepted hit at most per actually fired
projectile; living enemies, bosses, and destructible hostile projectiles are
valid targets. Wall impacts and expired shots are misses. Shots still flying
when combat ends are neutral and leave the denominator. No resolved shots
gives accuracy zero. Empty-room firing is excluded.

Damage taken counts actual post-defense HP and shield depletion, excluding
zero-damage UI refreshes and capacity reductions from stat changes. Healing
or regeneration does not erase recorded damage. Evaluate floor performance
only on a clear; deaths use the loss formula above.

## Decisions for the next round

Accepted alignment: target about 50 active hours to Delve 10000 including
failures and continuation; cap character level at 100; keep post-cap XP only
as lifetime XP with no future-level bank; leave Delve and item power uncapped.
Gear drives breakthroughs and ten-floor runs should be exceptional. The
current calibration uses a shorter-floor candidate for the 50-hour target,
not a validated forecast or an accepted encounter-budget exponent. Matched
kill times beyond Delve 10000 now continue on the same slope against an
uncapped hypothetical reference character. Accepted October 4: retain normal
gear growth with no extra compensation for the actual character cap. Endgame
gear policy is settled; numerical calibration remains subject to playtests.

The [numerical calibration pass](DUNGEON-CALIBRATION.md) records revised
reference-loadout formulas, an explicit progression scenario, and candidate
fixed XP costs. The one-third starting Common gear share is now accepted;
a full Rare set improves initial DPS by 16.76% and HP plus shield by 16.67%.
Accepted drop chances and rarity multipliers are unchanged.

1. Enemy stat curves: kill times and average-gear rarity anchors through
   Delve 10000 are selected. Fit health to smoothly evolving reference loadouts.
   Green ranged-enemy hits to defeat are selected at ten for Delve 1 and five
   for Delve 1000, including shields; other attacks retain relative damage.
   The decline to five hits and five-hit plateau above Delve 1000 are selected.
   Calibrate damage and character stats alongside XP, then tune encounter
   composition. Extend the selected kill-time trajectory using the uncapped
   endgame reference character while keeping actual XP level capped.
2. Loot: the complete base rarity distribution is accepted, including
   Rare/Uncommon convergence at 37.5% each at Delve 10000. Item count and
   XP/Delve continuation bonuses are accepted at +10% per additional floor,
   capped at +50% from floor six. Best-of-depth rarity within the
   same run is selected. Compare the provisionally
   endorsed stat multipliers using the completed research and compound combat
   effects. Distinctive effects remain deferred; v1 uses stronger stats only.
3. XP calibration: the `2 + 2 * sqrt(L - 1)` minute curve and approximately
   25-hour total to character level 100 are accepted. Fit reward and cost
   curves to that pace alongside character stat gains. Other coefficients
   remain under discussion; pacing and whole-item rarity application are
   no longer part of the open decision frontier. Five-tier order/colors are
   selected, as is the complete base rarity distribution above. The five-tier stat vector is
   provisionally endorsed; the requested comparative research is complete and
   whole-build tuning remains necessary.
4. Rating and performance: the baseline loss curve is accepted, crossing the
   +10 win at Delve 2500 and reaching the 20 ceiling at 5623.75. Performance
   weights are accepted at 40% speed, 40% accuracy, 20% damage avoidance.
   Calibrate metric normalization against reference builds and review the
   challenge-adjustment defaults as part of the complete numerical model.

## Calculation checks

Calculated on September 30, 2026:

- Rarity probabilities are nonnegative and sum to one across depths 1–1000,
  within floating-point precision.
- Rebased stat curves match all old integer-level anchors from 1–50, within
  floating-point precision; they preserve starting multipliers of one.
- Representative scores and depths preserve harder-win and harder-loss
  adjustments, the separate ten-percent performance ceiling, and valid
  extra-item probabilities.
- The example character XP pacing above uses the actual existing threshold
  formula and carries fractional XP rather than rounding each kill.

These checks establish arithmetic consistency, not gameplay balance. No
gameplay code or saved player data was changed.
