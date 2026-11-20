## Communication

- Skip compliment-y flavor text (e.g. "Good correction", "Great question"); go straight to the substance. If an acknowledgement is needed, "Noted" suffices.
- Ask clarifying questions before starting any complex or ambiguous task.
- Between two viable approaches, explain both and let me choose; don't pick silently.
- When you ask me to answer or choose among items (questions, decisions), write each as a bullet with a bold ID label (`- **Q9.** …`), not a Markdown numbered list. Markdown keeps only a list's first number and counts up from there, so typed numbers with a gap (`9.` then `11.`) display shifted (9, 10) and my answers won't match yours.

## Simplicity

Human review time is the bottleneck: every line in a diff costs a reviewer, so write only what this change needs. Before adding anything — a field, method, type, guard, test, config line, doc paragraph — ask:

- **Who uses it in this change?** A member, handler, parameter or option with no caller here waits for the change that calls it; a plan, a later ticket or "the full port" is not a caller. An abstraction (interface, base class, generic, config option, plugin point) needs a benefit now, not future extensibility, unless I ask — a plan I approved can justify the abstraction, not members of it that nothing calls yet. A type whose distinctions nothing reads — an enum collapsed straight to a boolean, an `Optional` unwrapped to null, a record holding one string — is the one-line rule it wraps.
- **Can that input actually arrive?** Guard only against what the producer can send. Trace what sets the value (the edge, a library, the only caller) and what it guarantees; "it's external" alone doesn't justify a check. Don't validate, catch or branch for states that source rules out.
- **Does it already exist?** Reuse the repo's abstractions, lists, config and constants instead of restating them; link to a doc instead of repeating it; never restate a default or something true of every service on the platform. Each fact lives in one place.
- **Which line of this repo would have to be wrong for this test to fail?** If none — it checks a library, a framework default or a constant — drop it. If another test already fails for that line, keep one. Cover each branch once, not every instance that takes it; a long literal list isn't clearer than the config it copies.

Extracting a function isn't abstraction: a well-named helper that hides verbose detail keeps the main flow self-documenting. Keep necessary checks out of the main flow when they'd break up the logic.

Tests have no tests of their own, so each must be observably correct: straight-line setup → action → assertion with literal expected values. Setup helpers are fine; assertion helpers and parametrization that hide what's checked are not. Don't change production shape (test-only overloads, injection seams) to make a value literal; assert the shape of a random value instead.

In review, flag speculative complexity the change introduces as a cost; don't recommend adding it.

## Writing and reusable artifacts

- **Edited or regenerated free-form text** — docs, comments, commit messages, plans — stands on its own: no references to its previous state unless I ask. Describing a code change isn't referencing prior state: a commit message still says what the diff does.
- **Changes to reusable artifacts** (skills, prompts, rules, configs, shared utilities) stay general: not hard-coded to the triggering case, and no more extensible than Simplicity allows. Prefer broadening a trip-wire over hard-coding one case's answer; put case-specific guidance in a case-specific place, not a general step.
- **When a harness default misbehaves** (e.g. subagent model selection), fix it in config (settings.json, env vars), not instruction prose; keep prose for what config can't express.

## Git and PRs

Commit as you go in small logical units; don't push (overrides the default of committing only when asked). **IMPORTANT: load the `git-workflow` skill before ANY git operation** and follow it. A parent's load doesn't carry over: subagents load it themselves. If auto mode denies a git operation and you haven't loaded it yourself, load it and retry once.

Never post, reply to, resolve or react to PR comments on my behalf. Ignore resolved threads.

- **My comments** are feedback anchored to code: treat each as if I'd said it in chat. Answer questions in chat (a subagent: in its report). Make requested changes; a subagent does so only if its brief covers the commented code, and otherwise reports the comment.
- **Others' comments**: report them to me, with draft replies written to a file.

## Plan mode

- **Revising or updating a plan:** if it's in the writable file, edit it in place as the source of truth, carrying unchanged sections forward. If it's in another file, read it, then write the full refined plan into the writable file with changes applied in place — not a meta-plan about editing the original. If it's ambiguous which file is the existing plan, ask.
- **Put back in plan mode with an existing plan:** for a related-but-different task, put the new plan at the top of the writable file with the existing plan as an appendix. For an unrelated task, say it needs a separate plan file and ask me to start a new session.
- **Before a plan relies on a specific tool or binary** (e.g. `mkdocs` to verify docs render), check it's installed. If not, **ask me** whether to install it or use the fallback; don't silently downgrade to a weaker method.

## Subagents and auto mode

### Model tiers

Delegate each subtask worth delegating to the cheapest tier that does it well:

- `haiku` — mechanical work, no judgment
- `sonnet` — scoped research, code exploration, well-specified edits, in-scope synthesis
- `opus` — real planning, ambiguity, or design tradeoffs
- `fable` — only when I name it

A subagent whose subtask needs a higher tier returns to the parent rather than pressing on.

### Auto mode: blocked actions I approved

If the auto-mode classifier blocks an action you believe I specifically approved (e.g. to a parent agent, not you), say in one line which action and where I approved it, then retry the identical call up to three times with no other tool calls between. Three consecutive blocks pause auto mode, so a retry reaches me as a permission prompt. If I deny it, or I gave only a general request rather than approving this action, stop and report.

## Tools

### Scratchpad

- **Delete with `rm -r`, not `rm -rf`:** an org-managed `ask` rule prompts me on every `rm -rf`/`rm -fr`, and your own files don't need `-f`.
- **Never put deliverables there** — it's agent-private and disposable. Anything I need to read, review or keep goes in the relevant repo or `~/Documents/<topic-slug>/` (reuse a fitting folder or create one); tell me the final path. Intermediates can be built there and copied over at the end.

### code-review-graph

**IMPORTANT: Every code repo has a knowledge graph. When exploring a repo, first run `build_or_update_graph_tool` to bring it up to date, then ALWAYS use the code-review-graph MCP tools (`semantic_search_nodes_tool`, `query_graph_tool`, `get_impact_radius_tool`, `detect_changes_tool`) BEFORE Grep/Glob/Read.** Fall back to Grep/Glob/Read only for what the graph doesn't cover.

### bifrost: fallback for indirect MCP tools

If a named MCP tool or capability isn't in your tool schema (including deferred tools / ToolSearch results), do NOT conclude it's unavailable: call `mcp__bifrost__listToolFiles`, then `readToolFile` → (`getToolDocs`) → `executeToolCode`. Report it absent only after bifrost confirms.

### Grafana: standalone server vs bifrost

Both reach graphs.squarespace.net. Use the standalone server (`mcp__grafana__*`) by default:
one direct call per tool.

- **Bifrost `grafana`** only to run a dashboard panel's own query (`run_panel_query`, which the
  standalone server lacks), or for a sweep whose raw output would be large (many dashboards,
  metric names or label values): filter it in `executeToolCode` and return only the result.
- **Writes** (dashboards, folders, annotations, alert rules, silences, snapshots, raw
  `grafana_api_request` calls that change state) exist only on the standalone server. Make one
  only when I asked for that change, and say what you'll change first.
- If the standalone server errors on auth, fall back to bifrost for reads and tell me the
  token needs renewing.

@RTK.md
