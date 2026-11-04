---
paths:
  - "sim/**"
---

# Simulation core

The simulation is pure logic, so it must run headlessly with no scene tree. Classes extend RefCounted and never touch nodes, rendering, input or any other engine singleton.

Every run must replay exactly from one seed and a command list. Draw all randomness from the seeded generator owned by the simulation, and never read the wall clock or iterate in an order that can vary between runs.

Presentation reaches the simulation only through commands, and the simulation reports back only through events. Rules must behave like the real Claude system, because a wrong rule teaches a wrong exam answer. Write the failing test before the code.
