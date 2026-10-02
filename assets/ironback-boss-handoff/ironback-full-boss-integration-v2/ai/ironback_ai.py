"""Engine-independent Ironback attack scheduler. Port to the game's boss controller.
No physics, damage, animations or engine integration are implemented here.
Distances are body-edge gaps in world pixels; elapsed time is simulation time.
"""
from dataclasses import dataclass
import random


@dataclass(frozen=True)
class Context:
    gap: float
    health_ratio: float
    grounded: bool = True
    waves_alive: bool = False
    leap_safe: bool = True
    rush_safe: bool = True
    player_alive: bool = True
    encounter_active: bool = True


class IronbackPolicy:
    COOLDOWNS = {'smash': 2.5, 'barrage': 12.0, 'leap': 6.0,
                 'backhand': 3.5, 'rush': 7.0}

    def __init__(self, seed=1):
        self.rng = random.Random(seed)
        self.reset()

    def reset(self):
        self.ready_at = {name: 0.0 for name in self.COOLDOWNS}
        self.history = []
        self.next_decision_at = 0.0
        self.busy = False
        self.phase_two = False
        self.phase_pending = False
        self.phase_seen = False

    def choose(self, now, c):
        """Returns an attack/phase-change intent, or None (hold/walk safely).
        Caller must call finish after the COMPLETE recovery/phase-change.
        Repeated polling must never reset attack animation or committed targets.
        """
        if not c.player_alive or not c.encounter_active:
            return None
        if c.health_ratio <= 0.0:
            return None  # Engine enters defeat and clears owned danger immediately.
        if c.health_ratio <= 0.5 and not self.phase_seen:
            self.phase_pending = True
        if self.busy or now < self.next_decision_at or not c.grounded:
            return None
        if self.phase_pending:
            if c.waves_alive:
                return None
            self.phase_pending = False
            self.phase_seen = True
            self.phase_two = True
            self.busy = True
            return 'phase_change'
        if c.waves_alive:
            return None  # Never add attacks while an old pair remains in arena.
        # First encounter move is the signature lesson, with normal full tell.
        if not self.history:
            weights = {'smash': 1.0}
        elif c.gap < 100:
            weights = {'smash': 65, 'backhand': 35}
        elif c.gap <= 300:
            weights = {'smash': 75, 'rush': 25}
        else:
            weights = {'leap': 70, 'rush': 30}
        if self.phase_two and c.gap <= 300 and self.history:
            weights['barrage'] = 22
        options = []
        for attack, weight in weights.items():
            if now < self.ready_at[attack]:
                continue
            if attack == 'leap' and not c.leap_safe:
                continue
            if attack == 'rush' and not c.rush_safe:
                continue
            # At most two signature smashes in a row; other attacks never repeat.
            if attack == 'smash' and self.history[-2:] == ['smash', 'smash']:
                continue
            if attack != 'smash' and self.history[-1:] == [attack]:
                continue
            options.append((attack, weight))
        if not options:
            return None  # Reposition/hold, do not substitute an unsafe attack.
        roll = self.rng.random() * sum(w for _, w in options)
        selected = options[-1][0]
        for attack, weight in options:
            roll -= weight
            if roll < 0:
                selected = attack
                break
        self.busy = True
        self.ready_at[selected] = now + self.COOLDOWNS[selected]
        self.history.append(selected)
        self.history = self.history[-8:]
        return selected

    def finish(self, now):
        """Called once after full recovery; cooldowns start at attack commitment,
        global breathing interval starts HERE. Do not call at the impact frame.
        """
        self.busy = False
        self.next_decision_at = now + self.rng.uniform(
            0.35 if self.phase_two else 0.50,
            0.55 if self.phase_two else 0.75)


if __name__ == '__main__':
    # Representative scheduler trace; this is not a difficulty simulation.
    policy = IronbackPolicy(17)
    for now in range(0, 60, 3):
        c = Context(gap=(60, 200, 420)[(now // 3) % 3],
                    health_ratio=1.0 if now < 30 else 0.45)
        move = policy.choose(float(now), c)
        print(f'{now:02d}s gap={c.gap:3} phase={2 if policy.phase_two else 1} {move}')
        if move:
            policy.finish(now + (4.75 if move == 'barrage' else 2.0))
