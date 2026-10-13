---
status: accepted
---

# Generate floors from difficulty points

Derive a floor difficulty budget from its hidden sampled difficulty and use it
as an ordinary-combat encounter budget. Each enemy type has a point cost and
a minimum Delve threshold compared with the sampled floor difficulty for
random eligibility, and combining enemies in a room multiplies its
cost. Room counts and encounter compositions follow this budget instead of
fixed stage sizes or a hard floor-duration cap.

At comparable difficulty, sparse floors target more rooms and more enemies
overall; dense floors spend more points on concurrent pressure and contain
fewer of both. Preserve the existing stat curve through the Delve-to-scaling-
level mapping. Tune eligibility thresholds so an average-pace player makes
roughly one new enemy type available per floor, without guaranteeing a spawn.

Guarantee one final boss outside the ordinary-room budget, with stats scaled
from the sampled floor difficulty. There is no separate boss allowance or
point cost; minibosses and unequal boss tiers are deferred.
