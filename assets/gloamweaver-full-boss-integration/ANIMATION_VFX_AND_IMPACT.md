# Ground animation, effects, and impact — revision 3

Required runtime states: floor_idle, ground_crawl, bite_tell, bite_active, bite_recovery, charge_tell, charge_hook, charge_travel, charge_skid, charge_recovery, snare_tell, snare_release, snare_recovery, hurt, phase_change, defeat. Retired ceiling/swing/drop states must never be entered.

Calibrate feet, spinneret, fangs, body center, and collision dimensions per pose. PNG alpha-bounds centers are not foot sockets. Apply all visual offsets, facing, scale, and rotation exactly once. Keep the charge body upright/low and floor-supported; do not rotate it into the old aerial zip presentation. Author ground walk and any missing ground charge poses instead of flipping the ceiling crawl upside down. Interim placeholder use must be explicitly visible in the agent's completion report.

Suggested existing charge pose sequence: zip_aim -> zip_release -> zip_compress -> zip_travel -> zip_arrival -> zip_recovery. Each is conditional on anatomical suitability on the floor. Use floor_idle for grounded idle and final recoveries, bite_tell/bite_active for bite, trap_prepare/trap_release/trap_recovery for snare, and the existing hurt/phase_change/defeat assets. Hurt must appear on accepted damage, approximately 0.15 s; do not restart an active attack's damage ID or erase its committed motion. Defeat disables all damage and clears boss-owned statuses before showing grounded collapse.

Web charge: hook_head at the moving hook, anchor_rosette at the verified wall socket, and a dynamic Line2D from the current transformed spinneret to hook/anchor. Convert world endpoints to the Line2D's local coordinates every frame. The cable_segment image is an optional accent, not a static substitute for the connecting line. Retain the cable through charge skid, dissolve after release. Use velocity-aligned procedural ground charge streaks or a suitable swing_streak accent, plus ground-level skid dust from landing_dust at charge stop; no aerial drop trails or landing events remain. Emit effects from actual world sockets, independently of hit acceptance.

Snare uses trap_seed -> trap_unfold -> trap_active -> trap_trigger and web_dissolve on expiry. Bite uses bite_streak at fangs during the active window. Hurt/phase uses hit_fray; defeat dissolves remaining silk. Effects must be registered in scene resources and exercised during acceptance testing.

| Accepted attack | Horizontal impulse magnitude | Upward impulse magnitude | Brief input lock |
|---|---:|---:|---:|
| Fang bite | 150 px/s | 90 px/s | 0.10 s |
| Web ground charge | 260 px/s | 120 px/s | 0.17 s |
| Silk snare | 0 | 0 | 0 |

Send a source-tagged damage payload through the player's existing damage receiver, preserving its invulnerability handling. Direction for charge follows committed travel; bite pushes away from fangs. Apply the impulse once only when the receiver accepts damage. Upward sign follows the engine coordinate system (Godot negative Y). Do not overwrite impulse with crawl input or multiply it by snare slow. Clamp movement through normal collision resolution, not teleportation. Visual hits and rejected invulnerable hits do not apply extra knockback.
