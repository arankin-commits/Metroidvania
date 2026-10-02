"""Scheduler behavioral checks only; actual fight needs controller-driven tests."""
import unittest
from ironback_ai import Context, IronbackPolicy


class PolicyChecks(unittest.TestCase):
    def test_commitment_and_breathing(self):
        p = IronbackPolicy(1)
        self.assertEqual(p.choose(0, Context(200, 1)), 'smash')
        self.assertIsNone(p.choose(10, Context(60, 1)))
        p.finish(10)
        self.assertIsNone(p.choose(10.1, Context(60, 1)))

    def test_waves_block_every_followup(self):
        p = IronbackPolicy()
        for t in range(100):
            self.assertIsNone(p.choose(t, Context(200, 1, waves_alive=True)))
        self.assertEqual(p.choose(101, Context(200, 1)), 'smash')

    def test_phase_change_waits_and_occurs_once(self):
        p = IronbackPolicy()
        p.choose(0, Context(200, 1))
        self.assertIsNone(p.choose(1, Context(200, .4)))
        p.finish(2)
        self.assertIsNone(p.choose(3, Context(200, .4, waves_alive=True)))
        self.assertEqual(p.choose(4, Context(200, .4)), 'phase_change')
        p.finish(5)
        self.assertNotEqual(p.choose(6, Context(200, .4)), 'phase_change')

    def test_no_phase_one_barrage_or_unsafe_movement(self):
        p = IronbackPolicy(9)
        for t in range(0, 500, 10):
            move = p.choose(t, Context(400, 1, leap_safe=False, rush_safe=False))
            self.assertNotIn(move, ('leap', 'rush', 'barrage'))
            if move:
                p.finish(t + 2)

    def test_history_and_cooldowns(self):
        p = IronbackPolicy(3)
        starts = {}
        history = []
        for t in range(0, 2000):
            move = p.choose(t, Context((60, 200, 420)[t % 3], .4))
            if move in p.COOLDOWNS:
                if move in starts:
                    self.assertGreaterEqual(t - starts[move], p.COOLDOWNS[move])
                if history and move != 'smash':
                    self.assertNotEqual(move, history[-1])
                self.assertNotEqual(history[-2:] + [move], ['smash'] * 3)
                starts[move] = t
                history.append(move)
            if move:
                p.finish(t + 2)

    def test_dead_inactive_and_airborne(self):
        for c in (Context(100, 0), Context(100, 1, player_alive=False),
                  Context(100, 1, encounter_active=False), Context(100, 1, grounded=False)):
            self.assertIsNone(IronbackPolicy().choose(0, c))


if __name__ == '__main__':
    unittest.main()
