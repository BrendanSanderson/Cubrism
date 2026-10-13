# Gear rarity: Borderlands and comparable loot systems

Research date: October 1, 2026. Primary-source design research; no gameplay changes. The proposed Cubrism multipliers remain tuning candidates, not values copied from another game.

## Finding

The useful lesson from Borderlands is to make rare equipment **more interesting as well as stronger**. The reviewed official material supports generated weapon variation, individually tuned weapon behaviors, and build-specific effects. It does not provide a universal same-level rule such as “a Legendary is exactly 2.5 times a Common.” No such numerical rarity table was verified in this research.

For Cubrism's initial stat-based equipment, `1 / 1.25 / 1.5 / 2 / 2.5` is a defensible provisional progression. Its justification is the desired gear breakthrough and straightforward readability, not industry precedent for those particular ratios. Later special effects should consume part of an item's intended power budget rather than automatically stacking without limit on top of the strongest raw multiplier.

## What the sources establish

### Borderlands 3

2K describes distinct weapon manufacturers, generated equipment, and special Legendary drops. Its examples emphasize different behaviors: protective weapon shields, multiple elemental damage types, and thrown guns that pursue enemies. Those examples illustrate the broader arsenal and should not all be classified as rarity-exclusive effects. [Official launch announcement](https://newsroom.2k.com/news/borderlandsr-3-is-now-available-worldwide)

Official August 6, 2020 hotfix notes tune weapons individually: Reflux and Brainstormer receive a higher projectile-chain chance; Bearcat's ammo cost drops from four to three; Rowan's Call gains accuracy; Complex Root charges faster; and Moonfire fires faster. The July 23 notes also describe removing 21 Anointments that were not engaging players and correcting excessive damage from certain gear/skill interactions. These are historical examples of multidimensional balance, not present-day stat recommendations. [Official Borderlands 3 announcements on Steam, August 6 and July 23 entries](https://store.steampowered.com/news/posts/?appgroupname=Borderlands+3%3A+Digital+Deluxe+Edition&appids=397540&enddate=1598537553)

2K's April 2021 announcement explains that Anointments can be replaced on an existing item to optimize a character build. Thus equipment usefulness depends partly on the effect matching the build; rarity alone does not describe the item's complete contribution. [Official Anointment reroll announcement](https://newsroom.2k.com/news/borderlandsr-3-show-me-the-eridium-mini-event-returns-today-new-loot-machines-arrive-april-8)

**Evidence limit:** the accessible official sources do not expose a complete Borderlands 3 generation formula, per-rarity part-count table, or universal same-level damage ratio. This research therefore does not claim exact white/green/blue/purple/orange multipliers, nor that every higher-rarity weapon beats every lower-rarity weapon in every build.

### Borderlands 4 is a separate reference

2K's official April 30, 2025 gameplay deep dive introduces a Licensed Parts system that combines abilities from multiple manufacturers in one weapon. Its Enhancement slot rewards matching equipment with manufacturer characteristics. These are specifically Borderlands 4 features; they should not be presented as Borderlands 3's precise implementation. [Official Borderlands 4 gameplay deep dive](https://newsroom.2k.com/news/borderlands-4-unveils-action-packed-gameplay-deep-dive)

This supports the design direction of combinations and synergy. The source does not publish a universal numerical rarity ladder or a same-level stat ratio suitable for direct reuse in Cubrism.

### Path of Exile: rarity increases modifier capacity

Grinding Gear Games' official item documentation gives Magic items at most one prefix and one suffix, and Rare items up to three of each: two versus six random modifiers. This is an exact documented difference in **modifier capacity**, not a claim that Rare equipment has three times the final combat power. Which modifiers are present and useful still matters. [Official item documentation](https://www.pathofexile.com/item-data)

For Cubrism, adding stat choices or complementary effects is a possible later way to distinguish rarity. It would be extra design scope; the present stat-multiplier system does not require a full affix generator.

### Diablo IV: affixes, special powers, and scoped numeric bonuses

The official Season 4: Loot Reborn announcement describes a May 2024 system with two affixes on Rare items and three on Legendary items. Legendary powers were stored as Aspects, while Greater Affixes were 1.5 times the strength of normal affixes. That `1.5×` applies to an individual Greater Affix, **not to an entire item or the Legendary rarity**. This is an explicitly dated historical design reference, not a claim about the current season's exact affix counts. [Official Loot Reborn announcement](https://news.blizzard.com/en-us/article/24077223/galvanize-your-legend-in-season-4-loot-reborn)

The same announcement says the developers reduced drop quantity while making each item more impactful, aiming to reduce inventory sorting. That is relevant to Cubrism's focus on better rarity odds during long runs instead of overwhelmingly more drops.

## Assessment of the proposed Cubrism ladder

Accepted tier names and colors are Common/white, Uncommon/green, Rare/blue, Epic/purple, and Legendary/orange. Proposed numeric strengths are:

| Tier | Item stat contribution | Increase over preceding tier |
| --- | ---: | ---: |
| Common | 1.00× | — |
| Uncommon | 1.25× | 25% |
| Rare | 1.50× | 20% |
| Epic | 2.00× | 33.3% |
| Legendary | 2.50× | 25% |

This makes Epic the largest relative adjacent jump. That is a tuning choice, not a mathematical problem. A Legendary is 2.5 times the corresponding Common **item contribution**, or 25% above the corresponding Epic contribution. It is not 2.5 times the character's total stats.

For example, if the character and other gear contribute 100 attack and the Common item adds 40, total attack is 140. Its otherwise equivalent Legendary adds 100, making total attack 200: a **42.9% total increase**, not 150%. More generally, if that Common item accounts for fraction `f` of the original total stat, replacing it with a `q`-times contribution gives a total ratio of `1 + f*(q - 1)`. This is our arithmetic, not a reported Borderlands formula.

The stronger the equipment share of a character's power, the more pronounced this ladder becomes. A matched-level, fixed-type comparison should hold the item slot, item power, subtype, and other rolls constant. Once different types, levels, or effects are compared, rarity alone should not be used to declare the winner.

## Recommendation for Cubrism

1. **Keep the proposed ladder as the first stat-based balance candidate.** It is simple and gives the rare drops enough potential impact to help players break through a Delve plateau. Label the coefficients as our tuning values.
2. **Measure the whole build.** For weapons, compare sustained effective DPS, including attack frequency and accuracy; for defenses, compare survivable damage and recovery. Multiplying both damage and attack frequency can multiply their effects on DPS. A broad “multiply every numeric field” rule is inappropriate for fields such as cooldown duration or proc probability without considering their meaning.
3. **Let item identity remain useful.** Within a tier, offer meaningful choices such as damage versus fire rate or health versus shield recovery. A pure uniform multiplier improves quality but does not itself create new builds.
4. **Treat special Legendary mechanics as a later, deliberate design addition.** When added, tune each item's ordinary stats with its special effect. Do not assume that `2.5×` raw strength plus an unrestricted multi-hit, chain, or recovery mechanic will stay near `2.5×` actual power.
5. **Tune item lifespan along with rarity.** A much older Legendary should eventually lose to sufficiently stronger newer gear. The item-power growth curve and rarity multipliers jointly determine when that happens; a rarity ladder cannot settle it by itself.

## Relationship to the accepted drop model

Following this research, the user selected stronger stats only for the first
version, including Legendary equipment. Distinctive effects are a desired
future addition and are outside the current refactor's scope. This is a
Cubrism product decision, not a claim about the games researched above.

The accepted first-floor anchors are Rare-or-better probability of 10% at Delve 500 and 20% at Delve 1000. Within the base Rare-or-better pool, the accepted split is 80% Rare, 15% Epic, and 5% Legendary. This implies the following **base per-item odds**, before any within-run best-of-depth effect:

| Delve | Rare | Epic | Legendary | Rare or better |
| ---: | ---: | ---: | ---: | ---: |
| 500 | 8% | 1.5% | 0.5% | 10% |
| 1000 | 16% | 3% | 1% | 20% |

These are Cubrism decisions, not rates derived from Borderlands. The size of a rarity upgrade and the frequency at which it appears should be evaluated together with the chance of surviving to extract it. Keeping item quantity modest while increasing quality is consistent with the stated goal of making continued runs feel rewarding.

If depth means rolling the entire rarity outcome several times and retaining the highest result, the **final** Rare/Epic/Legendary proportions at depth greater than one will not remain exactly 80/15/5. Those proportions describe the base roll. This follows from the best-of-depth calculation and should be explicit in the tuning document.

## Limitations

This review relies on official publisher/developer documentation and official game announcements. Some older Borderlands support pages now return errors; their complete publisher announcements were verified through the official Steam feed instead. It does not infer unpublished exact Borderlands multipliers from fan databases, community weapon tests, or individual item-card screenshots. The findings justify a design approach; playtesting is still needed to choose Cubrism's final numbers.
