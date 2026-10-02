import unittest
from gloamweaver_ai import Context, GloamweaverPolicy, SilkSlowReference


class PolicyChecks(unittest.TestCase):
    def test_first_move_safe_signature_and_busy_pause(self):
        p = GloamweaverPolicy()
        self.assertIsNone(p.choose(0, Context(200, 1, swing_safe=False)))
        self.assertEqual(p.choose(1, Context(200, 1)), 'swing')
        self.assertIsNone(p.choose(10, Context(50, 1, support='floor')))
        p.finish(10)
        self.assertIsNone(p.choose(10.1, Context(200, 1)))

    def test_phase_deferred_single_and_dead_airborne(self):
        p = GloamweaverPolicy()
        p.choose(0, Context(200, 1))
        self.assertIsNone(p.choose(1, Context(200, .4)))
        p.finish(3)
        self.assertIsNone(p.choose(4, Context(200, .4, support='airborne')))
        self.assertEqual(p.choose(5, Context(200, .4)), 'phase_change')
        p.finish(6)
        self.assertNotEqual(p.choose(7, Context(200, .4)), 'phase_change')
        for c in (Context(100, 0), Context(100, 1, player_alive=False),
                  Context(100, 1, encounter_active=False)):
            self.assertIsNone(GloamweaverPolicy().choose(0, c))

    def test_safety_and_trap_limit(self):
        p = GloamweaverPolicy(15)
        p.choose(0, Context(200, 1)); p.finish(2)
        for t in range(10, 1000, 10):
            action = p.choose(t, Context(200, 1, zip_safe=False,
                                        drop_safe=False, active_traps=2))
            self.assertNotIn(action, ('zip', 'drop', 'trap', 'double_swing'))
            if action:
                p.finish(t + 3)

    def test_forced_low_after_reposition(self):
        p = GloamweaverPolicy(8)
        p.first_swing_done = True
        p.force_low = True
        self.assertIsNone(p.choose(10, Context(200, 1, swing_safe=False, drop_safe=False)))
        self.assertIn(p.choose(11, Context(200, 1)), ('swing', 'drop'))
        self.assertFalse(p.force_low)

    def test_cooldowns_history_and_no_reposition_chain(self):
        p = GloamweaverPolicy(13)
        starts = {}; history = []
        pending_low = False
        for t in range(0, 2000, 2):
            a = p.choose(t, Context((60, 220, 450)[t % 3], .4))
            if a in p.COOLDOWNS:
                if a in starts:
                    self.assertGreaterEqual(t - starts[a], p.COOLDOWNS[a])
                if history and a != 'swing':
                    self.assertNotEqual(a, history[-1])
                self.assertNotEqual(history[-2:] + [a], ['swing'] * 3)
                if pending_low:
                    self.assertIn(a, p.LOW_OPPORTUNITY)
                pending_low = a in p.REPOSITION
                starts[a] = t; history.append(a)
            if a:
                p.finish(t + 3)

    def test_floor_options_and_reset(self):
        p = GloamweaverPolicy(2)
        self.assertEqual(p.choose(0, Context(300, 1, support='floor')), 'reattach')
        p.reset()
        self.assertFalse(p.busy)
        self.assertFalse(p.phase_two)
        self.assertEqual(p.history, [])
        self.assertTrue(all(t == 0 for t in p.ready_at.values()))

    def test_slow_nonstacking_ground_only_expiry(self):
        s = SilkSlowReference()
        s.contact(1)
        s.contact(1.1)
        self.assertEqual(s.multiplier(1.2), .7)
        self.assertEqual(s.until, 2.0)
        self.assertEqual(s.multiplier(1.2, grounded=False), 1.0)
        s.contact(1.6)
        self.assertEqual(s.until, 2.6)
        self.assertEqual(s.multiplier(3), 1.0)
        s.contact(4); s.clear()
        self.assertEqual(s.multiplier(4.1), 1.0)

    def test_far_distance_cannot_starve_snare(self):
        p = GloamweaverPolicy(17)
        p.first_swing_done = True
        p.nontrap_actions = 3
        self.assertEqual(p.choose(20, Context(900, 1)), 'trap')
        self.assertEqual(p.nontrap_actions, 0)
        self.assertTrue(p.last_decision['trap_due'])
        self.assertEqual(p.last_decision['selected'], 'trap')

    def test_due_snare_preserves_safety_cooldown_and_low_punish(self):
        for overrides in ({'trap_safe': False}, {'active_traps': 2}):
            p = GloamweaverPolicy(1)
            p.first_swing_done = True; p.nontrap_actions = 3
            self.assertNotEqual(p.choose(20, Context(900, 1, **overrides)), 'trap')
        p = GloamweaverPolicy(1)
        p.first_swing_done = True; p.nontrap_actions = 3
        p.ready_at['trap'] = 100
        self.assertNotEqual(p.choose(20, Context(900, 1)), 'trap')
        p = GloamweaverPolicy(1)
        p.first_swing_done = True; p.nontrap_actions = 3; p.force_low = True
        self.assertIn(p.choose(20, Context(900, 1)), p.LOW_OPPORTUNITY)

    def test_live_ceiling_sequence_uses_trap(self):
        p = GloamweaverPolicy(19)
        seen = []
        # Valid stable-ceiling opportunities, no old traps, generous intervals.
        for t in range(0, 120, 10):
            a = p.choose(t, Context(900, 1))
            if a:
                seen.append(a); p.finish(t + 3)
        self.assertEqual(seen[0], 'swing')
        self.assertIn('trap', seen)
        self.assertLessEqual(seen.index('trap'), 3)


if __name__ == '__main__':
    unittest.main()
