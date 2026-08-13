# Publication-vintage selection

An observation month states when the activity occurred. A publication vintage states when an official file containing that observation was released. These dates can differ because later releases may repeat or revise historical months.

For every dataset, component and observation month:

1. list all candidate official releases containing that month;
2. confirm file integrity, schema and practice-level grain;
3. review publication notices and retrospective corrections;
4. choose one defensible owner;
5. retain non-selected candidates and the reason they were not used;
6. prove that no other selected row owns the same component-month;
7. filter the analytical output to the configured observation window.

Never append every available publication. That would double-count revised historical observations.

## Ownership and overlap controls

The source-month ownership register should record every candidate release, the selected owner, the selection rule, the retained row count and any unresolved conflict. A component-month passes only when exactly one selected source owns it. Older and later representations of the same historical observation remain provenance evidence but do not both enter the analytical table.

Retrospective corrections are evaluated from official publication notices, file integrity, schema compatibility and source reconciliation. A later vintage can be selected for an earlier observation month without expanding the observation window. Conversely, a file released within or after the window contributes nothing when it contains no selected observation month.

Integrity exclusions remain explicit. A corrupt or structurally invalid member is not silently replaced, inferred or treated as reported zero. If another verified official member owns the same required component-month, that replacement is recorded. Otherwise the gap remains a limitation attached to the affected output.

## Worked reference example

The verified reference application covers observations from April 2025 through March 2026. The May 2026 OCS publication supplies a later evidence vintage containing those historical months; May 2026 is not added as an observation month. GPAD ownership is assembled from the official practice-level publication files whose component months cover the same twelve-month window. The broader CBT register compares candidate publication members by component and month, selects 190 members and retains two integrity exclusions in the provenance record.

This approach fixes the analytical period first, then chooses the most defensible official owner for each required component-month. It prevents overlap, supports later corrections and keeps excluded evidence visible without manufacturing activity.
