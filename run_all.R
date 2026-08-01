# schwarz_coppock_2022/run_all.R
# Runs the whole reproduction in order: fetch and verify the deposited archive, then
# every published table and figure, then the in-text quantities.
# Every script is self-contained and can also be run on its own.

library(here)
here::i_am("run_all.R")

# Deposited archive ----
# Downloads from Dataverse on a fresh clone; verifies checksums either way.
source(here::here("download_original.R"))

# Tables ----
source(here::here("maintained", "table_1_study_manifest.R"))
source(here::here("maintained", "table_2_meta_robustness.R"))
source(here::here("maintained", "table_a1_study_attributes.R"))

# Figures ----
# figure_a2_a45_cate_by_study.R writes 44 per-study appendix figures and is the slow
# step, at four seconds of the whole run's six.
source(here::here("maintained", "figure_1_sate_forest_plot.R"))
source(here::here("maintained", "figure_2_cate_candidate_race.R"))
source(here::here("maintained", "figure_3_cate_respondent_gender.R"))
source(here::here("maintained", "figure_4_cate_respondent_pid.R"))
source(here::here("maintained", "figure_a1_cate_candidate_attributes.R"))
source(here::here("maintained", "figure_a2_a45_cate_by_study.R"))

# In-text quantities ----
source(here::here("maintained", "text_in_text_numbers.R"))
