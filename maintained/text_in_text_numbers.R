# schwarz_coppock_2022/maintained/text_in_text_numbers.R
# Output: output/text_in_text_numbers.csv, output/text_study_level.csv
# Depends on: original/sate_estimates.rds, original/cand_attributes_cate_estimates.rds, helpers.R
# Description: The counts the article states in prose rather than in a table: how many of
#   the 67 study-level ATEs are positive, negative and significant, how many papers and
#   countries they come from, how they are spread over time, and how large the
#   candidate-attribute CATE set is. Also writes the study-level frame those counts are
#   taken from, which is what the article's descriptive claims about shape and spread are
#   checked against, since a pooled summary cannot answer a question about a distribution.

source(here::here("maintained", "helpers.R"))

sate_estimates <- read_rds(here::here("original", "sate_estimates.rds"))
cand_attributes <- read_rds(here::here("original", "cand_attributes_cate_estimates.rds"))

# Study-level frame ----
# One row per study, carrying what the article's descriptive sentences speak about: sign,
# significance, source paper, country, year, sample type, and whether the estimate was
# recovered by measuring a coefficient plot rather than from raw data.
study_level <- sate_estimates |>
  transmute(
    study_id,
    study_name_short,
    bib_entry,
    country,
    year,
    sample_type,
    have_data,
    note,
    digitally_measured =
      if_else(str_detect(coalesce(note, ""), "bounds and se from picture"), 1, 0),
    n_subjects,
    n_ratings,
    estimate,
    std.error,
    p.value,
    conf.low,
    conf.high
  )

write_csv(study_level, here::here("maintained", "output", "text_study_level.csv"))

# Sign and significance of the 67 study-level ATEs ----
# The article reports the significant counts in parentheses without saying which rule
# produced them, so both candidate rules are computed. The confidence interval rule is
# the one the archive's own script uses. Nineteen of the 67 rows carry no p-value, which
# is why the two rules do not sum to the same total.
sign_counts <- sate_estimates |>
  summarise(
    n_studies = n(),
    n_positive = sum(estimate > 0),
    n_negative = sum(estimate < 0),
    n_exactly_zero = sum(estimate == 0),
    prop_positive = mean(estimate > 0),
    n_pos_sig_ci = sum(conf.low > 0),
    n_neg_sig_ci = sum(conf.high < 0),
    n_not_sig_ci = sum(conf.low < 0 & conf.high > 0),
    n_pos_sig_p05 = sum(estimate > 0 & p.value < 0.05, na.rm = TRUE),
    n_neg_sig_p05 = sum(estimate < 0 & p.value < 0.05, na.rm = TRUE),
    n_missing_p = sum(is.na(p.value))
  )

# Totals reported in Table 1 and repeated in the text ----
totals <- sate_estimates |>
  summarise(
    n_subjects = sum(n_subjects),
    n_ratings = sum(n_ratings),
    n_have_data = sum(have_data == "Yes"),
    n_no_data = sum(have_data == "No")
  )

# Provenance and coverage of the sample ----
# n_papers counts the distinct bibliography keys the deposit assigns to the 67 studies.
# The digital-measurement counts read the deposit's own note field, which records for each
# study how its estimate was recovered.
provenance <- sate_estimates |>
  summarise(
    n_papers = n_distinct(bib_entry),
    n_countries = n_distinct(country),
    n_us_studies = sum(country == "USA"),
    prop_us_studies = mean(country == "USA"),
    first_year = min(year),
    last_year = max(year),
    n_studies_1999_to_2013 = sum(year > 1998 & year < 2014),
    n_studies_1998_or_earlier = sum(year <= 1998),
    n_digitally_measured = sum(str_detect(coalesce(note, ""), "bounds and se from picture")),
    n_papers_digitally_measured =
      n_distinct(bib_entry[str_detect(coalesce(note, ""), "bounds and se from picture")])
  )

# Size of the candidate-attribute CATE set, cited in the text and in the appendix ----
attribute_counts <- cand_attributes |>
  summarise(
    n_cates = n(),
    n_attribute_studies = n_distinct(study_id),
    n_cates_positive = sum(estimate > 0),
    prop_cates_positive = mean(estimate > 0)
  )

in_text <- bind_cols(sign_counts, totals, provenance, attribute_counts)

write_csv(in_text, here::here("maintained", "output", "text_in_text_numbers.csv"))
print(in_text |> pivot_longer(everything(), names_to = "quantity", values_to = "value"), n = Inf)
