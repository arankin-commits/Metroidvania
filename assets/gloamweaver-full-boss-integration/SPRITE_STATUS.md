# Asset status — ground revision 3

Retained PNGs are static keys, not complete frame-by-frame animation sequences. No new ground art was generated in this revision.

Active or conditionally reusable body keys: floor_idle; bite_tell, bite_active; trap_prepare, trap_release, trap_recovery; hurt, phase_change, defeat; zip_aim, zip_release, zip_compress, zip_travel, zip_arrival, zip_recovery. Zip poses require floor-specific socket/pose validation before production use.

Retired body keys (reference only): ceiling_idle_01/02, ceiling_crawl_01/02/03/04, swing_prepare, swing_hang, swing_rake, swing_rise, swing_recovery, reattach_catch, drop_gather, drop_airborne, drop_impact. Never require these to appear in the ground encounter.

Missing: a real ground crawl cycle (minimum four distinct supported gait poses) and potentially a lower ground charge cycle. Author these; floor_idle is only an interim walk placeholder, not a completed animation. Do not reuse upside-down ceiling walking.

All existing VFX can be used in the ground encounter: hook_head, anchor_rosette, cable_segment, swing_streak (conditional charge accent), landing_dust (ground skid dust), bite_streak, trap_seed, trap_unfold, trap_active, trap_trigger, hit_fray, web_dissolve. Dynamic cable geometry and procedural charge trails are still required. Preview JPGs and atlas sources are reference, not runtime sprites. The original design sheet and generation prompts are historical and superseded for mechanics.
