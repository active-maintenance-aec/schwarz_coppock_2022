# schwarz_coppock_2022/maintained/figure_3_cate_respondent_gender.R
# Output: output/figure_3_cate_respondent_gender.pdf, output/figure_3_cate_respondent_gender.png,
#   output/figure_3_meta_summary.csv, output/figure_3_diff_in_cates_resp_gender.csv,
#   output/figure_3_plotted_estimates.csv
# Depends on: original/resp_gender_cate_estimates.rds, helpers.R
# Description: Figure 3, CATEs of candidate gender by respondent gender, with the test
#   for the difference between the two pools.

source(here::here("maintained", "helpers.R"))

resp_gender <- read_rds(here::here("original", "resp_gender_cate_estimates.rds"))

pooled <- resp_gender |>
  group_by(resp_female) |>
  reframe(re_meta(estimate, std.error, method = "DL"))

write_csv(pooled, here::here("maintained", "output", "figure_3_meta_summary.csv"))
print(pooled)

# Difference between the two pooled CATEs ----
female_row <- pooled |> filter(resp_female == "Female respondents")
male_row <- pooled |> filter(resp_female == "Male respondents")

diff_result <- diff_test(
  female_row$estimate, female_row$std.error,
  male_row$estimate, male_row$std.error
) |>
  mutate(comparison = "Female respondents minus male respondents") |>
  relocate(comparison)

write_csv(diff_result, here::here("maintained", "output", "figure_3_diff_in_cates_resp_gender.csv"))
print(diff_result)

summary_df <- pooled |>
  mutate(
    study_name_short = "Random-effects meta-analysis",
    estimate_100 = estimate * 100,
    std.error_100 = std.error * 100,
    conf.high_100 = conf.high * 100,
    conf.low_100 = conf.low * 100
  )

difference_df <- resp_gender |>
  select(study_name_short, resp_female, estimate) |>
  pivot_wider(names_from = resp_female, values_from = estimate) |>
  mutate(
    difference = `Female respondents` - `Male respondents`,
    study_name_short_fac = fct_reorder(study_name_short, difference)
  )

gg_df <- resp_gender |>
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
# those 76 labels are published numbers and are written out here.
write_csv(
  gg_df |>
    transmute(panel = resp_female, study_id = replace_na(study_id, "pooled"),
              study_name_short = as.character(study_name_short),
              estimate_100, std.error_100, se_entry) |>
    arrange(panel, desc(estimate_100)),
  here::here("maintained", "output", "figure_3_plotted_estimates.csv")
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
  facet_grid(rows = vars(facet), cols = vars(resp_female), scales = "free_y", space = "free") +
  theme_bw() +
  theme(
    axis.title.y = element_blank(),
    axis.text.y = element_text(size = 8),
    legend.position = "none",
    strip.background = element_blank(),
    strip.text.y = element_blank()
  )

ggsave(here::here("maintained", "output", "figure_3_cate_respondent_gender.pdf"), g, height = 5, width = 6.5)
ggsave(here::here("maintained", "output", "figure_3_cate_respondent_gender.png"), g, height = 5, width = 6.5, dpi = 300)
