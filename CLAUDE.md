# CLAUDE.md — NSLLC Petroleum Toolkit

This file is loaded automatically at the start of every Claude Code session. It defines how I want Claude to behave when working on this codebase. Read it carefully before acting.

---

## What this project is

A browser-based engineering toolkit for Class II UIC, Class VI CCS, and related petroleum / regulatory work. Built as a single self-contained HTML file — inline CSS and vanilla JavaScript, no build system. All calculations run client-side. The toolkit is intended for use by the author (Eric White, P.G., NSLLC) and may be screenshotted into permit applications submitted to CalGEM, EPA Region 9, and the State Water Resources Control Board.

**Audience for outputs:** professional geologists, petroleum engineers, regulators. Calculations must be defensible, auditable, and clearly cited.

---

## Behavioral principles

These four principles take precedence over speed. For trivial tasks, use judgment.

### 1. Think before coding

- State assumptions explicitly. If uncertain, ask before implementing.
- If multiple interpretations of a request exist, present them — do not pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what is confusing. Ask.

### 2. Simplicity first

- Build the minimum that solves the problem. Nothing speculative.
- No features beyond what was asked.
- No abstractions for single-use code.
- No flexibility or configurability that was not requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical changes

- Touch only what you must. Match existing style even if you would do it differently.
- Do not refactor adjacent code that is not broken.
- Do not improve formatting in untouched files.
- If you notice unrelated dead code, mention it — do not delete it.
- Remove imports/variables/functions that your changes orphaned. Do not remove pre-existing dead code unless asked.

**The diff test:** every changed line must trace directly to the user's request.

### 4. Goal-driven execution

Define verifiable success criteria before writing code. For multi-step work, state a brief plan with verification checks:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
```

Strong criteria let you loop independently. Vague criteria ("make it work") require constant clarification.

---

## Domain rules (NON-NEGOTIABLE — IMPORTANT)

These reflect regulatory standards, professional style conventions, and reservoir engineering correctness. Violating them produces output that cannot be used in a permit application.

### Terminology

- Use **AOR** (not "Area of Review") for California Class II UIC contexts.
- Use **AoR** (lowercase o) for Class VI CCS contexts. **Never write out the full phrase in either case.**
- Use **proximal**, not "close to" or "adjacent to" in technical writing.
- Use lowercase **top** for stratigraphic horizons (e.g., "top Repetto", not "Top Repetto").
- Use **USDW** without a preceding "the" (e.g., "the base of USDW", not "the base of the USDW").
- Use **"negligible risk"**, never "zero risk".
- Distinguish **risk** (probability × consequence) from **hazard** (potential to cause harm). Use precisely.

### Units (field units throughout, no SI unless explicitly requested)

- Pressure: **psi**
- Depth, length, thickness: **ft**
- Permeability: **mD** (lowercase m, capital D)
- Porosity: **fraction** (e.g., 0.20), not percent — but display as percent in UI tables where space-constrained
- Rate: **bbl/d** (water/oil), **Mcf/d** (gas)
- Compressibility: **1/psi**
- Viscosity: **cP**
- Temperature: **°F**
- Salinity: **ppm** (NaCl-equivalent unless stated)
- Mass (CCS): **metric tonnes (t), kilotonnes (kt), megatonnes (Mt)**
- Density (user-facing): **lb/ft³** (see equations note below for internal-calc convention)

### Equations and physics

- All equations must use **field-unit conventional forms** unless explicitly told otherwise.
- Cite the source for any non-trivial correlation (Bernard 1967, McCain 1990, Newman 1973, Span-Wagner 1996, Arps 1953, etc.) directly in the methods note or tooltip.
- Default conservative for screening: bounding cases for regulatory submittals are preferred over best estimates without uncertainty quantification.

**Unit convention for friction and Reynolds calculations (IMPORTANT — common source of unit-mismatch bugs):**

The standard Fanning friction equation in petroleum field units uses density in **lb/gal**, not lb/ft³:

```
ΔP_friction (psi) = (11.46 × 10⁻⁶) × f × ρ × q² × L / d⁵
Re = 92.1 × ρ × q / (μ × d)
```

where ρ is in **lb/gal**, q in bbl/d, L in ft, d in inches, μ in cP.

**User-facing density inputs must remain in lb/ft³** because that is what petroleum engineers expect. **Internally, convert lb/ft³ → lb/gal by dividing by 7.481** before applying the friction or Reynolds equations.

When defining a fluid-type defaults table (e.g., fresh water, light produced water, brine), store both lb/ft³ (for display) and lb/gal (for internal calc). Document the conversion in code comments with a reference (Bourgoyne et al., "Applied Drilling Engineering," SPE Textbook Series, or Lyons Handbook of Petroleum Engineering).

Failing to do this conversion produces friction-loss values ~7.5× too high and effective permeability ~7.5× too low. If a test case for a friction/permeability calc gives results outside the expected sanity range, suspect a unit mismatch first.

### Output for permit applications

Every calculator tab must produce output that is **screenshot-ready** for inclusion in regulatory documents. This means:

- The governing equation must be shown with numeric substitution above or beside the main result, so a screenshot captures both the math and the answer.
- An **always-visible citation footer** must appear directly below the main result. The citation must travel with the screenshot.
- Helper text for every input must be **always visible** (italic gray, ~11–12px) — not hover-only. The tool is self-documenting.
- A `@media print` CSS block must allow clean printing of the **currently active tab only**, with app chrome (nav, header, tab bar) hidden, on a white background regardless of UI theme. Print must include a header ("NSLLC Toolkit — [active tab name]") and date footer.

If a new calculator tab is added without these features, it is not complete.

### Style

- Plain prose, active voice, technical precision over flourish.
- No bullet-point sprawl in helper text or methods notes — write in clear sentences.
- Use the SPE Style Guide as the default reference for petroleum technical writing.
- No Markdown formatting in any text intended for regulator-facing output (helper text, methods notes, citations).

---

## Code conventions

### Stack

- Single self-contained HTML file: inline CSS and inline vanilla JavaScript. No build system, no npm, no module bundler, no framework, no module imports, and no external runtime dependencies.
- Plots are hand-rolled SVG (built as strings and injected into the DOM). A single CDN-loaded library may be used only if one is already established in the file.
- Styling via CSS custom properties (variables) defined in `:root` — match existing patterns; do not introduce new styling systems.
- No backend, no database, no API calls in calculator logic — everything client-side.
- The file is meant to be opened by double-clicking, hosted as a single static file, or shared by email.

### File structure

- Everything lives in one HTML file. Each tab is a `<section>` shown or hidden via the tab nav (toggling the `hidden` attribute). Add a tab by registering it in the tab bar, the `tabIds` array, and `tabPrintNames`, then adding its `<section>`.
- Shared UI follows established class patterns (`.card`, `.row`, `.result`, `.result-primary`, `.result-grid`/`.kv`, `.input-helper`, `.eq-block`, `.citation-footer`). Reuse aggressively; do not duplicate markup or styling.
- Calculation functions live in the inline `<script>` as pure JS functions taking primitive inputs and returning primitive outputs, with documented field-unit inputs and outputs.

### State management

- Plain JS variables hold state; read inputs from the DOM and recompute on input/change events. No framework state and no global state library.
- Live reactivity is required: changing any input must update every dependent result immediately, including sensitivity tables.
- Recompute derived values in the update function on each event — do not cache and serve stale results.

### Naming

- Variables use the same notation as the equations where possible (e.g., `q`, `mu`, `k`, `h`, `phi`, `ct`, `r_w`, `P_e`, `P_wf`). Comments should clarify when this differs from JS conventions.
- Avoid generic names like `data`, `value`, `temp` — use the engineering term.
- JavaScript is loosely typed; document units in a JSDoc comment above each calculation function (e.g., `@param {number} q - injection rate, bbl/d`).

---

## Workflow expectations

### When adding a new calculator tab

1. Read existing tabs first to understand the established pattern (input + helper-text markup, result card style, helper text placement, citation footer, print CSS, sensitivity table layout).
2. Match that pattern. Do not introduce new visual or structural conventions.
3. Validate with the test case provided in the prompt before declaring complete.
4. Confirm the tab prints correctly (only the active tab, with chrome hidden) before declaring complete.
5. For any tab involving friction, hydraulics, or fluid mechanics: explicitly verify density-unit handling per the friction convention above before running the test case.

### When fixing bugs

1. Diagnose before fixing. Read the affected files. Identify the root cause. Report back what you found.
2. Look for shared root causes when multiple bugs are reported — do not fix three symptoms when one cause is responsible.
3. Wait for confirmation on the diagnosis before applying fixes (unless the bug is trivial).
4. After fixing, verify each bug is resolved and confirm no regressions.

### When test results fall outside expected ranges

If a calculator's test case produces results materially outside the expected sanity range (e.g., friction loss 5×+ higher than rule-of-thumb, k_eff 5×+ lower than typical), **do not declare the build complete**. The most common causes, in order:

1. Unit mismatch (especially density: lb/ft³ vs. lb/gal, viscosity: cP vs. lbm/ft·s)
2. Wrong constant for the unit system in use
3. Sign error in pressure differential
4. Misapplied formation factor or interest decimal

Stop and surface the discrepancy. Do not "tune" constants to make the number look right.

### When asked to "improve" or "polish"

1. Confirm scope first. Ask what should and should not change.
2. Do not refactor unrelated code, even if it looks improvable.
3. Visual/styling changes must be applied consistently across the app, not tab-by-tab.

### When committing

- Commit messages must be specific about what changed. "Update stuff" is unacceptable.
- Format: `Add [feature], fix [bug], update [thing]` — be precise.
- Do not commit `node_modules/`, `dist/`, `.env`, or OS files. The `.gitignore` should already exclude these.

---

## Anti-patterns to avoid

- Hardcoded colors instead of CSS variables or theme tokens
- Hover-only tooltips for important information (use always-visible helper text)
- Inline styles that override the established design system
- Generic loading spinners or "TODO" placeholders left in production code
- Injecting jQuery or other heavy libraries when vanilla JS suffices
- Inconsistent mixing of `id` and `class` selectors for the same purpose
- Using `innerHTML` for DOM updates that could be `textContent`
- New dependencies added without explicit approval
- "Tuning" a physics constant to make a test case pass instead of finding the actual unit or math bug

---

## Reference values built into the project

These values are defaults across the toolkit. Do not change them without explicit instruction.

- Water viscosity correlation: McCain-style temperature-only fit (no salinity correction in v1)
- Reservoir compressibility default (consolidated sandstone): 4 × 10⁻⁶ /psi (Newman 1973)
- Water compressibility default: 3 × 10⁻⁶ /psi (McCain 1990)
- Oil compressibility default: 10 × 10⁻⁶ /psi (McCain 1990 / Vasquez-Beggs)
- Wellbore radius default: 0.354 ft (8.5-inch hole)
- Drainage radius default for AOR: 660 ft (40-acre spacing)
- Injection fluid gradient default: 0.44 psi/ft (light produced water)
- USDW fluid gradient default: 0.433 psi/ft (fresh water)
- Reference temperature for Rw correction: 75°F (legacy chart convention; user-editable)
- Tubing roughness default: 0.0018 in (new commercial steel)
- Density-unit conversion for friction/Reynolds calcs: 1 lb/gal = 7.481 lb/ft³

### Standard fluid density references

For internal friction/Reynolds calculations, the following dual-unit reference values apply. Store both in fluid-type defaults tables:

| Fluid type | lb/ft³ (display) | lb/gal (internal calc) | Gradient (psi/ft) |
|---|---|---|---|
| Fresh water | 62.4 | 8.33 | 0.433 |
| Light produced water | 63.4 | 8.47 | 0.440 |
| Typical produced water | 64.9 | 8.67 | 0.450 |
| Heavy brine | 67.0 | 8.96 | 0.465 |

---

## Working signals

These guidelines are working if:

- Fewer unnecessary changes appear in diffs
- Fewer rewrites are needed because of overcomplication
- Clarifying questions arrive before implementation rather than after a mistake
- New tabs ship with screenshot-ready output the first time
- Print works correctly on every tab without per-tab fixes
- Friction and hydraulics calcs pass their sanity ranges on the first run

If any of these regress, revisit this file and tighten the relevant section.
