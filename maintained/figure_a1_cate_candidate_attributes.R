# schwarz_coppock_2022/maintained/figure_a1_cate_candidate_attributes.R
# Output: output/figure_a1_cate_candidate_attributes.pdf,
#   output/figure_a1_cate_candidate_attributes.png, output/figure_a1_cate_summary.csv
# Depends on: original/cand_attributes_cate_estimates.rds, helpers.R
# Description: Figure A.1, all 954 CATEs of candidate gender conditional on the other
#   randomized candidate attributes, one row per attribute level.

source(here::here("maintained", "helpers.R"))

cand_attributes <- read_rds(here::here("original", "cand_attributes_cate_estimates.rds"))

# The appendix says the majority of these CATEs are positive; the count is written out so
# the claim can be checked against a number rather than against the figure.
summary_counts <- cand_attributes |>
  summarise(
    n_cates = n(),
    n_studies = n_distinct(study_id),
    n_positive = sum(estimate > 0),
    prop_positive = mean(estimate > 0)
  )

write_csv(summary_counts, here::here("maintained", "output", "figure_a1_cate_summary.csv"))
print(summary_counts)

# The archive wraps both layers in ggstance::position_dodgev(). That function still
# resolves, but it moves nothing here: unique_label_fac takes 954 distinct values across
# 954 rows, so building the layer with and without the dodge puts every point at the same
# coordinates. It is dropped rather than translated.
g <- ggplot(cand_attributes, aes(x = estimate_100, y = unique_label_fac)) +
  geom_point(alpha = 0.5) +
  geom_linerange(aes(xmin = conf.low_100, xmax = conf.high_100), alpha = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  coord_cartesian(xlim = c(-20, 20)) +
  xlab("CATE estimate in percentage points") +
  theme_bw() +
  theme(
    axis.title.y = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major.y = element_blank()
  )

ggsave(here::here("maintained", "output", "figure_a1_cate_candidate_attributes.pdf"), g, width = 6.5, height = 8)
ggsave(here::here("maintained", "output", "figure_a1_cate_candidate_attributes.png"), g, width = 6.5, height = 8, dpi = 300)
