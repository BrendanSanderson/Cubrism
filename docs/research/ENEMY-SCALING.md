# Enemy scaling research

Research date: October 1, 2026. This is a design comparison, not an approved balance change. No gameplay code was changed.

## Finding

`(1 + x / 4)^1.4`, where `x = (sampledDelve - 1) / 100`, is a reasonable **shifted power curve**. It starts at 1, changes smoothly, and grows faster than a comparable linear curve but much slower than an exponential curve. The sources below do not establish a universal industry-standard enemy formula. They demonstrate that linear formulas, authored enemy/encounter tables, and individually tuned difficulty curves are all viable tools.

The most consequential Cubrism question is whether to apply the same curve to **both health and damage while also increasing the number of encounters**. Those changes compound. Retaining the curve as a candidate is justified; declaring it balanced before comparing it with player progression is not.

## Verified game examples

### Shattered Pixel Dungeon: linear scaling for a reusable enemy

The Mimic is explicitly assigned `Dungeon.scalingDepth()` when spawned. Its health is `6 * (1 + level)`, its ordinary damage roll ranges from `1 + level` to `2 + 2 * level`, and its attack skill is `6 + level`. These are linear stat formulas, with additional behavior and integer rounding rules. This is evidence about this enemy, not a claim that every enemy in the game uses one global linear curve. [Mimic source, pinned revision](https://github.com/00-Evan/shattered-pixel-dungeon/blob/2bb34a4e91d29c8785a9363cad6ddfe5122b1d4f/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/actors/mobs/Mimic.java#L215)

Implication for Cubrism: a simple per-enemy formula is legitimate. The chosen coefficients and surrounding encounters matter more than using a complicated curve.

### Brogue Community Edition: authored stats and changing encounters

The monster catalog assigns base stats per species: for example, a rat has 6 HP and a 1–3 damage range, while a goblin has 15 HP and a 2–5 range plus different behavior. The horde catalog separately defines depth eligibility and group composition: solo jackals appear at depths 1–3, while jackal groups appear at depths 3–7. This is a concrete example of difficulty progression through enemy selection and encounter composition, rather than requiring a universal depth multiplier. Special mechanics can still modify those base stats. [Monster catalog](https://github.com/tmewett/BrogueCE/blob/104a20fedbe7d9360d2dfc8ff665571694212ad8/src/brogue/Globals.c#L920), [horde catalog](https://github.com/tmewett/BrogueCE/blob/104a20fedbe7d9360d2dfc8ff665571694212ad8/src/variants/GlobalsBrogue.c#L716)

Implication for Cubrism: the planned frequent enemy introductions and density changes are substantial difficulty controls in their own right. Stat growth does not need to supply the entire sense of escalation.

### Diablo: tune health and damage against the actual player experience

Diablo IV's official 2.3.0 notes, dated July 1, 2025, describe reducing monster health growth per Pit tier after Torment I so more builds could progress toward Torment IV. They do not publish the exact formula. This verifies that the tier curve is a balance control tied to player builds, not a fixed standard that should be copied. [Official Diablo IV 2.3 patch notes, Miscellaneous](https://news.blizzard.com/en-us/article/24215995/diablo-iv-patch-notes-2-3)

Diablo III's historical 1.0.4 patch independently changed health and damage: Act III/IV normal-monster health increased 10%, elite health decreased 2.5%, and overall monster damage decreased 15%. This is direct evidence that durability and lethality can be tuned separately. It is historical evidence, not a statement of the current game's balance. [Official Diablo III 1.0.4 patch notes, Monsters](https://news.blizzard.com/en-us/article/7029347/patch-1-0-4-now-live)

## Mathematical comparison

The following are illustrative curve families, **not attributed game formulas**. To make a fair comparison, all three start at 1 and have the same initial slope, `0.35` per unit of `x`.

| Family | Example | Useful property | Main risk |
| --- | --- | --- | --- |
| Linear | `1 + 0.35*x` | Constant absolute additions; easiest to reason about | Each later step is a smaller percentage increase |
| Shifted power | `(1 + x/4)^1.4` | Smooth, moderately accelerating absolute growth | Later steps still become smaller percentage increases |
| Exponential | `exp(0.35*x)` | Constant percentage growth per equal step | Rapidly grows beyond additive/power-based player progression |
| Authored / piecewise | Designer-selected anchors with interpolation | Direct control of desired early, middle, and late pacing | More values to maintain; joins must be designed deliberately |

| Sampled Delve | `x` | Linear | Current power candidate | Exponential |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 0 | 1.000× | 1.000× | 1.000× |
| 101 | 1 | 1.350× | 1.367× | 1.419× |
| 501 | 5 | 2.750× | 3.112× | 5.755× |
| 1001 | 10 | 4.500× | 5.777× | 33.115× |
| 2001 | 20 | 8.000× | 12.286× | 1096.633× |

Matching the initial slope is a comparison convention. A gentler exponential can be tuned to match a later anchor instead; the table does not prove that every exponential is too steep.

For the current candidate, an ordinary `+10 Delve` increase means roughly **+3.52% stats at Delve 1**, **+1.00% at Delve 1001**, and **+0.26% at Delve 5001**. Absolute stat increases grow, but relative increases shrink. This can support a long gradual climb; it will not by itself create an equally strong new wall every ten points.

The denominator is a unit conversion, not decoration:

```text
(1 + x/4)^1.4
= (1 + (sampledDelve - 1)/400)^1.4
```

Removing `/100` while leaving `/4` unchanged makes progression 100 times faster along the input axis. It is safe to absorb the denominator into other constants only when preserving the intended curve.

## Evaluate the complete Cubrism progression

The current proposal also uses an ordinary-encounter budget of `12 * sqrt(1 + x)`. At Delve 1001 this budget is about 3.32 times the starting budget, alongside enemies with about 5.78 times the health and damage. With an unchanged roster and grouping pattern, the ordinary enemies' combined health workload would be roughly **19.2 times** the start before player improvements. Actual generation can differ because enemy prices, composition, rounding, and room grouping also change. This estimate excludes the guaranteed boss.

Even with a fixed enemy count, health and damage compound: if an enemy has twice the health and twice the damage, an unchanged player may spend twice as long fighting it while each attack hurts twice as much. In a simplified continuous-damage model that gives four times the damage exposure. Real dodging, discrete attacks, crowd control, shields, and kill thresholds alter this; it is a warning about interacting controls, not a prediction of measured difficulty.

The useful balance measurements are:

- **Time to kill:** enemy HP divided by the player's effective damage per second, including accuracy, attack speed, and gear.
- **Hits survivable:** usable health/shield divided by post-mitigation damage per hit, with the attack pattern held explicit.
- **Floor exposure:** encounter count, concurrent attackers, room spacing, and opportunities for shield recovery.
- **Progression payoff:** the change in these measurements when the player levels up, replaces an item, or upgrades its rarity.

The accepted rarity multipliers apply to the item's whole contribution, not the whole character. Doubling a weapon's contribution does not necessarily double total DPS. Character level is also independent of Delve: assuming a player at Delve 1001 has character level 11 would hide the unresolved XP pacing problem.

## Recommendation for the next design round

Keep the shifted-power family as the baseline comparison. Do not switch to exponential growth merely because it seems more conventional. Define expected combat outcomes at several Delve anchors first, then fit health and damage curves separately to those targets and the expected player equipment/XP state.

For fast combat, let better enemy behaviors, room combinations, and modestly longer floors provide some of the escalation. Consider slower damage growth than health growth if the current combination pushes players toward sudden deaths; consider slower health or encounter-budget growth if it pushes them toward long repetitive fights. Neither adjustment has a defensible exact coefficient until the target time to kill and hits survivable are selected.

Use at least early, middle, and late sample builds, including common gear and upgraded rare gear, to check that rarity creates the desired breakthrough without becoming mandatory immediately. Freeze two of health growth, damage growth, and encounter-budget growth while testing the third so changes can be interpreted.

## Scope and limitations

This bounded review uses primary source code and official developer patch notes. It is not a survey proving how frequently each curve family is used. Popular claims about Diablo III Greater Rift percentage formulas were found only in secondary material during this review and are deliberately not treated as verified formulas here. Numerical comparisons above were computed directly from the stated equations; no combat simulation or playtest has yet established the best Cubrism coefficients.
