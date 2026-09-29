# Flipping Volley ? 2026-09-28

The supplied Forest Guardian reference is preserved under
`design/references/forest-boss/forest-boss-design-sheet.png`.

Boss and earned Bow volleys create three downward-facing arrows. Each hovers
motionless and harmless at its individual spawn position for one second, then
tracks the target's current position. Vertical travel stays positive/downward,
including when the target jumps above the arrow or disappears. The hover adds one
second to lifetime, preserving normal flight duration. Hovering arrows clear when
the boss dies or the encounter deactivates; ordinary shots remain immediate.
Volley wall probes exclude their target body so release contact reaches the
existing swept damage check instead of being mistaken for a wall.

`tests/flipping_volley_smoke.gd` passes: exact hover duration, no early damage,
release and horizontal retargeting, target above/lost, lifetime, reset cleanup,
actual collider contact, boss and reward emitters, and unchanged ordinary shots.
The full boss combat regression and Web pack runtime smoke pass. The local pack
is 68,989,696 bytes (68.99 MB), with all 145 runtime resources loadable and all
61 original live media resources unchanged.
