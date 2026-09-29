# Smaller-window cropping correction

The user's 768x432 embedded debug window clipped the 1152x648 game image, hiding
the menu title and cutting off the right side. The project forced integer scaling,
whose minimum1x scale left the full-size rendered image outside the smaller window.
The earlier internal viewport screenshot misleadingly showed the complete image.

The root project now uses fractional fit scaling (Godot's default) with the same
1152x648 logical resolution and16:9 aspect preservation. The initial window override
is768x432, matching the reported debug-window size. Nearest-neighbor texture sampling
is unchanged. Logical room coordinates, camera envelopes and collision do not change.
Godot normalizes default-valued viewport/scaling properties out of project.godot;
the absence of scale_mode="integer" is intentional.

Verification:

- menu_smoke passes menu navigation.
- window_scaling_smoke checks the actual final window transform at768x432,
  1152x648 and800x600, requiring the complete view to fit without aspect distortion.
- The restarted embedded game reports physical size768x432, fractional stretch0,
  and final transform scale0.666667 on both axes, versus the old1.0 scale.
- Local Web export rebuilt; pack audit passes at67,905,308 bytes, below100MB.

An attempted desktop capture was occluded by another window and was discarded;
it is not presented as visual acceptance. A subsequent capture could not run after
the debug game closed. The native window-size/transform check and automated fit
checks establish the sizing correction; no new browser playtest is claimed.
