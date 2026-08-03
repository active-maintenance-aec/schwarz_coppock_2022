# schwarz_coppock_2022/maintained/figure_4_cate_respondent_pid.R
# Output: output/figure_4_cate_respondent_pid.pdf, output/figure_4_cate_respondent_pid.png,
#   output/figure_4_meta_summary.csv, output/figure_4_diff_in_cates_resp_pid.csv,
#   output/figure_4_plotted_estimates.csv
# Depends on: original/resp_pid_cate_estimates.rds, helpers.R
# Description: Figure 4, CATEs of candidate gender by respondent party identification
#   across the 20 US studies that recorded it, with the two difference tests.

source(here::here("maintained", "helpers.R"))

resp_pid <- read_rds(here::here("original", "resp_pid_cate_estimates.rds"))

pooled <- resp_pid |>
  group_by(resp_pid_3) |>
  reframe(re_meta(estimate, std.error, method = "DL"))

write_csv(pooled, here::here("maintained", "output", "figure_4_meta_summary.csv"))
print(pooled)

# Differences between pooled CATEs ----
# The archive computes the Independent-minus-Republican p-value from the Democrat-minus-
# Republican test statistic, which makes the two p-values identical. Both differences are
# tested against their own statistic here; see the errata section of the report.
dem_row <- pooled |> filter(resp_pid_3 == "Democratic respondents")
rep_row <- pooled |> filter(resp_pid_3 == "Republican respondents")
ind_row <- pooled |> filter(resp_pid_3 == "Independent respondents")

diff_result <- bind_rows(
  diff_test(dem_row$estimate, dem_row$std.error, rep_row$estimate, rep_row$std.error) |>
    mutate(comparison = "Democratic minus Republican"),
  diff_test(ind_row$estimate, ind_row$std.error, rep_row$estimate, rep_row$std.error) |>
    mutate(comparison = "Independent minus Republican")
) |>
  relocate(comparison)

write_csv(diff_result, here::here("maintained", "output", "figure_4_diff_in_cates_resp_pid.csv"))
print(diff_result)

summary_df <- pooled |>
  mutate(
    study_name_short = "Random-effects meta-analysis",
    estimate_100 = estimate * 100,
    std.error_100 = std.error * 100,
    conf.high_100 = conf.high * 100,
    conf.low_100 = conf.low * 100
  )

difference_df <- resp_pid |>
  filter(resp_pid_3 %in% c("Democratic respondents", "Republican respondents")) |>
  select(study_name_short, resp_pid_3, estimate) |>
  pivot_wider(names_from = resp_pid_3, values_from = estimate) |>
  mutate(
    difference = `Democratic respondents` - `Republican respondents`,
    study_name_short_fac = fct_reorder(study_name_short, difference)
  )

gg_df <- resp_pid |>
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

# The figure prints an estimate and standard error beside every row of all three panels,
# so those 58 labels are published numbers and are written out here.
write_csv(
  gg_df |>
    transmute(panel = resp_pid_3, study_id = replace_na(study_id, "pooled"),
              study_name_short = as.character(study_name_short),
              estimate_100, std.error_100, se_entry) |>
    arrange(panel, desc(estimate_100)),
  here::here("maintained", "output", "figure_4_plotted_estimates.csv")
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
    hjust = 1, size = 1.5, nudge_y = 0.2
  ) +
  coord_cartesian(xlim = c(-20, 20)) +
  xlab("CATE estimate in percentage points") +
  facet_grid(rows = vars(facet), cols = vars(resp_pid_3), scales = "free_y", space = "free") +
  theme_bw() +
  theme(
    axis.title.y = element_blank(),
    axis.text.y = element_text(size = 8),
    legend.position = "none",
    strip.background = element_blank(),
    strip.text.y = element_blank(),
    text = element_text(size = 8)
  )

ggsave(here::here("maintained", "output", "figure_4_cate_respondent_pid.pdf"), g, height = 4, width = 6.5)
ggsave(here::here("maintained", "output", "figure_4_cate_respondent_pid.png"), g, height = 4, width = 6.5, dpi = 300)
