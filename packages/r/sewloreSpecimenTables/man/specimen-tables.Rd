\name{specimen-tables}
\alias{read_specimen_csv}
\alias{validate_specimen_measurements}
\alias{pair_specimen_measurements}
\alias{summarise_specimen_pairs}
\alias{write_specimen_pairs}
\alias{synthetic_specimens}
\title{Explicitly Paired Specimen Measurement Tables}
\description{Validate long-format measurements, retain original units, and compare paired measurements within explicitly identified cohorts, specimens, wash cycles and axes. Included examples are entirely synthetic, not empirical observations.}
\usage{
read_specimen_csv(file)
validate_specimen_measurements(data)
pair_specimen_measurements(data, incomplete = c("error", "report"))
summarise_specimen_pairs(pairs)
write_specimen_pairs(pairs, file, spreadsheet_safe = TRUE)
synthetic_specimens()
}
\arguments{
  \item{file}{For import, an existing local UTF-8 CSV file. For export, a local output path; an existing file is overwritten.}
  \item{data}{Nonempty data frame with unique column names and required columns \code{specimen_id}, \code{wash_cycle}, \code{axis}, \code{stage}, \code{value}, \code{unit}; optional \code{cohort}. Stages are before and after; units are mm, cm and in. Cycle numbers are positive integers. Values are positive finite numbers.}
  \item{incomplete}{Default \code{"error"} rejects a missing before or after observation. \code{"report"} retains incomplete pairs with a status and missing computed changes. No missing observation is estimated.}
  \item{pairs}{The nonempty result of \code{pair_specimen_measurements}.}
  \item{spreadsheet_safe}{If true, exported character cells beginning with a possible formula marker receive an apostrophe prefix. Numeric columns retain numeric signs. This changes affected exported labels, not the input object, and is a conservative precaution rather than a guarantee for every spreadsheet application.}
}
\details{
Comparison keys are cohort, specimen identifier, wash cycle and axis. A duplicate stage within a key is an error, including duplicate equal observations. Labels are trimmed; stage, unit and axis are lowercased. Cohort and specimen identifier remain case-sensitive. If cohort is omitted, the explicit output label is \code{unspecified}; callers must establish that observations are comparable before grouping them.

Every before/after pair must represent the intended baseline for that cycle. For cumulative change from an original baseline, supply that original measurement as each cycle's before value. The package never substitutes the first or previous cycle automatically.

One inch is 25.4 millimetres. Delta is after minus before in millimetres. Change percent is 100 times delta divided by before. Shrinkage percent is the negative of change percent: contraction is positive and expansion is negative. R uses floating-point arithmetic, so comparisons and rounding should account for numeric precision.

Summary means are unweighted means of per-specimen percentage changes. The standard deviation is descriptive spread across complete pairs, not measurement uncertainty or a confidence interval. It is missing for a single complete pair. No inference about fabric composition, care instructions or population performance is made.
}
\value{
Import and validation return a normalized long data frame with \code{value_mm}, preserving additional input columns. Pairing returns a \code{sewlore_pairs} data frame with status, before/after input values and units, normalized values, delta, change and shrinkage percentages. Summary returns one row per cohort/cycle/axis including complete and missing counts and descriptive means, median and standard deviation. Export invisibly returns the normalized output path. \code{synthetic_specimens} returns the explicitly synthetic bundled example measurements.
}
\seealso{\url{https://sewlore.com/pages/fabric-measurement-methods-guide}}
\examples{
data <- synthetic_specimens() # Synthetic demonstrations, not laboratory data.
pairs <- pair_specimen_measurements(data)
summarise_specimen_pairs(pairs)
path <- tempfile(fileext = ".csv")
write_specimen_pairs(pairs, path)
unlink(path)
}
