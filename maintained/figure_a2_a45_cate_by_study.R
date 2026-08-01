# schwarz_coppock_2022/maintained/figure_a2_a45_cate_by_study.R
# Output: output/figure_a2_<study_id>.pdf through output/figure_a45_<study_id>.pdf,
#   output/figure_a2_a45_index.csv
# Depends on: original/cand_attributes_cate_estimates.rds, helpers.R
# Description: Figures A.2 through A.45, one per study, showing that study's CATEs of
#   candidate gender at each level of its other randomized attributes.

source(here::here("maintained", "helpers.R"))

cand_attributes <- read_rds(here::here("original", "cand_attributes_cate_estimates.rds"))

# Appendix figure numbering ----
# Sorting on study_id reproduces the order the published appendix uses, so the first
# study is Figure A.2 and the last is Figure A.45.
index <- cand_attributes |>
  distinct(study_id, study_name) |>
  arrange(study_id) |>
  mutate(
    figure_number = row_number() + 1,
    n_cates = map_int(study_id, ~ sum(cand_attributes$study_id == .x)),
    file = str_glue("figure_a{figure_number}_{study_id}.pdf")
  )

write_csv(index, here::here("maintained", "output", "figure_a2_a45_index.csv"))
print(index, n = nrow(index))

# One figure per study ----
# Mo (2015) is the one study whose CATEs run past the shared plus or minus 20 point
# window, and the archive widens its axis to plus or minus 80. Henderson et al., and the
# two Bansak et al. studies, carry enough attribute levels that the archive shrinks their
# axis text. Both exceptions are reproduced here.
draw_study <- function(study, figure_number, file) {
  df_study <- cand_attributes |> filter(study_id == study)
  wide_axis <- study == "mo_1"
  many_rows <- study %in% c("henderson_1", "bansak_1", "bansak_2")
  x_limit <- if (wide_axis) 80 else 20

  g <- ggplot(df_study, aes(x = estimate_100, y = CATE_label)) +
    geom_point(alpha = 0.5) +
    geom_linerange(aes(xmin = conf.low_100, xmax = conf.high_100), alpha = 0.5) +
    geom_vline(xintercept = 0, linetype = "dashed") +
    geom_text(
      x = x_limit,
      aes(y = CATE_label, label = se_entry),
      hjust = 1,
      size = if (many_rows) 1 else 3,
      nudge_y = 0.2
    ) +
    coord_cartesian(xlim = c(-x_limit, x_limit)) +
    xlab("CATE estimate in percentage points") +
    theme_bw() +
    theme(axis.title.y = element_blank())

  if (many_rows) {
    g <- g + theme(axis.text.y = element_text(size = 4))
    height <- 2 + nrow(df_study) * 0.08
  } else {
    height <- 1 + nrow(df_study) * 0.15
  }

  ggsave(here::here("maintained", "output", file), g, width = 6.5, height = height)
}

pwalk(list(index$study_id, index$figure_number, index$file), draw_study)
