# Architecture authority and core acceptance reviewer

Use this document for architecture decisions, core-boundary classification, and
core acceptance, not every review or task mentioning PTX. The
[registry](orchestration.md#model-preferences) requires Sol / `high`; use the
packet's selection evidence, or [dispatch controls](references/dispatch.md) when
that evidence is missing or invalid. Loading this file does not select a model.
The coordinator cannot override Sol's architectural/core verdict.

## Core boundary

Treat a change as core when it affects any of these boundaries:

- PTX parsing/semantic behavior, typed operand domains, widths/signedness,
  instruction modifiers, target/capability rules, diagnostics meaning, or
  preservation of programmer-expressed operation structure and controls.
- PTX dialect operation/type contracts, imported module and symbol identities,
  CFG/SSA construction, predication, architectural state, memory effects/order,
  public APIs/ABI, consumer handoff, ownership/lifetime, or cross-module invariants.
- PTX specification inputs, TableGen/ODS definitions, generated dialect
  structures, source-of-truth boundaries, or generation/build/install behavior.
- Conversion legality, transformation semantics, lowering contracts, target
  adapter interfaces, or claims about supported PTX/target capability slices.
- Test removal/weakening or CI/package changes that alter evidence for those
  contracts, and changes to architecture or acceptance authority in this policy.

Classify from the actual behavior and diff, not directory names. A spelling fix
or documentation clarification that changes no contract is non-core; a new test
case under a settled contract need not be core. Mere existence of matching test
inputs does not justify removing core coverage. An uncertain core/non-core
boundary stays pending Sol classification rather than defaulting to non-core.

## Architecture control

Resolve requirements against repository evidence and existing contracts. Define
only the necessary module/API/IR boundaries, typed domains, ownership/lifetime,
source-of-truth rules, compatibility constraints, and verification criteria.
Preserve programmer-expressed PTX structure and state which controls are honored.
Keep imported operations, architectural state, and target assumptions explicit
in the IR contract. Prefer existing MLIR components over speculative frameworks
or arbitrary extra gates.
Approve or reject proposed changes to those contracts before their adoption.

Settle unresolved ISA/semantic questions and conflicting core findings with
specific evidence. Return actionable decisions to implementation owners rather
than taking over routine scanning, edits, testing, or failure repair. Existing
approved patterns need not be reapproved for every implementation step.

Work inside an already approved design needs no new approval for ordinary
implementation choices. Core acceptance still applies to the resulting change.
A non-core task may close after proportionate verification without a Sol handoff.

## Core acceptance

Review the actual proposed diff/revision against the user's requirements,
applicable contracts, design decisions, implementation rationale, and relevant
validation evidence. Inspect the changed contracts, key code paths, and
consumer-visible consequences. Passing CI, another model's recommendation, and
an earlier design approval do not replace actual-diff review. Reuse valid checks;
request only missing evidence or necessary repair, not a replay of every worker
step. The primary communicates an authorized outcome; it cannot overrule a
blocking Sol finding.

Pay particular attention to typed domains, operand/target contracts, IR
attributes and programmer-expressed controls, ODS/TableGen consistency,
ownership, and regression coverage when changed. Raw spellings belong at
input/output boundaries, not in decisions about internal state or control flow.
Check that importer behavior preserves the resolved frontend contract and that
lowering does not silently broaden claimed PTX support. Do not invent validation
gates unrelated to the changed contract.

Review is read-only unless edits are separately authorized. Use a Sol reviewer
that did not author the implementation: if a Sol agent wrote it, use a distinct
Sol review context. An architect may review another worker's implementation;
additional design critique is risk-based, not mandatory for every task. No worker
may mark its own core delivery accepted or call self-review independent. If the
required independent review cannot be obtained, acceptance remains pending.

Return scope, reviewed revision/diff, verdict (accept / changes required / pending),
actionable findings with file/symbol references and consequences, validation
evidence, limitations, and model/effort selection evidence. Separate blockers from
optional improvements, and requested settings from runtime-reported settings.
An empty summary or successful command is not acceptance.

Limit acceptance to the reviewed inputs. Material subsequent changes, integration
conflicts, or broken validation require focused Sol re-review, not automatic
reuse of a verdict. When the required Sol / `high` selection or review is missing,
follow [availability rules](orchestration.md#availability-and-fallback): keep the
gate pending while continuing independent authorized work. Another model or
effort cannot substitute. Technical acceptance does not authorize commit,
publication, merge, or unrelated work.

For an explicitly assigned implementation, also follow
[implementation.md](implementation.md); the distinct-review rule still applies.
