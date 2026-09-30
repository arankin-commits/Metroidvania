# Climbable Surface Reference System

The Rabbit Boss arena may contain multiple independent climbable surfaces.

The boss must NOT track climbing using only a LEFT/RIGHT value.

The climbing system should maintain references to the actual environment
surface the boss is interacting with.

Required conceptual variables:

currentClimbSurface
lastClimbSurface
climbSide

The exact data types should follow the existing game engine and project
architecture.

For example, currentClimbSurface may be:

- A collider reference
- A game object reference
- A node reference
- An actor reference
- A component reference

Do NOT introduce a custom reference system if the engine already provides
a safe way to reference collision objects.

---

# Surface Variables

## currentClimbSurface

Represents the actual surface the boss is currently attached to.

When the boss successfully grabs a climbable surface:

currentClimbSurface = detectedSurface

When the boss completely leaves climbing:

currentClimbSurface = null

This variable should be used whenever behavior depends on the specific
surface being climbed.

---

## lastClimbSurface

Represents the most recent surface the boss detached from.

Before leaving a surface:

lastClimbSurface = currentClimbSurface

Then:

currentClimbSurface = null

lastClimbSurface is primarily used to prevent the boss from immediately
re-grabbing the same surface.

Do NOT permanently blacklist lastClimbSurface.

It should become valid again after the appropriate re-grab condition
is satisfied.

---

## climbSide

Represents which side of the boss the CURRENT surface occupies.

Possible values:

LEFT
RIGHT
NONE

climbSide is NOT the identity of the surface.

For example:

currentClimbSurface = Pillar_A
climbSide = LEFT

or:

currentClimbSurface = RightWall
climbSide = RIGHT

When not climbing:

climbSide = NONE

---

# Surface Detection

When airborne, search for valid climbable surfaces near the boss.

Surface detection should return information conceptually similar to:

detectedSurface
detectedSide
surfaceNormal
contactPoint

Use the existing physics/collision API whenever possible.

Do not hard-code arena coordinates.

For example, DO NOT implement:

if boss.x < 100:
    currentClimbSurface = leftWall

Instead, identify the actual collider/object detected by the physics
system.

---

# Valid Climbable Surfaces

Not every collider should automatically be climbable.

Use the project's existing system for identifying climbable geometry.

Depending on the engine, this may be:

- Collision layer
- Collision mask
- Tag
- Group
- Component
- Interface
- Object type

Prefer whichever method already matches the project's architecture.

Conceptually:

if detectedObject is climbable:
    surface may be grabbed

else:
    ignore it

---

# Entering A Surface

When the boss detects a valid climbable surface:

1. Verify the boss is allowed to grab a surface.
2. Verify the surface is climbable.
3. Verify re-grab restrictions.
4. Store the detected surface.
5. Determine which side it is on.
6. Enter CLIMBING.
7. Display rabbit_climb.

Conceptually:

if canGrabSurface(detectedSurface):

    currentClimbSurface = detectedSurface
    climbSide = detectedSide

    MovementState = CLIMBING
    ActionState = CLIMB

---

# rabbit_climb Orientation

Sprite orientation while climbing must depend on climbSide.

RIGHT SURFACE:

currentClimbSurface = detectedSurface
climbSide = RIGHT

sprite = rabbit_climb
horizontalFlip = false

LEFT SURFACE:

currentClimbSurface = detectedSurface
climbSide = LEFT

sprite = rabbit_climb
horizontalFlip = true

Do NOT determine climbing orientation from the player's location.

Do NOT create rabbit_climb_left.png.

Use runtime horizontal sprite flipping.

---

# Maintaining Surface Attachment

While MovementState == CLIMBING:

The boss must verify that currentClimbSurface is still valid.

Conceptually:

if currentClimbSurface is valid:
    remain attached

else:
    detach from surface
    enter FALL

This is important because surfaces may eventually:

- Move
- Become disabled
- Be destroyed
- Change collision state
- Stop being climbable

Do not assume a stored surface reference will remain valid forever.

---

# Leaving A Surface

Whenever the boss intentionally leaves a climbable surface:

Store the surface before clearing the reference.

Conceptually:

lastClimbSurface = currentClimbSurface
currentClimbSurface = null
climbSide = NONE

Then begin the appropriate movement/action.

Examples:

CLIMB -> JUMP
CLIMB -> POUNCE
CLIMB -> FALL

Do NOT clear currentClimbSurface before saving it to lastClimbSurface.

---

# Surface Re-Grab Prevention

The boss must not immediately reconnect to the exact same surface it
just left.

Use:

lastClimbSurface
surfaceRegrabDelay

Example:

Boss leaves Pillar_A.

lastClimbSurface = Pillar_A

If Pillar_A is detected again immediately:

reject the grab

If Pillar_B is detected:

allow the grab if all other requirements are satisfied.

After surfaceRegrabDelay expires:

Pillar_A becomes eligible again.

Conceptually:

function canGrabSurface(surface):

    if surface is not climbable:
        return false

    if surface == lastClimbSurface AND regrabTimer > 0:
        return false

    return true

This restriction should compare SURFACE REFERENCES, not positions.

Do not use:

if newSurfacePosition == oldSurfacePosition

Use the actual object/collider identity.

---

# Different Surface Re-Grabbing

The re-grab delay should primarily prevent immediately grabbing the SAME
surface.

Example:

Boss leaves:

Pillar_A

While airborne:

Pillar_A -> temporarily blocked
Pillar_B -> available
LeftWall -> available
RightWall -> available

This allows rapid movement between different pieces of arena geometry
without allowing the boss to become stuck repeatedly grabbing the same
wall.

---

# Surface Jump

When jumping away from a surface:

1. Save currentClimbSurface as lastClimbSurface.
2. Determine launch direction using climbSide.
3. Clear currentClimbSurface.
4. Clear climbSide.
5. Start the re-grab timer.
6. Apply jump velocity.
7. Enter ASCENDING.
8. Display rabbit_jump.

Example:

If:

climbSide == LEFT

the surface is on the boss's left.

Launch primarily RIGHT.

If:

climbSide == RIGHT

the surface is on the boss's right.

Launch primarily LEFT.

IMPORTANT:

Determine launch direction BEFORE resetting climbSide.

---

# Surface Pounce

The boss may pounce directly from currentClimbSurface.

Sequence:

CLIMB
  ↓
Store player target
  ↓
Store currentClimbSurface as lastClimbSurface
  ↓
Clear currentClimbSurface
  ↓
Clear climbSide
  ↓
Start surface re-grab timer
  ↓
POUNCE_STARTUP / POUNCE_ACTIVE
  ↓
rabbit_pounce

Once the pounce begins, sprite orientation should be controlled by the
committed pounce direction rather than climbSide.

---

# Moving Surfaces

If the existing game supports moving climbable objects, preserve the
surface reference while attached.

The boss should remain logically associated with:

currentClimbSurface

rather than only remembering the coordinates where the surface was
originally detected.

If appropriate for the engine, the boss should follow the movement of
the surface while attached.

Do not implement moving-platform support from scratch if the game does
not currently require it.

However, the architecture should not assume all climbable surfaces are
permanently stationary.

---

# Surface Selection For Boss AI

The boss AI may eventually use surface references when deciding how to
move around the arena.

Do NOT require this advanced behavior for the first implementation.

The initial implementation only needs to correctly:

- Detect surfaces
- Store surface references
- Cling to them
- Jump from them
- Pounce from them
- Prevent immediate same-surface re-grabs

However, structure the system so the AI can later evaluate available
surfaces.

Future logic may include:

availableClimbSurfaces
targetClimbSurface
currentClimbSurface
lastClimbSurface

For example:

currentClimbSurface = Pillar_A

AI decides:

targetClimbSurface = Pillar_B

Boss jumps from Pillar_A toward Pillar_B.

This future functionality should NOT require redesigning the basic
surface-reference system.

---

# Climbing Debug Information

When debug mode is enabled, display:

Movement State
Action State
currentClimbSurface
lastClimbSurface
climbSide
surfaceRegrabTimer
Detected Surface
Surface Valid
Surface Climbable

When possible, display the name or ID of the referenced surface.

Example:

Movement State: CLIMBING
Current Surface: Pillar_02
Last Surface: LeftWall
Climb Side: RIGHT
Regrab Timer: 0.00

This will make climbing bugs significantly easier to diagnose.

---

# Surface Reference Acceptance Tests

## Test 1: Right Wall

Boss contacts RightWall.

Expected:

currentClimbSurface = RightWall
climbSide = RIGHT
sprite = rabbit_climb
horizontalFlip = false

---

## Test 2: Left Wall

Boss contacts LeftWall.

Expected:

currentClimbSurface = LeftWall
climbSide = LEFT
sprite = rabbit_climb
horizontalFlip = true

---

## Test 3: Leave Surface

Boss jumps from Pillar_A.

Expected immediately after leaving:

currentClimbSurface = null
lastClimbSurface = Pillar_A
climbSide = NONE
surfaceRegrabTimer > 0

---

## Test 4: Same Surface Re-Grab

Boss leaves Pillar_A.

Boss immediately collides with Pillar_A again.

Expected:

Pillar_A is NOT grabbed while its re-grab restriction is active.

---

## Test 5: Different Surface

Boss leaves Pillar_A.

Boss contacts Pillar_B before the re-grab timer expires.

Expected:

Pillar_B CAN be grabbed.

currentClimbSurface = Pillar_B

---

## Test 6: Re-Grab After Delay

Boss leaves Pillar_A.

Wait until surfaceRegrabDelay expires.

Boss contacts Pillar_A.

Expected:

Pillar_A can be grabbed again.

---

## Test 7: Invalid Surface

Boss contacts ordinary non-climbable terrain.

Expected:

currentClimbSurface remains null
CLIMB state does not activate

---

## Test 8: Surface Becomes Invalid

Boss is attached to Pillar_A.

Pillar_A becomes disabled, destroyed, or otherwise invalid.

Expected:

currentClimbSurface = null
climbSide = NONE
MovementState = DESCENDING
sprite = rabbit_fall

The game must not crash because of a stale surface reference.