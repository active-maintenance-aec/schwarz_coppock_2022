# schwarz_coppock_2022/maintained/table_2_meta_robustness.R
# Output: output/table_2_meta_robustness.csv, output/table_2_trim_sensitivity.csv
# Depends on: original/sate_estimates.rds, helpers.R
# Description: Table 2, pooled estimates for eight subsets of studies, under the
#   published DerSimonian-Laird estimator and under REML alongside it. Also writes a
#   sensitivity check on the trimming rule, which the archive and the article describe
#   differently.

source(here::here("maintained", "helpers.R"))

sate_estimates <- read_rds(here::here("original", "sate_estimates.rds"))

# Subsets ----
# The year cut is written as year > 2010 in the archive but labelled post-2014 and
# pre-1998. Both labels are accurate: the sample contains no study fielded between 1998
# and 2014, a gap the article notes in footnote 4, so any threshold in that window
# produces the same two groups.
subsets <- bind_rows(
  sate_estimates |>
    mutate(group = if_else(year > 2010, "Post-2014 studies", "Pre-1998 studies")),
  sate_estimates |>
    mutate(group = if_else(representative_sample == 1,
                           "Representative sample",
                           "Convenience/student sample")),
  sate_estimates |>
    mutate(group = if_else(country == "USA", "American sample", "Non-American sample")),
  sate_estimates |>
    filter(estimate < quantile(estimate, 0.95), estimate > quantile(estimate, 0.02)) |>
    mutate(group = "Trimmed (middle 90% of estimates)"),
  sate_estimates |>
    mutate(group = "All studies")
) |>
  mutate(group = fct_relevel(
    group,
    "Post-2014 studies", "Pre-1998 studies",
    "Convenience/student sample", "Representative sample",
    "American sample", "Non-American sample",
    "Trimmed (middle 90% of estimates)", "All studies"
  ))

# Pooled estimates ----
pooled_dl <- subsets |>
  group_by(group) |>
  reframe(re_meta(estimate, std.error, method = "DL"))

pooled_reml <- subsets |>
  group_by(group) |>
  reframe(re_meta(estimate, std.error, method = "REML")) |>
  transmute(
    group,
    entry_reml = make_se_entry(estimate, std.error, 3),
    interval_reml = make_interval_entry(conf.low, conf.high, 3)
  )

table_2 <- pooled_dl |>
  transmute(
    group,
    entry = make_se_entry(estimate, std.error, 3),
    interval = make_interval_entry(conf.low, conf.high, 3),
    n_studies,
    estimate,
    std.error,
    conf.low,
    conf.high
  ) |>
  left_join(pooled_reml, by = "group") |>
  arrange(group)

write_csv(table_2, here::here("maintained", "output", "table_2_meta_robustness.csv"))
print(table_2 |> select(group, entry, interval, n_studies, entry_reml))

# Trimming rule sensitivity ----
# The article says the trimmed row drops "the bottom and top 5% of point estimates" and
# the row is labelled "middle 90%", but the archive keeps estimates strictly between the
# 2nd and 95th percentiles, which drops six studies rather than a symmetric six or eight.
# The published row is the asymmetric one, so it is what table_2 reports; the symmetric
# trim the text describes is computed here so the difference is visible rather than
# argued about.
trim_sensitivity <- bind_rows(
  sate_estimates |>
    filter(estimate < quantile(estimate, 0.95), estimate > quantile(estimate, 0.02)) |>
    reframe(re_meta(estimate, std.error, method = "DL")) |>
    mutate(rule = "Archive: above 2nd and below 95th percentile"),
  sate_estimates |>
    filter(estimate < quantile(estimate, 0.95), estimate > quantile(estimate, 0.05)) |>
    reframe(re_meta(estimate, std.error, method = "DL")) |>
    mutate(rule = "Text: above 5th and below 95th percentile")
) |>
  relocate(rule)

write_csv(trim_sensitivity, here::here("maintained", "output", "table_2_trim_sensitivity.csv"))
print(trim_sensitivity)
