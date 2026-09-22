# Read illustrative precomputed values; never run simulations or infer empirical power.
read_power_results <- function(path = "data/power_results.csv") {
  results <- read.csv(path)
  required <- c("taxa", "effect_size", "power")
  if (!all(required %in% names(results))) stop("Power CSV must contain taxa, effect_size, and power.")
  if (!all(vapply(results[required], is.numeric, logical(1))) ||
      nrow(results) < 2L || anyNA(results[required]) ||
      any(!is.finite(as.matrix(results[required]))) ||
      any(results$power < 0 | results$power > 1) ||
      any(results$taxa <= 0 | results$taxa != round(results$taxa)) ||
      anyDuplicated(results$taxa) || length(unique(results$effect_size)) != 1L) {
    stop("Power CSV requires unique positive taxon counts, one effect size, and finite power values in [0, 1].")
  }
  results <- results[order(results$taxa), ]
  if (length(unique(diff(results$taxa))) != 1L) stop("Power slider requires evenly spaced taxon counts.")
  results
}

power_at_sample_size <- function(results, taxa) {
  index <- match(taxa, results$taxa)
  if (is.na(index)) stop("Choose a sample size represented in the precomputed table.")
  results$power[[index]]
}

plot_power_profile <- function(results, taxa) {
  selected <- results[results$taxa == taxa, , drop = FALSE]
  ggplot2::ggplot(results, ggplot2::aes(x = taxa, y = power)) +
    ggplot2::geom_hline(yintercept = 0.80, linetype = "dashed", color = "#F39C12") +
    ggplot2::geom_line(color = "#2C3E50", linewidth = 1.1) +
    ggplot2::geom_point(color = "#2C3E50", size = 2.6) +
    ggplot2::geom_point(data = selected, shape = 21, fill = "#2C3E50", color = "white", size = 5, stroke = 1.3) +
    ggplot2::annotate("text", x = min(results$taxa), y = 0.83,
                      label = "Target power = 0.80", hjust = 0, color = "#8A5A00", size = 3.5) +
    ggplot2::scale_x_continuous(breaks = results$taxa) +
    ggplot2::scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    ggplot2::labs(x = "Number of taxa", y = "Statistical power",
      subtitle = "Illustrative precomputed profile · not empirical results") +
    ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      plot.subtitle = ggplot2::element_text(color = "#54696A", margin = ggplot2::margin(b = 18)),
      plot.margin = ggplot2::margin(15, 18, 15, 12))
}

power_diagnosis <- function(power) {
  if (length(power) != 1L || !is.numeric(power) || !is.finite(power) || power < 0 || power > 1) {
    stop("Power must be one finite number between 0 and 1.")
  }
  if (power < 0.80) "LOW" else "ACCEPTABLE"
}
