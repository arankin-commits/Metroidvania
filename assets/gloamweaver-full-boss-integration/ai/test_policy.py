import unittest
from gloamweaver_ai import Context, GloamweaverPolicy, SilkSlowReference

class GroundPolicyTests(unittest.TestCase):
    def test_no_aerial_actions(self):
        p=GloamweaverPolicy(3)
        actions=set()
        for i in range(100):
            a=p.choose(i*10,Context(250 if i%2 else 90,1,charge_safe=True,trap_safe=True))
            if a: actions.add(a); p.finish(i*10+3)
        self.assertEqual(actions, {'bite','charge','trap'})
    def test_charge_requires_valid_path_and_range(self):
        for gap,safe in [(90,True),(170,True),(400,False)]:
            self.assertNotEqual(GloamweaverPolicy().choose(0,Context(gap,1,charge_safe=safe)), 'charge')
    def test_airborne_and_busy_cannot_commit(self):
        p=GloamweaverPolicy()
        self.assertIsNone(p.choose(0,Context(90,1,grounded=False)))
        self.assertEqual(p.choose(0,Context(90,1)), 'bite')
        self.assertIsNone(p.choose(100,Context(90,1)))
    def test_trap_cap_and_priority(self):
        p=GloamweaverPolicy(); p.nontrap_actions=3
        self.assertEqual(p.choose(0,Context(400,1,charge_safe=True,trap_safe=True)), 'trap')
        p=GloamweaverPolicy(); p.nontrap_actions=3
        self.assertIsNone(p.choose(0,Context(150,1,trap_safe=True,active_traps=2)))
    def test_post_charge_requires_other_offense(self):
        p=GloamweaverPolicy()
        self.assertEqual(p.choose(0,Context(400,1,charge_safe=True)), 'charge')
        p.finish(3)
        self.assertIsNone(p.choose(20,Context(400,1,charge_safe=True)))
        self.assertEqual(p.choose(21,Context(90,1)), 'bite')
        p.finish(24)
        self.assertEqual(p.choose(30,Context(400,1,charge_safe=True)), 'charge')
    def test_full_recovery_pause_and_cooldown(self):
        p=GloamweaverPolicy(); p.choose(0,Context(90,1)); p.finish(1)
        self.assertIsNone(p.choose(1.1,Context(90,1)))
        self.assertIsNone(p.choose(2,Context(90,1)))
        self.assertEqual(p.choose(4,Context(90,1)), 'bite')
    def test_phase_queues_until_grounded_and_recovered(self):
        p=GloamweaverPolicy(); p.choose(0,Context(90,1))
        self.assertIsNone(p.choose(10,Context(90,.4)))
        p.finish(10)
        self.assertIsNone(p.choose(12,Context(90,.4,grounded=False)))
        self.assertEqual(p.choose(13,Context(90,.4)), 'phase_change')
        p.finish(14)
        self.assertEqual(p.choose(16,Context(150,.4,trap_safe=True,active_traps=2)), 'trap')
    def test_defeat_and_reset(self):
        p=GloamweaverPolicy(); self.assertIsNone(p.choose(0,Context(90,0)))
        p.choose(0,Context(90,1)); p.reset()
        self.assertEqual(p.choose(0,Context(90,1)), 'bite')
    def test_slow_ground_only_and_cleanup(self):
        s=SilkSlowReference(); s.contact(2)
        self.assertEqual(s.multiplier(2.1),.7)
        self.assertEqual(s.multiplier(2.1,False),1)
        self.assertEqual(s.multiplier(3.1),1)
        s.contact(4); s.clear(); self.assertEqual(s.multiplier(4.1),1)

if __name__=='__main__': unittest.main()
