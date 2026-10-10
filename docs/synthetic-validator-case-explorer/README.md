# Synthetic Fabric CSV Validation Case Explorer | Sewlore

A 72-row educational dataset for exploring expected diagnostics by category, feature, core-validator result and strict-policy result. Every row is a deliberately synthetic software test input. These are not physical fabric measurements and cannot predict shrinkage, fit or material performance.

The [explorer CSV](sewlore-synthetic-validator-case-explorer.csv) contains one row per case. `Case Count` is 1 for each row. The source categories are normal (18), edge (13) and invalid (41). Core-validator labels accept 30 cases and reject 42; strict-policy labels accept 27 and reject 45. These are per-case outcomes: a separate whole-file policy can reject a batch containing an invalid row.

The source revision is `a4d965dc9c561c4c8ceccaadf3e8647f628a25f7`. The transformation joins `case_catalog.csv` and `expected_labels.csv` by case ID, retains category and diagnostic-field labels, and adds an explicit synthetic-data notice and source link to every exported row. [Public provenance](provenance.json) records source and output hashes.

See [Sewlore's methods and revision-pinned downloads](https://sewlore.com/pages/synthetic-fabric-csv-validation-cases) for raw inputs, expected diagnostics and the fixed source release. This file is a prepared Tableau data source; a Tableau Public workbook URL is not claimed by the source file itself.

MIT license and Sewlore attribution are retained in [LICENSE.txt](LICENSE.txt).
