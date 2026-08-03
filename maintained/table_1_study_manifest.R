# schwarz_coppock_2022/maintained/table_1_study_manifest.R
# Output: output/table_1_study_manifest.csv
# Depends on: original/sate_estimates.rds, helpers.R
# Description: Table 1, the manifest of the 67 studies, with the totals row. The published
#   table prints the study label rather than study_id; study_id is carried here so that the
#   published cells can be keyed to a study without keying them to a printed label, whose
#   years were updated between the deposit and the page.

source(here::here("maintained", "helpers.R"))

sate_estimates <- read_rds(here::here("original", "sate_estimates.rds"))

study_rows <- sate_estimates |>
  transmute(
    study_id,
    study_name_short,
    n_subjects = formatC(n_subjects, format = "d", big.mark = ","),
    n_ratings = formatC(n_ratings, format = "d", big.mark = ","),
    have_data,
    sample_type
  ) |>
  arrange(desc(have_data), study_name_short)

totals_row <- sate_estimates |>
  summarise(
    study_id = "total",
    study_name_short = "Total",
    n_subjects = formatC(sum(n_subjects), format = "d", big.mark = ","),
    n_ratings = formatC(sum(n_ratings), format = "d", big.mark = ","),
    have_data = as.character(sum(have_data == "Yes")),
    sample_type = ""
  )

table_1 <- bind_rows(study_rows, totals_row)

write_csv(table_1, here::here("maintained", "output", "table_1_study_manifest.csv"))
print(totals_row)
