RabbitBoss
│
├── Action State
│   ├── IDLE
│   ├── WALK
│   ├── JUMP
│   ├── CLIMB
│   └── POUNCE
│
├── Movement State
│   ├── GROUNDED
│   ├── ASCENDING
│   ├── DESCENDING
│   └── CLIMBING
│
├── Surface State
│   ├── currentClimbSurface
│   ├── lastClimbSurface
│   ├── climbSide
│   └── surfaceRegrabTimer
│
└── Visual State
    ├── rabbit_default
    ├── rabbit_step
    ├── rabbit_jump
    ├── rabbit_fall
    ├── rabbit_climb
    └── rabbit_pounce