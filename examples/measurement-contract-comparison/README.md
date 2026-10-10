# Sewing measurement contracts: JavaScript, Drupal and Rust

Ten small software fixtures show where three published Sewlore arithmetic interfaces agree and where their input contracts differ. The result is a reproducible comparison, not a claim that the packages are interchangeable.

The implementations are the npm package `@sewingselami/sewlore-sewing-math` 0.1.0, the JavaScript math bundled with the Packagist Drupal module `sewlore/measurement-calculators` 1.0.0, and the Rust crate `sewlore-sewing-math` 0.1.0. `source-lock.json` identifies the exact published artifacts, source revision and SHA-256 of each included file. Minimal source subsets are included unchanged so running this project requires no package downloads.

**The Drupal package uses PHP to render/configure its interface, but its measurement arithmetic runs in JavaScript.** We examined its block and controller; this project does not claim to test a separate PHP arithmetic implementation.

## Why the distinction matters

Converting a signed number, accepting a length, and calculating a ratio are different contracts. A small sewing worksheet can silently change behavior if its developer substitutes one API for another. The [Sewlore measurement methods guide](https://sewlore.com/pages/fabric-measurement-methods-guide) explains the denominators and recording assumptions behind the examples. The [Rust measurement reference](https://sewlore.com/pages/rust-sewing-measurements) explains typed units and numeric-range rejection.

These inputs are **synthetic software fixtures**. No fabric specimens, physical printer readings, accuracy study or performance benchmark was collected.

## Actual ten-case snapshot

| Case | npm JavaScript | Drupal-bundled JavaScript | Rust |
|---|---|---|---|
| C01: 1 inch → centimetres | 2.54 | 2.54 | 2.54 |
| C02: 25.4 mm → inches | Unsupported unit | 1 | 1 |
| C03: −1 cm → inches | Accepts −0.3937007874… | Rejects negative length | Rejects negative length |
| C04: `5e-324` cm → inches | Returns zero | Returns zero | Rejects numeric underflow |
| C05: 10 → 14 → 10.5 cm | 40% stretch; 5% residual; 87.5% recovered extension | Same three quantities | Same three quantities |
| C06: 10 → 10 → 10 cm | Recovery is `null` | Recovery is `null` | Recovery is `None`, CLI `null` |
| C07: 10 → 15 → 9.5 cm | −5% residual; about 110% recovered; unusual=true | Same quantities and flag | Same quantities and flag |
| C08: stretched 9 below original 10 | Rejects | Rejects | Rejects |
| C09: 10cm → 140mm → 10.5cm | Common unit required | Common unit required | Normalizes inputs; 40%, 5%, 87.5% |
| C10: target100mm; X99.6/Y100.4; tolerance0.5% | Each axis within tolerance; X/Y gap0.8pp exceeds tolerance | Print-scale operation absent | Same independent flags as npm |

The runner produced 30 result records: **20 accepted, 6 rejected, 4 unsupported**. It made 26 real numerical API/CLI calls. Unsupported cases are identified from the interface contracts before calling a function; the adapter does not normalize unsupported inputs or manufacture missing operations. Raw outputs and error reasons are retained in [results/observed.json](results/observed.json).

## Run locally

Prerequisites: Python 3.10+, Node.js 18+ and a functioning Rust/Cargo toolchain. No Python/Node package dependencies or Rust external crates are installed. Rust's standard-library toolchain and linker must already be available.

```sh
python run.py
```

The command verifies the 11 source-file hashes, builds the unchanged Rust CLI with `cargo build --offline --locked --release`, executes all cases, and checks the outcomes against the explicit expectations in `cases.json`. Missing runtimes or failed builds are errors; no substituted implementation is used.

The recorded local run used Python 3.12.10, Node.js 25.2.1, Cargo 1.94.1 and Rust 1.94.1 on Windows. An actual second run produced the same result JSON bytes. Older toolchains, other operating systems and full Drupal integration were not exercised by this comparison.

To save a new actual result snapshot:

```sh
python run.py --write
```

To choose existing runtime executables:

```sh
python run.py --node /path/to/node --cargo /path/to/cargo
```

Build artifacts stay under `.work/` and are ignored. The runner performs no network calls, credential lookup, package-registry mutation or CI dispatch. A public repository does not mean that a hosted pipeline ran.

## Interpretation and limits

- All interfaces use binary floating-point arithmetic. Nonzero numerical comparisons in this harness allow relative and absolute error 1e-12; expected zero is checked exactly. This numerical comparison tolerance is not a physical measurement uncertainty.
- npm accepts only `cm`/`in` in `convertLength` and allows negative finite conversion inputs. Its stretch/print functions require positive readings. Drupal and Rust length conversion accept `cm`/`mm`/`in` and reject negative lengths.
- Rust additionally rejects conversion of a positive length to zero through underflow. The two tested JavaScript converters return zero for C04. This exceptionally small value is a numeric stress fixture, not a plausible sewing reading.
- JavaScript stretch calls require a common unit; Rust normalizes explicitly typed mixed units. The JavaScript adapter refuses C09 rather than silently comparing raw 10 and 140 as though they used the same unit.
- Recovered extension uses the applied extension as denominator. An undefined denominator remains undefined, and an unusual released reading remains visible rather than being clamped.
- This is a ten-case contract snapshot, not exhaustive equivalence, full Drupal integration testing, a native browser-extension test, or empirical validation of fabric/printer behavior.

## Sources and licensing

Published packages: [npm](https://www.npmjs.com/package/@sewingselami/sewlore-sewing-math), [Packagist](https://packagist.org/packages/sewlore/measurement-calculators), [crates.io](https://crates.io/crates/sewlore-sewing-math/0.1.0), [Rust documentation](https://docs.rs/sewlore-sewing-math/0.1.0/sewlore_sewing_math/).

The harness is MIT-licensed. Included upstream numerical sources retain their MIT notices; the Drupal module as a whole remains GPL-2.0-or-later and is not vendored as a PHP implementation. See [NOTICE](NOTICE), [LICENSE](LICENSE) and the individual `vendor/` notices. AI assisted the comparison harness and explanatory drafting; actual published code execution and explicit limitations are recorded. No exclusive human authorship, physical testing or search-ranking outcome is claimed.
