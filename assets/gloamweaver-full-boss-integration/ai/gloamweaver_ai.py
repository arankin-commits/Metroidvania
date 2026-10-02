"""Executable selection reference, not Godot physics/combat implementation.
Caller supplies measured support/path safety and calls finish after FULL recovery.
"""
from dataclasses import dataclass
import random


@dataclass(frozen=True)
class Context:
    gap: float
    health_ratio: float
    support: str = 'ceiling'  # ceiling / floor / airborne
    swing_safe: bool = True
    zip_safe: bool = True
    drop_safe: bool = True
    trap_safe: bool = True
    reattach_safe: bool = True
    active_traps: int = 0  # Include deploying traps/reservations.
    player_alive: bool = True
    encounter_active: bool = True


class GloamweaverPolicy:
    COOLDOWNS = {'swing': 4.0, 'zip': 6.5, 'trap': 8.0,
                 'drop': 6.0, 'bite': 3.5, 'double_swing': 11.0,
                 'reattach': 1.0}
    REPOSITION = {'zip', 'trap'}
    LOW_OPPORTUNITY = {'swing', 'double_swing', 'drop'}

    def __init__(self, seed=1):
        self.rng = random.Random(seed)
        self.reset()

    def reset(self):
        self.ready_at = {a: 0.0 for a in self.COOLDOWNS}
        self.history = []
        self.busy = False
        self.next_decision_at = 0.0
        self.phase_two = False
        self.phase_pending = False
        self.phase_seen = False
        self.force_low = False
        self.first_swing_done = False
        self.nontrap_actions = 0
        self.last_decision = {}

    def choose(self, now, c):
        if (not c.encounter_active or not c.player_alive
                or c.health_ratio <= 0.0):
            return None  # Engine owns immediate defeat/cancel/cleanup.
        if c.health_ratio <= .5 and not self.phase_seen:
            self.phase_pending = True
        if self.busy or now < self.next_decision_at:
            return None
        if c.support not in ('ceiling', 'floor'):
            return None
        if self.phase_pending:
            self.phase_pending = False
            self.phase_seen = self.phase_two = self.busy = True
            return 'phase_change'
        trap_allowed = (c.trap_safe and c.active_traps < (3 if self.phase_two else 2)
                        and now >= self.ready_at['trap'])
        # A ceiling boss can place a floor snare at ANY horizontal distance.
        # Guarantee variety after three other actions, without overriding safety,
        # cooldowns, the initial swing lesson or the post-zip low-punish obligation.
        trap_due = (c.support == 'ceiling' and self.first_swing_done
                    and not self.force_low and self.nontrap_actions >= 3
                    and trap_allowed)
        if c.support == 'floor':
            weights = {'bite': 60, 'reattach': 40} if c.gap <= 120 else {'reattach': 1}
        elif not self.first_swing_done:
            weights = {'swing': 1}
        elif self.force_low:
            weights = {'swing': 70, 'drop': 30}
            if self.phase_two:
                weights['double_swing'] = 20
        elif trap_due:
            weights = {'trap': 1}
        elif c.gap > 360:
            weights = {'swing': 35, 'zip': 45, 'drop': 20, 'trap': 20}
        else:
            weights = {'swing': 60, 'zip': 20, 'trap': 20}
            if self.phase_two:
                weights['double_swing'] = 20
        safe = {'swing': c.swing_safe, 'double_swing': c.swing_safe,
                'zip': c.zip_safe, 'drop': c.drop_safe,
                'trap': c.trap_safe and c.active_traps < (3 if self.phase_two else 2),
                'reattach': c.reattach_safe, 'bite': True}
        options = []
        rejected = {}
        for a, w in weights.items():
            if not safe[a]:
                rejected[a] = 'unsafe_path_or_trap_limit'
                continue
            if now < self.ready_at[a]:
                rejected[a] = 'cooldown'
                continue
            if a == 'swing' and self.history[-2:] == ['swing', 'swing']:
                rejected[a] = 'repeat_limit'
                continue
            if a != 'swing' and self.history[-1:] == [a]:
                rejected[a] = 'repeat_limit'
                continue
            options.append((a, w))
        self.last_decision = {'time': now, 'support': c.support, 'gap': c.gap,
                              'trap_allowed': trap_allowed, 'trap_due': trap_due,
                              'nontrap_actions': self.nontrap_actions,
                              'force_low': self.force_low,
                              'candidate_weights': dict(weights),
                              'eligible': dict(options), 'rejected': rejected,
                              'selected': None}
        if not options:
            return None  # Harmless hold/crawl; never bypass safety or cooldowns.
        roll = self.rng.random() * sum(w for _, w in options)
        action = options[-1][0]
        for a, w in options:
            roll -= w
            if roll < 0:
                action = a
                break
        self.busy = True
        self.last_decision['selected'] = action
        if action == 'trap':
            self.nontrap_actions = 0
        elif action != 'reattach':
            self.nontrap_actions += 1
        self.ready_at[action] = now + self.COOLDOWNS[action]
        self.history.append(action)
        self.history = self.history[-8:]
        if action == 'swing':
            self.first_swing_done = True
        if action in self.REPOSITION:
            self.force_low = True
        elif action in self.LOW_OPPORTUNITY:
            self.force_low = False
        return action

    def finish(self, now):
        self.busy = False
        self.next_decision_at = now + self.rng.uniform(
            .45 if self.phase_two else .55, .65 if self.phase_two else .80)


class SilkSlowReference:
    """Nonstacking boss-owned ground-speed status reference, seconds.
    Actual engine must source-tag this modifier and preserve other statuses.
    """
    def __init__(self):
        self.clear()

    def clear(self):
        self.until = 0.0
        self.last_refresh = float('-inf')

    def contact(self, now, grounded=True):
        if grounded and now - self.last_refresh >= .5:
            self.until = now + 1.0
            self.last_refresh = now

    def multiplier(self, now, grounded=True):
        return .70 if grounded and now < self.until else 1.0
