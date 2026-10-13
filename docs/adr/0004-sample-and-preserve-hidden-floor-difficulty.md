---
status: accepted
---

# Sample and preserve hidden floor difficulty

Generate each floor from one hidden difficulty sampled from a normal
distribution centered on the account's current Delve Level, with standard
deviation equal to five percent of that score. Use that value to design the
floor, determine enemy eligibility, and scale enemy and gear power through a
smooth Delve-to-scaling-level mapping. Preserve the sampled value with the
floor plan across sessions, so resuming the same floor cannot reroll its
difficulty.

Winning a floor harder than the account's entry Delve Level gives extra Delve
progress; easier wins grant less, and harder failures cost less. This challenge
adjustment is distinct from the performance bonus, initially capped at ten
percent, and bonuses for continuing the same run.
The lower-bound sampling policy, curve coefficients, and numerical
reward formulas remain tuning proposals in the main design document.
