# Delve calibration: capped character, uncapped Delve

Updated October 4, 2026. Offline design calculations only; no gameplay implementation.
The accepted loss curve, performance weights, and one-third starting gear
share are recorded in [the balance document](DUNGEON-BALANCE.md). Other
calibration inputs and illustrative outputs below remain proposed defaults.

Reproduce with `python3 docs/calibration/delve_reference.py` from this worktree.

## Accepted scope and limits

The user selected about 50 hours of representative active play to reach Delve
10000, including failures and continuation bonuses and excluding menus and
idle time. Keep this target tunable. Character level caps at 100 for v1 and
may be expanded later. XP earned at the cap counts toward lifetime XP only;
it grants no further stats and cannot fund future levels after a cap increase.

Delve has no maximum. Item power and enemy stats keep scaling beyond 10000,
while base rarity probabilities retain their accepted plateau. After character
level 100, stronger gear supplies further power growth. There is no final
globally best item at a fixed power ceiling. Ten consecutive floors should be
an exceptional run; there is no run-depth cap.

The first-pass 137-hour route and its pre-10000 reference levels above 100
are superseded. The current model preserves accepted starting gear, combat
anchors, survival, rarity, and rating rules. It studies the first 10000 Delve
points as a pacing milestone; that finite numerical range is not a gameplay
cap. Beyond 10000, the user selected continued growth against an uncapped
hypothetical reference character: level 200 with matching Legendary gear at
Delve 20000. The actual character remains capped at 100. Accepted October 4:
gear continues its normal growth without extra compensation for that
character-level deficit. The numerical values remain initial tuning values.

## Candidate 50-hour pacing study

Holding accepted kill-time targets and the +10 base gain fixed, try a gentler
encounter budget `B = 12*(1+x)^0.1` instead of the previous square-root growth.
Keep the same illustrative paired one-point enemies, room grouping cost,
two active seconds of overhead per room, and 20% combat-time allowance.
The exponent 0.1 is a proposed starting value, not an accepted formula.

One illustrative player tries up to three floors per run, with conditional
clear chances of 95%, 90%, and 80%, then extracts after the third clear.
Assume performance score 0.6, matched sampled/account difficulty, and a failed
floor consuming half a successful floor's time. Apply accepted continuation
bonuses and losses. These are explicit scenario assumptions, not observed
clear rates or a selected definition of a typical run.

At fixed Delve `R`, let `reach[d]` be the product of prior clear probabilities:

```text
gain[d] = 10 * (1 + 0.10*min(d-1,5)) * 1.06
loss[R] = min(20, 2 + 8*(R-1)/2499)
expectedNetDelve = sum(reach[d] * (p[d]*gain[d] - (1-p[d])*loss[R]))
expectedMinutes = referenceFloorMinutes(R)
                  * sum(reach[d] * (p[d] + 0.5*(1-p[d])))
expectedRouteMinutes = integral from 1 to 10000 of
                       expectedMinutes / expectedNetDelve dR
```

This local-drift approximation gives **49.28 hours** with budget exponent
0.1. Its all-win unbonused comparison is 43.57 hours. By contrast, the old
exponent 0.5 gives 156.28 hours for this same representative scenario and
136.51 hours for the all-win comparison. Shorter ordinary encounters can
therefore approach the new target without changing the accepted Delve gains
or making individual enemies die faster than the accepted benchmarks.

The candidate's Delve-10000 floor is about 3.93 minutes, versus the earlier
15.31-minute scenario. No duration cap is imposed; longer floors remain
possible from later difficulty and composition. Do not apply a simple
50/137 multiplier to enemy kill times or all floor content, which would
break the accepted boss/ordinary-enemy targets.

This calculation ignores gear acquisition, stalls, evolving player skill,
sample variance, and within-run changes of Delve. It also approximates the
lower rating boundary rather than simulating it. It establishes a feasible
direction for pacing, not a promise that actual players will reach 10000 in
50 hours. Failure probabilities stand in for health attrition; this model
does not demonstrate that ten-floor runs will be exceptional.

Sensitivity with the same candidate budget, half-floor failures, and a 0.6
performance score except for the explicitly unbonused comparison:

| Assumed play pattern | Hours to Delve 10000 |
| --- | ---: |
| All successes, fresh run each floor, no bonuses | 43.57 |
| Extract after one floor; 95% clear chance | 46.00 |
| Attempt three; 95% / 90% / 80% conditional clear chances | 49.28 |
| Attempt five; 95% / 90% / 80% / 65% / 50% conditional clear chances | 62.38 |

These are alternate assumptions, not evidence that shorter runs are optimal.
They omit how banked loot and skill change future clear chances. The roughly
50-hour target should be validated against actual play before treating any
scenario's probabilities as representative.

## Verified current player and gear formulas

Character level `L` and sampled Delve `F` remain independent inputs. Define
`x = (F - 1) / 100`, `C_p(L) = ((L + 4) / 5)^p`, and:

```text
delta = 100 * ((1 + x/4)^1.4 - (1 + x/5)^1.2)

Intrinsic HP     = 100 * C_1.2(L)
Intrinsic shield = 100 * C_1.1(L)
Intrinsic attack =  25 * C_1.1(L)

Average Common gear HP      = 2.5 + 27*delta/40
Average Common gear shield  = 1.5 + 27*delta/40
Average Common gear attack  = 2.5 + 27*delta/160
Average Common gear defence = 3.5 + 17*delta/40
Common attack-speed boost   = (x + 1)/25
```

These average all seven equipment slots, including two independent uniformly
random attachment subtypes. This is an ensemble average rather than a single
possible attachment pair. Existing items have random types and attachment
subtypes, but no random numerical stat rolls; visual variants do not alter
stats. Apply the provisionally endorsed rarity factor `q` to gear contributions
only, then add intrinsic character stats.

```text
flatArmour = q * (0.0875 + 17*delta/1600)
cooldown   = max(0.05, 0.5 - 0.02*q*(x+1)/25)
DPS        = totalAttack / cooldown
```

Only Special Pulsar currently generates attack-speed gear stats. With the
accepted rarity milestones, cooldown is approximately 0.4992, 0.4890, 0.4688,
0.4184, and 0.2980 seconds at Delve 1, 1000, 2500, 5000, and 10000. None reaches
the 0.05-second cap. The old Special Pulsar tier factor must not be combined
with the new whole-item rarity factor.

Source evidence: [intrinsic and aggregated stats](../Cubrism/Player.swift:82),
[cooldown](../Cubrism/Player.swift:94),
[Common item formulas and attachment choices](../Cubrism/Equipment.swift:91),
[loaded multipliers](../Cubrism/constants.json:22), and
[damage mitigation](../Cubrism/Player.swift:147).

## Accepted starting gear contribution

At character level 1 and Delve 1, the current rebased formulas give a full
Common set 55.09 ideal DPS and 204 combined HP and shield. Replacing the
entire set with Rare gear gives 57.64 DPS and 206 combined HP and shield:
only **4.63% more DPS and 0.98% more capacity**. This result is independent
of the reference progression-route assumptions below.

The full-item rarity rule fixes partial multiplier application, but tiny
starting gear contributions still make early quality upgrades weak. A
change accepted October 3 is to give a full Common set about one-third of total
starting attack, HP, and shield. With existing intrinsic starting values,
the gear-only totals are attack 12.5, HP 50, shield 50. A complete Rare
set gives 16.76% more DPS and 16.67% more capacity than Common. Distribute
base contributions across appropriate slots so early equipment has a useful
effect; retain whole-item rarity application. This changes the gear power
curve, not the accepted rarity probabilities or multipliers.

Enemy HP/damage must be recalibrated to preserve the accepted two-second
kill and ten-hit survival targets with the revised Common reference set.
The offline model now uses these accepted starting contributions. It retains
the previous growth terms provisionally rather than multiplying entire
growth curves by the large starting-value correction. The one-third rule is
a starting benchmark, not a constant gear share enforced at every character
level and Delve. Actual gear and character level continue to grow separately.

```text
Average Common gear HP     = 50   + 27*delta/40
Average Common gear shield = 50   + 27*delta/40
Average Common gear attack = 12.5 + 27*delta/160
```

Defence and attack-speed contributions remain as above. At character level
1 and Delve 1, the revised full Common set yields HP 150, shield 150, attack
37.5, and ideal DPS 75.12. Fitting the same combat targets gives reference
ordinary HP 150.24, boss HP 2253.61, and green-projectile raw damage 30.0875
(30 after flat armour). The Rare version yields HP 175, shield 175, attack
43.75, and DPS 87.71. A fixed Common-reference enemy therefore takes about
1.71 seconds to defeat with the Rare set; no enemy stat changes in response
to equipping it. These continuous estimates require discrete combat validation.

## Current reference progression route

Use the three-floor scenario above and the proposed budget exponent 0.1.
Fractional enemy/room counts represent an average composition. With the
accepted ordinary/boss kill-time curves:

```text
referenceFloorMinutes(F) =
  1.2 * ((B/1.25)*ordinarySeconds(F) + 2*(B/2.5) + bossSeconds(F)) / 60

referenceMinutesToDelve(R) = integral from 1 to R of
  expectedMinutes(s) / expectedNetDelve(s) ds
```

Sampled floor difficulty equals account Delve in this particular study.
Resulting floor durations and cumulative active play are:

| Delve milestone | Reference floor minutes | Cumulative active hours |
| --- | ---: | ---: |
| 1 | 1.18 | 0.00 |
| 1000 | 1.55 | 2.22 |
| 2500 | 1.96 | 6.64 |
| 5000 | 2.62 | 17.08 |
| 10000 | 3.93 | 49.28 |

The model's active time includes combat downtime and the stated room overhead,
with no menus or idle time. Floors are not subject to these values as timers.
Longer floors remain possible. The original square-root-budget calculation
gave approximately 137 all-win hours and is retained only as a comparison,
not as a current XP or combat-stat calibration.

## Fixed XP costs with the character cap

Use a proposed base reward density of `50*(1+(F-1)/700)^2.5` XP per reference
minute of planned combat. This retains the rebased legacy reward power curve
while removing the legacy exponential requirement curve. Fifty is a proposed
XP unit scale, not an accepted pacing choice.

At design time, integrate the unbonused density over the reference route
during each accepted `2+2*sqrt(L-1)` minute interval, for levels 1 through 99.
This route already includes rating bonuses and failures. Only the XP bonus
is excluded while fitting thresholds, so continuing actually accelerates XP
progress rather than having that benefit canceled by higher costs. For this
study, a failed floor earns half its XP as well as taking half its time.
Finite kill and boss allocations may change that relationship in gameplay.

The resulting costs are fixed by character level; actual player speed, gear,
or current Delve never rewrites them. Proposed values under this scenario:

| Character level | Reference Delve at level start | XP to next level | Reference minutes |
| --- | ---: | ---: | ---: |
| 1 | 1.0 | 103.3 | 2.00 |
| 10 | 416.8 | 1373.1 | 8.00 |
| 25 | 1419.7 | 9801.5 | 11.80 |
| 50 | 3192.4 | 59609.2 | 16.00 |
| 99 | 6380.7 | 358454.2 | 21.80 |
| 100 | — | No next level | Lifetime XP only |

Reaching 100 totals 1501.026145 reference minutes (25 hours, 1 minute) before
XP bonuses. Applying continuation XP to these same fixed thresholds makes
this scenario reach the cap in approximately 1448.82 minutes (24 hours,
9 minutes), around Delve 6294. Those are scenario results, not new accepted
targets. The reference character remains level 100 afterward. Excess XP
never spills into a hidden level 101 or future-level balance.

Numerical integration with Delve steps one and two changes the shown XP
costs by at most 0.0008%; this checks resolution, not gameplay validity.

Runtime rewards must use completed content, never elapsed minutes. Translate
the reference density into a finite ordinary XP pool based on spent encounter
points and a separate boss pool. Distribute ordinary XP through room costs
and enemy point shares; grant each allocation once on defeat. Do not also add
room XP on top of a pool that already includes room workload. Spawned adds
must share a finite allocation so waiting for respawns cannot create XP.
Apply the accepted continuation multiplier once; retain earned XP on death.
Equivalent-budget sparse and dense floors receive comparable total XP,
although their realized XP per minute can differ.

## Fitting enemy stats

Through Delve 10000, the reference route supplies earned XP, including the
continuation XP bonus. Map it through the fixed thresholds to an offline
character level, capped at 100. Beyond 10000, use the user-selected uncapped
hypothetical reference, `referenceLevel = F / 100`, to fit enemy stats.
This joins at level 100 and reaches 200 at Delve 20000; it is not the actual
player's XP level. Fractional reference levels smooth the fit; actual levels
remain discrete. Interpolate reference gear contributions between accepted rarity
milestones, evaluate the complete player formulas, and fit:

```text
ordinaryReferenceHP(F) = referenceDPS(F) * ordinarySeconds(F)
bossReferenceHP(F)     = referenceDPS(F) * bossSeconds(F)
greenRawHit(F) = (referenceHP(F) + referenceShield(F)) / targetGreenHits(F)
                + referenceFlatArmour(F)
```

Preserve enemy-type HP differences and authored attack damage ratios around
these benchmarks. Only `F` selects the fixed reference; actual equipped gear
and actual character level never set an enemy's stats. Thus better gear and
retained XP can break a plateau. Integer projectile damage must not silently
invalidate fractional reference-hit targets.

This pass establishes a reproducible way to fit the agreed targets. It does
not establish actual clear rates, a balanced loot acquisition rate, or an
average player's progression route. Starting gear contribution is settled;
evaluate weaker/stronger builds and failure/continuation scenarios before
selecting the complete numerical model for implementation.

| Sampled Delve | Reference character level | Ordinary HP | Boss HP | Green raw hit |
| --- | ---: | ---: | ---: | ---: |
| 1 | 1.00 | 150.24 | 2253.61 | 30.09 |
| 1000 | 19.52 | 961.13 | 14416.89 | 334.58 |
| 2500 | 41.17 | 3123.21 | 46848.17 | 848.36 |
| 5000 | 78.81 | 12081.63 | 181224.41 | 2207.85 |
| 10000 | 100.00 | 63309.45 | 949641.70 | 5382.68 |

At Delve 10000, benchmark gear supplies approximately 77.6% of attack and
74.6% of HP plus shield. Actual intrinsic character stats are capped while item
power can continue growing. Holding character level at 100 and comparing
Legendary sets at Delve 10000 and 20000 confirms increasing item-derived
power. The endgame comparison below separates the capped player from the
uncapped reference used to set enemy stats.
The legacy attack-speed formula eventually reaches its cooldown floor;
damage and capacity growth must not accidentally inherit that individual
stat's cap. Further stat-curve tuning remains explicit design work.

## Endgame: uncapped reference character, capped actual character

The user clarified that enemy scaling must continue as though the reference
character can still level. Beyond the existing level-100 reference at Delve
10000, use reference level `F / 100` and full Legendary gear at power `F`.
The actual player's intrinsic stats remain those of level 100. Gear power
uses the same continuous `x = (F - 1) / 100`; it does not use capped character
level. This changes no probabilities or pre-10000 calibration outputs.

Continue the accepted time trajectory against the hypothetical reference:

```text
ordinaryReferenceSeconds(F) = 2 + 2*(F-1)/4999
bossReferenceSeconds(F) = 15*ordinaryReferenceSeconds(F)
enemyHP(F) = referenceDPS(F, F/100, Legendary)*referenceSeconds(F)
greenRawHit(F) = referenceCapacity(F, F/100, Legendary)/5
                + referenceArmour(F, Legendary)
```

Accepted gear policy, October 4: retain normal gear growth with no additional
term specifically replacing missing character stats. Under the current
numerical curve, evaluate the level-100 player against these fixed enemies:

| Sampled Delve | Hypothetical level | Reference ordinary / boss | Actual L100 ordinary / boss | Actual green-hit capacity |
| --- | ---: | ---: | ---: | ---: |
| 10000 | 100 | 6.0 s / 90.0 s | 6.0 s / 90.0 s | 5.00 |
| 20000 | 200 | 10.0 s / 150.0 s | 11.0 s / 165.6 s | 4.43 |
| 50000 | 500 | 22.0 s / 330.1 s | 24.7 s / 370.6 s | 4.31 |
| 100000 | 1000 | 42.0 s / 630.1 s | 46.5 s / 697.9 s | 4.36 |

Both builds in each row use identical full Legendary equipment at that
row's sampled power. Times are ideal sustained-fire calculations; ordinary
enemy differences, misses, dodging, regeneration, and gear acquisition are
not simulated. Green-hit capacity is a continuous damage ratio with no
regeneration, not a rounded count of projectiles survived. Actual level 100
needs about 10.36% more DPS and 12.91% more total HP plus shield at Delve
20000 to match the hypothetical reference, rather than needing twice the
total build power. Item stats already supply most of that power.

The level-gap penalty does not increase forever with the present curves:
gear growth eventually outpaces the missing intrinsic contribution. Longer
target fights and growing encounter budgets continue adding pressure.
The linear kill-time extension also means long endgame fights: the Delve
100000 reference boss takes about 10.5 minutes, or 11.6 minutes for the
capped player in this scenario. Preserve this as an explicit consequence
of the selected trajectory when evaluating the desired fast feel.

Existing equipment has no character-level equip requirement, so the level
cap does not prevent wearing higher-power drops; see [equipping](../Cubrism/VendorPopUpNode.swift:296).
The current item constructor has no item-level ceiling, although the Delve
design still needs decimal-power generation. See [equipment](../Cubrism/Equipment.swift:24).
The legacy cooldown floor is 0.05 seconds. Under the proposed Legendary
curve it is reached at Delve 22401, after which further attack-speed
contribution gives no benefit. Other item stats continue increasing. This
is a concrete tuning limit, not evidence of a universal infinite scaling
formula. The present comparison is a candidate, not an implemented balance.

## Current route quality checks

At each milestone, hold reference character level and enemy stats fixed and
vary the whole equipped set. These are sustained-fire calculations, not
recorded game sessions. Common and Legendary denote item quality at that
milestone's gear power; they do not mean carrying Delve-1 items forever.

| Sampled Delve | Common-set kill time | Benchmark-set kill time | Legendary-set kill time |
| --- | ---: | ---: | ---: |
| 1 | 2.00 s | 2.00 s | 1.33 s |
| 1000 | 2.56 s | 2.40 s | 1.81 s |
| 2500 | 3.57 s | 3.00 s | 2.24 s |
| 5000 | 6.12 s | 4.00 s | 3.33 s |
| 10000 | 15.79 s | 6.00 s | 6.00 s |

The benchmark gear still yields ten green hits at Delve 1 and five thereafter
at the listed milestones. A complete Common set at Delve 10000 yields about
2.71 hits instead of the benchmark Legendary set's five. Thus quality affects
both kill speed and survival while enemies stay fixed. Interpolating the
reference rarity factor should remain continuous across rarity milestones
and the point where the reference character reaches the cap.

The accepted rating curve also yields the intended increasing plateau
pressure. For an illustrative performance score of 0.6, at matched difficulty:

| Account Delve | Break-even clear rate, run floor 1 | Break-even clear rate, run floor 6+ |
| --- | ---: | ---: |
| 1000 | 32.90% | 24.64% |
| 2500 | 48.54% | 38.61% |
| 5000 | 62.94% | 53.10% |
| 10000 | 65.36% | 55.71% |

These are local expected-score calculations, `loss/(gain+loss)`, conditional
on already reaching the given run floor. They are not overall run success
rates or forecasts of player skill. Continuing raises gains but also carries
depleted health and risks the entire unbanked bag. Actual clear rates, loot
banking, and retained XP require the first playable version or a richer
simulation; the calculations above establish direction and arithmetic only.
