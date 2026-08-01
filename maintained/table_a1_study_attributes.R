# schwarz_coppock_2022/maintained/table_a1_study_attributes.R
# Output: output/table_a1_study_attributes.csv
# Depends on: original/cand_attributes_cate_estimates.rds, helpers.R
# Description: Table A.1, the attributes other than gender that each study randomized.
#   The published table lists them in prose the authors typed by hand; the deposit
#   carries only the variable names those descriptions were written from, so this table
#   lists the variable names instead. The study coverage is the checkable part.

source(here::here("maintained", "helpers.R"))

cand_attributes <- read_rds(here::here("original", "cand_attributes_cate_estimates.rds"))

table_a1 <- cand_attributes |>
  distinct(study_id, study_name, col) |>
  arrange(study_id, col) |>
  summarise(
    n_attributes = n(),
    attributes = paste(col, collapse = ", "),
    .by = c(study_id, study_name)
  ) |>
  left_join(count(cand_attributes, study_id, name = "n_cates"), by = "study_id") |>
  relocate(n_cates, .after = n_attributes)

write_csv(table_a1, here::here("maintained", "output", "table_a1_study_attributes.csv"))
print(table_a1 |> select(study_id, n_attributes, n_cates), n = nrow(table_a1))
