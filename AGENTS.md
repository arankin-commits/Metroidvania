# Project memory

Before designing or changing cave rooms, forest rooms, traversal geometry, room rewards,
or room presentation, read `design/ROOM_DESIGN_MEMORY.md`. It is the shared room-design
baseline, including movement measurements, accepted design decisions, save behavior,
and the checks needed when a room changes. Update that document when playtesting
produces a new reusable lesson.

Work in the root Godot project. `Metroidvania-main/` is a separate nested project;
do not mirror edits into it. Preserve unrelated existing work.

Keep room geometry and game state authoritative: rendered solid terrain must match
collision, rewards and shortcuts must survive cave/forest travel, and entering a room
must never replace the last activated hand checkpoint. Hand interaction sets the
checkpoint in memory; the Save button and normal progress saves handle disk persistence.
