# Project memory

Before designing or changing cave rooms, forest rooms, traversal geometry, room rewards,
or room presentation, read both `design/ROOM_DESIGN_MEMORY.md` and
`design/ART_DESIGN_MEMORY.md`. The room note owns movement measurements, layout,
accepted design decisions, save behavior, and verification. The art note extends that
baseline with visual direction and gameplay readability. Update the relevant existing
note when work produces a new reusable lesson; do not duplicate rules or preserve
temporary observations as permanent guidance.

Work in the root Godot project. `Metroidvania-main/` is a separate nested project;
do not mirror edits into it. Preserve unrelated existing work.

Keep room geometry and game state authoritative: rendered solid terrain must match
collision, rewards and shortcuts must survive cave/forest travel, and entering a room
must never replace the last activated hand checkpoint. Hand interaction sets the
checkpoint in memory; the Save button and normal progress saves handle disk persistence.
