# Active Maintenance Report: schwarz_coppock_2022

2026-08-01

- [Summary](#summary)
  - [Does the deposited archive run?](#does-the-deposited-archive-run)
  - [Does the maintained rewrite reproduce the
    paper?](#does-the-maintained-rewrite-reproduce-the-paper)
- [Paper overview](#paper-overview)
- [Original archive reproducibility](#original-archive-reproducibility)
- [Errata](#errata)
- [Ground truth](#ground-truth)
- [Maintained rewrite](#maintained-rewrite)
- [Figures](#figures)
- [Rewrite verification](#rewrite-verification)
- [R environment](#r-environment)

*Drafted by Claude Opus 5 under the supervision of Alex Coppock.*

This repository holds the actively maintained replication code for
Schwarz and Coppock (2022), together with the reproducibility report
that documents what the original archive did and did not do. It is part
of a program applying the maintenance proposal in Peer, Orr and Coppock
(2021, *PS: Political Science & Politics*, doi
[10.1017/S1049096521000366](https://doi.org/10.1017/S1049096521000366))
to a set of published archives.

|  |  |
|----|----|
| Article | [10.1086/716290](https://doi.org/10.1086/716290) |
| Replication archive | [10.7910/DVN/R27ULT](https://doi.org/10.7910/DVN/R27ULT) |

**The data are not redistributed here.** The deposit is 0.5 MB across 12
files and lives at Harvard Dataverse, which is the only copy this
repository points at. `download_original.R` fetches it and verifies
every file; `original_manifest.csv` pins the file identifiers, sizes and
checksums, so the exact bytes this code was written against are recorded
in version control even though the bytes themselves are not.

**Repository layout.** `maintained/` is the maintained rewrite: one
script per published table or figure, writing to `output/`, which is
committed so a reader can compare a fresh run against it without
downloading anything. `ground_truth/` ties every published number to the
code that produces it. `original/` is created by the download script and
is deliberately absent from the repository. This file is the
reproducibility report, also available as a PDF in `report/`.

**License.** CC0 1.0 Universal, matching the terms of the deposit this
repository maintains. See `LICENSE`.

**To reproduce.** Clone or download the repository, open
`schwarz_coppock_2022.Rproj`, and run:

``` r
source("run_all.R")
```

That fetches the deposit, verifies its 12 files, and produces every
table and figure into `maintained/output/`. Required packages:
tidyverse, metafor, knitr, kableExtra, here. Paths resolve through
`here`, so nothing depends on the working directory. The full run takes
about six seconds. A successful run overwrites `maintained/output/`,
which is committed: **`git diff` on that folder is the reproduction
check.**

# Summary

Two questions, answered before the detail.

## Does the deposited archive run?

Yes, completely. All five analysis scripts execute without error on a
current R installation. There are no `setwd()` calls, no hardcoded
absolute paths and no functions called before they are defined, and
every package the scripts name still installs from CRAN, `rmeta` and
`ggstance` included. Nothing in the deposit needs a substitution to run.

What the archive does not do is write anything. All eight `ggsave()`
calls, all three `print.xtable()` calls and the single `sink()` block
are commented out in the deposited files, so a clean run leaves nothing
behind but a stray `Rplots.pdf` from the plots being printed to a
device. There is nothing to diff a rerun against, which is why the
maintained rewrite writes its outputs to disk.

## Does the maintained rewrite reproduce the paper?

Mostly, and the exceptions are in the article rather than in the code.
72 of the 78 verifiable ground truth claims match the published values
to reported precision, including every pooled estimate and standard
error printed on Figures 1 through 4 and all forty cells of Table 2. The
remaining 22 recorded quantities are ones the article never prints, most
of them confidence interval bounds that the forest plots draw but do not
label.

The 6 failures are all counts stated in prose, and none of them changes
a substantive conclusion:

- The article reports that of the 67 estimates, “47 are positive (23
  significant) and 18 are negative (11 significant).” The deposit has 47
  positive, **19** negative and one exactly zero, which is the only
  split that sums to 67; 47 plus 18 sums to 65. Neither of the two
  plausible significance rules recovers 23 and 11. The rule the
  archive’s own script applies, a confidence interval excluding zero,
  gives 29 positive-and-significant and 6 negative-and-significant.
  Testing p below 0.05 instead gives 19 and 2, and cannot be what was
  done in any case, because 19 of the 67 rows carry no p-value at all.
- The article describes Figure 3 as covering “the 36 experiments where
  we were able to identify respondent gender.” The deposit has 37, and
  so does the published figure, whose panel A prints 37 study rows.
- The discussion says “more than three-fourths of the studies show a
  positive effect.” The share is 47 of 67, or 70.1%.
- Table A.1 lists 43 studies where the appendix carries 44 per-study
  CATE figures; Simas and Murdoch (2019) has Figure A.44 but no Table
  A.1 row.

Every estimate, standard error, interval and p-value the article reports
reproduces exactly. What does not reproduce is a set of hand-counted
descriptions of those estimates.

# Paper overview

**Citation**: Schwarz, S. and Coppock, A. (2022). “What Have We Learned
about Gender from Candidate Choice Experiments? A Meta-Analysis of
Sixty-Seven Factorial Survey Experiments.” *The Journal of Politics*,
84(2), 655-668. DOI: 10.1086/716290

**Summary**: Sixty-seven conjoint and factorial candidate choice survey
experiments, fielded between 1982 and 2021 in more than twenty
countries, all randomized candidate gender alongside other candidate
attributes. Each study’s treatment effect of being described as a woman
is re-estimated on a common footing and the 67 estimates are pooled by
random-effects meta-analysis. The pooled effect is a gain of 1.8
percentage points of vote share for women candidates, with a confidence
interval from 1.1 to 2.5 points. The effect is larger for white than for
Black candidates in the US context (2.2 against 0.9 points), larger
among women respondents than men (3.0 against 0.9), and reverses sign
among Republicans (-1.4) while running positive among Democrats (4.2)
and Independents (3.3).

**What the deposit contains**: five pre-computed summary datasets and
five analysis scripts. The individual-level data belong to the authors
of the 67 original studies and are not redistributed, so the deposit
begins one level up, at estimated ATEs and CATEs with their standard
errors. Every number in the article is a function of those five files.

# Original archive reproducibility

| Script | Status on current R | Resolution |
|:---|:---|:---|
| helpers.R | Clean (sourced by all five scripts) | No changes required |
| meta_analyze_sates.R | Runs; writes nothing, every output call is commented out | No changes required |
| meta_analyze_cates_cand_race.R | Runs; writes nothing | No changes required |
| meta_analyze_cates_resp_gender.R | Runs; writes nothing | No changes required |
| meta_analyze_cates_resp_pid.R | Runs; writes nothing. Reports the Independent-Republican p-value from the Democrat-Republican statistic | Corrected in the rewrite; see Errata |
| meta_analyze_cates_cand_attributes.R | Runs; writes nothing. Its per-study figure loop is written but its writes are commented out | Restored in the rewrite as 44 written figures |

The deposited scripts on a current R installation.

Nothing here needs fixing to make the archive run. The deprecations are
all warnings rather than errors: `geom_errorbarh()` and the `%+%`
operator are deprecated in ggplot2 4.0.0 but still work,
`reshape2::melt()` and `dcast()` are superseded, and `dplyr::do()` has
been superseded since 1.0.0. What is wrong with this archive is the
p-value bug documented in the Errata, which is a logic error rather than
a run failure.

**`rmeta` and `ggstance` are both still installable.** The maintained
rewrite replaces `rmeta::meta.summaries()` with `metafor::rma()` on
maintenance grounds rather than availability grounds: `rmeta` has not
been updated since March 2018. The two implementations of
DerSimonian-Laird agree on every pooled estimate, standard error and
interval bound in the paper to more than ten significant figures.
`ggstance::position_dodgev()` resolves without incident from ggstance
0.3.7, which `coefplot` pulls in. It is dropped from the rewrite for a
different reason: it is inert. Building the layer with and without it
puts every point at the same coordinates, because every y value it is
asked to dodge is already unique, 954 distinct labels across 954 rows in
Figure A.1 and no repeated label within any study in Figures A.2 through
A.45.

**What the archive does not produce.** Every write in the deposit is
commented out: eight `ggsave()` calls, three `print.xtable()` calls and
one `sink()` block. Two of the commented `ggsave()` paths point at a
directory that was never part of the deposit
(`04_Drafts/current_draft/figures/`). The consequence is that the
deposit cannot be checked against itself. There is no committed output
to diff a rerun against, and a reader who runs all five scripts sees
console output and a `Rplots.pdf` and nothing else. Restoring those
writes, so that a rerun can be compared against a committed result, is
the single largest change the maintained rewrite makes.

# Errata

**The Independent-versus-Republican p-value is computed from the wrong
statistic.** In `meta_analyze_cates_resp_pid.R`, the block that tests
the two differences between pooled partisan CATEs computes the second
p-value from the first test’s statistic:

``` r
# Archive:
I_R_statistic = I_R_estimate / I_R_std.error,
I_R_p.value = 2 * pnorm(abs(D_R_statistic), lower.tail = FALSE)

# Rewrite:
I_R_p.value = 2 * pnorm(abs(I_R_statistic), lower.tail = FALSE)
```

`I_R_statistic` is computed on the line above and then never used, so
the reported Independent-Republican p-value is numerically identical to
the Democrat-Republican one.

| Quantity | Published | Original archive | Maintained rewrite |
|----|----|----|----|
| Independent minus Republican, p | not reported | 2.21e-10 (equals the D-R p-value) | 1.06e-07 |

The article states only that “the Republican estimate is statistically
significantly different from the Democratic and Independent estimates,”
which is true of both the wrong value and the right one. No published
number changes.

**Not corrected: the trimming rule.** Table 2’s last-but-one row is
labelled “Trimmed (middle 90% of estimates)” and the text says the row
drops “the bottom and top 5% of point estimates.” The code keeps
estimates above the 2nd percentile and below the 95th, retaining 61 of
67 studies. Correcting 0.02 to 0.05 would be a plausible reading of a
typo, but it is a change to a sample definition rather than to a
mechanical error, so the rewrite reproduces the published row as
computed and reports the alternative separately in
`output/table_2_trim_sensitivity.csv`. The symmetric rule the text
describes gives 0.020 over 59 studies against the published 0.018 over
61, so the robustness claim the row is making survives either reading.

**Not corrected: the year threshold.** The subset labelled “Post-2014
studies” is selected by `year > 2010`. The labels are nonetheless
accurate, because the sample contains no study fielded between 1998 and
2014, a gap the article notes in its fourth footnote, so every threshold
in that window produces the same two groups of 63 and 4.

# Ground truth

| Table or figure | Reproduces | Not stated in the article | Does not reproduce |
|:----------------|-----------:|--------------------------:|-------------------:|
| figure_1        |          5 |                         0 |                  0 |
| figure_2        |          6 |                         5 |                  0 |
| figure_3        |          6 |                         5 |                  1 |
| figure_4        |          7 |                         8 |                  0 |
| figure_a1       |          3 |                         0 |                  0 |
| table_1         |          3 |                         1 |                  0 |
| table_2         |         40 |                         1 |                  0 |
| table_a1        |          0 |                         0 |                  1 |
| text            |          2 |                         2 |                  4 |

Ground truth: 100 recorded quantities, by where the article states them.

`ground_truth/schwarz_coppock_2022_ground_truth.csv` records 100
quantities. `value_script` is what the deposited scripts produce through
`rmeta`, `value_rewrite` is what `maintained/` produces through
`metafor`, and `value_paper` is filled only by reading the article: from
Table 1 and Table 2, from the article’s prose, and from the
pooled-estimate labels printed inside Figures 1 through 4, which are
rasterized in the published PDF and were read off page renderings. Where
the article does not state a quantity the cell is empty and `match` is
`NA`, which is the case for every confidence interval bound in the four
figures: the forest plots draw the intervals but label only the estimate
and its standard error.

| Table or figure | Claim | Article | Deposit | Note |
|:---|:---|---:|---:|:---|
| text | n_negative | 18.00 | 19.000 | Text: 18 are negative. The deposit has 19 negative, one exactly zero and 47 positive, which sums to 67; the published 47 plus 18 sums to 65 |
| text | n_pos_and_sig_ci_rule | 23.00 | 29.000 | Text: 47 estimates are positive (23 significant). The archive script’s rule, a confidence interval excluding zero, gives 29 |
| text | n_neg_and_sig_ci_rule | 11.00 | 6.000 | Text: 18 are negative (11 significant). The archive script’s rule gives 6 |
| text | prop_positive | 0.75 | 0.701 | Discussion states more than three-fourths of the studies show a positive effect. value_paper records that lower bound rather than an equality; 47 of 67 is 0.701, so the claim does not hold |
| figure_3 | n_studies_in_text | 36.00 | 37.000 | Text: for the 36 experiments where we were able to identify respondent gender. The deposit and the paper’s own figure both have 37 |
| table_a1 | n_studies_listed | 43.00 | 44.000 | Published Table A.1 lists 43 studies. Simas and Murdoch (2019) has a CATE figure at A.44 but no Table A.1 row |

The six published quantities that do not reproduce.

# Maintained rewrite

| Script | Output |
|:---|:---|
| helpers.R | Packages, re_meta(), diff_test(), label formatting |
| table_1_study_manifest.R | table_1_study_manifest.csv |
| table_2_meta_robustness.R | table_2_meta_robustness.csv, table_2_trim_sensitivity.csv |
| table_a1_study_attributes.R | table_a1_study_attributes.csv |
| figure_1_sate_forest_plot.R | figure_1_sate_forest_plot.pdf and .png, figure_1_meta_summary.csv |
| figure_2_cate_candidate_race.R | figure_2_cate_candidate_race.pdf and .png, figure_2_meta_summary.csv, figure_2_diff_in_cates_cand_race.csv |
| figure_3_cate_respondent_gender.R | figure_3_cate_respondent_gender.pdf and .png, figure_3_meta_summary.csv, figure_3_diff_in_cates_resp_gender.csv |
| figure_4_cate_respondent_pid.R | figure_4_cate_respondent_pid.pdf and .png, figure_4_meta_summary.csv, figure_4_diff_in_cates_resp_pid.csv |
| figure_a1_cate_candidate_attributes.R | figure_a1_cate_candidate_attributes.pdf and .png, figure_a1_cate_summary.csv |
| figure_a2_a45_cate_by_study.R | 44 per-study appendix figures, figure_a2_a45_index.csv |
| text_in_text_numbers.R | text_in_text_numbers.csv |

The maintained rewrite.

**Substitutions.**

| Deposited | Maintained | Why |
|----|----|----|
| `rmeta::meta.summaries(method = "random")` | `metafor::rma(method = "DL")` | Same DerSimonian-Laird estimator; `rmeta` last updated 2018 |
| `do(tidy(with(., ...)))` | `group_by() \|> reframe(re_meta(...))` | `do()` superseded in dplyr 1.0.0 |
| `reshape2::melt()` and `dcast()` | `pivot_wider()`, or dropped | The melt-dcast-clean_names round trip existed only to line two pooled rows up side by side |
| `geom_errorbarh(height = 0)` | `geom_linerange()` | Deprecated in ggplot2 4.0.0 |
| `ggstance::position_dodgev()` | dropped | Still available, but inert: every y value it dodges is already unique |
| `ggplot() %+% data` | `ggplot(data)` | Deprecated in ggplot2 4.0.0 |
| commented-out `ggsave()`, `print.xtable()`, `sink()` | `ggsave()` and `write_csv()` to `output/` | So that a rerun can be diffed against a committed result |
| `%>%` | `\|>` | Native pipe |

**The estimator is named at every call site.** `re_meta()` in
`helpers.R` takes `method` as a required argument rather than defaulting
to `DL`, so no script can pool without saying which estimator it pooled
with. `table_2_meta_robustness.R` reports both: the DL columns reproduce
the published table, and REML columns sit beside them as an addition
rather than a correction. REML moves no estimate by more than 0.001 and
widens most intervals slightly, which is what a different heterogeneity
estimator on 67 studies should do.

**Coverage the archive states but does not deliver.** The deposit’s
README says `meta_analyze_cates_cand_attributes.R` produces “Figure A.1,
Figures A.2 through A.45, Table A.1.” It contains the code for all
three, with the writes commented out. The rewrite restores the 44
per-study figures, which take four seconds of the run’s six. Table A.1
is a partial exception: the published table pairs each study with a
prose description of its randomized attributes (“Race, ballot length”),
and the deposit carries only the variable names those descriptions were
written from, so `table_a1_study_attributes.csv` lists the variable
names and the counts instead. The study coverage is the checkable part,
and it is where the 43-against-44 discrepancy shows up.

# Figures

<img src="maintained/output/figure_1_sate_forest_plot.png"
style="width:100.0%"
alt="Figure 1. The 67 study-level ATEs and the pooled random-effects estimate." />

<img src="maintained/output/figure_2_cate_candidate_race.png"
style="width:100.0%"
alt="Figure 2. CATEs of candidate gender by candidate race." />

<img src="maintained/output/figure_3_cate_respondent_gender.png"
style="width:100.0%"
alt="Figure 3. CATEs of candidate gender by respondent gender." />

<img src="maintained/output/figure_4_cate_respondent_pid.png"
style="width:100.0%"
alt="Figure 4. CATEs of candidate gender by respondent party identification." />

<img src="maintained/output/figure_a1_cate_candidate_attributes.png"
style="width:100.0%"
alt="Figure A.1. All 954 CATEs of candidate gender conditional on the other randomized candidate attributes." />

# Rewrite verification

| Table or figure | Claim | Article | Deposit | Rewrite | Deposit matches | Rewrite matches |
|:---|:---|---:|---:|---:|---:|---:|
| table_1 | n_studies | 67.000 | 67.000 | 67.000 | 1 | 1 |
| table_1 | n_subjects_total | 120601.000 | 120601.000 | 120601.000 | 1 | 1 |
| table_1 | n_ratings_total | 774971.000 | 774971.000 | 774971.000 | 1 | 1 |
| figure_1 | re_meta_estimate_pp | 1.800 | 1.842 | 1.842 | 1 | 1 |
| figure_1 | re_meta_se_pp | 0.400 | 0.355 | 0.355 | 1 | 1 |
| figure_1 | re_meta_ci_low_pp | 1.100 | 1.147 | 1.147 | 1 | 1 |
| figure_1 | re_meta_ci_high_pp | 2.500 | 2.537 | 2.537 | 1 | 1 |
| figure_1 | n_studies | 67.000 | 67.000 | 67.000 | 1 | 1 |
| text | n_positive | 47.000 | 47.000 | 47.000 | 1 | 1 |
| text | n_negative | 18.000 | 19.000 | 19.000 | 0 | 0 |
| text | n_exactly_zero | 1.000 | 1.000 | 1.000 | 1 | 1 |
| text | n_pos_and_sig_ci_rule | 23.000 | 29.000 | 29.000 | 0 | 0 |
| text | n_neg_and_sig_ci_rule | 11.000 | 6.000 | 6.000 | 0 | 0 |
| text | prop_positive | 0.750 | 0.701 | 0.701 | 0 | 0 |
| table_2 | post_2014_studies_estimate | 0.021 | 0.021 | 0.021 | 1 | 1 |
| table_2 | post_2014_studies_std_error | 0.004 | 0.004 | 0.004 | 1 | 1 |
| table_2 | post_2014_studies_conf_low | 0.014 | 0.014 | 0.014 | 1 | 1 |
| table_2 | post_2014_studies_conf_high | 0.028 | 0.028 | 0.028 | 1 | 1 |
| table_2 | post_2014_studies_n_studies | 63.000 | 63.000 | 63.000 | 1 | 1 |
| table_2 | pre_1998_studies_estimate | -0.047 | -0.047 | -0.047 | 1 | 1 |
| table_2 | pre_1998_studies_std_error | 0.037 | 0.037 | 0.037 | 1 | 1 |
| table_2 | pre_1998_studies_conf_low | -0.118 | -0.118 | -0.118 | 1 | 1 |
| table_2 | pre_1998_studies_conf_high | 0.025 | 0.025 | 0.025 | 1 | 1 |
| table_2 | pre_1998_studies_n_studies | 4.000 | 4.000 | 4.000 | 1 | 1 |
| table_2 | convenience_student_sample_estimate | 0.023 | 0.023 | 0.023 | 1 | 1 |
| table_2 | convenience_student_sample_std_error | 0.006 | 0.006 | 0.006 | 1 | 1 |
| table_2 | convenience_student_sample_conf_low | 0.012 | 0.012 | 0.012 | 1 | 1 |
| table_2 | convenience_student_sample_conf_high | 0.034 | 0.034 | 0.034 | 1 | 1 |
| table_2 | convenience_student_sample_n_studies | 31.000 | 31.000 | 31.000 | 1 | 1 |
| table_2 | representative_sample_estimate | 0.015 | 0.015 | 0.015 | 1 | 1 |
| table_2 | representative_sample_std_error | 0.005 | 0.005 | 0.005 | 1 | 1 |
| table_2 | representative_sample_conf_low | 0.004 | 0.004 | 0.004 | 1 | 1 |
| table_2 | representative_sample_conf_high | 0.025 | 0.025 | 0.025 | 1 | 1 |
| table_2 | representative_sample_n_studies | 36.000 | 36.000 | 36.000 | 1 | 1 |
| table_2 | american_sample_estimate | 0.023 | 0.023 | 0.023 | 1 | 1 |
| table_2 | american_sample_std_error | 0.006 | 0.006 | 0.006 | 1 | 1 |
| table_2 | american_sample_conf_low | 0.011 | 0.011 | 0.011 | 1 | 1 |
| table_2 | american_sample_conf_high | 0.035 | 0.035 | 0.035 | 1 | 1 |
| table_2 | american_sample_n_studies | 35.000 | 35.000 | 35.000 | 1 | 1 |
| table_2 | non_american_sample_estimate | 0.014 | 0.014 | 0.014 | 1 | 1 |
| table_2 | non_american_sample_std_error | 0.005 | 0.005 | 0.005 | 1 | 1 |
| table_2 | non_american_sample_conf_low | 0.004 | 0.004 | 0.004 | 1 | 1 |
| table_2 | non_american_sample_conf_high | 0.023 | 0.023 | 0.023 | 1 | 1 |
| table_2 | non_american_sample_n_studies | 32.000 | 32.000 | 32.000 | 1 | 1 |
| table_2 | trimmed_middle_90_of_estimates_estimate | 0.018 | 0.018 | 0.018 | 1 | 1 |
| table_2 | trimmed_middle_90_of_estimates_std_error | 0.003 | 0.003 | 0.003 | 1 | 1 |
| table_2 | trimmed_middle_90_of_estimates_conf_low | 0.012 | 0.012 | 0.012 | 1 | 1 |
| table_2 | trimmed_middle_90_of_estimates_conf_high | 0.023 | 0.023 | 0.023 | 1 | 1 |
| table_2 | trimmed_middle_90_of_estimates_n_studies | 61.000 | 61.000 | 61.000 | 1 | 1 |
| table_2 | all_studies_estimate | 0.018 | 0.018 | 0.018 | 1 | 1 |
| table_2 | all_studies_std_error | 0.004 | 0.004 | 0.004 | 1 | 1 |
| table_2 | all_studies_conf_low | 0.011 | 0.011 | 0.011 | 1 | 1 |
| table_2 | all_studies_conf_high | 0.025 | 0.025 | 0.025 | 1 | 1 |
| table_2 | all_studies_n_studies | 67.000 | 67.000 | 67.000 | 1 | 1 |
| figure_2 | black_cand_estimate_pp | 0.900 | 0.924 | 0.924 | 1 | 1 |
| figure_2 | black_cand_se_pp | 0.400 | 0.404 | 0.404 | 1 | 1 |
| figure_2 | white_cand_estimate_pp | 2.200 | 2.243 | 2.243 | 1 | 1 |
| figure_2 | white_cand_se_pp | 0.700 | 0.705 | 0.705 | 1 | 1 |
| figure_2 | n_studies | 16.000 | 16.000 | 16.000 | 1 | 1 |
| figure_2 | diff_in_cates_pvalue | 0.104 | 0.104 | 0.104 | 1 | 1 |
| figure_3 | female_resp_estimate_pp | 3.000 | 3.006 | 3.006 | 1 | 1 |
| figure_3 | female_resp_se_pp | 0.500 | 0.532 | 0.532 | 1 | 1 |
| figure_3 | male_resp_estimate_pp | 0.900 | 0.855 | 0.855 | 1 | 1 |
| figure_3 | male_resp_se_pp | 0.500 | 0.510 | 0.510 | 1 | 1 |
| figure_3 | n_studies_in_figure | 37.000 | 37.000 | 37.000 | 1 | 1 |
| figure_3 | n_studies_in_text | 36.000 | 37.000 | 37.000 | 0 | 0 |
| figure_3 | diff_in_cates_pvalue | 0.004 | 0.004 | 0.004 | 1 | 1 |
| figure_4 | dem_resp_estimate_pp | 4.200 | 4.154 | 4.154 | 1 | 1 |
| figure_4 | dem_resp_se_pp | 0.800 | 0.799 | 0.799 | 1 | 1 |
| figure_4 | ind_resp_estimate_pp | 3.300 | 3.277 | 3.277 | 1 | 1 |
| figure_4 | ind_resp_se_pp | 0.800 | 0.805 | 0.805 | 1 | 1 |
| figure_4 | rep_resp_estimate_pp | -1.400 | -1.418 | -1.418 | 1 | 1 |
| figure_4 | rep_resp_se_pp | 0.400 | 0.363 | 0.363 | 1 | 1 |
| figure_4 | n_studies | 20.000 | 20.000 | 20.000 | 1 | 1 |
| figure_a1 | n_cates | 954.000 | 954.000 | 954.000 | 1 | 1 |
| figure_a1 | prop_cates_positive | 0.500 | 0.699 | 0.699 | 1 | 1 |
| figure_a1 | n_attribute_studies | 44.000 | 44.000 | 44.000 | 1 | 1 |
| table_a1 | n_studies_listed | 43.000 | 44.000 | 44.000 | 0 | 0 |

Every quantity the article states, against the deposit and the rewrite
(78 rows).

The rewrite reproduces the deposit exactly. Across all 100 recorded
quantities the two agree to better than 1e-10 in every case but one, the
Independent-Republican p-value corrected in the Errata above. Where the
deposit fails to match the article, so does the rewrite, which is the
intended behaviour: the failures are in counts the article states, not
in anything the code computes.

# R environment

| Package    | Version |
|:-----------|:--------|
| dplyr      | 1.2.1   |
| forcats    | 1.0.1   |
| ggplot2    | 4.0.3   |
| here       | 1.0.2   |
| kableExtra | 1.4.0   |
| knitr      | 1.51    |
| lubridate  | 1.9.5   |
| purrr      | 1.2.2   |
| readr      | 2.2.0   |
| stringr    | 1.6.0   |
| tibble     | 3.3.1   |
| tidyr      | 1.3.2   |
| tidyverse  | 2.0.0   |

Packages loaded when this report was rendered.

Rendered under R version 4.6.0 (2026-04-24) on macOS Tahoe 26.5.2.
