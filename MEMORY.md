# MEMORY.md — NSLLC Petroleum Toolkit

Persistent project state. Updated as the project evolves. Claude should read this at session start to know what already exists, what is in progress, and what is planned.

---

## Project status

**Phase:** Active development. Multiple calculator tabs built and styled. Visual refinement and feature additions ongoing.

**Last updated:** 2026-05-26

---

## Implemented tabs

Each entry below should be kept current as tabs are added or significantly changed.

### 1. ZEI / AOR Calculator
- Single-well Bernard / Warner-Lear pressure transient analysis
- Inputs: q, mu, B, k, h, phi, c_t, r_w, P_i, t, plus endangering pressure inputs (P_USDW, z_USDW_base, grad_USDW, z_top_perf, grad_inj)
- Helper calculators: Swanson k_brine, water viscosity from T, total compressibility from components
- Solves ZEI radius by bisection on Ei-function
- Plot: ΔP vs. radial distance (log scale) with ZEI radius and endangering ΔP reference lines
- Cross-section view for endangering pressure concept (USDW, confining zone, injection zone, hypothetical conduit, head height)
- Volumetric radius of injected fluid (CalGEM-friendly add)
- Status: working

### 2. Arps Decline (Forecast & EUR)
- Exponential, hyperbolic, harmonic with optional D_min switchover to exponential
- Inputs: qi, Di, b, forecast horizon, economic limit, terminal Di
- Outputs: EUR, q_final, log/linear plots of rate and cumulative
- Status: working

### 3. Single-Well Economics
- Uses Arps annual production from the decline tab
- Inputs: oil price, gas price, GOR, OPEX fixed ($/month/well), OPEX variable, CAPEX, abandonment, discount rate, WI, Lease NRI, RI
- RI defaults to WI × Lease NRI / 100; manual override; "Calc RI" button to reset to default
- RI color coding: green if RI > default (carry), red if RI < default (override/burden), neutral if equal
- Revenue scales on RI; OPEX, CAPEX, abandonment scale on WI
- Oil price sensitivity table: $40 to $130 in 10 bins; rows for IRR, NPV10, ROI undisc, ROI disc; current price column highlighted
- Status: working after bug fix passes

### 4. CCS Calculations & Conversions
- CO₂ mass ↔ volume conversions (tonnes, kt, Mt, scf, Mscf, MMcf, Bcf, sm³, bbl, m³, acre-ft)
- CO₂ density & viscosity estimator (P, T → ρ, μ)
- CO₂ phase diagram with user point overlay (P-T axes, log pressure, regions shaded, triple/critical points marked)
- Storage capacity (DOE volumetric method)
- Injection rate conversions (Mt/yr ↔ MMscf/d ↔ etc.)
- Plume radius (simple volumetric estimate)
- Quick reference constants box
- Status: working

### 5. Resistivity → Porosity → Salinity
- Temperature at depth (Mode A: from BHT; Mode B: direct gradient)
- Base case inputs: Rt, φ, T_ref (default 75°F, user-editable), target depth
- Salinity correlation toggle: Gen-9 NaCl (default) and Schlumberger 1988
- 10 formation factor methods (Archie, Humble, Sethi, etc.)
- Base case results for selected rock type
- Sensitivity table: 10 FF methods (rows) × 7 porosities (10–40% in 5% steps) as columns
- Highlights row of selected rock type, column nearest user's porosity, intersection cell
- Status: working

### 6. Total Compressibility (c_t)
- Inputs: S_w, S_o, c_rock, c_w, c_o (all editable with helper text and defaults)
- Quick reference table of typical c_rock, c_w, c_o ranges
- Results: c_t prominently displayed, component contributions with percentages
- Equation block with numeric substitution shown above main result (for screenshot capture)
- Always-visible citation footer (Newman 1973, McCain 1990, 40 CFR §146.6)
- Print-friendly CSS — active tab only
- Status: working

### 7. Single Well ZEI Calc
- Single-well, single-page quick-look ZEI for Class II UIC permit screening (separate from the existing ZEI / AOR tab #1; do not conflate)
- Bernard / Warner-Lear log-approximation ΔP(r,t); endangering pressure P_c and ΔP_c; volumetric radii with/without dispersion (Warner & Lear 1977)
- Mode toggles: thickness (direct or gross×N:G), permeability (direct / air×mult / Swanson), P_i (absolute or gradient), SG_i (direct or gradient) — each shows the equivalent value
- 20-radius distance table with ZEI flag; ZEI radius by bisection (upper bound 100,000 ft); ΔP-vs-distance chart with ΔP_endanger threshold line and linear/log x-axis toggle
- Equations via HTML sub/sup (.eq-block, no math library); single letter-portrait print page; refs Warner & Lear 1977, Matthews & Russell 1967, Swanson 1981
- "Current" volumetric radius uses gross historical injection; auto μ from McCain temperature-only (≈0.40 cP at 150°F, editable)
- Status: working (math verified against the Excel test case)

---

## Planned tabs (in priority order)

### Next: Darcy Permeability (RAT)
- Estimate effective permeability from RAT injection surveys
- Inputs: surface injection pressure, observed rate (stabilized), BHT, tubing depth, tubing OD/ID, roughness, fluid type/gradient/density, viscosity from T, FVF, P_e (with 3 input modes: direct entry, fluid level, regional gradient), drainage radius, h_eff, h_perf
- Computes friction loss (Swamee-Jain), P_wf, ΔP across formation, k_eff
- Outputs: k_eff, kh, injectivity index, specific injectivity
- Sensitivity table: P_e × h_eff
- Status: prompt drafted, not yet built

### Later additions discussed but not yet scheduled
- Step-rate test analyzer (paste in P, q pairs → fit two-line intersection → fracture pressure)
- Fall-off test pre-screener (test design helper)
- MASP / injection pressure limit calculator (per 14 CCR §1724.7)
- Cement volume + capacity calculator (P&A workflow)
- Hydrostatic / gradient / mud weight converters
- Standing Bo / Rs / Pb correlations (oil PVT bundle)
- Unit converter side panel (always-visible across tabs)
- API number parser / validator
- Multi-rate injectivity analysis
- Streamline-based plume estimation overlay for AOR (Water Board–facing)
- Save/load project state as JSON

---

## Architectural decisions made

- **Stack:** single self-contained HTML file with inline CSS and JavaScript. No build system, no npm, no framework. Deployed by uploading the HTML file directly (Netlify Drop, GitHub Pages, or email attachment). Auditability is a core design goal: a regulator can open the file in a text editor and read the source directly.
- **No backend.** All math runs in browser. Auditability is a core design goal: a regulator can inspect the source code via the public repo.
- **All plots are hand-rolled SVG** (built as strings and injected). Line plots use a shared `makePlot()` helper; bespoke diagrams (cross-section, CO₂ phase diagram) are drawn directly because shaded irregular regions need full control.
- **Field units throughout** unless a tab explicitly involves SI (none currently do).
- **Live reactivity everywhere.** No "calculate" buttons; inputs update outputs immediately. Exception: "Calc RI" button in economics, which resets RI to default; the RI field is otherwise editable.
- **Helper text always visible.** Hover-only tooltips were rejected as inappropriate for shareable, screenshot-able permit output.
- **Print = active tab only.** App-wide print CSS implemented to handle this uniformly.
- **No PDF export yet.** Deferred. Screenshot + browser print currently sufficient. Revisit if regulator or client requests change.
- **Faults in ZEI deferred.** Not in v1. Plan was image-well theory with scaled rate for partial transmissivity, but tabled until core toolkit stabilizes.

---

## Known limitations and caveats

These are intentional simplifications, not bugs. Do not "fix" them without discussion.

- Water viscosity uses temperature only, no salinity correction (~5% error for typical brines).
- Friction calculation uses measured depth for hydrostatic on deviated wells (correct only for vertical wells; flagged in methods note).
- Effective permeability from RAT is skin-included; not separable without pressure transient analysis.
- Storage efficiency factor in CCS capacity calc uses DOE-NETL methodology with user-editable factor; defaults match published ranges.
- CO₂ density correlation is a simplified fit, not full Span-Wagner EOS — adequate for screening.
- Endangering pressure uses initial reservoir pressure as the baseline; alternative reference to hydrostatic at top perf is possible but not implemented.

---

## Bug history (recent — keep last 5–10 entries)

- **2026-05-26:** CLAUDE.md and MEMORY.md previously described the stack as React + TypeScript + Vite, which was incorrect. Actual stack is a single self-contained HTML file with inline CSS/JS. Corrected during the Single Well ZEI Calc build, after the npm/KaTeX request surfaced the mismatch.
- **2026-05-XX:** Tab switching broke during visual redesign — all tabs rendered simultaneously. Fixed by restoring conditional rendering on the active-tab state variable.
- **2026-05-XX:** Oil price sensitivity table heading rendered but no rows appeared. Fixed by wiring sensitivity calc to live state and rendering rows from the computed array.
- **2026-05-XX:** RI color coding not applied. Fixed by attaching conditional style to the input element and computing color from current WI, Lease NRI, RI values on each render.
- **2026-05-XX:** Regression after fix pass — all economics inputs became non-reactive (results frozen at initial render). Root cause: cached derived values were not recomputed on input events. Restored reactivity by recomputing all dependent results in the input handler.
- **2026-05-XX:** Print CSS scoped only to Total Compressibility tab; pressing Ctrl+P from any other tab printed nothing or wrong content. Fixed by refactoring print rules to target the currently active tab generically rather than hardcoding the c_t selector.

---

## Style and branding

- Numeric Solutions logo in header (saved locally at `public/numeric-solutions-logo.png` or `.svg`)
- App title: "NSLLC Petroleum Toolkit"
- Brand color palette: derived from numericsolutions.com — primary blue/teal (replace the previous generic `#2c5282`)
- Typography: Inter or IBM Plex Sans for UI; JetBrains Mono or IBM Plex Mono for numeric values and equations
- Spacing: 24px between major sections, 12px within
- Cards: subtle shadow (`0 1px 3px rgba(0,0,0,0.08)`), 6–8px radius
- Numbers in tables: monospace, right-aligned, thousands separators, sensible precision (no trailing 0.813361 — show 0.813)

---

## Deployment

- Live public URL: https://nsllc-toolkit.netlify.app (Netlify, deployed 2026-06-05)
- Netlify site ID: 8aa6f9a8-aa59-4e3e-9e70-7776c653dc2e | site name: nsllc-toolkit
- To redeploy: POST zip to https://api.netlify.com/api/v1/sites/8aa6f9a8-aa59-4e3e-9e70-7776c653dc2e/deploys with Authorization: Bearer <token> and Content-Type: application/zip. Zip must contain index.html (the toolkit) + public/numeric-solutions-logo.png.
- Netlify personal access token: create once at app.netlify.com/user/applications, reuse for all future deploys. Do NOT paste the token in chat — store in a password manager and provide it verbally or via env var.
- Repo: GitHub (ebwhite3/Oil-Gas-CCS-Toolkit)
- Branches: `main` only
- Cross-machine workflow: i9 workstation ↔ OptiPlex via git pull/push; never via Dropbox/OneDrive
- Local LAN preview: `serve.bat` (repo root) runs `python -m http.server 8000 --bind 0.0.0.0` and serves its own folder, so it keeps working if the folder is moved/renamed. Double-click to start. Reachable on the LAN at `http://10.66.1.10:8000/oil-gas-ccs-toolkit.html`. Use `--bind 127.0.0.1` to restrict to localhost.

---

## Notes for Claude on using this file

- Read this at session start. It is faster than re-reading all source code to understand project state.
- Update relevant sections when you complete work that changes the project state — new tabs, fixed bugs, architectural decisions.
- When you add an entry to bug history, keep the list to roughly the last 10 entries. Drop the oldest when adding new ones.
- If a section becomes outdated, fix it before continuing the requested work — do not let stale memory propagate.
- Do not duplicate content from CLAUDE.md here. CLAUDE.md is "rules"; MEMORY.md is "state".
