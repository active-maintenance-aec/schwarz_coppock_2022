# schwarz_coppock_2022/ground_truth/run_archive.R
# Output: ground_truth/archive_run_status.csv, ground_truth/archive_overwrites.csv
# Depends on: original/ (run download_original.R first)
# Description: Runs every deposited analysis script, once per pass, and records how each
#   run ended and what it did to the files the deposit ships.
#
#   The deposit is flat and every script reads its inputs from the working directory, so
#   each pass runs in its own scratch copy: original/ must hold the deposit and nothing
#   else, and download_original.R refuses a stray file. helpers.R is only ever sourced by
#   the five analysis scripts, so it gets no row of its own.
#
#   The stripped pass withholds every deposited file that deposited code writes. Every
#   write in this deposit is commented out, so that set is empty and the two passes stage
#   the same files; both are run so the table has the same shape as every other repo's.
#   Run under Rscript, no script adds or changes a file, so archive_overwrites.csv is
#   header-only.
#
#   This script is not part of run_all.R. It needs rmeta, coefplot, reshape2, janitor, and
#   xtable, which the deposit loads and the maintained rewrite does not, and its two
#   tables are committed so that nothing downstream needs them.

library(here)
library(tidyverse)

here::i_am("ground_truth/run_archive.R")

deposit <- here::here("original")
stopifnot(dir.exists(deposit))

# Scripts, in the order the deposit's README lists them ----
scripts <- tribble(
  ~script, ~role,
  "meta_analyze_sates.R", "analysis",
  "meta_analyze_cates_cand_attributes.R", "analysis",
  "meta_analyze_cates_cand_race.R", "analysis",
  "meta_analyze_cates_resp_gender.R", "analysis",
  "meta_analyze_cates_resp_pid.R", "analysis"
)

# The deposited files that deposited code also writes. None: every ggsave(), sink(), and
# print.xtable() call is commented out.
shipped_outputs <- character(0)

stopifnot(all(file.exists(file.path(deposit, c(scripts$script, "helpers.R")))))

# Stage a scratch copy of the deposit ----
stage <- function(label, include_outputs) {
  # normalizePath, because tempdir() resolves through /private on macOS, and the
  # scrubbing below has to see the same spelling the error messages carry.
  root <- file.path(normalizePath(tempdir(), winslash = "/", mustWork = FALSE),
                    str_c("schwarz_coppock_2022_", label))
  unlink(root, recursive = TRUE)
  dir.create(root, recursive = TRUE)
  files <- list.files(deposit, all.files = TRUE, no.. = TRUE)
  if (!include_outputs) files <- setdiff(files, shipped_outputs)
  file.copy(file.path(deposit, files), root)
  root
}

# Run each script in its own process ----
# The scripts share object names, so sourcing them into one session would let one
# script's leftovers rescue the next.
run_one <- function(root, script) {
  log_file <- file.path(dirname(root), str_c(basename(root), "_", make.names(script), ".log"))
  expr <- str_c("setwd(", deparse(root), "); source(", deparse(script), ", echo = FALSE)")
  status <- system2(file.path(R.home("bin"), "Rscript"), args = c("-e", shQuote(expr)),
                    stdout = log_file, stderr = log_file)
  lines <- read_lines(log_file)
  first <- which(str_starts(lines, "Error"))
  stopped_at <- if (length(first) == 0) {
    NA_character_
  } else {
    lines[first[1]:min(first[1] + 2, length(lines))] |>
      discard(\(x) str_detect(x, "Execution halted")) |>
      str_c(collapse = " ") |>
      str_replace_all(fixed(root), "<deposit>") |>
      str_squish() |>
      str_trunc(220)
  }
  tibble(script = script, exit_status = status, stopped_at = stopped_at)
}

run_pass <- function(root) map(scripts$script, \(s) run_one(root, s)) |> list_rbind()

checksums <- function(root) {
  files <- list.files(root, all.files = TRUE, no.. = TRUE)
  set_names(unname(tools::md5sum(file.path(root, files))), files)
}

# The stripped pass ----
stripped_root <- stage("stripped", include_outputs = FALSE)
stripped_before <- checksums(stripped_root)
stripped <- run_pass(stripped_root)
stripped_after <- checksums(stripped_root)

# The as-shipped pass ----
shipped_root <- stage("as_shipped", include_outputs = TRUE)
shipped_before <- checksums(shipped_root)
as_shipped <- run_pass(shipped_root)
shipped_after <- checksums(shipped_root)

# Archive run status, one row per script per pass ----
run_status <- bind_rows(as_shipped = as_shipped, stripped = stripped, .id = "pass") |>
  left_join(scripts, by = "script") |>
  transmute(pass, script, role, exit_status,
            outcome = if_else(exit_status == 0, "clean", "error"),
            stopped_at)

stopifnot(nrow(run_status) == 2 * nrow(scripts), !anyNA(run_status$role))

# Archive overwrites ----
# With no shipped output to withhold, the only rows either pass can carry are deposited
# files whose bytes a run changed, which would be overwritten, and files no deposit
# member names, which are added.
changed <- function(before, after, pass) {
  tibble(file = names(before)) |>
    filter(after[file] != before[file]) |>
    mutate(pass = pass, effect = "overwritten", matches_deposit = FALSE)
}

added <- function(before, after, pass) {
  tibble(pass = pass, file = setdiff(names(after), names(before)),
         effect = "added", matches_deposit = NA)
}

overwrites <- bind_rows(
  changed(shipped_before, shipped_after, "as_shipped"),
  added(shipped_before, shipped_after, "as_shipped"),
  changed(stripped_before, stripped_after, "stripped"),
  added(stripped_before, stripped_after, "stripped")
) |>
  select(pass, file, effect, matches_deposit)

write_csv(run_status, here::here("ground_truth", "archive_run_status.csv"))
write_csv(overwrites, here::here("ground_truth", "archive_overwrites.csv"))

print(run_status, n = nrow(run_status), width = 200)
print(overwrites, n = nrow(overwrites))
