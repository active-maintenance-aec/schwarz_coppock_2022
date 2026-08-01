# schwarz_coppock_2022/maintained/text_in_text_numbers.R
# Output: output/text_in_text_numbers.csv
# Depends on: original/sate_estimates.rds, original/cand_attributes_cate_estimates.rds, helpers.R
# Description: The counts the article states in prose rather than in a table: how many of
#   the 67 study-level ATEs are positive, negative and significant, and how large the
#   candidate-attribute CATE set is.

source(here::here("maintained", "helpers.R"))

sate_estimates <- read_rds(here::here("original", "sate_estimates.rds"))
cand_attributes <- read_rds(here::here("original", "cand_attributes_cate_estimates.rds"))

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
    n_have_data = sum(have_data == "Yes")
  )

# Size of the candidate-attribute CATE set, cited in the text and in the appendix ----
attribute_counts <- cand_attributes |>
  summarise(
    n_cates = n(),
    n_attribute_studies = n_distinct(study_id),
    n_cates_positive = sum(estimate > 0),
    prop_cates_positive = mean(estimate > 0)
  )

in_text <- bind_cols(sign_counts, totals, attribute_counts)

write_csv(in_text, here::here("maintained", "output", "text_in_text_numbers.csv"))
print(in_text |> pivot_longer(everything(), names_to = "quantity", values_to = "value"), n = Inf)
