# schwarz_coppock_2022/maintained/figure_2_cate_candidate_race.R
# Output: output/figure_2_cate_candidate_race.pdf, output/figure_2_cate_candidate_race.png,
#   output/figure_2_meta_summary.csv, output/figure_2_diff_in_cates_cand_race.csv,
#   output/figure_2_plotted_estimates.csv
# Depends on: original/cand_race_cate_estimates.rds, helpers.R
# Description: Figure 2, CATEs of candidate gender by candidate race across the 16 US
#   studies that randomized both, with the test for the difference between the two pools.

source(here::here("maintained", "helpers.R"))

# The deposited object arrives grouped by cand_white and study_id. The grouping is
# dropped on read so that every summary below states its own grouping.
cand_race <- read_rds(here::here("original", "cand_race_cate_estimates.rds")) |>
  ungroup()

pooled <- cand_race |>
  group_by(cand_white) |>
  reframe(re_meta(estimate, std.error, method = "DL"))

write_csv(pooled, here::here("maintained", "output", "figure_2_meta_summary.csv"))
print(pooled)

# Difference between the two pooled CATEs ----
white_row <- pooled |> filter(cand_white == "White candidate")
black_row <- pooled |> filter(cand_white == "Black candidate")

diff_result <- diff_test(
  white_row$estimate, white_row$std.error,
  black_row$estimate, black_row$std.error
) |>
  mutate(comparison = "White candidate minus Black candidate") |>
  relocate(comparison)

write_csv(diff_result, here::here("maintained", "output", "figure_2_diff_in_cates_cand_race.csv"))
print(diff_result)

summary_df <- pooled |>
  mutate(
    study_name_short = "Random-effects meta-analysis",
    estimate_100 = estimate * 100,
    std.error_100 = std.error * 100,
    conf.high_100 = conf.high * 100,
    conf.low_100 = conf.low * 100
  )

# Studies are ordered by how much the white-candidate CATE exceeds the black-candidate one.
difference_df <- cand_race |>
  select(study_name_short, cand_white, estimate) |>
  pivot_wider(names_from = cand_white, values_from = estimate) |>
  mutate(
    difference = `White candidate` - `Black candidate`,
    study_name_short_fac = fct_reorder(study_name_short, difference)
  )

gg_df <- cand_race |>
  bind_rows(summary_df) |>
  mutate(
    facet = as.numeric(study_name_short == "Random-effects meta-analysis"),
    estimate_100 = estimate * 100,
    std.error_100 = std.error * 100,
    conf.high_100 = conf.high * 100,
    conf.low_100 = conf.low * 100,
    se_entry = make_se_entry(estimate_100, std.error_100, digits = 1),
    study_name_short = factor(
      study_name_short,
      levels = c(levels(difference_df$study_name_short_fac), "Random-effects meta-analysis")
    )
  )

# The figure prints an estimate and standard error beside every row of both panels, so
# those 34 labels are published numbers and are written out here.
write_csv(
  gg_df |>
    transmute(panel = cand_white, study_id = replace_na(study_id, "pooled"),
              study_name_short = as.character(study_name_short),
              estimate_100, std.error_100, se_entry) |>
    arrange(panel, desc(estimate_100)),
  here::here("maintained", "output", "figure_2_plotted_estimates.csv")
)

g <- ggplot(gg_df, aes(x = estimate_100, y = study_name_short)) +
  geom_point(alpha = 0.8, stroke = 0) +
  geom_linerange(aes(xmin = conf.low_100, xmax = conf.high_100), alpha = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_vline(data = summary_df, aes(xintercept = estimate_100)) +
  geom_rect(
    data = summary_df,
    aes(xmin = conf.low_100, xmax = conf.high_100, x = NULL, y = NULL),
    ymin = 0, ymax = 100, alpha = 0.1
  ) +
  geom_text(
    x = 20,
    aes(y = study_name_short, label = se_entry),
    hjust = 1, size = 2, nudge_y = 0.2
  ) +
  coord_cartesian(xlim = c(-20, 20)) +
  xlab("CATE estimate in percentage points") +
  facet_grid(rows = vars(facet), cols = vars(cand_white), scales = "free_y", space = "free") +
  theme_bw() +
  theme(
    axis.title.y = element_blank(),
    axis.text.y = element_text(size = 8),
    legend.position = "none",
    strip.background = element_blank(),
    strip.text.y = element_blank()
  )

ggsave(here::here("maintained", "output", "figure_2_cate_candidate_race.pdf"), g, height = 3.5, width = 6.5)
ggsave(here::here("maintained", "output", "figure_2_cate_candidate_race.png"), g, height = 3.5, width = 6.5, dpi = 300)
