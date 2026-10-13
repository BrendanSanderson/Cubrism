---
status: superseded by ADR-0002
---

# Settle progression at floor checkpoints

Superseded by [ADR 0002](0002-risk-run-loot-until-leaving-a-checkpoint.md).
The original reward-banking rule below was changed: floor checkpoints offer
loot, but only leaving the run safely banks it. Floor-by-floor experience and
difficulty updates remain part of the current design.

The dungeon replaces selectable stages with repeatable generated floors, each
containing a starting room, combat rooms, and a boss. Each floor attempt settles
progression independently: a successful clear reaches a checkpoint, awards
items and experience, and adjusts difficulty before the next floor; death
retains earned experience and grants no new items. This makes every completed
floor a reward and progression boundary, rather than postponing rewards and
rating adjustment until the end of a descent through several floors.

At a checkpoint the player may end the run or continue with remaining health.
Continuing offers bonuses to loot, experience, and difficulty increase at the
cost of greater risk of dying. Rewards already secured at a completed floor
remain secured. The exact bonus mechanics and rating formula remain separate
design decisions. Completing another floor cannot award the previous floor's
rewards again.
