# sewloreSpecimenTables

A small R package for explicit before/after specimen pairs. It normalizes mm, cm and inches while preserving original values, units, specimen identifiers, cohort, wash cycle and measuring axis.

By [Sewlore](https://sewlore.com/). Method context: [fabric measurement methods guide](https://sewlore.com/pages/fabric-measurement-methods-guide).

**Every bundled example is synthetic.** These numbers do not describe tested fabrics, real experiments or academic research.

## Local use

Requires R 4.1 or newer. The analysis functions depend only on base/recommended R packages; `knitr` is needed to rebuild the HTML vignette. The prepared version is 0.1.0; this README does not assert that it is already published on R-universe or CRAN.

```r
install.packages("sewloreSpecimenTables_0.1.0.tar.gz", repos = NULL, type = "source")
library(sewloreSpecimenTables)

observations <- synthetic_specimens() # SYNTHETIC, not experimental data
pairs <- pair_specimen_measurements(observations)
summarise_specimen_pairs(pairs)
write_specimen_pairs(pairs, "synthetic-pairs.csv")
```

For your own CSV, use these columns:

```csv
cohort,specimen_id,wash_cycle,axis,stage,value,unit
SYNTHETIC_DEMO,SYN-001,1,warp,before,20,cm
SYNTHETIC_DEMO,SYN-001,1,warp,after,194,mm
```

`read_specimen_csv("observations.csv")` validates UTF-8 input. `stage` is `before` or `after`; `unit` is `mm`, `cm` or `in`. Axis labels are normalized to lowercase but their physical meaning is caller-defined. Duplicate stages within a cohort/specimen/cycle/axis are errors. Missing stages are errors by default; `incomplete = "report"` shows their status and leaves computed changes missing.

Choose the baseline explicitly for every cycle. A cycle's before value can be the immediately preceding measurement or a repeated original baseline, depending on your method. The package does not infer cumulative versus incremental measurement. Set cohort labels for comparable specimens; missing cohort labels become `unspecified`, which is not evidence that fabrics or procedures are comparable.

## Interpretation

- `delta_mm = after_mm - before_mm`.
- `change_percent = 100 * delta_mm / before_mm`.
- `shrinkage_percent = -change_percent`: positive means contraction, negative means expansion.
- Summary percentages average individual specimen percentages. The descriptive standard deviation is missing when only one complete specimen is present; it is not measurement uncertainty, a confidence interval or a material-performance claim.
- Original values and units are preserved. Calculations use ordinary R floating point; round for display only, to match the actual measurement precision.
- CSV export overwrites the chosen output path. With default `spreadsheet_safe = TRUE`, text beginning with a formula marker is prefixed with an apostrophe in the export; affected exported identifiers therefore differ from their originals. The in-memory data remains unchanged. This is not a guarantee against every spreadsheet import behavior.

The analysis functions read and write local files only and perform no network calls or telemetry. The HTML vignette contains ordinary reference links, without remote fonts or images. This is a data-format and arithmetic helper, not a standardized testing method or a source of fabric care advice.

## Development

```sh
R CMD build --user=Sewlore sewloreSpecimenTables
R CMD check --no-manual sewloreSpecimenTables_0.1.0.tar.gz
```

The tests exercise pairing keys, repeated cycles, mixed units, missing data, duplicate observations, zero and nonfinite baselines, invalid cycles, descriptive single-specimen behavior, CSV quoting and conservative text-cell escaping.

The build command above uses R 4.6.1's native `--user` option to record the actual project publisher in the automatically generated `Packaged` metadata instead of a private machine account name. It does not change analysis data or disable checks. On an older builder, check `R CMD build --help` for supported flags; the declared R 4.1 minimum concerns analysis functions, not a verified build on every R release.

MIT licensed. Developed with AI assistance; the implementation, synthetic fixtures, native tests and documentation are included for review. The brand maintainer is Sewlore; no academic affiliation, ORCID authorship or peer review is claimed.
