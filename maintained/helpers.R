# schwarz_coppock_2022/maintained/helpers.R
# Shared packages and helper functions sourced by every script in maintained/.

library(here)
library(tidyverse)
library(metafor)

here::i_am("maintained/helpers.R")

# Random-effects meta-analysis ----
# The archive pools with rmeta::meta.summaries(method = "random"), which is the
# DerSimonian-Laird estimator. metafor::rma() is the maintained equivalent, and the
# estimator is a required argument here rather than a default, so that every call site
# states which one it is pooling with. method = "DL" reproduces the published numbers;
# method = "REML" is metafor's own default and is reported alongside as an addition.
# The return columns follow broom's naming, plus the study count the tables report.
re_meta <- function(estimate, std_error, method) {
  fit <- metafor::rma(yi = estimate, sei = std_error, method = method)
  tibble(
    estimate = as.numeric(fit$b),
    std.error = fit$se,
    conf.low = fit$ci.lb,
    conf.high = fit$ci.ub,
    n_studies = fit$k
  )
}

# Wald test for the difference between two pooled estimates ----
# The two subgroups are disjoint sets of studies, so the difference has variance equal
# to the sum of the two variances. This reimplements the melt/dcast/transmute block the
# archive repeats in each of the three CATE scripts.
diff_test <- function(est1, se1, est2, se2) {
  d <- est1 - est2
  se <- sqrt(se1^2 + se2^2)
  z <- d / se
  tibble(
    estimate = d,
    std.error = se,
    statistic = z,
    p.value = 2 * pnorm(abs(z), lower.tail = FALSE)
  )
}

# Table and figure label formatting ----
# Carried over unchanged from the archive's helpers.R so that the maintained tables and
# the published ones are formatted identically.
add_parens <- function(x, digits = 3) {
  paste0("(", sprintf(paste0("%.", digits, "f"), as.numeric(x)), ")")
}

format_num <- function(x, digits = 3) {
  sprintf(paste0("%.", digits, "f"), as.numeric(x))
}

make_se_entry <- function(est, se, digits = 2) {
  paste0(format_num(est, digits = digits), " ", add_parens(se, digits = digits))
}

make_interval_entry <- function(conf.low, conf.high, digits = 2) {
  paste0("[", format_num(conf.low, digits = digits), ", ", format_num(conf.high, digits = digits), "]")
}

# Blank a figure PDF's embedded timestamps ----
# R's pdf() device stamps /CreationDate and /ModDate with the wall clock, so an
# otherwise deterministic pipeline writes a different file on every run. The epoch
# string is the same width as what it replaces, which keeps the cross-reference byte
# offsets valid, and a file with no timestamp is left alone.
blank_pdf_timestamps <- function(path) {
  epoch <- charToRaw("D:19700101000000")
  raw_pdf <- readBin(path, "raw", file.size(path))
  hits <- grepRaw("D:[0-9]{14}", raw_pdf, all = TRUE)
  if (length(hits) == 0) return(invisible(path))
  for (h in hits) raw_pdf[h:(h + length(epoch) - 1L)] <- epoch
  writeBin(raw_pdf, path)
  invisible(path)
}
