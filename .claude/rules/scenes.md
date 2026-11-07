---
paths:
  - "scenes/**"
  - "ui/**"
---

# Godot presentation

This is Godot 4. Use typed GDScript, `@export`, `signal` syntax and `Callable`, and never Godot 3 APIs.

Scenes subscribe to simulation events and draw them, and they change simulation state only by sending commands. The project uses the Compatibility renderer because it is the only one Godot supports on the web, so do not rely on Forward+ or Mobile features. Headless tests cannot judge a UI, so run the game windowed and inspect a screenshot.

Every tooltip, menu and log line carries the real term beside the fiction name, for example "Interlock" with "PreToolUse hook", because the game teaches the term and not the metaphor. Tooltips reference fact ids and never carry free text about features.
