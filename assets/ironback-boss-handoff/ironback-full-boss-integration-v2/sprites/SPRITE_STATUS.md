> Revision 2: Read ../IMPLEMENTATION_CORRECTIONS.md first. Its required VFX coverage, sprite playback bindings and attack-specific knockback supersede conflicting earlier guidance.

# Actual sprite deliverables

30 individual PNGs, RGBA with real alpha, on common384x448 canvases and estimated bottom-center pivot(192,340). Source atlas measured1536x1024, NOT requested1536x1280. It is not uniformly spaced enough for automatic 6x5 atlas import: use the individual files. manifest.json records explicit measured source rectangles and each opacity-bound rectangle. Pixels are not rescaled; do not stretch the source atlas into the requested dimensions.

6 idle/walk keys;6 smash keys;6 leap keys;3 backhand keys;3 rush keys;1 hurt key;1 phase key;2 defeat keys;1 impact FX;1 traveling-wave FX. Barrage deliberately reuses smash keys with three timed impact events. Body key poses cover the named combat states; the VFX set is incomplete and must be supplemented per IMPLEMENTATION_CORRECTIONS.md. All named combat states have body pose coverage, but these are KEY POSES rather than all intermediate drawings in the original animation specification.

The generator does not fully maintain strict side-facing anatomy: overhead/contact poses turn toward the camera, and limb proportions/armor details vary slightly. Some soft amber vent/FX halo alpha remains. The static pose separation preserves it, rather than silently flattening or deleting it. Rush active/brake and idle/walk changes are subtle. There is no fully authored turn clip, death transition, vent sequence or wave-dissipation sequence. The integration agent must either author/refine these or report reduced key-pose fidelity and use explicit holds/fades for non-damaging FX end states.

Root registration is estimated from the strong-alpha silhouette bounds, not measured anatomical feet across a running animation. This provides separate usable assets and consistent canvas metadata, but airborne/front-facing frames can shift apparent body center. Review/adjust per-frame visual offsets in game without changing player physics or attack events. Large side-on punches must not make the body root slide simply because a bounding box is wider.

Use nearest-neighbor sampling and the project's appropriate pixel scale. The older suggested2x scale would make these already-large delivered sprites too large in some viewports; choose from actual pixel/body dimensions and desired boss bounds. Keep sprite presentation and body/attack collision independently registered and visually honest.
