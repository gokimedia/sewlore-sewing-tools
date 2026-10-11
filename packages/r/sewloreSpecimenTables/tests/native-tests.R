library(sewloreSpecimenTables)

checks <- 0L
expect <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
  checks <<- checks + 1L
}
expect_error <- function(expression, pattern = NULL) {
  error <- tryCatch({ force(expression); NULL }, error = identity)
  expect(inherits(error, "error"), "Expected a validation error")
  if (!is.null(pattern)) expect(grepl(pattern, conditionMessage(error)), "Unexpected validation error")
}
near <- function(a, b) isTRUE(all.equal(a, b, tolerance = 1e-10, check.attributes = FALSE))

synthetic <- synthetic_specimens()
expect(nrow(synthetic) == 14L, "Synthetic fixture row count")
expect(all(synthetic$provenance == "SYNTHETIC_NOT_EMPIRICAL"), "Fixture provenance must be explicit")
expect(all(grepl("^SYN-", synthetic$specimen_id)), "Fixture identifiers must be synthetic")
pairs <- pair_specimen_measurements(synthetic)
expect(nrow(pairs) == 7L, "Pairs must remain separate by specimen/cycle/axis/cohort")
expect(all(pairs$status == "paired"), "Fixture completeness")
first <- pairs[pairs$specimen_id == "SYN-A-01" & pairs$wash_cycle == 1 & pairs$axis == "warp", ]
expect(near(first$before_mm, 200), "Centimetre conversion")
expect(near(first$after_mm, 194), "Millimetre conversion")
expect(near(first$delta_mm, -6), "Delta contraction sign")
expect(near(first$change_percent, -3), "Change percent baseline")
expect(near(first$shrinkage_percent, 3), "Shrinkage contraction sign")
expansion <- pairs[pairs$specimen_id == "SYN-A-01" & pairs$axis == "weft", ]
expect(near(expansion$change_percent, 1), "Expansion sign")
expect(near(expansion$shrinkage_percent, -1), "Expansion shrinkage sign")
inch <- pairs[pairs$cohort == "SYNTHETIC_B", ]
expect(near(inch$before_mm, 101.6), "Inch conversion")
expect(inch$before_unit == "in" && inch$after_unit == "cm", "Original mixed units preserved")
cycle2 <- pairs[pairs$specimen_id == "SYN-A-01" & pairs$wash_cycle == 2, ]
expect(near(cycle2$before_mm, 194), "Second cycle must use explicit supplied before value")
summary <- summarise_specimen_pairs(pairs)
expect(nrow(summary) == 4L, "Summary groups remain separate")
warp <- summary[summary$cohort == "SYNTHETIC_A" & summary$wash_cycle == 1 & summary$axis == "warp", ]
expect(near(warp$mean_change_percent, -2.5), "Mean of per-specimen percentages")
expect(near(warp$sd_change_percent, sqrt(0.5)), "Descriptive sample SD")
expect(is.na(summary$sd_change_percent[summary$cohort == "SYNTHETIC_B"]), "Single pair SD must be missing")
expect(identical(synthetic, synthetic_specimens()), "Pairing must not mutate the input")

expect_error(pair_specimen_measurements(rbind(synthetic, synthetic[1, ])), "Duplicate stage")
duplicate <- synthetic[1:2, ]; duplicate[3, ] <- duplicate[1, ]; duplicate$stage[3] <- " BEFORE "
expect_error(pair_specimen_measurements(duplicate), "Duplicate stage")
missing <- synthetic[-2, ]
expect_error(pair_specimen_measurements(missing), "Incomplete pair")
reported <- pair_specimen_measurements(missing, "report")
expect(sum(reported$status == "missing_after") == 1L, "Missing after status")
expect(is.na(reported$change_percent[reported$status != "paired"]), "No imputed change")
reported_summary <- summarise_specimen_pairs(reported)
expect(sum(reported_summary$n_missing) == 1L, "Summary missing count")
no_before <- pair_specimen_measurements(synthetic[2, , drop = FALSE], "report")
expect(no_before$status == "missing_before", "Missing before status")
expect(summarise_specimen_pairs(no_before)$n_paired == 0L, "All-missing group count")
expect(is.na(summarise_specimen_pairs(no_before)$mean_change_percent), "All-missing mean remains missing")

bad <- synthetic; bad$value[1] <- 0
expect_error(validate_specimen_measurements(bad), "positive")
bad <- synthetic; bad$value[1] <- -1
expect_error(validate_specimen_measurements(bad), "positive")
bad <- synthetic; bad$value[1] <- Inf
expect_error(validate_specimen_measurements(bad), "finite")
bad <- synthetic; bad$value[1] <- NA_real_
expect_error(validate_specimen_measurements(bad), "finite")
bad <- synthetic; bad$value[1] <- .Machine$double.xmax; bad$unit[1] <- "in"
expect_error(validate_specimen_measurements(bad), "finite")
bad <- synthetic; bad$value[1] <- "20,0"
expect_error(validate_specimen_measurements(bad), "decimal")
bad <- synthetic; bad$wash_cycle[1] <- 1.5
expect_error(validate_specimen_measurements(bad), "integer")
bad <- synthetic; bad$wash_cycle[1] <- 0
expect_error(validate_specimen_measurements(bad), "integer")
bad <- synthetic; bad$unit[1] <- "px"
expect_error(validate_specimen_measurements(bad), "unit must")
bad <- synthetic; bad$stage[1] <- "unknown"
expect_error(validate_specimen_measurements(bad), "stage must")
bad <- synthetic; bad$specimen_id[1] <- " "
expect_error(validate_specimen_measurements(bad), "nonempty")
bad <- synthetic; bad$axis[1] <- "warp\034x"
expect_error(validate_specimen_measurements(bad), "control characters")
expect_error(validate_specimen_measurements(synthetic[0, ]), "nonempty")
expect_error(validate_specimen_measurements(synthetic[, -2]), "Columns")
bad <- synthetic; names(bad)[2] <- names(bad)[1]
expect_error(validate_specimen_measurements(bad), "Columns")

normalized <- synthetic[1:2, ]; normalized$unit <- c(" CM ", " MM "); normalized$axis <- c(" WARP ", "warp"); normalized$stage <- c(" BEFORE ", "after")
expect(near(pair_specimen_measurements(normalized)$change_percent, -3), "Whitespace and case normalization")
cohorts <- rbind(synthetic[1:2, ], synthetic[1:2, ]); cohorts$cohort[3:4] <- "OTHER_SYNTHETIC_COHORT"
expect(nrow(pair_specimen_measurements(cohorts)) == 2L, "Same specimen label can exist in distinct explicit cohorts")
unicode <- synthetic[1:2, ]; unicode$specimen_id <- "Örnek, 01 \"test\""
unicode_pairs <- pair_specimen_measurements(unicode)
expect(unicode_pairs$specimen_id == "Örnek, 01 \"test\"", "Unicode and CSV punctuation preserved")
without_cohort <- synthetic[1:2, ]; without_cohort$cohort <- NULL
expect(pair_specimen_measurements(without_cohort)$cohort == "unspecified", "Missing cohort has an explicit placeholder")

path <- tempfile(fileext = ".csv")
write_specimen_pairs(unicode_pairs, path)
roundtrip <- utils::read.csv(path, check.names = FALSE, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
expect(roundtrip$specimen_id == unicode_pairs$specimen_id, "CSV quoted identifier roundtrip")
expect(near(roundtrip$delta_mm, unicode_pairs$delta_mm), "Numeric sign is not formula-prefixed")
danger <- synthetic[1:2, ]; danger$specimen_id <- "=HYPERLINK(\"https://example.invalid\")"
danger_pairs <- pair_specimen_measurements(danger)
write_specimen_pairs(danger_pairs, path)
escaped <- utils::read.csv(path, stringsAsFactors = FALSE)
expect(startsWith(escaped$specimen_id, "'="), "Text formula marker escaped")
expect(startsWith(danger_pairs$specimen_id, "="), "Export must not alter the input identifier")
write_specimen_pairs(danger_pairs, path, FALSE)
expect(startsWith(utils::read.csv(path, stringsAsFactors = FALSE)$specimen_id, "="), "Explicit raw export option")
expect_error(write_specimen_pairs(pairs, path, NA), "TRUE or FALSE")
unlink(path)

csv <- tempfile(fileext = ".csv")
utils::write.csv(synthetic, csv, row.names = FALSE, fileEncoding = "UTF-8")
expect(nrow(read_specimen_csv(csv)) == 14L, "Native CSV import")
unlink(csv)
expect_error(read_specimen_csv("https://example.invalid/data.csv"), "local CSV")
expect_error(write_specimen_pairs(pairs, "https://example.invalid/data.csv"), "local output path")
cat("PASS:", checks, "native assertions; synthetic fixtures only\n")
