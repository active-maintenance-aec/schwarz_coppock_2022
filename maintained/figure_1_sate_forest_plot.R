# schwarz_coppock_2022/maintained/figure_1_sate_forest_plot.R
# Output: output/figure_1_sate_forest_plot.pdf, output/figure_1_sate_forest_plot.png,
#   output/figure_1_meta_summary.csv, output/figure_1_plotted_estimates.csv
# Depends on: original/sate_estimates.rds, helpers.R
# Description: Figure 1, a forest plot of the 67 study-level ATEs with the pooled
#   random-effects estimate beneath them.

source(here::here("maintained", "helpers.R"))

sate_estimates <- read_rds(here::here("original", "sate_estimates.rds"))

summary_df <- sate_estimates |>
  reframe(re_meta(estimate, std.error, method = "DL")) |>
  mutate(
    study_name_short = "Random-effects meta-analysis",
    estimate_100 = estimate * 100,
    std.error_100 = std.error * 100,
    conf.high_100 = conf.high * 100,
    conf.low_100 = conf.low * 100
  )

write_csv(
  summary_df |> select(estimate, std.error, conf.low, conf.high, n_studies),
  here::here("maintained", "output", "figure_1_meta_summary.csv")
)
print(summary_df |> select(estimate, std.error, conf.low, conf.high, n_studies))

gg_df <- sate_estimates |>
  bind_rows(summary_df) |>
  mutate(
    facet = as.numeric(study_name_short == "Random-effects meta-analysis"),
    study_name_short = fct_reorder(factor(study_name_short), estimate),
    estimate_100 = estimate * 100,
    std.error_100 = std.error * 100,
    conf.high_100 = conf.high * 100,
    conf.low_100 = conf.low * 100,
    se_entry = make_se_entry(estimate_100, std.error_100, digits = 1)
  )

# The figure prints an estimate and standard error beside every row, so those 68 labels
# are published numbers and are written out here to be compared against the page.
write_csv(
  gg_df |>
    transmute(study_id = replace_na(study_id, "pooled"),
              study_name_short = as.character(study_name_short),
              estimate_100, std.error_100, se_entry) |>
    arrange(desc(estimate_100)),
  here::here("maintained", "output", "figure_1_plotted_estimates.csv")
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
    hjust = 1, size = 2.5, nudge_y = 0.25
  ) +
  coord_cartesian(xlim = c(-20, 20)) +
  xlab("ATE estimate in percentage points") +
  facet_grid(rows = vars(facet), scales = "free_y", space = "free") +
  theme_bw() +
  theme(
    axis.title.y = element_blank(),
    axis.title.x = element_text(size = 8),
    axis.text.y = element_text(size = 8),
    legend.position = "none",
    strip.background = element_blank(),
    strip.text = element_blank()
  )

ggsave(here::here("maintained", "output", "figure_1_sate_forest_plot.pdf"), g, height = 7.5, width = 6.5)
ggsave(here::here("maintained", "output", "figure_1_sate_forest_plot.png"), g, height = 7.5, width = 6.5, dpi = 300)
