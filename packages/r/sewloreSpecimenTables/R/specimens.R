.number_column <- function(x, name) {
  if (is.factor(x)) x <- as.character(x)
  if (!is.numeric(x) && !is.character(x)) stop(name, " must contain numeric values", call. = FALSE)
  if (is.character(x)) {
    x <- trimws(x)
    valid <- !is.na(x) & grepl("^[+-]?([0-9]+(\\.[0-9]*)?|\\.[0-9]+)([eE][+-]?[0-9]+)?$", x)
    if (!all(valid)) stop(name, " must use unambiguous decimal numbers", call. = FALSE)
  }
  answer <- suppressWarnings(as.numeric(x))
  if (!all(is.finite(answer))) stop(name, " must contain finite values", call. = FALSE)
  answer
}

.label_column <- function(x, name, lowercase = FALSE) {
  if (!is.character(x) && !is.factor(x)) stop(name, " must contain text", call. = FALSE)
  answer <- trimws(as.character(x))
  if (anyNA(answer) || any(!nzchar(answer)) || any(grepl("[[:cntrl:]]", answer)))
    stop(name, " must contain nonempty labels without control characters", call. = FALSE)
  if (lowercase) answer <- tolower(answer)
  answer
}

.pair_key <- function(x) paste(x$cohort, x$specimen_id, x$wash_cycle, x$axis, sep = "\034")

validate_specimen_measurements <- function(data) {
  required <- c("specimen_id", "wash_cycle", "axis", "stage", "value", "unit")
  if (!is.data.frame(data) || !nrow(data)) stop("data must be a nonempty data frame", call. = FALSE)
  if (anyDuplicated(names(data)) || !all(required %in% names(data)))
    stop("Columns must be unique and include: ", paste(required, collapse = ", "), call. = FALSE)
  answer <- as.data.frame(data, stringsAsFactors = FALSE)
  answer$specimen_id <- .label_column(answer$specimen_id, "specimen_id")
  answer$axis <- .label_column(answer$axis, "axis", TRUE)
  answer$stage <- .label_column(answer$stage, "stage", TRUE)
  answer$unit <- .label_column(answer$unit, "unit", TRUE)
  if (!all(answer$stage %in% c("before", "after"))) stop("stage must be before or after", call. = FALSE)
  if (!all(answer$unit %in% c("mm", "cm", "in"))) stop("unit must be mm, cm or in", call. = FALSE)
  answer$wash_cycle <- .number_column(answer$wash_cycle, "wash_cycle")
  if (any(answer$wash_cycle < 1 | answer$wash_cycle > 1000000 | answer$wash_cycle != floor(answer$wash_cycle)))
    stop("wash_cycle must be an integer from 1 to 1,000,000", call. = FALSE)
  answer$wash_cycle <- as.integer(answer$wash_cycle)
  answer$value <- .number_column(answer$value, "value")
  if (any(answer$value <= 0)) stop("value must be positive", call. = FALSE)
  answer$cohort <- if ("cohort" %in% names(answer)) .label_column(answer$cohort, "cohort") else rep("unspecified", nrow(answer))
  answer$value_mm <- answer$value * c(mm = 1, cm = 10, `in` = 25.4)[answer$unit]
  if (!all(is.finite(answer$value_mm)) || any(answer$value_mm <= 0)) stop("Converted values must be positive and finite", call. = FALSE)
  if (anyDuplicated(paste(.pair_key(answer), answer$stage, sep = "\034")))
    stop("Duplicate stage within a cohort/specimen/wash_cycle/axis pair; observations are never silently averaged", call. = FALSE)
  rownames(answer) <- NULL
  answer
}

read_specimen_csv <- function(file) {
  if (!is.character(file) || length(file) != 1L || is.na(file) || grepl("^[A-Za-z][A-Za-z0-9+.-]*://", file) || !file.exists(file) || dir.exists(file))
    stop("file must be an existing local CSV file", call. = FALSE)
  data <- utils::read.csv(file, colClasses = "character", check.names = FALSE,
    stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM", na.strings = c("", "NA"))
  validate_specimen_measurements(data)
}

pair_specimen_measurements <- function(data, incomplete = c("error", "report")) {
  incomplete <- match.arg(incomplete)
  data <- validate_specimen_measurements(data)
  keys <- .pair_key(data)
  result <- lapply(unique(keys), function(key) {
    part <- data[keys == key, , drop = FALSE]
    before <- part[part$stage == "before", , drop = FALSE]
    after <- part[part$stage == "after", , drop = FALSE]
    complete <- nrow(before) == 1L && nrow(after) == 1L
    if (!complete && incomplete == "error") stop("Incomplete pair for specimen ", part$specimen_id[1], " in cycle ", part$wash_cycle[1], "/", part$axis[1], call. = FALSE)
    bmm <- if (nrow(before)) before$value_mm[1] else NA_real_
    amm <- if (nrow(after)) after$value_mm[1] else NA_real_
    delta <- if (complete) amm - bmm else NA_real_
    change <- if (complete) 100 * (delta / bmm) else NA_real_
    if (complete && (!is.finite(delta) || !is.finite(change))) stop("Computed change exceeds finite numeric range", call. = FALSE)
    data.frame(cohort = part$cohort[1], specimen_id = part$specimen_id[1],
      wash_cycle = part$wash_cycle[1], axis = part$axis[1],
      status = if (complete) "paired" else if (!nrow(before)) "missing_before" else "missing_after",
      before_value = if (nrow(before)) before$value[1] else NA_real_,
      before_unit = if (nrow(before)) before$unit[1] else NA_character_,
      after_value = if (nrow(after)) after$value[1] else NA_real_,
      after_unit = if (nrow(after)) after$unit[1] else NA_character_,
      before_mm = bmm, after_mm = amm, delta_mm = delta,
      change_percent = change, shrinkage_percent = -change,
      stringsAsFactors = FALSE)
  })
  answer <- do.call(rbind, result)
  rownames(answer) <- NULL
  class(answer) <- c("sewlore_pairs", "data.frame")
  answer
}

.check_pairs <- function(pairs) {
  needed <- c("cohort", "specimen_id", "wash_cycle", "axis", "status", "before_mm", "after_mm", "delta_mm", "change_percent", "shrinkage_percent")
  if (!inherits(pairs, "sewlore_pairs") || !all(needed %in% names(pairs)) || !nrow(pairs))
    stop("pairs must be a nonempty result of pair_specimen_measurements", call. = FALSE)
  invisible(TRUE)
}

summarise_specimen_pairs <- function(pairs) {
  .check_pairs(pairs)
  keys <- paste(pairs$cohort, pairs$wash_cycle, pairs$axis, sep = "\034")
  result <- lapply(unique(keys), function(key) {
    group <- pairs[keys == key, , drop = FALSE]
    paired <- group[group$status == "paired", , drop = FALSE]
    n <- nrow(paired)
    data.frame(cohort = group$cohort[1], wash_cycle = group$wash_cycle[1], axis = group$axis[1],
      n_paired = n, n_missing = nrow(group) - n,
      mean_before_mm = if (n) mean(paired$before_mm) else NA_real_,
      mean_after_mm = if (n) mean(paired$after_mm) else NA_real_,
      mean_change_percent = if (n) mean(paired$change_percent) else NA_real_,
      median_change_percent = if (n) stats::median(paired$change_percent) else NA_real_,
      sd_change_percent = if (n > 1L) stats::sd(paired$change_percent) else NA_real_,
      stringsAsFactors = FALSE)
  })
  answer <- do.call(rbind, result)
  answer <- answer[order(answer$cohort, answer$wash_cycle, answer$axis), , drop = FALSE]
  rownames(answer) <- NULL
  answer
}

write_specimen_pairs <- function(pairs, file, spreadsheet_safe = TRUE) {
  .check_pairs(pairs)
  if (!is.character(file) || length(file) != 1L || is.na(file) || !nzchar(file) || grepl("^[A-Za-z][A-Za-z0-9+.-]*://", file)) stop("file must be a local output path, not a URL", call. = FALSE)
  if (!is.logical(spreadsheet_safe) || length(spreadsheet_safe) != 1L || is.na(spreadsheet_safe)) stop("spreadsheet_safe must be TRUE or FALSE", call. = FALSE)
  answer <- as.data.frame(pairs)
  if (spreadsheet_safe) {
    for (name in names(answer)) {
      if (is.character(answer[[name]])) {
        dangerous <- !is.na(answer[[name]]) & grepl("^[[:space:]]*[=+@-]", answer[[name]])
        answer[[name]][dangerous] <- paste0("'", answer[[name]][dangerous])
      }
    }
  }
  utils::write.csv(answer, file = file, row.names = FALSE, na = "", fileEncoding = "UTF-8", quote = TRUE)
  invisible(normalizePath(file, winslash = "/", mustWork = TRUE))
}

synthetic_specimens <- function() {
  read_specimen_csv(system.file("extdata", "synthetic-specimens.csv", package = "sewloreSpecimenTables"))
}
