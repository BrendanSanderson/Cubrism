# Delve drop chances

Status: complete base rarity distribution accepted October 3, 2026. Not
implemented. Same-run continuation rarity is also accepted.
Rare and Uncommon converge at Delve 10000 at the accepted 37.5% each,
preserving the Common, Epic, and Legendary curves. Uncommon
rises from 30% and Rare from 15%; Common falls from 49% to 5%.

Selected tiers: Common (white), Uncommon (green), Rare (blue), Epic (purple),
and Legendary (orange). The earlier Rare endpoint of 50% is superseded
by 37.5%; Epic stays at 15% and Legendary at 5%. These are base chances
before continuation bonuses. Rare-or-better is their subtotal, not a sixth outcome.

Starting odds at Delve 1 are **15% Rare, 5% Epic, and 1% Legendary**, totaling
21%. Epic was raised from the earlier 3% proposal. These odds replace the
older Delve 500/1000 anchors, which are below the new starting total. The
accepted quadratic curve fits the caps exactly at Delve 10000, flattening
smoothly there. It supersedes the prior linear and exponential candidates.

## Gradual formula shown in this table

Rarity uses saved sampled difficulty `F` directly. The accepted distribution starts
Uncommon at 30% and Rare at 15%, both rising to 37.5% using the same taper.
Their endpoints divide the available 75% equally; Common, Epic, and Legendary
are unchanged. See [the balance proposal](DUNGEON-BALANCE.md).

```text
t = clamp((F - 1) / 9999, 0, 1)
growth = t * (2 - t)
baseRare      = 0.15 + 0.225 * growth
baseEpic      = 0.05 + 0.10 * growth
baseLegendary = 0.01 + 0.04 * growth
q = baseRare + baseEpic + baseLegendary
# Accepted convergence, October 3, 2026
baseUncommon  = 0.30 + 0.075 * growth
baseCommon    = 1 - q - baseUncommon
```

The curve is continuous, slows gradually, and joins the cap plateau with zero
slope at 10000. The accepted distribution there
and beyond is 5% Common, 37.5% Uncommon, 37.5% Rare, 15% Epic, and 5% Legendary. Rows are rounded; these are
per-item base probabilities before continuation and extraction risk.

## Starting odds and every 100 Delve

| Delve | Common | Uncommon | Rare | Epic | Legendary | Rare-or-better |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 49.00% | 30.00% | 15.00% | 5.00% | 1.00% | 21.00% |
| 100 | 48.13% | 30.15% | 15.44% | 5.20% | 1.08% | 21.72% |
| 200 | 47.27% | 30.30% | 15.89% | 5.39% | 1.16% | 22.44% |
| 300 | 46.41% | 30.44% | 16.33% | 5.59% | 1.24% | 23.15% |
| 400 | 45.56% | 30.59% | 16.76% | 5.78% | 1.31% | 23.85% |
| 500 | 44.72% | 30.73% | 17.19% | 5.97% | 1.39% | 24.55% |
| 600 | 43.89% | 30.87% | 17.62% | 6.16% | 1.46% | 25.24% |
| 700 | 43.06% | 31.01% | 18.04% | 6.35% | 1.54% | 25.92% |
| 800 | 42.25% | 31.15% | 18.45% | 6.53% | 1.61% | 26.60% |
| 900 | 41.44% | 31.29% | 18.86% | 6.72% | 1.69% | 27.27% |
| 1,000 | 40.65% | 31.42% | 19.27% | 6.90% | 1.76% | 27.93% |
| 1,100 | 39.86% | 31.56% | 19.67% | 7.08% | 1.83% | 28.58% |
| 1,200 | 39.08% | 31.69% | 20.07% | 7.25% | 1.90% | 29.23% |
| 1,300 | 38.31% | 31.82% | 20.47% | 7.43% | 1.97% | 29.87% |
| 1,400 | 37.55% | 31.95% | 20.86% | 7.60% | 2.04% | 30.50% |
| 1,500 | 36.80% | 32.08% | 21.24% | 7.77% | 2.11% | 31.12% |
| 1,600 | 36.05% | 32.21% | 21.62% | 7.94% | 2.18% | 31.74% |
| 1,700 | 35.32% | 32.33% | 22.00% | 8.11% | 2.24% | 32.35% |
| 1,800 | 34.59% | 32.46% | 22.37% | 8.27% | 2.31% | 32.95% |
| 1,900 | 33.87% | 32.58% | 22.73% | 8.44% | 2.38% | 33.55% |
| 2,000 | 33.17% | 32.70% | 23.10% | 8.60% | 2.44% | 34.14% |
| 2,100 | 32.47% | 32.82% | 23.45% | 8.76% | 2.50% | 34.72% |
| 2,200 | 31.77% | 32.94% | 23.81% | 8.91% | 2.57% | 35.29% |
| 2,300 | 31.09% | 33.05% | 24.16% | 9.07% | 2.63% | 35.85% |
| 2,400 | 30.42% | 33.17% | 24.50% | 9.22% | 2.69% | 36.41% |
| 2,500 | 29.75% | 33.28% | 24.84% | 9.37% | 2.75% | 36.96% |
| 2,600 | 29.10% | 33.39% | 25.18% | 9.52% | 2.81% | 37.51% |
| 2,700 | 28.45% | 33.50% | 25.51% | 9.67% | 2.87% | 38.05% |
| 2,800 | 27.81% | 33.61% | 25.83% | 9.81% | 2.93% | 38.57% |
| 2,900 | 27.18% | 33.72% | 26.16% | 9.96% | 2.98% | 39.10% |
| 3,000 | 26.56% | 33.82% | 26.47% | 10.10% | 3.04% | 39.61% |
| 3,100 | 25.95% | 33.93% | 26.79% | 10.24% | 3.10% | 40.12% |
| 3,200 | 25.35% | 34.03% | 27.09% | 10.38% | 3.15% | 40.62% |
| 3,300 | 24.76% | 34.13% | 27.40% | 10.51% | 3.20% | 41.11% |
| 3,400 | 24.17% | 34.23% | 27.70% | 10.64% | 3.26% | 41.60% |
| 3,500 | 23.59% | 34.33% | 27.99% | 10.77% | 3.31% | 42.08% |
| 3,600 | 23.03% | 34.43% | 28.28% | 10.90% | 3.36% | 42.55% |
| 3,700 | 22.47% | 34.52% | 28.57% | 11.03% | 3.41% | 43.01% |
| 3,800 | 21.92% | 34.62% | 28.85% | 11.16% | 3.46% | 43.47% |
| 3,900 | 21.38% | 34.71% | 29.13% | 11.28% | 3.51% | 43.92% |
| 4,000 | 20.84% | 34.80% | 29.40% | 11.40% | 3.56% | 44.36% |
| 4,100 | 20.32% | 34.89% | 29.67% | 11.52% | 3.61% | 44.79% |
| 4,200 | 19.80% | 34.98% | 29.93% | 11.64% | 3.65% | 45.22% |
| 4,300 | 19.30% | 35.06% | 30.19% | 11.75% | 3.70% | 45.64% |
| 4,400 | 18.80% | 35.15% | 30.44% | 11.86% | 3.75% | 46.05% |
| 4,500 | 18.31% | 35.23% | 30.69% | 11.97% | 3.79% | 46.46% |
| 4,600 | 17.83% | 35.31% | 30.94% | 12.08% | 3.83% | 46.85% |
| 4,700 | 17.36% | 35.39% | 31.18% | 12.19% | 3.88% | 47.25% |
| 4,800 | 16.90% | 35.47% | 31.41% | 12.30% | 3.92% | 47.63% |
| 4,900 | 16.45% | 35.55% | 31.65% | 12.40% | 3.96% | 48.00% |
| 5,000 | 16.00% | 35.62% | 31.87% | 12.50% | 4.00% | 48.37% |
| 5,100 | 15.57% | 35.70% | 32.10% | 12.60% | 4.04% | 48.73% |
| 5,200 | 15.14% | 35.77% | 32.31% | 12.70% | 4.08% | 49.09% |
| 5,300 | 14.72% | 35.84% | 32.53% | 12.79% | 4.12% | 49.44% |
| 5,400 | 14.31% | 35.91% | 32.74% | 12.88% | 4.15% | 49.78% |
| 5,500 | 13.91% | 35.98% | 32.94% | 12.97% | 4.19% | 50.11% |
| 5,600 | 13.52% | 36.05% | 33.14% | 13.06% | 4.23% | 50.43% |
| 5,700 | 13.14% | 36.11% | 33.34% | 13.15% | 4.26% | 50.75% |
| 5,800 | 12.76% | 36.18% | 33.53% | 13.24% | 4.29% | 51.06% |
| 5,900 | 12.40% | 36.24% | 33.72% | 13.32% | 4.33% | 51.36% |
| 6,000 | 12.04% | 36.30% | 33.90% | 13.40% | 4.36% | 51.66% |
| 6,100 | 11.69% | 36.36% | 34.08% | 13.48% | 4.39% | 51.95% |
| 6,200 | 11.35% | 36.42% | 34.25% | 13.56% | 4.42% | 52.23% |
| 6,300 | 11.02% | 36.47% | 34.42% | 13.63% | 4.45% | 52.50% |
| 6,400 | 10.70% | 36.53% | 34.58% | 13.70% | 4.48% | 52.77% |
| 6,500 | 10.39% | 36.58% | 34.74% | 13.77% | 4.51% | 53.03% |
| 6,600 | 10.09% | 36.63% | 34.90% | 13.84% | 4.54% | 53.28% |
| 6,700 | 9.79% | 36.68% | 35.05% | 13.91% | 4.56% | 53.52% |
| 6,800 | 9.51% | 36.73% | 35.20% | 13.98% | 4.59% | 53.76% |
| 6,900 | 9.23% | 36.78% | 35.34% | 14.04% | 4.62% | 53.99% |
| 7,000 | 8.96% | 36.82% | 35.47% | 14.10% | 4.64% | 54.21% |
| 7,100 | 8.70% | 36.87% | 35.61% | 14.16% | 4.66% | 54.43% |
| 7,200 | 8.45% | 36.91% | 35.74% | 14.22% | 4.69% | 54.64% |
| 7,300 | 8.21% | 36.95% | 35.86% | 14.27% | 4.71% | 54.84% |
| 7,400 | 7.97% | 36.99% | 35.98% | 14.32% | 4.73% | 55.03% |
| 7,500 | 7.75% | 37.03% | 36.09% | 14.37% | 4.75% | 55.22% |
| 7,600 | 7.53% | 37.07% | 36.20% | 14.42% | 4.77% | 55.40% |
| 7,700 | 7.33% | 37.10% | 36.31% | 14.47% | 4.79% | 55.57% |
| 7,800 | 7.13% | 37.14% | 36.41% | 14.52% | 4.81% | 55.73% |
| 7,900 | 6.94% | 37.17% | 36.51% | 14.56% | 4.82% | 55.89% |
| 8,000 | 6.76% | 37.20% | 36.60% | 14.60% | 4.84% | 56.04% |
| 8,100 | 6.59% | 37.23% | 36.69% | 14.64% | 4.86% | 56.18% |
| 8,200 | 6.43% | 37.26% | 36.77% | 14.68% | 4.87% | 56.32% |
| 8,300 | 6.27% | 37.28% | 36.85% | 14.71% | 4.88% | 56.44% |
| 8,400 | 6.13% | 37.31% | 36.92% | 14.74% | 4.90% | 56.57% |
| 8,500 | 5.99% | 37.33% | 36.99% | 14.77% | 4.91% | 56.68% |
| 8,600 | 5.86% | 37.35% | 37.06% | 14.80% | 4.92% | 56.78% |
| 8,700 | 5.74% | 37.37% | 37.12% | 14.83% | 4.93% | 56.88% |
| 8,800 | 5.63% | 37.39% | 37.18% | 14.86% | 4.94% | 56.97% |
| 8,900 | 5.53% | 37.41% | 37.23% | 14.88% | 4.95% | 57.06% |
| 9,000 | 5.44% | 37.42% | 37.27% | 14.90% | 4.96% | 57.13% |
| 9,100 | 5.36% | 37.44% | 37.32% | 14.92% | 4.97% | 57.20% |
| 9,200 | 5.28% | 37.45% | 37.36% | 14.94% | 4.97% | 57.27% |
| 9,300 | 5.22% | 37.46% | 37.39% | 14.95% | 4.98% | 57.32% |
| 9,400 | 5.16% | 37.47% | 37.42% | 14.96% | 4.99% | 57.37% |
| 9,500 | 5.11% | 37.48% | 37.44% | 14.97% | 4.99% | 57.41% |
| 9,600 | 5.07% | 37.49% | 37.46% | 14.98% | 4.99% | 57.44% |
| 9,700 | 5.04% | 37.49% | 37.48% | 14.99% | 5.00% | 57.47% |
| 9,800 | 5.02% | 37.50% | 37.49% | 15.00% | 5.00% | 57.49% |
| 9,900 | 5.00% | 37.50% | 37.50% | 15.00% | 5.00% | 57.50% |
| 10,000 | 5.00% | 37.50% | 37.50% | 15.00% | 5.00% | 57.50% |

## Continuing the same run

Using each item's own floor probabilities, the accepted best-of-depth method
uses the base caps above and may exceed them after the continuation bonus:

```text
Common    = baseCommon^d
Uncommon  = (1 - q)^d - baseCommon^d
Rare      = (1 - baseEpic - baseLegendary)^d - (1 - q)^d
Epic      = (1 - baseLegendary)^d - (1 - baseEpic - baseLegendary)^d
Legendary = 1 - (1 - baseLegendary)^d
```

Keeping the best roll shifts the mix toward Epic and Legendary. Previously
collected loot keeps its original rarity; death loses unbanked loot. Depth
counts consecutive floors within the same run only. Every new run resets to
one rarity draw; earlier wins in separate runs do not accumulate this bonus.

## Combat calibration decision

The user accepted kill times increasing linearly from two to four seconds
for a reference ordinary enemy, and thirty to sixty seconds for a boss,
between Delve 1 and 5000. These use average gear at the appropriate item power:
Common at Delve 1, Uncommon at 1000, Rare at 2500, Epic at 5000, and Legendary
at 10000. Typical rolls within each rarity define these reference loadouts.
The user also accepted the extension to Delve 10000 at approximately six
seconds for ordinary enemies and ninety seconds for bosses with average
Legendary gear. Reference equipment should evolve smoothly between anchors.

These are benchmarks for retained equipped gear, not the mean rarity of a
random drop. Evaluate loot acquisition and extraction against them without
turning the milestones into guaranteed drops or rarity unlock thresholds.
Calibrate health against reference builds; enemy stats do not dynamically
follow the individual player's equipment. Character level and Delve-derived
power are separate and do not necessarily stay one-for-one during play.
