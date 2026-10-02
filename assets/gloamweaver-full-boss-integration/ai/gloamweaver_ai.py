"""Ground revision 3 selection reference; engine owns physics and full recovery."""
from dataclasses import dataclass
import random

@dataclass(frozen=True)
class Context:
    gap: float
    health_ratio: float
    grounded: bool = True
    charge_safe: bool = False  # Verified floor path/wall anchor/trap avoidance.
    trap_safe: bool = False
    active_traps: int = 0  # Includes reservations and deploying seeds.
    player_alive: bool = True
    encounter_active: bool = True

class GloamweaverPolicy:
    COOLDOWNS = {'bite': 3.5, 'charge': 7.0, 'trap': 8.0}
    def __init__(self, seed=1):
        self.rng = random.Random(seed)
        self.reset()
    def reset(self):
        self.ready_at = dict.fromkeys(self.COOLDOWNS, 0.0)
        self.busy = False
        self.next_decision_at = 0.0
        self.phase_two = False
        self.history = []
        self.nontrap_actions = 0
        self.after_charge = False
        self.last_decision = {}
    def choose(self, now, c):
        if not c.encounter_active or not c.player_alive or c.health_ratio <= 0:
            return None  # Engine cancels danger/cleans statuses immediately.
        if self.busy or now < self.next_decision_at or not c.grounded:
            return None
        if c.health_ratio <= .5 and not self.phase_two:
            self.phase_two = self.busy = True
            return 'phase_change'
        trap_ok = c.trap_safe and c.active_traps < (3 if self.phase_two else 2)
        if c.gap <= 120:
            weights = {'bite':65, 'trap':35}
        elif c.gap < 180:
            weights = {'trap':1}
        else:
            weights = {'charge':70 if self.phase_two else 60,
                       'trap':30 if self.phase_two else 40}
        safe = {'bite':c.gap <= 120,
                'charge':c.charge_safe and c.gap >= 180 and not self.after_charge,
                'trap':trap_ok}
        eligible, rejected = {}, {}
        for action, weight in weights.items():
            reason = None
            if not safe[action]: reason = 'unsafe_range_path_or_slots'
            elif now < self.ready_at[action]: reason = 'cooldown'
            elif action == 'bite' and self.history[-2:] == ['bite','bite']: reason = 'repeat_limit'
            elif action != 'bite' and self.history[-1:] == [action]: reason = 'repeat_limit'
            if reason: rejected[action] = reason
            else: eligible[action] = weight
        trap_due = self.nontrap_actions >= 3 and 'trap' in eligible
        if trap_due: eligible = {'trap':1}
        self.last_decision = {'time':now,'gap':c.gap,'eligible':eligible.copy(),
            'rejected':rejected,'trap_due':trap_due,'after_charge':self.after_charge,'selected':None}
        if not eligible: return None  # Harmless crawl/idle; approach bite range if appropriate.
        action = self.rng.choices(list(eligible), weights=list(eligible.values()))[0]
        self.busy = True
        self.ready_at[action] = now + self.COOLDOWNS[action]
        self.history = (self.history + [action])[-8:]
        self.nontrap_actions = 0 if action == 'trap' else self.nontrap_actions + 1
        self.after_charge = action == 'charge'
        self.last_decision['selected'] = action
        return action
    def finish(self, now):
        self.busy = False
        self.next_decision_at = now + self.rng.uniform(.55,.80)

class SilkSlowReference:
    """Engine applies a source-owned modifier to ordinary grounded walking only."""
    def __init__(self): self.clear()
    def clear(self):
        self.until = 0.0
        self.last_refresh = float('-inf')
    def contact(self, now, grounded=True):
        if grounded and now-self.last_refresh >= .5:
            self.until = now+1.0
            self.last_refresh = now
    def multiplier(self, now, grounded=True):
        return .70 if grounded and now < self.until else 1.0
