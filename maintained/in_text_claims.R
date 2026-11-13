# schwarz_coppock_2022/maintained/in_text_claims.R
# Output: printed CLAIM lines and a CLAIM SUMMARY line; no files
# Depends on: maintained/output/, ground_truth/published_claims.csv, errata_entries.csv,
#   helpers.R, excheckr
# Description: Every number the article and its appendix print, paired with the sentence
#   that prints it and with the value this pipeline produces, in the article's own units
#   and rounding, in the order a reader meets them.
#
#   This file recomputes. It reads the same output/ files ground_truth/build_ground_truth.R
#   reads and does its own selection, unit conversion and rounding, so the two arrive at
#   each claimed number by separate paths and a disagreement between them is a finding
#   rather than a repetition. Where this file formats a raw estimate, the ground truth
#   parses the label the plot or the table actually draws, and the reverse. It never reads
#   the ground truth's own comparison table, and it never refits: the pipeline has already
#   produced every estimate.
#
#   It may read ground_truth/published_claims.csv, which is the extraction rather than the
#   comparison, and errata_entries.csv, the errata spine. The first supplies the claim ids
#   and the article's own transcribed strings; the second says which of them a published
#   erratum corrects and to what. No value printed below is taken from either.
#
#   Each prose claim carries the article's sentence verbatim in a block comment, then a
#   "# covers:" tag naming the claim id in published_claims.csv it accounts for. Float
#   cells carry no sentence, because a table cell and a label on a forest plot are read off
#   a page rather than out of a sentence; they are printed in bulk, one line each.
#
#   Every claim prints one line reading
#
#       CLAIM <claim_id> = <value> || [verdict] <label>
#
#   through excheckr, at the precision the article prints. build_ground_truth.R runs this
#   file non-interactively, counts those lines and compares them claim by claim, so a block
#   that stops printing is a failure rather than silent coverage. The verdict is derived
#   from the extraction and the errata spine, never typed: [match] where the article and
#   this file agree, [corrected] where a quantity erratum names the claim and this value is
#   the correction it prints, [hedged] for a descriptive claim stated as a bound, and
#   [absent] where the deposit has no counterpart. [derived] is declared at the call site
#   for a claim the pipeline is known to contradict and no erratum corrects to a value:
#   each says why in its label, and build_ground_truth.R records where the fault lies. A
#   MISMATCH, STALE, DRIFT, or MISSING stops the run.
#
#   cat() is used here and nowhere else in this repository, per the in-text claims spec.
#
# Schwarz, Susanne, and Alexander Coppock. 2022. "What Have We Learned about Gender from
# Candidate Choice Experiments? A Meta-Analysis of Sixty-Seven Factorial Survey
# Experiments." The Journal of Politics 84(2): 655-668.

source(here::here("maintained", "helpers.R"))
library(excheckr)

options(width = 200)

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

published <- read_csv(here::here("ground_truth", "published_claims.csv"),
                      col_types = cols(.default = col_character()))

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
t1 <- out("table_1_study_manifest.csv")
t2 <- out("table_2_meta_robustness.csv")
t2_trim <- out("table_2_trim_sensitivity.csv")
ta1 <- out("table_a1_study_attributes.csv")
fa1 <- out("figure_a1_cate_summary.csv")
fa2_index <- out("figure_a2_a45_index.csv")
fa2_cells <- out("figure_a2_a45_plotted_estimates.csv")
counts <- out("text_in_text_numbers.csv")
studies <- out("text_study_level.csv")

# The errata spine ----
# Every column is read as character, so a corrected 0.7015 keeps its precision. The spine
# addresses the hand-kept ground truth, whose ids are not the extraction's, so each id a
# quantity erratum corrects is carried across to the extraction claim it is printed as.
# Entry 1 corrects one overstatement printed in two sentences, so its one ground truth row
# stands for two claims here. Note-form entries set no corrected value and are left out,
# as are the other classes, which correct a word or a label and leave every number where
# the article put it.
errata <- read_csv(here::here("errata_entries.csv"), col_types = cols(.default = col_character()))

ground_truth_to_extraction <- tribble(
  ~ground_truth_id, ~claim_id,
  "text_prop_positive", "theory :: share_positive_fraction",
  "text_prop_positive", "discussion :: share_positive_fraction",
  "text_n_pos_and_sig_ci_rule", "results :: n_positive_significant",
  "text_n_negative", "results :: n_negative",
  "text_n_neg_and_sig_ci_rule", "results :: n_negative_significant",
  "figure_3_n_studies_in_text", "results :: n_resp_gender_studies"
)

corrections <- errata |>
  filter(class == "quantity", !is.na(corrected_values)) |>
  mutate(ground_truth_id = str_split(claim_ids, ";"),
         corrected = str_split(corrected_values, ";")) |>
  unnest(c(ground_truth_id, corrected))

stopifnot(all(corrections$ground_truth_id %in% ground_truth_to_extraction$ground_truth_id))

errata_by_claim <- corrections |>
  inner_join(ground_truth_to_extraction, by = "ground_truth_id",
             relationship = "one-to-many") |>
  summarize(claim_ids = str_flatten(claim_id, ";"),
            corrected_values = str_flatten(corrected, ";"),
            .by = c(entry, class))

# label_column = "claim" prints the extraction's description beside each value. The
# extraction's expect column records the declarations made at the call sites below and is
# not passed here.
claim_start(published = published, errata = errata_by_claim, format = "id",
            label_column = "claim")

heading <- function(text) cat("\n", text, "\n", strrep("-", nchar(text)), "\n", sep = "")

# Accessors. Each stops if its filter does not select exactly one row, so a claim cannot
# quietly print a value read from a row that is not there.
one <- function(data, column, ...) {
  selected <- data |> filter(...)
  stopifnot(nrow(selected) == 1)
  value <- selected[[column]]
  stopifnot(!is.na(value))
  value
}

# ============================================================================
# Abstract
# ============================================================================

heading("Title and abstract (p. 655)")

# "What Have We Learned about Gender from Candidate Choice Experiments? A Meta-Analysis of
# Sixty-Seven Factorial Survey Experiments"
# The title spells its count out, which no scan for digits reaches.
# covers: title :: n_studies
claim("title :: n_studies", nrow(studies))

# "We collect 67 such studies from all over the world and reanalyze them using a
# standardized approach."
# covers: abstract :: n_studies
claim("abstract :: n_studies", nrow(studies))

# "We find that the average effect of being a woman (relative to a man) is a gain of
# approximately 2 percentage points."
# covers: abstract :: pooled_ate_pp
claim("abstract :: pooled_ate_pp", 100 * f1_pooled$estimate, digits = 0)

# ============================================================================
# Introduction (pp. 655-657)
# ============================================================================

heading("Introduction (pp. 655-657)")

# The introduction's other numbers are quoted from Kelley and McAllister (1984), King and
# Leigh (2010), Thomsen (2020) and Abramson, Kocak and Magazinnik (2019). Nothing in the
# deposit bears on any of them; they are classified transcribed or definitional in
# published_claims.csv and are checked against their sources rather than against a
# pipeline that never touches them.

# "We collected 67 conjoint and factorial candidate-choice experiments in which the
# researchers randomized candidate gender and studied respondents' vote choice."
# covers: intro :: n_studies_collected
claim("intro :: n_studies_collected", nrow(studies))

# "Our set of 67 includes studies conducted on six continents and in countries with widely
# varying levels of democratization."
# covers: intro :: n_studies_set
claim("intro :: n_studies_set", n_distinct(studies$study_id))

# The continent of each study is not a field the deposit carries, so the count is formed
# here from the country field, which it does carry. The mapping is a fact about geography
# and no published number enters it.
continent_of <- function(country) {
  case_when(
    country %in% c("USA") ~ "North America",
    country %in% c("Argentina", "Brazil", "Chile") ~ "South America",
    country %in% c("Denmark", "Germany", "Norway", "Romania", "Switzerland", "UK") ~ "Europe",
    country %in% c("Afghanistan", "India", "Japan", "Jordan", "Vietnam") ~ "Asia",
    country %in% c("Malawi", "Tunisia", "Zambia") ~ "Africa",
    country %in% c("Australia") ~ "Oceania"
  )
}

continents <- studies |>
  mutate(continent = continent_of(country)) |>
  count(continent, sort = TRUE)

stopifnot(!any(is.na(continents$continent)))

# covers: intro :: n_continents
claim("intro :: n_continents", nrow(continents))
cat("  evidence: ",
    str_flatten_comma(str_glue("{continents$continent} ({continents$n})")), "\n", sep = "")

# "Our meta-analytic estimate of the average effect of being a woman (vs. a man) is an
# approximately 2 percentage point increase in support."
# covers: intro :: pooled_ate_pp
claim("intro :: pooled_ate_pp", 100 * f1_pooled$estimate, digits = 0)

# ============================================================================
# Supply and demand explanations for candidate selection (pp. 657-659)
# ============================================================================

heading("Supply and demand explanations (pp. 657-659)")

# "Across the 67 studies we summarize, three-fourths find a positive effect of being
# described as a woman."
# covers: theory :: n_studies
claim("theory :: n_studies", nrow(studies))

# covers: theory :: share_positive_fraction
claim("theory :: share_positive_fraction", mean(studies$estimate > 0), digits = 3)
cat("  evidence: ", sum(studies$estimate > 0), " of ", nrow(studies),
    " estimates are positive; ", sum(studies$estimate < 0), " are negative and ",
    sum(studies$estimate == 0), " is exactly zero\n", sep = "")

# "That said, the majority of studies on gender and vote choice we revisit here were
# conducted in industrialized, democratic countries."
# The deposit records the country and nothing about its level of industrialization or
# democratization, so the classification below is applied here rather than read off. It is
# deliberately narrow: the claim holds a fortiori under any wider list, since the American
# studies alone are already a majority.
industrialized_democracies <- c("USA", "UK", "Japan", "Norway", "Australia", "Chile",
                                "Denmark", "Germany", "Switzerland")

# covers: theory :: majority_industrialized_democracies
claim("theory :: majority_industrialized_democracies",
      mean(studies$country %in% industrialized_democracies), digits = 3)
cat("  evidence: ", sum(studies$country %in% industrialized_democracies), " of ",
    nrow(studies), " studies were fielded in ",
    str_flatten_comma(sort(industrialized_democracies)),
    "; the ", sum(studies$country == "USA"), " American studies are a majority on their own\n",
    sep = "")

# ============================================================================
# Design (pp. 659-661)
# ============================================================================

heading("Design (pp. 659-661)")

# "In total, we located 67 experiments from 49 papers."
# covers: design :: n_studies_located
claim("design :: n_studies_located", nrow(studies))

# covers: design :: n_papers
# The deposit assigns 50 bibliography keys where the sentence says 49 papers, and it cannot
# say whether two of them are one source. Errata entry 13 carries the sentence as a note.
claim("design :: n_papers", n_distinct(studies$bib_entry),
      "distinct bibliography keys the deposit assigns, against the papers the sentence names",
      expect = "derived")

# "In 48 of the 67 cases, we were able to obtain replication data through either private
# communication or publicly available repositories."
# covers: design :: n_with_raw_data
claim("design :: n_with_raw_data", sum(studies$have_data == "Yes"))

# covers: design :: n_studies_denominator
claim("design :: n_studies_denominator", nrow(studies))

# "In the remaining 19 cases, we attempted to recover the necessary statistics from the
# article text or graphical presentation of results."
# covers: design :: n_without_raw_data
claim("design :: n_without_raw_data", sum(studies$have_data == "No"))

# "While over half our studies were conducted in the United States, we also include samples
# from Afghanistan, Argentina, Australia, Brazil, Chile, Denmark, Germany, India, Japan,
# Jordan, Malawi, Norway, Switzerland, Tunisia, the United Kingdom, Vietnam, and Zambia."
# covers: design :: share_us_studies
claim("design :: share_us_studies", mean(studies$country == "USA"), digits = 3)
cat("  evidence: ", sum(studies$country == "USA"), " of ", nrow(studies),
    " studies are American, drawn from ", n_distinct(studies$country), " countries\n", sep = "")

# "Overall, our database of studies includes 67 experiments from six continents across
# three and a half decades."
# covers: design :: n_studies_database
claim("design :: n_studies_database", nrow(studies))

# covers: design :: n_continents
claim("design :: n_continents", nrow(continents))

# covers: design :: span_decades
claim("design :: span_decades", (max(studies$year) - min(studies$year)) / 10, digits = 1)
cat("  evidence: the earliest study was fielded in ", min(studies$year),
    " and the latest in ", max(studies$year), "\n", sep = "")

# "Where the raw data are available, we estimate robust standard errors and 95% confidence
# intervals using the estimatr package for R."
# The confidence level is recoverable rather than asserted: the pooled interval's half
# width divided by its standard error is the critical value the level implies.
# covers: design :: confidence_level
claim("design :: confidence_level",
      100 * (1 - 2 * pnorm(-(f1_pooled$conf.high - f1_pooled$estimate) / f1_pooled$std.error)),
      digits = 0)

# ============================================================================
# Table 1: study manifest (pp. 660-661)
# ============================================================================

heading("Table 1, the 67-study manifest (pp. 660-661)")

# The published table prints subject and rating counts for each of the 67 studies and a
# totals row. No sentence, because a table cell is not read out of one. The counts are
# read back from the formatted table the pipeline writes, with the thousands separators
# the page prints removed.
table_1_cells <- published |>
  filter(str_starts(claim_id, "table_1 :: ")) |>
  mutate(
    study_id = str_split_i(claim_id, fixed(" :: "), 2),
    statistic = str_split_i(claim_id, fixed(" :: "), 3)
  )

for (i in seq_len(nrow(table_1_cells))) {
  cell <- table_1_cells[i, ]
  column <- if (cell$statistic == "n_subjects") "n_subjects" else "n_ratings"
  value <- one(t1, column, study_id == cell$study_id)
  claim(cell$claim_id, as.numeric(str_remove_all(value, ",")), digits = 0)
}

# ============================================================================
# Results: main finding (pp. 661-663)
# ============================================================================

heading("Results, main finding (pp. 661-663)")

# "Using random effects meta-analysis, we estimate the average ATE to be 1.8 percentage
# points, with a confidence interval stretching from 1.1 to 2.5 points."
# covers: results :: pooled_ate_pp
claim("results :: pooled_ate_pp", 100 * f1_pooled$estimate, digits = 1)

# covers: results :: pooled_ci_low_pp
claim("results :: pooled_ci_low_pp", 100 * f1_pooled$conf.low, digits = 1)

# covers: results :: pooled_ci_high_pp
claim("results :: pooled_ci_high_pp", 100 * f1_pooled$conf.high, digits = 1)

# "We see a very consistent pattern in favor of women candidates on average: 47 estimates
# are positive (23 significant) and 18 are negative (11 significant)."
# covers: results :: n_positive
claim("results :: n_positive", counts$n_positive)

# The article does not say which significance rule produced the parenthetical counts. Both
# candidate rules are printed. The confidence interval rule is the one the deposited script
# uses; the p-value rule cannot be what was done, because 19 of the 67 rows carry no
# p-value at all. Neither recovers 23 and 11, and no threshold rule can: the counts are
# monotone in the threshold, and the threshold that puts 23 estimates in the positive
# column leaves 5 in the negative one.
# covers: results :: n_positive_significant
claim("results :: n_positive_significant", counts$n_pos_sig_ci)
cat("  evidence: interval excluding zero gives ", counts$n_pos_sig_ci,
    " positive and ", counts$n_neg_sig_ci, " negative; p below 0.05 gives ",
    counts$n_pos_sig_p05, " and ", counts$n_neg_sig_p05, ", with ", counts$n_missing_p,
    " studies carrying no p-value\n", sep = "")

# covers: results :: n_negative
claim("results :: n_negative", counts$n_negative)

# covers: results :: n_negative_significant
claim("results :: n_negative_significant", counts$n_neg_sig_ci)

# "The estimates from Japan are truly mixed: one estimate is positive and significant (Kage
# et al. 2019), another is negative and significant (Ono and Yamada 2020), and a third
# comes in precisely at 0.0 (Horiuchi, Smith, and Yamamoto 2020)."
# covers: results :: horiuchi_estimate_pp
claim("results :: horiuchi_estimate_pp", 100 * one(studies, "estimate", study_id == "horiuchi_1"), digits = 1)

# "Our summary read of this collection of studies is that the average effect of being
# described as a woman candidate is an approximately 2 percentage point gain in vote
# margin and that this positive effect applies in most, but emphatically not all,
# contexts."
# covers: results :: pooled_ate_pp_restated
claim("results :: pooled_ate_pp_restated", 100 * f1_pooled$estimate, digits = 0)

# "Figure 1. Results of 67 candidate choice experiments on the effect of candidate gender"
# covers: figure_1 :: caption_n_studies
claim("figure_1 :: caption_n_studies", f1_pooled$n_studies)

# ============================================================================
# Figure 1: the 67 study-level ATEs (p. 662)
# ============================================================================

heading("Figure 1, estimates and standard errors printed beside every row (p. 662)")

# The forest plot prints an estimate and a standard error, in percentage points and to one
# decimal, beside each of its 68 rows. Those are published numbers and are compared here
# one by one.
figure_cells <- published |>
  filter(str_detect(claim_id, "^figure_[1-4] :: "),
         str_detect(claim_id, " :: (estimate|std_error)$")) |>
  mutate(
    figure = str_split_i(claim_id, fixed(" :: "), 1),
    statistic = str_split_i(claim_id, fixed(" :: "), -1),
    study_id = str_split_i(claim_id, fixed(" :: "), -2),
    panel_slug = if_else(str_count(claim_id, fixed(" :: ")) == 3,
                         str_split_i(claim_id, fixed(" :: "), 2), NA_character_)
  )

panel_name <- c(black = "Black candidate", white = "White candidate",
                female = "Female respondents", male = "Male respondents",
                democrat = "Democratic respondents", independent = "Independent respondents",
                republican = "Republican respondents")

plotted <- list(figure_1 = f1, figure_2 = f2, figure_3 = f3, figure_4 = f4)

# Two Figure 3 cells are the one place the deposit disagrees with a figure the article
# printed: the deposited respondent-gender file is a revision behind the Sen (2017) SSI 2
# estimate Figure 1 reproduces. Errata entry 15 carries them as a note, so each is declared
# rather than asserted, with the article's value in its label.
revised_since_deposit <- c(
  "figure_3 :: female :: sen_2 :: estimate" =
    "Sen SSI 2, female respondents, from a deposited file one revision behind the figure, which prints 6.0",
  "figure_3 :: male :: sen_2 :: estimate" =
    "Sen SSI 2, male respondents, from a deposited file one revision behind the figure, which prints 0.5"
)

print_figure_cells <- function(figure) {
  cells <- figure_cells |> filter(.data$figure == .env$figure)
  data <- plotted[[figure]]
  for (i in seq_len(nrow(cells))) {
    cell <- cells[i, ]
    row <- if (is.na(cell$panel_slug)) {
      filter(data, study_id == cell$study_id)
    } else {
      filter(data, study_id == cell$study_id, panel == panel_name[[cell$panel_slug]])
    }
    stopifnot(nrow(row) == 1)
    value <- if (cell$statistic == "estimate") row$estimate_100 else row$std.error_100
    # Rounded the way the figure script prints its labels. Horiuchi's standard error is
    # 0.05 to the last bit, which sprintf() prints as the 0.1 on the page and round()
    # takes to 0.0, so leaving the rounding to the comparison would score a cell the page
    # and the plot agree on as a mismatch.
    value <- as.numeric(sprintf("%.1f", value))
    if (cell$claim_id %in% names(revised_since_deposit)) {
      claim(cell$claim_id, value, revised_since_deposit[[cell$claim_id]], digits = 1,
            expect = "derived")
    } else {
      claim(cell$claim_id, value, digits = 1)
    }
  }
}

print_figure_cells("figure_1")

# ============================================================================
# Results: robustness subsets (pp. 662-663)
# ============================================================================

heading("Results, robustness subsets and Table 2 (pp. 662-663)")

# "This difference could be due to changing gender norms over time, although it is
# difficult to be sure because we were only able to include four studies from this period."
# covers: results :: n_pre_1998_studies
claim("results :: n_pre_1998_studies", counts$n_studies_1998_or_earlier)

# "Surprisingly, our sample includes no studies conducted between 1998 and 2014, but this
# drought is ended by the explosion of interest in candidate choice experiments following
# the publication of Hainmueller et al. (2014)."
# covers: results :: n_studies_1999_to_2013
claim("results :: n_studies_1999_to_2013", counts$n_studies_1999_to_2013)
cat("  evidence: fielding years present are ",
    str_flatten_comma(sort(unique(studies$year))), "\n", sep = "")

# "Effects appear to be somewhat larger, on average, among convenience or student samples
# as compared to representative samples (2.3 vs. 1.5 percentage points, respectively)."
# covers: results :: convenience_estimate_pp
claim("results :: convenience_estimate_pp",
      100 * one(t2, "estimate", group == "Convenience/student sample"), digits = 1)

# covers: results :: representative_estimate_pp
claim("results :: representative_estimate_pp",
      100 * one(t2, "estimate", group == "Representative sample"), digits = 1)

# "Average effects are slightly larger among American samples than non-American samples
# (2.3 vs. 1.4 percentage points, respectively)."
# covers: results :: american_estimate_pp
claim("results :: american_estimate_pp",
      100 * one(t2, "estimate", group == "American sample"), digits = 1)

# covers: results :: non_american_estimate_pp
claim("results :: non_american_estimate_pp",
      100 * one(t2, "estimate", group == "Non-American sample"), digits = 1)

# "However, all estimates for these subtypes, with the exception of the pre-1998 studies,
# are positive and statistically significant, and none of the differences across types are
# statistically significant."
subtypes <- t2 |>
  filter(group != "All studies") |>
  mutate(positive_and_significant = as.integer(estimate > 0 & conf.low > 0))

# covers: results :: subtypes_significant_except_pre_1998
claim("results :: subtypes_significant_except_pre_1998",
      as.numeric(str_extract(one(subtypes, "group", positive_and_significant == 0), "\\d{4}")),
      digits = 0)
cat("  evidence: ",
    str_flatten_comma(str_glue("{subtypes$group}: {sprintf('%.3f', subtypes$estimate)} \\
                                [{sprintf('%.3f', subtypes$conf.low)}, \\
                                {sprintf('%.3f', subtypes$conf.high)}]")), "\n", sep = "")

# The three contrasts the sentence speaks of are between disjoint sets of studies, so each
# difference has variance equal to the sum of the two variances. Differencing two pooled
# estimates already in output/ is a derivation, not a refit.
contrast_p <- function(group_a, group_b) {
  a <- filter(t2, group == group_a)
  b <- filter(t2, group == group_b)
  stopifnot(nrow(a) == 1, nrow(b) == 1)
  2 * pnorm(abs(a$estimate - b$estimate) / sqrt(a$std.error^2 + b$std.error^2), lower.tail = FALSE)
}

contrasts <- tibble(
  contrast = c("Post-2014 minus pre-1998", "Convenience/student minus representative",
               "American minus non-American"),
  p_value = c(contrast_p("Post-2014 studies", "Pre-1998 studies"),
              contrast_p("Convenience/student sample", "Representative sample"),
              contrast_p("American sample", "Non-American sample"))
)

# covers: results :: no_significant_differences_across_types
claim("results :: no_significant_differences_across_types", min(contrasts$p_value), digits = 2)
cat("  evidence: ",
    str_flatten_comma(str_glue("{contrasts$contrast}: p = {sprintf('%.3f', contrasts$p_value)}")),
    "\n", sep = "")

# "Importantly, even when we trim the bottom and top 5% of point estimates from our
# analysis, our meta-analytic estimate remains robust, suggesting that our findings are not
# merely attributable to a handful of outlying studies."
# The deposited code trims above the 2nd and below the 95th percentile, not symmetrically
# at 5, so the percentile the sentence names is recovered here from the retained counts
# rather than asserted.
trim_archive <- t2_trim |> filter(str_starts(rule, "Archive"))
trim_symmetric <- t2_trim |> filter(str_starts(rule, "Text"))

# covers: results :: trim_percent
# The line prints the bottom tail and names the top one in its label. Errata entry 12
# carries the sentence as a note, since the deposit cannot say which rule was intended.
claim("results :: trim_percent", 100 * trim_archive$n_dropped_low / trim_archive$n_all,
      str_glue("per cent of estimates the published row trims from the bottom, against the ",
               "5 the sentence names for each tail; it trims ",
               "{sprintf('%.1f', 100 * trim_archive$n_dropped_high / trim_archive$n_all)} ",
               "from the top"),
      digits = 1, expect = "derived")
cat("  evidence: the published row drops ", trim_archive$n_dropped_low, " study at the bottom and ",
    trim_archive$n_dropped_high, " at the top, retaining ", trim_archive$n_studies, " of ",
    trim_archive$n_all, " at ", sprintf("%.3f", trim_archive$estimate),
    "; a symmetric five per cent rule retains ", trim_symmetric$n_studies, " at ",
    sprintf("%.3f", trim_symmetric$estimate), "\n", sep = "")

# "Trimmed (middle 90% of estimates)"
# covers: table_2 :: trimmed :: label_percent
claim("table_2 :: trimmed :: label_percent",
      100 * trim_archive$n_studies / nrow(studies),
      "per cent of estimates the trimmed row retains, against the label; see errata entry 12",
      digits = 0, expect = "derived")

# The published table, cell by cell, read back from the formatted entries the pipeline
# writes rather than from the numbers behind them. No sentence: a table cell is not read
# out of one.
table_2_groups <- c(post_2014 = "Post-2014 studies", pre_1998 = "Pre-1998 studies",
                    convenience_student = "Convenience/student sample",
                    representative = "Representative sample", american = "American sample",
                    non_american = "Non-American sample",
                    trimmed = "Trimmed (middle 90% of estimates)", all_studies = "All studies")

table_2_cells <- published |>
  filter(str_starts(claim_id, "table_2 :: "), str_detect(claim_id, "label_percent", negate = TRUE)) |>
  mutate(
    slug = str_split_i(claim_id, fixed(" :: "), 2),
    statistic = str_split_i(claim_id, fixed(" :: "), 3)
  )

for (i in seq_len(nrow(table_2_cells))) {
  cell <- table_2_cells[i, ]
  row <- t2 |> filter(group == table_2_groups[[cell$slug]])
  stopifnot(nrow(row) == 1)
  value <- switch(cell$statistic,
                  estimate = row$estimate,
                  std_error = row$std.error,
                  conf_low = row$conf.low,
                  conf_high = row$conf.high,
                  n_studies = row$n_studies)
  claim(cell$claim_id, value, digits = if (cell$statistic == "n_studies") 0 else 3)
}

# ============================================================================
# Results: effects conditional on candidate characteristics (p. 663)
# ============================================================================

heading("Results, effects conditional on candidate characteristics (p. 663)")

# "Most of the studies in our sample randomized other candidate features beyond gender,
# allowing us to study whether the positive effects we observe on average hold for
# candidates of different parties, ages, races, professions, marital status, or political
# experiences, among other attributes."
# covers: results :: most_studies_randomized_other_attributes
claim("results :: most_studies_randomized_other_attributes",
      fa1$n_studies / nrow(studies), digits = 3)
cat("  evidence: ", fa1$n_studies, " of ", nrow(studies),
    " studies contribute conditional effects on another randomized attribute\n", sep = "")

# "In the appendix, we show 954 separate CATEs, the majority of which are positive."
# covers: results :: n_cates
claim("results :: n_cates", fa1$n_cates)

# covers: results :: cates_majority_positive
claim("results :: cates_majority_positive", fa1$prop_positive, digits = 3)
cat("  evidence: ", fa1$n_positive, " of ", fa1$n_cates,
    " conditional effects are positive, across ", fa1$n_studies, " studies\n", sep = "")

# "Here we focus on candidate race in the US context, since we have a large number of
# studies (16) over which to pool."
# covers: results :: n_cand_race_studies
claim("results :: n_cand_race_studies", one(f2_pooled, "n_studies", cand_white == "White candidate"))

# "As shown in figure 2, the effects are slightly larger among white candidates (2.2
# percentage points) than black candidates (0.9 points), although the difference between
# these two estimates is not statistically significant (p p .104)."
# covers: results :: white_cand_cate_pp
claim("results :: white_cand_cate_pp",
      100 * one(f2_pooled, "estimate", cand_white == "White candidate"), digits = 1)

# covers: results :: black_cand_cate_pp
claim("results :: black_cand_cate_pp",
      100 * one(f2_pooled, "estimate", cand_white == "Black candidate"), digits = 1)

# covers: results :: cand_race_diff_p
claim("results :: cand_race_diff_p", f2_diff$p.value, digits = 3)

heading("Figure 2, estimates and standard errors printed beside every row (p. 663)")
print_figure_cells("figure_2")

# ============================================================================
# Results: effects conditional on respondent characteristics (pp. 663-664)
# ============================================================================

heading("Results, effects conditional on respondent characteristics (pp. 663-664)")

# "Figure 3 shows the CATEs of candidate gender, conditional on respondent gender, for the
# 36 experiments where we were able to identify respondent gender."
# covers: results :: n_resp_gender_studies
claim("results :: n_resp_gender_studies", one(f3_pooled, "n_studies", resp_female == "Female respondents"))

# "The effect is positive for both groups: 3.0 points among women and 0.9 points among men.
# The difference between the two estimates is itself statistically significant (p p .004),
# providing some support for the gender affinity hypothesis."
# covers: results :: female_resp_cate_pp
claim("results :: female_resp_cate_pp",
      100 * one(f3_pooled, "estimate", resp_female == "Female respondents"), digits = 1)

# covers: results :: male_resp_cate_pp
claim("results :: male_resp_cate_pp",
      100 * one(f3_pooled, "estimate", resp_female == "Male respondents"), digits = 1)

# covers: results :: resp_gender_diff_p
claim("results :: resp_gender_diff_p", f3_diff$p.value, digits = 3)

heading("Figure 3, estimates and standard errors printed beside every row (p. 664)")
print_figure_cells("figure_3")

heading("Results, effects by respondent partisanship (p. 664)")

# "In figure 4, we summarize the results of 20 studies conducted in the US context, for
# which the partisan identification of respondents was available."
# covers: results :: n_resp_pid_studies
claim("results :: n_resp_pid_studies",
      one(f4_pooled, "n_studies", resp_pid_3 == "Democratic respondents"))

# "The effect is negative among Republicans (21.4 points) but 3.3 percentage points for
# Independents and 4.2 points for Democrats."
# The published minus sign is typeset as a 2 in the article's text layer.
# covers: results :: republican_cate_pp
claim("results :: republican_cate_pp",
      100 * one(f4_pooled, "estimate", resp_pid_3 == "Republican respondents"), digits = 1)

# covers: results :: independent_cate_pp
claim("results :: independent_cate_pp",
      100 * one(f4_pooled, "estimate", resp_pid_3 == "Independent respondents"), digits = 1)

# covers: results :: democrat_cate_pp
claim("results :: democrat_cate_pp",
      100 * one(f4_pooled, "estimate", resp_pid_3 == "Democratic respondents"), digits = 1)

# "The Republican estimate is statistically significantly different from the Democratic and
# Independent estimates."
# covers: results :: republican_differs_from_dem_and_ind
claim("results :: republican_differs_from_dem_and_ind", max(f4_diff$p.value), digits = 2)
cat("  evidence: ",
    str_flatten_comma(str_glue("{f4_diff$comparison}: p = {format(f4_diff$p.value, digits = 3)}")),
    "\n", sep = "")

heading("Figure 4, estimates and standard errors printed beside every row (p. 664)")
print_figure_cells("figure_4")

# ============================================================================
# Discussion (pp. 664-665)
# ============================================================================

heading("Discussion (pp. 664-665)")

# "We have summarized the statistical evidence on gender from 67 candidate choice
# experiments."
# covers: discussion :: n_studies
claim("discussion :: n_studies", nrow(studies))

# "Our main finding is that the average effect of being a woman candidate is a 1.8
# percentage point increase in support."
# covers: discussion :: pooled_ate_pp
claim("discussion :: pooled_ate_pp", 100 * f1_pooled$estimate, digits = 1)

# "We observe considerable study-to-study variation, although more than three-fourths of
# the studies show a positive effect."
# covers: discussion :: share_positive_fraction
claim("discussion :: share_positive_fraction", mean(studies$estimate > 0), digits = 3)
cat("  evidence: ", sum(studies$estimate > 0), " of ", nrow(studies),
    " estimates are positive, a share of ", sprintf("%.1f", 100 * mean(studies$estimate > 0)),
    " per cent\n", sep = "")

# "However, on the whole, our results do not depend on other candidate characteristics such
# as experience, age, or occupation as we detail in the appendix (see figs. A.2-A.45,
# available online)."
# covers: discussion :: appendix_first_study_figure
claim("discussion :: appendix_first_study_figure", min(fa2_index$figure_number))

# covers: discussion :: appendix_last_study_figure
claim("discussion :: appendix_last_study_figure", max(fa2_index$figure_number))

# ============================================================================
# Appendix A: study-by-study CATEs (pp. 2-33)
# ============================================================================

heading("Appendix A (pp. 2-33)")

# "Table A.1: Overview of Attributes (Other Than Gender) Included in Study Designs"
# The published table lists one row per study whose other randomized attributes the
# appendix reports. The count is the table's own row count.
# covers: table_a1 :: n_studies_listed
# The table lists 43; errata entry 5 restores the missing row, a float correction with no
# corrected value to score against, so the count is declared rather than asserted.
claim("table_a1 :: n_studies_listed", nrow(ta1),
      "studies with per-study appendix figures, against the rows the published table lists",
      expect = "derived")

# "Figure A.1 shows the distribution of CATEs, conditional on each of the attributes listed
# in Table A.1."
# The count is formed here by adding up the per-study figures the appendix draws, which is
# a different path to it from the pooled count the results section quotes.
# covers: figure_a1 :: n_cates
claim("figure_a1 :: n_cates", sum(fa2_index$n_cates))

heading("Figures A.2 to A.45, estimates and standard errors printed beside every row")

# Each of the 44 per-study appendix figures prints an estimate and a standard error beside
# every row, exactly as the four main figures do. Those labels are compared here one by one
# against what the pipeline plots. No sentence: they are read off a page.
appendix_cells <- published |>
  filter(str_detect(claim_id, "^figure_a\\d+ :: "), !str_starts(claim_id, "figure_a1 :: "),
         str_detect(claim_id, " :: (estimate|std_error)$")) |>
  mutate(
    statistic = str_split_i(claim_id, fixed(" :: "), -1),
    cate_label = str_split_i(claim_id, fixed(" :: "), -2),
    figure_number = as.integer(str_remove(str_split_i(claim_id, fixed(" :: "), 1), "figure_a"))
  )

fa2_keyed <- fa2_cells |> mutate(cate_label = str_replace_all(CATE_label, "−", "-"))

for (i in seq_len(nrow(appendix_cells))) {
  cell <- appendix_cells[i, ]
  row <- fa2_keyed |>
    filter(figure_number == cell$figure_number, cate_label == cell$cate_label)
  stopifnot(nrow(row) == 1)
  value <- if (cell$statistic == "estimate") row$estimate_100 else row$std.error_100
  # Rounded the way the figure script prints its labels, as for the main figures.
  claim(cell$claim_id, as.numeric(sprintf("%.1f", value)), digits = 1)
}

# Figure A.18 is Costa (2020), whose attribute levels are whole tweets. At the width the
# appendix uses, the row labels push the panel, the points, the intervals, the estimate
# labels and the axis off the right edge of the page, so the published figure prints none
# of its ten estimates and its axis title is cut off mid-word. The pipeline draws ten.
# covers: figure_a18 :: printed_estimates
# Errata entry 4 reprints the figure legibly. The line counts the estimates the pipeline
# draws, against the none the published figure shows.
claim("figure_a18 :: printed_estimates", sum(fa2_cells$figure_number == 18),
      "estimates the pipeline draws in Figure A.18, against the none the published figure shows",
      expect = "derived")

# ============================================================================
# Appendix B: digital measurement of coefficient estimates (pp. 34-35)
# ============================================================================

heading("Appendix B (pp. 34-35)")

# "Figure 1 in the main text includes estimates from nine experiments in seven papers that
# we were only able to obtain by digitally measuring the coefficient plots included in the
# published papers."
# The deposit records how each study's estimate was recovered in a free-text note field;
# the studies whose note says the bounds and standard error were estimated from a picture
# are the digitally measured ones.
measured <- studies |> filter(digitally_measured == 1)

# covers: appendix_b :: n_digitally_measured_experiments
# The note field marks ten experiments in eight papers where the appendix says nine in
# seven, and a free-text field cannot say which count was meant. Errata entry 14 carries
# the sentence as a note.
claim("appendix_b :: n_digitally_measured_experiments", nrow(measured),
      "experiments the deposit's note field marks as digitally measured, against the nine the appendix names",
      expect = "derived")

# covers: appendix_b :: n_digitally_measured_papers
claim("appendix_b :: n_digitally_measured_papers", n_distinct(measured$bib_entry),
      "papers those experiments come from, against the seven the appendix names",
      expect = "derived")
cat("  evidence: ", str_flatten_comma(measured$study_name_short), "\n", sep = "")

# "The average absolute error is 0.000747, or 0.075 percentage points. The correlation of
# the two sets of estimates is 0.9999726."
# The validation compares digital measurements of Kirkland and Coppock (2018, Figure 3)
# against estimates computed from their raw data. The deposit carries neither, so neither
# number is reconstructible from it; see build_ground_truth.R, which records the reason.
# covers: appendix_b :: mean_absolute_error
claim("appendix_b :: mean_absolute_error", NA_real_, expect = "absent")

# covers: appendix_b :: mean_absolute_error_pp
claim("appendix_b :: mean_absolute_error_pp", NA_real_, expect = "absent")

# covers: appendix_b :: correlation
claim("appendix_b :: correlation", NA_real_, expect = "absent")

# Gates ----
# assert_claims() stops on any failing verdict, on a quantity erratum whose claim was not
# printed or did not score [corrected], and on any difference between the claims printed
# and those the extraction marks needs_block. claim_summary() prints the verdict counts.
assert_claims()
invisible(claim_summary())
