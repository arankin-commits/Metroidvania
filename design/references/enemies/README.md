# Enemy references

User-supplied enemy reference images, copied unchanged from
`C:\NCAT\metroid\enemies` on 2026-09-29. Keep these source images as the
reference for future enemy appearance, animation and behavior work.

| Biome | Reference |
| --- | --- |
| Cave | [Goblin](cave/goblin.png) |
| Cave | [Goblin combo](<cave/goblin combo.png>) |
| Cave | [Goblin dog](<cave/goblin dog.png>) |
| Cave | [Goblin sentinel](<cave/goblin sentinel.png>) |
| Forest | [Kobold archer](<forest/kobold archer.png>) |
| Forest | [Kobold clubber](<forest/kobold clubber.png>) |
| Forest | [Kobold summoner](<forest/kobold summoner.png>) |

These are design references. Adding them to this catalog does not instantiate
new enemies, grant abilities, or change existing encounters. Runtime assets
derived from them belong in `assets/`; source references stay outside Web exports.

Six reusable enemy prefabs and 217 body frames are now prepared under
`scenes/enemies/` and `assets/characters/enemies/`. The Goblin combo sheet supplies
the basic Goblin's three attacks. The separate Archer arrow panel is an effect.
They are instantiated only by `tests/scenes/enemy_animation_lab.tscn`; open that
scene in Godot and press F6 to test them with the real player controller.
See [the animation review](../../reviews/enemy-animation-review.md) for controls,
animation counts, asset provenance, verification and extraction prompts.
