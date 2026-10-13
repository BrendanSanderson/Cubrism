"""Offline candidate for the accepted 50-hour Delve-10000 pacing milestone.

Uses local expected rating drift, not simulated players or a playtime forecast.
Actual character level caps at 100; Delve and item power do not cap. Beyond
10000, enemy calibration uses an uncapped hypothetical level of F / 100.
Fixed XP costs fit unbonused XP on the reference route. Continuation XP is
then applied separately, accelerating character progress rather than raising
its costs. Runtime rewards would come from completed content, never a clock.
See DUNGEON-CALIBRATION.md for assumptions and unresolved tuning choices.
"""

from bisect import bisect_right
from math import sqrt

CHARACTER_CAP = 100
DELVE_MILESTONE = 10000
RARITY_DELVES = [1, 1000, 2500, 5000, 10000]
RARITY_FACTORS = [1, 1.25, 1.5, 2, 2.5]


def interpolate(value, xs, ys):
    if not xs[0] <= value <= xs[-1]:
        raise ValueError("Outside the calibration scenario")
    i = min(bisect_right(xs, value) - 1, len(xs) - 2)
    t = (value - xs[i]) / (xs[i + 1] - xs[i])
    return ys[i] + t * (ys[i + 1] - ys[i])


def ordinary_seconds(f):
    # Continue the accepted slope beyond 10000. These are target times for
    # the reference character; an actual capped character can take longer.
    return 2 + 2 * (f - 1) / 4999


def floor_minutes(f, budget_exponent=0.1):
    x = (f - 1) / 100
    budget = 12 * (1 + x) ** budget_exponent
    # Provisional canonical composition: paired one-point enemies, costing
    # 2.5 per room; two active seconds overhead per room; 20% timing allowance.
    seconds = budget / 1.25 * ordinary_seconds(f)
    seconds += 2 * budget / 2.5 + 15 * ordinary_seconds(f)
    return 1.2 * seconds / 60


def xp_per_minute(f):
    # Proposed XP unit scale and retained, rebased legacy reward power curve.
    return 50 * (1 + (f - 1) / 700) ** 2.5


def reference_stats(f, level, rarity):
    # Intentionally uncapped: this build can represent a hypothetical
    # character used to calibrate enemies, not an attainable XP level.
    x = (f - 1) / 100
    delta = 100 * ((1 + x / 4) ** 1.4 - (1 + x / 5) ** 1.2)
    # Accepted aggregate starting gear contributions. Retain the previous
    # ensemble-average growth terms provisionally; individual slot allocation
    # is separate from this offline benchmark.
    hp = 100 * ((level + 4) / 5) ** 1.2 + rarity * (50 + 27 * delta / 40)
    shield = 100 * ((level + 4) / 5) ** 1.1 + rarity * (50 + 27 * delta / 40)
    attack = 25 * ((level + 4) / 5) ** 1.1 + rarity * (12.5 + 27 * delta / 160)
    armour = rarity * (0.0875 + 17 * delta / 1600)
    cooldown = max(0.05, 0.5 - 0.02 * rarity * (x + 1) / 25)
    return hp, shield, attack / cooldown, armour, cooldown


def player_stats(f, level, rarity):
    return reference_stats(f, min(level, CHARACTER_CAP), rarity)


def endgame_comparison(f):
    """Current gear-curve candidate; no extra cap-compensation on items."""
    if f < DELVE_MILESTONE:
        raise ValueError("Endgame comparison starts at Delve 10000")
    virtual_level = f / 100
    reference = reference_stats(f, virtual_level, 2.5)
    actual = player_stats(f, CHARACTER_CAP, 2.5)
    seconds = ordinary_seconds(f)
    enemy_hp = reference[2] * seconds
    green_raw_hit = (reference[0] + reference[1]) / 5 + reference[3]
    actual_seconds = enemy_hp / actual[2]
    actual_hits = (actual[0] + actual[1]) / (green_raw_hit - actual[3])
    return (f, virtual_level, seconds, 15 * seconds, actual_seconds,
            15 * actual_seconds, actual_hits)


def route_derivatives(r, probabilities, performance, failed_fraction,
                      budget_exponent):
    # Each depth contributes only if prior floors cleared. Freeze R within
    # this local expectation. Failed XP share equals failed time share here;
    # actual kill/boss allocations may make them differ in gameplay.
    reach = 1.0
    net = time_weight = boosted_xp_weight = 0.0
    loss = min(20, 2 + 8 * (r - 1) / 2499)
    for depth, chance in enumerate(probabilities, start=1):
        bonus = 1 + 0.1 * min(depth - 1, 5)
        gain = 10 * bonus * (1 + 0.1 * performance)
        net += reach * (chance * gain - (1 - chance) * loss)
        completed_share = reach * (chance + failed_fraction * (1 - chance))
        time_weight += completed_share
        boosted_xp_weight += completed_share * bonus
        reach *= chance
    if net <= 0:
        raise ValueError("Scenario has no positive expected rating drift")
    dt = floor_minutes(r, budget_exponent) * time_weight / net
    base_xp = dt * xp_per_minute(r)
    return dt, base_xp, base_xp * boosted_xp_weight / time_weight


def integrate_route(step=1, probabilities=(0.95, 0.90, 0.80), performance=0.6,
                    failed_fraction=0.5, budget_exponent=0.1):
    floors = list(range(1, DELVE_MILESTONE + 1, step))
    if floors[-1] != DELVE_MILESTONE:
        floors.append(DELVE_MILESTONE)
    times, experience, boosted = [0.0], [0.0], [0.0]
    for a, b in zip(floors, floors[1:]):
        da = route_derivatives(a, probabilities, performance, failed_fraction,
                               budget_exponent)
        db = route_derivatives(b, probabilities, performance, failed_fraction,
                               budget_exponent)
        for output, va, vb in zip((times, experience, boosted), da, db):
            output.append(output[-1] + (b - a) * (va + vb) / 2)
    return floors, times, experience, boosted


def calibration_data(step=1):
    floors, times, experience, boosted = integrate_route(step)
    levels = list(range(1, CHARACTER_CAP + 1))
    level_times = [0.0]
    for level in levels[:-1]:
        level_times.append(level_times[-1] + 2 + 2 * sqrt(level - 1))
    thresholds = [interpolate(t, times, experience) for t in level_times]
    return floors, times, thresholds, boosted, level_times, levels


def write_swift_calibration(destination):
    """Export fixed costs and reference levels for the initial runtime tuning."""
    from pathlib import Path

    floors, _, thresholds, boosted, _, levels = calibration_data()
    scores = [1] + list(range(100, DELVE_MILESTONE + 1, 100))
    values = [interpolate(min(interpolate(f, floors, boosted), thresholds[-1]),
                          thresholds, levels) for f in scores]
    costs = [b - a for a, b in zip(thresholds, thresholds[1:])]
    lines = ["import Foundation", "",
             "// Generated from docs/calibration/delve_reference.py using the initial",
             "// three-floor 50-hour scenario. Costs are fixed; bonuses do not rewrite them.",
             "enum DelveCalibration {"]
    for name, table in [("levelUpCosts", costs), ("referenceDelves", scores),
                        ("referenceLevels", values)]:
        lines.append(f"    static let {name}: [Double] = [")
        for i in range(0, len(table), 5):
            lines.append("        " + ", ".join(f"{v:.12g}" for v in table[i:i+5]) + ",")
        lines.append("    ]")
    lines.append("}")
    Path(destination).write_text("\n".join(lines) + "\n")


def calculate(step=1):
    floors, times, thresholds, boosted, level_times, levels = calibration_data(step)

    xp_rows = []
    for level in [1, 10, 25, 50, 99]:
        start, end = level_times[level - 1:level + 1]
        f = interpolate(start, times, floors)
        cost = thresholds[level] - thresholds[level - 1]
        xp_rows.append((level, f, cost, end - start))

    def character_level(f):
        # Reference character has reached the cap before the milestone.
        # F beyond this study's range therefore remains capped, without
        # clamping enemy or item scaling to the end of the reference table.
        xp = interpolate(min(f, DELVE_MILESTONE), floors, boosted)
        return interpolate(min(xp, thresholds[-1]), thresholds, levels)

    combat_rows, quality_rows = [], []
    for f, rarity in zip(RARITY_DELVES, RARITY_FACTORS):
        level = character_level(f)
        hp, shield, dps, armour, cooldown = reference_stats(f, level, rarity)
        hits = 10 - 5 * min((f - 1) / 999, 1)
        combat_rows.append((f, level, floor_minutes(f), dps,
                            dps * ordinary_seconds(f),
                            dps * 15 * ordinary_seconds(f),
                            (hp + shield) / hits + armour, cooldown))
        enemy_hp = dps * ordinary_seconds(f)
        common_seconds = enemy_hp / reference_stats(f, level, 1)[2]
        legendary_seconds = enemy_hp / reference_stats(f, level, 2.5)[2]
        quality_rows.append((f, common_seconds, legendary_seconds))
    # Numerical contract checks for the design model, not runtime game tests.
    assert abs(level_times[-1] - 1501.026145) < 0.000001
    assert len(thresholds) == CHARACTER_CAP
    costs = [b - a for a, b in zip(thresholds, thresholds[1:])]
    assert costs[0] > 0 and all(b > a for a, b in zip(costs, costs[1:]))
    assert boosted[-1] > thresholds[-1]
    assert character_level(10000) == character_level(20000) == CHARACTER_CAP
    assert reference_stats(20000, 100, 2.5)[2] > reference_stats(10000, 100, 2.5)[2]
    assert player_stats(20000, 200, 2.5) == player_stats(20000, 100, 2.5)
    assert reference_stats(20000, 200, 2.5)[2] > player_stats(20000, 100, 2.5)[2]
    return {
        "xp": xp_rows, "combat": combat_rows,
        "base_cap_minutes": level_times[-1],
        "boosted_cap_minutes": interpolate(thresholds[-1], boosted, times),
        "boosted_cap_delve": interpolate(thresholds[-1], boosted, floors),
        "milestone_minutes": times[-1],
        "quality": quality_rows,
    }


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--swift-output", help="Write the initial runtime calibration table to this path")
    arguments = parser.parse_args()
    if arguments.swift_output:
        write_swift_calibration(arguments.swift_output)
    result = calculate()
    print("Unbonused XP calibration: character level | reference Delve | next-level XP | target minutes")
    for level, f, cost, minutes in result["xp"]:
        print(f"{level} | {f:.1f} | {cost:,.1f} | {minutes:.2f}")
    print("Combat scenario: Delve | reference character level | floor minutes | DPS | ordinary HP | boss HP | green raw hit | cooldown")
    for row in result["combat"]:
        print(" | ".join(f"{v:,.2f}" for v in row))
    print(f"Minutes to character 100: {result['base_cap_minutes']:.6f} before XP bonuses; "
          f"{result['boosted_cap_minutes']:.2f} with XP bonuses at Delve {result['boosted_cap_delve']:.1f}")
    print(f"Hours to Delve {DELVE_MILESTONE}: {result['milestone_minutes']/60:.4f}")
    print("Quality comparison: Delve | Common kill seconds | Legendary kill seconds")
    for f, common, legendary in result["quality"]:
        print(f"{f} | {common:.3f} | {legendary:.3f}")
    print("Endgame candidate, matching Legendary gear: Delve | virtual level | reference ordinary/boss seconds | actual L100 ordinary/boss seconds | actual green hits")
    for f in (10000, 20000, 50000, 100000):
        print(" | ".join(f"{v:,.3f}" for v in endgame_comparison(f)))
    base = reference_stats(1, 1, 1)
    rare = reference_stats(1, 1, 1.5)
    print(f"Initial full Rare set: DPS +{100*(rare[2]/base[2]-1):.4f}%; HP+shield +{100*((rare[0]+rare[1])/(base[0]+base[1])-1):.4f}%")
    coarse = calculate(step=2)
    difference = max(abs(a[2] - b[2]) / a[2] for a, b in zip(result["xp"], coarse["xp"]))
    print(f"XP-cost integration sensitivity, Delve step 1 vs 2: {100*difference:.6f}%")
    print("Pacing sensitivity: scenario | hours to Delve 10000")
    for label, chances, performance in [
        ("All wins, fresh runs, no bonuses", (1,), 0),
        ("Extract after one; 95% clear", (0.95,), 0.6),
        ("Try three; 95/90/80% clear", (0.95, 0.90, 0.80), 0.6),
        ("Try five; 95/90/80/65/50% clear", (0.95, 0.90, 0.80, 0.65, 0.50), 0.6),
    ]:
        route = integrate_route(probabilities=chances, performance=performance)
        print(f"{label} | {route[1][-1]/60:.2f}")
