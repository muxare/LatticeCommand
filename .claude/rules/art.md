---
paths:
  - "art/**"
---

# Art pipeline

Each shipped asset has one Blender Python script in `art/scripts/` that exports to `art/models/`. Run scripts with the Blender build pinned in `CLAUDE.md`. Models change only by changing their script, and a live MCP session must end with the script that reproduces its result.

Export binary glTF (`.glb`) with transforms applied and metric scale. Name files by kind and variant, such as `hull_frigate_a.glb`, and use Godot import suffixes such as `-col` for collision meshes. Name materials after the palette so Godot can swap them per colony: Harbour amber, Conclave teal, Shipyard orange, Concord violet. Commit the generated `.glb` files and regenerate them whenever a script changes.
