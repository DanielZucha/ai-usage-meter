# WIKI_SCHEMA.md — Project Wiki Schema

> This project's `knowledge/` directory follows the canonical LLM Wiki contract
> at `~/.claude/rules/llm-wiki.md`. Read that rule for the shared structure
> (three-layer architecture, INGEST / QUERY / LINT operations, evidence-tag
> grammar, confidence vocabulary, cross-reference rule, decision-page format).
>
> This file declares **only what is project-specific**: flavor, entity types in
> use, project-specific page fields, and any additional evidence tags.

## Project flavor

<!-- One of: biology | tooling | mixed -->
**Flavor**: tooling

<!-- One paragraph: what this project investigates or builds, and what the
     wiki is for. Keep it short — AGENTS.md carries the full overview. -->
**Wiki purpose**: Records why the meter is shaped the way it is: provider data-source choices, the credential-free rule, the snapshot contract, and the sharp edges of the Claude and Codex usage surfaces.

## Entity types in use

<!-- Tick the entity subdirs this project uses. Add project-specific types as
     needed. Page templates live under
     ~/.claude/templates/knowledge/_entity_templates/{biology,tooling}/. -->

### Biology entity types
- [ ] `entities/genes/` — one file per gene of interest
- [ ] `entities/pathways/` — one file per pathway
- [ ] `entities/cell_types/` — one file per cell type
- [ ] `entities/diseases/` — one file per disease relevant to the project
- [ ] `hypotheses/` — H<n>_<slug>.md with evidence chains
- [ ] `literature/` — <author><year>.md with structured claims

### Tooling entity types
- [ ] `entities/components/` (provisioned, unpopulated in v1) — one file per module / Nextflow process / Shiny module
- [ ] `entities/processes/` — pipeline processes: inputs, outputs, resources, known issues
- [ ] `entities/integrations/` (provisioned, unpopulated in v1) — external services: API, auth, rate limits, failure modes
- [ ] `entities/data_formats/` (provisioned, unpopulated in v1) — SpatialData / AnnData / CSV schemas, fields, constraints
- [x] `entities/runbooks/` — how to run, common failures, recovery steps

## Project-specific page fields

<!-- Optional. If every gene page in this project must carry a
     "Detected in islet type X" field, declare it here so future entries are
     consistent. Otherwise delete this section. -->

## Project-specific evidence tags

- `[ADR:codex-polling]` identifies the approved contract and session diagnosis
  recorded in [the app-owned polling decision](decisions/2026-09-06_codex-app-owned-polling.md).
- `[S#:C#]` identifies a numbered claim in
  [the source registry](sources/source_registry.md); `[S#]` identifies its
  source, and `[S#:F#]` a numbered finding in that source.
- `[Commit:sha]` identifies a Git commit by its abbreviated SHA.
- `[PRAudit:1]` identifies the historical
  [Stop-hook PR 4 audit](decisions/2026-09-06_pr-4_audit.md).
- `[PRAudit:2]` identifies the renewed
  [app-owned polling audit](decisions/2026-09-06_pr-4_polling_audit.md).

<!-- Optional. The canonical tags ([AuthorYear:C_id], [ResearchLoop:iter_N],
     [V##:section_N], [NB##:section_N], [PubMed:PMID], [F#], [ADR:NNN],
     [PR:NNN], [Issue:NNN]) are available by default. Declare any additional
     tags here. -->

Related: [knowledge index](index.md)

**Last updated**: 2026-09-06
