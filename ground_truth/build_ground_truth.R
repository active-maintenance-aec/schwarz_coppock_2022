# schwarz_coppock_2022/ground_truth/build_ground_truth.R
# Output: ground_truth/published_claims_reproduction.csv,
#   ground_truth/schwarz_coppock_2022_ground_truth.csv, ground_truth/float_coverage.csv
# Depends on: ground_truth/published_claims.csv, maintained/output/, maintained/in_text_claims.R,
#   errata_entries.csv
# Description: Takes every published number recorded in the extraction and puts beside it
#   the value this pipeline produces, printed to the precision the page uses, together
#   with a verdict and, where the two disagree, where the fault lies.
#
#   The extraction is the article's side and is hand-reviewed; nothing here types a
#   published number. Everything in value_rewrite is read out of maintained/output/ by the
#   code below.
#
#   This file and maintained/in_text_claims.R are two instruments on the same pipeline
#   outputs. Where this file parses the label a plot or a table actually draws, the claims
#   file formats the raw estimate behind it, and the reverse. Both are run here and
#   compared claim by claim, so a disagreement between them stops the build.
#
#   It also rewrites the hand-kept ground truth in the canonical column order, computing
#   the columns that must never be typed, and writes the float coverage table.
#
#   It runs standalone.

library(here)
here::i_am("ground_truth/build_ground_truth.R")

source(here::here("maintained", "helpers.R"))

options(width = 200)

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

published <- read_csv(here::here("ground_truth", "published_claims.csv"),
                      col_types = cols(.default = col_character()))

stopifnot(
  !any(duplicated(published$claim_id)),
  identical(names(published), c("claim_id", "location", "claim_type", "claim", "value_paper",
                                "digits", "comparison", "expect", "needs_block", "notes")),
  all(published$claim_type %in% c("pipeline", "definitional", "structural", "descriptive",
                                  "transcribed")),
  all(published$comparison %in% c("==", "<", "<=", ">", ">=", "approx")),
  all(is.na(published$expect) | published$expect %in% c("range", "derived", "absent", "shape")),
  all(published$needs_block %in% c("TRUE", "FALSE")),
  all(str_detect(published$location, "^(Table|Figure) (A\\.)?\\d+$") |
        !str_detect(published$location, "^(Table|Figure)"))
)

# Every comparison below is of strings printed at the page's own precision, and this file
# carries no digit count of its own, so the extraction's digits must be the precision its
# own value_paper is printed at.
stopifnot(all(as.integer(published$digits) == excheckr::claim_digits(published$value_paper)))

f1 <- out("figure_1_plotted_estimates.csv")
f2 <- out("figure_2_plotted_estimates.csv")
f3 <- out("figure_3_plotted_estimates.csv")
f4 <- out("figure_4_plotted_estimates.csv")
f1_pooled <- out("figure_1_meta_summary.csv")
f2_pooled <- out("figure_2_meta_summary.csv")
f3_pooled <- out("figure_3_meta_summary.csv")
f4_pooled <- out("figure_4_meta_summary.csv")
f2_diff <- out("figure_2_diff_in_cates_cand_race.csv")
f3_diff <- out("figure_3_diff_in_cates_resp_gender.csv")
f4_diff <- out("figure_4_diff_in_cates_resp_pid.csv")
t2 <- out("table_2_meta_robustness.csv")
t2_trim <- out("table_2_trim_sensitivity.csv")
ta1 <- out("table_a1_study_attributes.csv")
fa1 <- out("figure_a1_cate_summary.csv")
fa2_index <- out("figure_a2_a45_index.csv")
fa2_cells <- out("figure_a2_a45_plotted_estimates.csv")
counts <- out("text_in_text_numbers.csv")
studies <- out("text_study_level.csv")

# Every join in this file goes through here, which asserts uniqueness on both sides and a
# one-to-one result, so a mistyped label cannot silently drop a published claim.
join_1to1 <- function(x, y, by) {
  stopifnot(!any(duplicated(x[[by]])), !any(duplicated(y[[by]])))
  joined <- left_join(x, y, by = by)
  stopifnot(nrow(joined) == nrow(x))
  joined
}

counterpart <- function(claim_id, value_rewrite) {
  tibble(claim_id = claim_id, value_rewrite = as.character(value_rewrite))
}

# Float cells ----
# The figures print an estimate and a standard error beside every row. Those labels are
# built by the figure script and written out with the estimates, so the published cell is
# compared against the string the plot draws rather than against a number reformatted here.
panel_slug_of <- c("Black candidate" = "black", "White candidate" = "white",
                   "Female respondents" = "female", "Male respondents" = "male",
                   "Democratic respondents" = "democrat",
                   "Independent respondents" = "independent",
                   "Republican respondents" = "republican")

figure_cells <- bind_rows(
  f1 |> mutate(location = "figure_1", panel = NA_character_),
  f2 |> mutate(location = "figure_2"),
  f3 |> mutate(location = "figure_3"),
  f4 |> mutate(location = "figure_4")
) |>
  mutate(
    panel_slug = unname(panel_slug_of[panel]),
    stem = if_else(is.na(panel_slug),
                   paste0(location, " :: ", study_id),
                   paste0(location, " :: ", panel_slug, " :: ", study_id)),
    plotted_estimate = str_extract(se_entry, "^[^ ]+"),
    plotted_std_error = str_extract(se_entry, "(?<=\\()[^)]+(?=\\))")
  )

stopifnot(!any(is.na(figure_cells$plotted_estimate)), !any(is.na(figure_cells$plotted_std_error)))

figure_counterparts <- bind_rows(
  counterpart(str_c(figure_cells$stem, " :: estimate"), figure_cells$plotted_estimate),
  counterpart(str_c(figure_cells$stem, " :: std_error"), figure_cells$plotted_std_error)
)

# The 44 per-study appendix figures print the same pair of labels beside every row, so all
# 954 conditional effects appear on the page. The published minus sign is not a hyphen, and
# the labels carry both, so it is normalised on the way into the key.
appendix_cells <- fa2_cells |>
  mutate(
    stem = str_glue("figure_a{figure_number} :: {study_id} :: \\
                     {str_replace_all(CATE_label, '−', '-')}"),
    plotted_estimate = str_extract(se_entry, "^[^ ]+"),
    plotted_std_error = str_extract(se_entry, "(?<=\\()[^)]+(?=\\))")
  )

appendix_counterparts <- bind_rows(
  counterpart(str_c(appendix_cells$stem, " :: estimate"), appendix_cells$plotted_estimate),
  counterpart(str_c(appendix_cells$stem, " :: std_error"), appendix_cells$plotted_std_error)
) |>
  filter(claim_id %in% published$claim_id)

# Table 1 cells are compared against the deposited counts themselves rather than against
# the formatted manifest, which is where the claims file reads them.
table_1_counterparts <- bind_rows(
  counterpart(str_glue("table_1 :: {studies$study_id} :: n_subjects"), studies$n_subjects),
  counterpart(str_glue("table_1 :: {studies$study_id} :: n_ratings"), studies$n_ratings),
  counterpart("table_1 :: total :: n_subjects", sum(studies$n_subjects)),
  counterpart("table_1 :: total :: n_ratings", sum(studies$n_ratings))
)

# Table 2 cells are parsed out of the formatted entries the table prints, which is the
# opposite of the claims file, which formats the numeric columns behind them.
table_2_slug <- c("Post-2014 studies" = "post_2014", "Pre-1998 studies" = "pre_1998",
                  "Convenience/student sample" = "convenience_student",
                  "Representative sample" = "representative",
                  "American sample" = "american", "Non-American sample" = "non_american",
                  "Trimmed (middle 90% of estimates)" = "trimmed",
                  "All studies" = "all_studies")

table_2_parsed <- t2 |>
  transmute(
    slug = table_2_slug[as.character(group)],
    estimate = str_extract(entry, "^[^ ]+"),
    std_error = str_extract(entry, "(?<=\\()[^)]+(?=\\))"),
    conf_low = str_extract(interval, "(?<=\\[)[^,]+"),
    conf_high = str_trim(str_extract(interval, "(?<=, )[^\\]]+")),
    n_studies = as.character(n_studies)
  ) |>
  pivot_longer(-slug, names_to = "statistic", values_to = "value_rewrite") |>
  transmute(claim_id = str_glue("table_2 :: {slug} :: {statistic}"), value_rewrite)

stopifnot(!any(is.na(table_2_parsed$value_rewrite)))

# Prose claims ----
# Each is derived here from maintained/output/ by this file's own path.
pooled_pp <- 100 * f1_pooled$estimate
share_positive <- mean(studies$estimate > 0)
trim_archive <- t2_trim |> filter(str_starts(rule, "Archive"))
measured <- studies |> filter(digitally_measured == 1)

subtype_failing <- t2 |>
  filter(group != "All studies", !(estimate > 0 & conf.low > 0)) |>
  pull(group) |>
  as.character()

stopifnot(length(subtype_failing) == 1)

disjoint_contrast_p <- function(group_a, group_b) {
  a <- filter(t2, group == group_a)
  b <- filter(t2, group == group_b)
  stopifnot(nrow(a) == 1, nrow(b) == 1)
  2 * pnorm(abs(a$estimate - b$estimate) / sqrt(a$std.error^2 + b$std.error^2), lower.tail = FALSE)
}

across_type_p <- c(
  disjoint_contrast_p("Post-2014 studies", "Pre-1998 studies"),
  disjoint_contrast_p("Convenience/student sample", "Representative sample"),
  disjoint_contrast_p("American sample", "Non-American sample")
)

# The article states no continent field and the deposit carries none, so the count comes
# from the country field through the same geography the claims file uses. Written out here
# independently rather than shared, since a shared helper would make the two instruments one.
continent_count <- studies |>
  mutate(continent = case_when(
    country == "USA" ~ "North America",
    country %in% c("Argentina", "Brazil", "Chile") ~ "South America",
    country %in% c("Denmark", "Germany", "Norway", "Romania", "Switzerland", "UK") ~ "Europe",
    country %in% c("Afghanistan", "India", "Japan", "Jordan", "Vietnam") ~ "Asia",
    country %in% c("Malawi", "Tunisia", "Zambia") ~ "Africa",
    country == "Australia" ~ "Oceania"
  )) |>
  summarise(n = n_distinct(continent), missing = sum(is.na(continent)))

stopifnot(continent_count$missing == 0)

prose_counterparts <- bind_rows(
  counterpart("abstract :: n_studies", nrow(studies)),
  counterpart("abstract :: pooled_ate_pp", sprintf("%.0f", pooled_pp)),
  counterpart("intro :: n_studies_collected", nrow(studies)),
  counterpart("intro :: n_studies_set", nrow(studies)),
  counterpart("intro :: n_continents", continent_count$n),
  counterpart("intro :: pooled_ate_pp", sprintf("%.0f", pooled_pp)),
  counterpart("theory :: n_studies", nrow(studies)),
  counterpart("theory :: share_positive_fraction", sprintf("%.3f", share_positive)),
  counterpart("design :: n_studies_located", nrow(studies)),
  counterpart("design :: n_papers", n_distinct(studies$bib_entry)),
  counterpart("design :: n_with_raw_data", counts$n_have_data),
  counterpart("design :: n_studies_denominator", nrow(studies)),
  counterpart("design :: n_without_raw_data", counts$n_no_data),
  counterpart("design :: share_us_studies", sprintf("%.3f", counts$prop_us_studies)),
  counterpart("design :: n_studies_database", nrow(studies)),
  counterpart("design :: n_continents", continent_count$n),
  counterpart("design :: span_decades",
              sprintf("%.1f", (counts$last_year - counts$first_year) / 10)),
  counterpart("design :: confidence_level",
              sprintf("%.0f",
                      100 * (2 * pnorm((f1_pooled$conf.high - f1_pooled$conf.low) /
                                         (2 * f1_pooled$std.error)) - 1))),
  counterpart("results :: pooled_ate_pp", sprintf("%.1f", pooled_pp)),
  counterpart("results :: pooled_ci_low_pp", sprintf("%.1f", 100 * f1_pooled$conf.low)),
  counterpart("results :: pooled_ci_high_pp", sprintf("%.1f", 100 * f1_pooled$conf.high)),
  counterpart("results :: n_positive", sum(studies$estimate > 0)),
  counterpart("results :: n_positive_significant", sum(studies$conf.low > 0)),
  counterpart("results :: n_negative", sum(studies$estimate < 0)),
  counterpart("results :: n_negative_significant", sum(studies$conf.high < 0)),
  counterpart("results :: horiuchi_estimate_pp",
              sprintf("%.1f", 100 * studies$estimate[studies$study_id == "horiuchi_1"])),
  counterpart("results :: pooled_ate_pp_restated", sprintf("%.0f", pooled_pp)),
  counterpart("figure_1 :: caption_n_studies", nrow(studies)),
  counterpart("results :: n_pre_1998_studies", sum(studies$year <= 1998)),
  counterpart("results :: n_studies_1999_to_2013",
              sum(studies$year > 1998 & studies$year < 2014)),
  counterpart("results :: convenience_estimate_pp",
              sprintf("%.1f", 100 * t2$estimate[t2$group == "Convenience/student sample"])),
  counterpart("results :: representative_estimate_pp",
              sprintf("%.1f", 100 * t2$estimate[t2$group == "Representative sample"])),
  counterpart("results :: american_estimate_pp",
              sprintf("%.1f", 100 * t2$estimate[t2$group == "American sample"])),
  counterpart("results :: non_american_estimate_pp",
              sprintf("%.1f", 100 * t2$estimate[t2$group == "Non-American sample"])),
  counterpart("results :: subtypes_significant_except_pre_1998",
              str_extract(subtype_failing, "\\d{4}")),
  counterpart("results :: no_significant_differences_across_types",
              sprintf("%.2f", min(across_type_p))),
  counterpart("results :: trim_percent",
              str_glue("{sprintf('%.1f', 100 * trim_archive$n_dropped_low / trim_archive$n_all)} \\
                        and {sprintf('%.1f', 100 * trim_archive$n_dropped_high / trim_archive$n_all)}")),
  counterpart("table_2 :: trimmed :: label_percent",
              sprintf("%.0f", 100 * trim_archive$n_studies / trim_archive$n_all)),
  counterpart("results :: n_cates", sum(fa2_index$n_cates)),
  counterpart("results :: cates_majority_positive", sprintf("%.3f", fa1$prop_positive)),
  counterpart("results :: n_cand_race_studies",
              f2_pooled$n_studies[f2_pooled$cand_white == "Black candidate"]),
  counterpart("results :: white_cand_cate_pp",
              sprintf("%.1f", 100 * f2_pooled$estimate[f2_pooled$cand_white == "White candidate"])),
  counterpart("results :: black_cand_cate_pp",
              sprintf("%.1f", 100 * f2_pooled$estimate[f2_pooled$cand_white == "Black candidate"])),
  counterpart("results :: cand_race_diff_p", sprintf("%.3f", f2_diff$p.value)),
  counterpart("results :: n_resp_gender_studies",
              f3_pooled$n_studies[f3_pooled$resp_female == "Male respondents"]),
  counterpart("results :: female_resp_cate_pp",
              sprintf("%.1f", 100 * f3_pooled$estimate[f3_pooled$resp_female == "Female respondents"])),
  counterpart("results :: male_resp_cate_pp",
              sprintf("%.1f", 100 * f3_pooled$estimate[f3_pooled$resp_female == "Male respondents"])),
  counterpart("results :: resp_gender_diff_p", sprintf("%.3f", f3_diff$p.value)),
  counterpart("results :: n_resp_pid_studies",
              f4_pooled$n_studies[f4_pooled$resp_pid_3 == "Republican respondents"]),
  counterpart("results :: republican_cate_pp",
              sprintf("%.1f", 100 * f4_pooled$estimate[f4_pooled$resp_pid_3 == "Republican respondents"])),
  counterpart("results :: independent_cate_pp",
              sprintf("%.1f", 100 * f4_pooled$estimate[f4_pooled$resp_pid_3 == "Independent respondents"])),
  counterpart("results :: democrat_cate_pp",
              sprintf("%.1f", 100 * f4_pooled$estimate[f4_pooled$resp_pid_3 == "Democratic respondents"])),
  counterpart("results :: republican_differs_from_dem_and_ind",
              sprintf("%.2f", max(f4_diff$p.value))),
  counterpart("discussion :: n_studies", nrow(studies)),
  counterpart("discussion :: pooled_ate_pp", sprintf("%.1f", pooled_pp)),
  counterpart("discussion :: share_positive_fraction", sprintf("%.3f", share_positive)),
  counterpart("discussion :: appendix_first_study_figure", min(fa2_index$figure_number)),
  counterpart("discussion :: appendix_last_study_figure", max(fa2_index$figure_number)),
  counterpart("table_a1 :: n_studies_listed", nrow(ta1)),
  counterpart("figure_a1 :: n_cates", fa1$n_cates),
  counterpart("appendix_b :: n_digitally_measured_experiments", nrow(measured)),
  counterpart("appendix_b :: n_digitally_measured_papers", n_distinct(measured$bib_entry)),
  counterpart("figure_a18 :: printed_estimates", sum(fa2_cells$figure_number == 18)),
  counterpart("title :: n_studies", nrow(studies)),
  counterpart("theory :: majority_industrialized_democracies",
              sprintf("%.3f", mean(studies$country %in% c("USA", "UK", "Japan", "Norway",
                                                          "Australia", "Chile", "Denmark",
                                                          "Germany", "Switzerland")))),
  counterpart("results :: most_studies_randomized_other_attributes",
              sprintf("%.3f", n_distinct(fa2_cells$study_id) / nrow(studies)))
)

counterparts <- bind_rows(figure_counterparts, appendix_counterparts, table_1_counterparts,
                          table_2_parsed, prose_counterparts)

# A counterpart keyed to a claim the article does not make is a mistyped label, and it
# would otherwise vanish in the join without ever reaching the reproduction table.
stopifnot(all(counterparts$claim_id %in% published$claim_id))

# Published claims with no counterpart, and why ----
# Each reason is a statement about the deposit, and each is checked rather than asserted:
# the deposit is five summary .rds files and carries no respondent-level data, no digital
# measurements, and no field recording anything the transcribed claims speak about.
no_counterpart <- tribble(
  ~claim_id, ~reason,
  "intro :: kelley_mcallister_britain_pp", "Quoted from Kelley and McAllister (1984); nothing in the deposit bears on it",
  "intro :: kelley_mcallister_australia_pp", "Quoted from Kelley and McAllister (1984); nothing in the deposit bears on it",
  "intro :: king_leigh_first_year", "Quoted from King and Leigh (2010); nothing in the deposit bears on it",
  "intro :: king_leigh_last_year", "Quoted from King and Leigh (2010); nothing in the deposit bears on it",
  "intro :: thomsen_first_year", "Quoted from Thomsen (2020); nothing in the deposit bears on it",
  "intro :: thomsen_last_year", "Quoted from Thomsen (2020); nothing in the deposit bears on it",
  "intro :: abramson_majority_threshold", "A majority threshold in the cited theoretical argument, not a quantity the deposit records",
  "theory :: ipu_share_women_legislators", "Quoted from Inter-Parliamentary Union (2018); nothing in the deposit bears on it",
  "theory :: welch_first_year", "Quoted from Welch et al. (1985); nothing in the deposit bears on it",
  "theory :: welch_last_year", "Quoted from Welch et al. (1985); nothing in the deposit bears on it",
  "theory :: welch_gap_pp", "Quoted from Welch et al. (1985); nothing in the deposit bears on it",
  "theory :: hayes_lawless_contests", "Quoted from Hayes and Lawless (2015); nothing in the deposit bears on it",
  "discussion :: vote_margin_reference", "The midpoint of the vote margin scale, not a quantity the deposit records",
  "discussion :: karpowitz_pp", "Quoted from Karpowitz, Monson and Preece (2017); nothing in the deposit bears on it",
  "theory :: women_share_world_population", "A world population share quoted from the cited source; nothing in the deposit bears on it",
  "theory :: n_demand_side_explanations", "The number of explanations the article sets out to review, a fact about its own structure",
  "design :: n_inclusion_criteria", "The number of inclusion criteria the article states, a fact about its own design",
  "design :: most_studies_not_designed_for_gender", "A claim about what each study was designed to test. The deposit records no field for a study's original purpose",
  "appendix_a :: most_studies_not_primarily_gender", "The appendix's restatement of the same claim about study purpose, which the deposit likewise cannot answer",
  "appendix_b :: mean_absolute_error", "The validation compares digital measurements against estimates from Kirkland and Coppock's raw data; the deposit carries neither",
  "appendix_b :: mean_absolute_error_pp", "The validation compares digital measurements against estimates from Kirkland and Coppock's raw data; the deposit carries neither",
  "appendix_b :: correlation", "The validation compares digital measurements against estimates from Kirkland and Coppock's raw data; the deposit carries neither"
)

stopifnot(all(no_counterpart$claim_id %in% published$claim_id))

# Every published claim is either computed here or named above with a reason. A claim that
# is neither is the coverage failure this file exists to expose.
uncovered <- setdiff(published$claim_id, c(counterparts$claim_id, no_counterpart$claim_id))

if (length(uncovered) > 0) {
  print(uncovered)
  stop(str_glue("{length(uncovered)} published claim(s) have no counterpart and no stated reason."))
}

# A pipeline or descriptive claim may never be excused by a reason: those are exactly the
# claims the pipeline is supposed to reach, and the appendix B validation is the one case
# where the deposit cannot, which is recorded rather than waived silently.
excused_pipeline <- published |>
  filter(claim_id %in% no_counterpart$claim_id, claim_type %in% c("pipeline", "descriptive"))

stopifnot(all(excused_pipeline$claim_id %in%
                c("appendix_b :: mean_absolute_error", "appendix_b :: mean_absolute_error_pp",
                  "appendix_b :: correlation")))

# Verdicts ----
# A descriptive claim is a statement about a threshold rather than an equality, so its
# verdict is the comparison the sentence makes, which the extraction records in
# comparison. A descriptive claim whose comparison this file cannot score stops the build.
descriptive_test <- published |>
  filter(claim_type == "descriptive") |>
  select(claim_id, relation = comparison)

stopifnot(all(descriptive_test$relation %in% c("==", ">", ">=", "<")))

holds <- function(relation, rewrite, paper) {
  x <- suppressWarnings(as.numeric(rewrite))
  y <- suppressWarnings(as.numeric(paper))
  case_when(
    relation == "==" ~ rewrite == paper,
    relation == ">" ~ x > y,
    relation == ">=" ~ x >= y,
    relation == "<" ~ x < y
  )
}

gt <- published |>
  select(claim_id, location, claim_type, value_paper) |>
  join_1to1(counterparts, "claim_id") |>
  join_1to1(descriptive_test, "claim_id") |>
  join_1to1(no_counterpart, "claim_id") |>
  mutate(
    match_rewrite = case_when(
      is.na(value_rewrite) ~ NA,
      claim_type == "descriptive" ~ holds(relation, value_rewrite, value_paper),
      .default = value_rewrite == value_paper
    ) |> as.integer()
  )

# Where the fault lies ----
# Set on every row that is not a clean match, because a zero otherwise reads as a failure
# of the rewrite and none of these is one. A new disagreement with no locus stops the
# build rather than joining the unexplained.
defect <- tribble(
  ~claim_id, ~defect_locus, ~notes,
  "design :: n_papers", "unresolved",
  "The deposit assigns 50 distinct bibliography keys to the 67 studies. Whether the article's 49 treats two of them as one source cannot be settled from the deposit",
  "results :: n_positive_significant", "unresolved",
  "No significance rule the deposit supports gives 23. The counts are monotone in any threshold: the threshold putting 23 estimates in the positive column leaves 5 in the negative one, and the threshold putting 11 in the negative column leaves 44 in the positive one",
  "results :: n_negative_significant", "unresolved",
  "See the note on the positive count. Under the interval rule the deposited script uses, 6 negative estimates are significant, and no rule reaches 11",
  "results :: n_negative", "paper_internal",
  "The deposited estimates split 47 positive, 19 negative and one exactly zero, the only division summing to 67. The published 47 plus 18 sums to 65",
  "theory :: share_positive_fraction", "paper_internal",
  "47 of 67 estimates are positive, a share of 0.701, which is below three-fourths",
  "discussion :: share_positive_fraction", "paper_internal",
  "47 of 67 estimates are positive, a share of 0.701, which is below three-fourths",
  "results :: n_resp_gender_studies", "paper_internal",
  "The deposit has 37 studies with respondent gender, and the published Figure 3 draws 37 rows in each panel",
  "figure_3 :: female :: sen_2 :: estimate", "archive",
  "The published figure prints 6.0 where the deposited respondent-gender file gives 5.925. The deposited study-level file carries the revised Sen (2017) SSI 2 estimate that Figure 1 reproduces, so the CATE file is a revision behind it",
  "figure_3 :: male :: sen_2 :: estimate", "archive",
  "The published figure prints 0.5 where the deposited respondent-gender file gives 0.437, the same one-revision gap as the female panel",
  "table_a1 :: n_studies_listed", "paper_internal",
  "The appendix carries 44 per-study figures, A.2 through A.45, and Table A.1 lists 43 studies. Simas and Murdoch (2019) has Figure A.44 and no Table A.1 row",
  "appendix_b :: n_digitally_measured_experiments", "unresolved",
  "The deposit's note field marks 10 experiments as having had bounds and standard errors estimated from a picture. Whether the article's nine excludes one of them cannot be settled from a free-text field",
  "appendix_b :: n_digitally_measured_papers", "unresolved",
  "Those 10 experiments come from 8 papers; see the note on the experiment count",
  "results :: trim_percent", "unresolved",
  "The published trimmed row drops the bottom 3.0 per cent and the top 6.0 per cent of estimates, not 5 per cent from each tail. Whether the intended rule was the symmetric one, which moves the published estimate from 0.018 to 0.020, cannot be settled from the deposit",
  "table_2 :: trimmed :: label_percent", "unresolved",
  "The row retains 61 of 67 estimates, 91 per cent, under the same asymmetric rule; see the note on the trimming percentage",
  "appendix_b :: mean_absolute_error", "archive",
  "The deposit carries no digital measurements and no respondent-level data, so the validation cannot be reconstructed from it",
  "appendix_b :: mean_absolute_error_pp", "archive",
  "The deposit carries no digital measurements and no respondent-level data, so the validation cannot be reconstructed from it",
  "appendix_b :: correlation", "archive",
  "The deposit carries no digital measurements and no respondent-level data, so the validation cannot be reconstructed from it",
  "figure_a18 :: printed_estimates", "paper_internal",
  "Costa (2020)'s attribute levels are whole tweets. At the width the appendix uses, the row labels push the panel, the points, the intervals, the estimate labels and the axis off the right edge of the page, so the published Figure A.18 prints none of the 10 estimates it is drawn from and its axis title is cut off mid-word"
)

stopifnot(all(defect$claim_id %in% published$claim_id), !any(duplicated(defect$claim_id)))

gt <- gt |>
  join_1to1(defect, "claim_id") |>
  mutate(notes = coalesce(notes, reason)) |>
  select(claim_id, location, claim_type, value_paper, value_rewrite, match_rewrite,
         defect_locus, notes)

unexplained <- gt |> filter(match_rewrite == 0, is.na(defect_locus))

if (nrow(unexplained) > 0) {
  print(unexplained, n = Inf)
  stop(str_glue("{nrow(unexplained)} disagreeing claim(s) carry no defect_locus."))
}

stale_locus <- gt |> filter(match_rewrite == 1, !is.na(defect_locus))

if (nrow(stale_locus) > 0) {
  print(stale_locus, n = Inf)
  stop(str_glue("{nrow(stale_locus)} matching claim(s) carry a defect_locus."))
}

# Coverage of maintained/in_text_claims.R ----
# The claims file is run non-interactively here and its printed lines are counted, because
# a "# covers:" marker proves a block was written and not that it runs. A block that errors
# or falls silent satisfies a textual gate completely and fails this one.
claims_output <- capture.output(source(here::here("maintained", "in_text_claims.R"),
                                       local = new.env()))

in_text <- tibble(line = str_subset(claims_output, "^CLAIM (?!SUMMARY)")) |>
  transmute(
    claim_id = str_match(line, "^CLAIM (.*?) = ")[, 2],
    value_in_text = str_match(line, "^CLAIM .*? = (.*) \\|\\| ")[, 2]
  )

stopifnot(!any(is.na(in_text$claim_id)), !any(is.na(in_text$value_in_text)))

stopifnot(!any(duplicated(in_text$claim_id)))

# The extraction's needs_block says which claims need a block. It has to be the rule this
# file states: every claim with a counterpart, and the three appendix B validation numbers,
# whose blocks print that the deposit has none.
validation_claims <- c("appendix_b :: mean_absolute_error", "appendix_b :: mean_absolute_error_pp",
                       "appendix_b :: correlation")

must_have_block <- published |> filter(needs_block == "TRUE")

stopifnot(
  setequal(must_have_block$claim_id,
           union(setdiff(published$claim_id, no_counterpart$claim_id), validation_claims)),
  setequal(published$claim_id[published$expect %in% "absent"], validation_claims),
  all(published$claim_id[published$expect %in% "derived"] %in%
        gt$claim_id[!is.na(gt$defect_locus)])
)

if (nrow(in_text) != nrow(must_have_block)) {
  stop(str_glue("in_text_claims.R printed {nrow(in_text)} claims against ",
                "{nrow(must_have_block)} that require a block."))
}

blockless <- setdiff(must_have_block$claim_id, in_text$claim_id)

if (length(blockless) > 0) {
  print(head(blockless, 30))
  stop(str_glue("{length(blockless)} published claim(s) have no block in in_text_claims.R."))
}

unknown <- setdiff(in_text$claim_id, published$claim_id)

if (length(unknown) > 0) {
  stop(str_glue("in_text_claims.R prints claims the article does not make: ",
                "{str_flatten_comma(unknown)}"))
}

# Every block carries a "# covers:" marker naming what it accounts for, which is what makes
# the file readable beside the article. The markers are checked against the claims the file
# actually prints, so a marker cannot outlive its block.
markers <- read_lines(here::here("maintained", "in_text_claims.R")) |>
  str_subset("^#\\s*covers:") |>
  str_remove("^#\\s*covers:") |>
  str_trim()

stopifnot(length(markers) > 0, all(markers %in% published$claim_id))

# The two instruments ----
# They reach each claimed number from the same outputs by separate paths, so a disagreement
# means one of them is wrong. excheckr prints a negative zero without its sign, and the
# trimming claim states two numbers, of which the claims file prints the first and names
# the second in its label, so each value is compared in the form the claims file prints.
printed_form <- function(x) {
  x |>
    str_replace("^-(0(\\.0*)?)$", "\\1") |>
    str_remove(" and .*$")
}

disagreements <- gt |>
  inner_join(in_text, by = "claim_id") |>
  filter(!is.na(value_rewrite), printed_form(value_rewrite) != value_in_text)

if (nrow(disagreements) > 0) {
  print(disagreements |> select(claim_id, value_paper, value_rewrite, value_in_text), n = Inf)
  stop(str_glue("The ground truth and in_text_claims.R disagree on {nrow(disagreements)} claims."))
}

write_csv(gt, here::here("ground_truth", "published_claims_reproduction.csv"))

# The ground truth ----
# ground_truth/schwarz_coppock_2022_ground_truth.csv compares the deposited scripts, the
# rewrite and the article on the quantities the floats are built around. Its values are
# typed by hand: the deposited scripts write nothing to disk, so value_script was read off
# a run of them, and value_paper off the article. This file reads it back, checks it, and
# writes it again in the canonical column order with the columns that must never be typed
# recomputed: claim_type, digits, holds, disposition, and disposition_reason.
ground_truth_path <- here::here("ground_truth", "schwarz_coppock_2022_ground_truth.csv")
ground_truth_columns <- c("paper_id", "claim_id", "location", "claim_type", "claim",
                          "value_paper", "digits", "value_script", "match", "value_rewrite",
                          "match_rewrite", "holds", "defect_locus", "disposition",
                          "disposition_reason", "notes")

hand_gt <- read_csv(ground_truth_path, col_types = cols(.default = col_character()))

stopifnot(identical(names(hand_gt), ground_truth_columns))

# The claim id is the float's slug and the claim joined by an underscore, and it has to be
# unique, because the errata spine addresses these rows by id. The slug is this file's key
# for a location written as printed: "Table A.1" is table_a1.
location_key <- function(location) {
  location |>
    str_to_lower() |>
    str_remove_all("\\.") |>
    str_replace_all(" ", "_")
}

stopifnot(
  !any(duplicated(hand_gt$claim_id)),
  all(hand_gt$claim_id == str_c(location_key(hand_gt$location), "_", hand_gt$claim)),
  all(hand_gt$location == "Text" | str_detect(hand_gt$location, "^(Table|Figure) (A\\.)?\\d+$")),
  all(hand_gt$defect_locus %in% c(NA, "archive", "paper_internal", "environment", "rewrite",
                                  "unresolved", "upstream"))
)

# Errata spine gate ----
# errata.qmd names, for each published entry, the ground truth rows that entry corrects. An
# id that no longer exists is a typo or a renamed claim, and a dangling reference in a
# document whose whole purpose is correcting the record is worse than a build that refuses.
errata_ids <- read_csv(here::here("errata_entries.csv"), col_types = cols(.default = col_character())) |>
  pull(claim_ids) |>
  str_split(";") |>
  unlist() |>
  str_trim()
errata_ids <- errata_ids[!is.na(errata_ids) & errata_ids != ""]
dangling_errata_ids <- setdiff(errata_ids, hand_gt$claim_id)

if (length(dangling_errata_ids) > 0) {
  stop("errata_entries.csv lists claim ids absent from the ground truth: ",
       str_flatten_comma(dangling_errata_ids))
}

print(str_glue("Errata spine: {length(unique(errata_ids))} distinct claim ids listed, ",
               "all present in the ground truth."))

# Claim type and printed precision ----
# The extraction keys these claims differently, so no row here has an extraction row to
# copy from. Every row is a pipeline quantity at the precision its value_paper prints,
# except the two whose notes say value_paper records a bound ("more than three-fourths",
# "the majority"), which are descriptive. Their verdict is already recorded in match, so
# holds adds nothing and stays NA on every row.
bound_claims <- c("text_prop_positive", "figure_a1_prop_cates_positive")
stopifnot(all(bound_claims %in% hand_gt$claim_id))

# Disposition: what became of each defect ----
# corrected_here is computed from the errata spine and never typed. Any other judgment would
# be keyed here to what the README or the errata already say happened; no row needs one, so
# a defect nobody has judged stays NA.
disposition_judgments <- tibble(claim_id = character(), disposition = character(),
                                disposition_reason = character())

logical_from <- function(x) {
  value <- as.logical(x)
  stopifnot(identical(is.na(value), is.na(x)))
  value
}

ground_truth <- hand_gt |>
  select(-disposition, -disposition_reason) |>
  left_join(disposition_judgments, by = "claim_id") |>
  mutate(
    claim_type = if_else(claim_id %in% bound_claims, "descriptive", "pipeline"),
    digits = excheckr::claim_digits(value_paper),
    across(c(match, match_rewrite), logical_from),
    holds = NA,
    disposition = case_when(
      is.na(defect_locus) ~ NA_character_,
      claim_id %in% errata_ids ~ "corrected_here",
      .default = disposition
    ),
    disposition_reason = if_else(disposition %in% "corrected_here", NA_character_,
                                 disposition_reason)
  ) |>
  select(all_of(ground_truth_columns))

undisposed <- ground_truth |> filter(defect_locus == "paper_internal", is.na(disposition))

if (nrow(undisposed) > 0) {
  print(undisposed |> select(claim_id, location, claim), n = nrow(undisposed))
  stop(str_glue("{nrow(undisposed)} paper_internal rows carry no disposition."))
}

print(ground_truth |> filter(!is.na(defect_locus)) |> count(defect_locus, disposition))

write_csv(ground_truth, ground_truth_path, na = "NA")

# Float coverage ----
# One row per float the article and its appendix publish. The floats carrying data are the
# ones the extraction locates claims at; the two appendix B figures carry none of the
# deposit's numbers and are listed here. A cell is a number printed on the float's face:
# for a figure, the estimate and standard error printed beside each row, and for a table,
# every number it prints other than a structural count of its own rows. A caption's count
# is a sentence about the float rather than a cell of it.
#
# The deposited scripts write nothing, and the ground truth compares them only on the
# pooled quantities, so no float is compared cell by cell against the archive and
# reproduced_by_archive is NA throughout.
appendix_b_floats <- tribble(
  ~float, ~note,
  "Figure B.46", "A screenshot of the measurement tool; carries no data.",
  "Figure B.47", str_c("Plots digital measurements against direct estimates for Kirkland and ",
                       "Coppock (2018, Figure 3). The deposit carries neither, and the markers ",
                       "overplot, so the plotted count is not read.")
)

float_cells <- gt |>
  filter(str_detect(location, "^(Table|Figure) ")) |>
  mutate(
    float = location,
    is_figure = str_starts(float, "Figure"),
    cell = if_else(is_figure, str_detect(claim_id, " :: (estimate|std_error)$"),
                   claim_type != "structural"),
    row_key = str_remove(claim_id, " :: (estimate|std_error)$")
  )

cell_counts <- float_cells |>
  summarize(
    published_numbers = sum(cell),
    covered = sum(cell & !is.na(match_rewrite)),
    reproduced_by_rewrite = sum(cell & match_rewrite %in% 1),
    .by = float
  )

# A plotted row is reproduced when both labels printed beside it are.
plotted_rows <- float_cells |>
  filter(is_figure, cell) |>
  summarize(reproduced = all(match_rewrite %in% 1), .by = c(float, row_key)) |>
  summarize(plotted = n(), plotted_reproduced = sum(reproduced), .by = float)

# Figure A.1 prints no labels; what it plots is the conditional effects the appendix counts,
# reproduced when that count is.
figure_a1_count <- gt |> filter(claim_id == "figure_a1 :: n_cates")
figure_a18_count <- gt |> filter(claim_id == "figure_a18 :: printed_estimates")
stopifnot(nrow(figure_a1_count) == 1, nrow(figure_a18_count) == 1)

unlabelled_figures <- tibble(
  float = c("Figure A.1", "Figure A.18"),
  plotted = as.integer(c(figure_a1_count$value_paper, figure_a18_count$value_paper)),
  plotted_reproduced = c(if_else(figure_a1_count$match_rewrite %in% 1, plotted[1], 0L), 0L)
)

float_notes <- c(
  "Table 2" = "The trimmed row's label prints a share the row does not retain (errata entry 12).",
  "Figure 3" = str_c("Two Sen (2017) SSI 2 estimates come from a deposited file one revision ",
                     "behind the figure (errata entry 15)."),
  "Table A.1" = str_c("Prints no numbers: one row per study and a prose description of its ",
                      "attributes. Its row count is a structural claim, corrected by errata entry 5."),
  "Figure A.1" = str_c("Prints no numbers on its face; plotted counts the conditional effects ",
                       "the appendix says it draws."),
  "Figure A.18" = str_c("Prints none of the ", figure_a18_count$value_rewrite, " estimates it is ",
                        "drawn from: the row labels push the panel off the page (errata entry 4).")
)

float_order <- function(float) {
  part <- str_match(float, "^(Table|Figure) ([AB]\\.)?(\\d+)$")
  tibble(appendix = replace_na(part[, 3], ""), kind = part[, 2], number = as.integer(part[, 4]))
}

float_coverage <- cell_counts |>
  bind_rows(tibble(float = appendix_b_floats$float, published_numbers = 0L, covered = 0L,
                   reproduced_by_rewrite = 0L)) |>
  left_join(bind_rows(plotted_rows, unlabelled_figures), by = "float") |>
  mutate(
    reproduced_by_archive = NA_integer_,
    note = coalesce(unname(float_notes[float]),
                    appendix_b_floats$note[match(float, appendix_b_floats$float)]),
    plotted = if_else(str_starts(float, "Table"), NA_integer_, plotted),
    plotted_reproduced = if_else(str_starts(float, "Table"), NA_integer_, plotted_reproduced)
  )

# Main text first, then appendix A, then appendix B, tables before figures within each.
float_coverage <- float_coverage |>
  bind_cols(float_order(float_coverage$float)) |>
  arrange(appendix, desc(kind), number) |>
  select(float, published_numbers, covered, reproduced_by_rewrite, reproduced_by_archive,
         plotted, plotted_reproduced, note)

# Every table carrying data is covered cell for cell, every float appears once, and every
# figure but the one whose markers are not read has a plotted count.
stopifnot(
  !anyDuplicated(float_coverage$float),
  !anyNA(float_order(float_coverage$float)$number),
  with(filter(float_coverage, str_starts(float, "Table")), all(covered == published_numbers)),
  with(filter(float_coverage, str_starts(float, "Figure"), float != "Figure B.46",
              float != "Figure B.47"), !anyNA(plotted) & !anyNA(plotted_reproduced))
)

write_csv(float_coverage, here::here("ground_truth", "float_coverage.csv"), na = "NA")
print(float_coverage, n = nrow(float_coverage), width = 200)

# Summary ----
print(gt |>
        summarize(claims = n(),
                  reproduced = sum(match_rewrite == 1, na.rm = TRUE),
                  disagree = sum(match_rewrite == 0, na.rm = TRUE),
                  no_counterpart = sum(is.na(match_rewrite)),
                  .by = location) |>
        arrange(location), n = Inf)

print(gt |> filter(match_rewrite == 0) |>
        select(claim_id, value_paper, value_rewrite, defect_locus), n = Inf)
