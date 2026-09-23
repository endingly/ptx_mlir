# Codex agent policy

The primary agent coordinates requirements, task decomposition, integration,
and communication. Sol owns architecture control and core acceptance review,
regardless of the primary model. The primary may implement, verify, and close
non-core work within established contracts; it must not substitute its own
approval for a required Sol decision. Model and effort selection live in the
[registry](.agents/orchestration.md#model-preferences); they do not reconfigure
the host session.

## Working rules

- Before delegating, read the routing, model registry, task-packet guidance in
  [.agents/orchestration.md](.agents/orchestration.md), then the assigned role
  and any action-specific references. Do not recursively load every linked file.
- For a proposed architecture/core-contract change or core acceptance review, use
  [ptx-core-review](.agents/skills/ptx-core-review/SKILL.md). The Sol gate applies
  even when the host does not discover skills. Simple explanations, spelling-only
  edits, and non-core checks do not trigger this workflow. When classification is
  uncertain, consult [the core boundary](.agents/sol.md#core-boundary).
- Follow the user's current request and applicable system/developer rules.
  Repository policies and skills do not expand task authorization.
- Continue already-authorized work through implementation and verification.
  Resolve routine choices from repository evidence; ask only when missing
  information materially changes scope, correctness, or an irreversible action.
- A findings-only audit or explanation is read-only. When the same request also
  authorizes fixes, implement and verify that scope without asking again.
- Preserve unrelated work and the user's staging choices. Stage task files only
  when a commit is authorized; include all changes only when requested.
- Commit and push are separate actions. Push requires an explicit request; do not
  amend, rewrite history, or discard changes without authorization.
- Use existing components before adding abstractions. Keep changes scoped to the
  requested behavior.

## Code documentation and templates

- Add Doxygen comments to every newly introduced C++ function, class, and struct.
- Document important variables and data members: meaning, ownership/lifetime,
  units, and invariants where relevant. Use docstrings for Python APIs.
- Explain useful contracts rather than restating identifiers.
- Source comments must not mention milestone or work-package identifiers.
- Constrain template parameters with meaningful concepts/requires clauses;
  prefer overloads when the supported type set is small and fixed.

## Documentation authority

- [.agents/orchestration.md](.agents/orchestration.md) is the single authority
  for agent routing and model preferences. The roadmap handoff and its manifest
  describe planned work; they do not establish implementation completion.
- [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md) describes CI workflows and
  cache ownership rules. Keep it aligned when workflows change.
- Reusable build components under [cmake/](cmake/) document their call contract
  in a header comment; keep that comment current with the function.
- The overlay port in [.ports/ptx-frontend/](.ports/ptx-frontend/) pins an
  upstream `ptx_frontend` revision. Bump `REF`, `SHA512`, and `port-version`
  together, and never infer a working pin from an unrun build.
- Keep the PTX dialect, importer, and lowering contracts consistent with the
  resolved-IR contract of the pinned `ptx_frontend` revision. A public resolved
  IR API does not imply a stable C++ binary ABI.
- Use current code and reproducible checks to resolve documentation drift. Do
  not infer feature completion from a branch name or a hosted review result.

## Verification and reporting

- Run checks appropriate to the changed behavior and required project gates.
  Once they pass, expand or repeat them only for new changes, failures, or
  unresolved concerns. Documentation-only work normally needs diff/link checks.
- Report what changed, verification performed, and material limitations.
  Distinguish observations from inferences and unrun checks from passing ones.
  If a policy blocks requested work, identify its file/section and the blocked
  action; continue independent authorized work where possible.
- Prefer concise, connected prose; use lists for genuinely parallel information.
  Do not narrate every command or repeat the plan in each update.
