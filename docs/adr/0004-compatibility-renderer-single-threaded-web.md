# ADR-0004: The game uses the Compatibility renderer and exports to the web single-threaded

| | |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-11-04 |
| **Deciders** | Mikael Axelsson |
| **Sources** | `lattice-command-gdd.md` ("Why Godot 4", "3D presentation and art direction", "Scope and milestones"); `CLAUDE.md` ("Tools", "Code conventions"); `project.godot`; `export_presets.cfg`; Godot 4.7 documentation, [Exporting for the Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) and [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html), read 2026-11-04 |
| **Related** | [ADR-0001](0001-record-architecture-decisions.md), [ADR-0002](0002-godot-4-as-engine.md), [ADR-0003](0003-typed-gdscript.md), [ADR-0014](0014-scripted-blender-art-pipeline.md) (scripted Blender art pipeline), [ADR-0018](0018-vertical-slice-gate-and-scope.md) (vertical slice gate), [ADR-0021](0021-ci-on-github-actions.md) (CI on GitHub Actions) |

## Context

A playable web build is the reason GDScript was chosen, and it restricts rendering as well. The Godot 4.7 documentation says that on the web Godot can only target WebGL 2.0 through the Compatibility rendering method, and its renderer comparison marks Forward+ and Mobile as unsupported there. Art built around features of the other renderers would look different or fail when it reached the browser, and that would surface late.

Threading is the second web constraint. A threaded web export requires the host to send the cross-origin isolation headers `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`. The documentation describes single-threaded export, available since Godot 4.3, as the preferred and default way to export for the web. A game meant to be tried with one click should not depend on what its host can configure.

## Decision

The project uses the Compatibility renderer, which `project.godot` sets for desktop and mobile as well as the web case that `CLAUDE.md` explains, and the web preset exports single-threaded. Scenes, shaders and art must not rely on features of Forward+ or Mobile, and the web build must not require special server headers.

`project.godot` expresses this in its `[rendering]` section as `renderer/rendering_method="gl_compatibility"` and `renderer/rendering_method.mobile="gl_compatibility"`. It has no `.web` key, and on the pinned 4.7.2 build that setting resolves to `gl_compatibility` by default, as a probe of the engine confirmed on 2026-11-04. The file's `config/features` names only `4.7`, and it sets no main scene yet.

`export_presets.cfg` holds a single preset named `Web` for the `Web` platform, marked runnable, with `export_filter="all_resources"` and `export_path="build/web/index.html"`. Its only option is `variant/thread_support=false`, so every other export option takes the engine's default. The renderer keys and `variant/thread_support` must not change without a superseding ADR. The export filter and path describe the state on 2026-11-04 and are not part of this decision; [ADR-0019](0019-test-framework.md) notes that the filter may need to exclude `tests/`.

**Open points.** The sources leave three things undecided. The GDD says the vertical slice must prove that Compatibility carries the stylized look, but the slice's contents do not include a web build, which appears only at Beta, so it is undecided whether the look is judged in a browser. How the audio design is realised within the web build's audio limits is undecided. No download size budget exists. The GDD specifies the Concord fog along supply lanes as quad or shader fog, because volumetric fog is unavailable under Compatibility.

## Alternatives considered

**Forward+ or Mobile for the desktop build, with Compatibility only on the web.** Godot allows per-platform renderer settings, and the desktop build would gain better lighting and effects. It lost because `project.godot` sets Compatibility for the desktop and mobile keys as well, and `CLAUDE.md` and the path-scoped rule state the renderer without a per-platform exception. That leaves a single look to author and verify, although the sources do not spell out this reasoning, so it is this ADR's reading rather than a recorded argument.

**Threaded web export.** Threads would perform better, since the documentation states that single-threaded export is less performant. It lost because every host would then have to send the isolation headers, or the build would have to simulate them through a service worker, and that works against one-click access.

## Consequences

The project has one renderer to author against, and the look seen on desktop is closer to what the browser shows. The export can be served without special headers, and the single preset is simple enough to read at a glance. A test export from a scratch copy of these two files on 2026-11-04 succeeded on the pinned build with the installed templates and produced a page with threads disabled, though that was a one-off probe and not a standing check.

The costs fall on the visuals, the audio and the frame budget. Compatibility has no VoxelGI, SDFGI, screen-space indirect lighting, screen-space reflections, volumetric fog, sub-surface scattering or compute shaders, it caps reflection probes at 2 per mesh, and its colour precision is low dynamic range. Omni and spot lights default to 8 per mesh. The GDD's strong rim light has to be achieved within these limits. Single-threaded audio uses Sample playback, in which audio effects, reverb, doppler and procedural generation are not supported and positional audio may misbehave, while the documented alternative of Stream playback adds latency. The web build cannot use threads, so a heavy simulation step would have to fit on the one thread that also draws the frame. The web download is not small either: the probe's nearly empty export produced a 39.5 MB `index.wasm`, about 10.1 MB when gzipped, as the GDD records.

## Staying on track

| Check | Enforced by | State |
| --- | --- | --- |
| Sessions touching `scenes/**` or `ui/**` are told not to rely on Forward+ or Mobile features | `.claude/rules/scenes.md`; this instructs and does not block | Active |
| `project.godot` and `export_presets.cfg` keep the values above; the PreToolUse hook does not protect these files | Pull request review | Manual |
| The web export succeeds in CI | GitHub Actions workflow | Pending (needs CI, [ADR-0021](0021-ci-on-github-actions.md)) |
| The exported game runs in a browser from a host with no special headers | Person running the build | Pending (needs a main scene and game code) |
| The look is legible under Compatibility in a windowed screenshot | Windowed run and screenshot inspection, per `CLAUDE.md` | Pending (needs a first scene) |
| Compatibility carries the stylized look | Vertical slice review | Pending (needs vertical slice, [ADR-0018](0018-vertical-slice-gate-and-scope.md)) |

**Drift signals.** A diff changes `rendering_method` or sets `variant/thread_support=true`. A scene or script uses `RenderingDevice`, compute shaders, `FogVolume`, or an `Environment` with SDFGI, SSIL, SSR or volumetric fog enabled. A hosting configuration gains COOP or COEP headers. A screenshot looks right on desktop while the browser build differs. A playtest reports positional audio or effects missing only in the browser. A report shows long frames on the web build during simulation steps. Slice screenshots from desktop are accepted as evidence of how the browser build looks, with no browser run behind them.

**Revisit when.** Godot's official documentation lists Forward+ or a WebGPU-based renderer as supported on the web, the vertical slice shows that Compatibility cannot carry the look, measured simulation or audio needs cannot be met on one thread, or the project gives up the web build.
