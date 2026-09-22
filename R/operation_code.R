# Deterministic suggestions only: the app displays these strings, never evaluates them.
operation_r_code <- function(id) {
  snippets <- list(
    hypothesis = c(
      '# Record the hypothesis and planned contrast before examining results.',
      'hypothesis <- "Test if body size evolution accelerated during the Eocene in mammals."',
      'prediction <- "Eocene variance rate exceeds the background variance rate"',
      'eocene_ma <- c(younger = NA_real_, older = NA_real_) # Supply reviewed boundaries in Ma.',
      'stopifnot(all(is.finite(eocene_ma)), eocene_ma[1] >= 0, eocene_ma[2] > eocene_ma[1])'
    ),
    group = c(
      '# Local CSV: taxon (unique tree-tip identifier), include (TRUE/FALSE), rationale.',
      'sampling <- utils::read.csv("data/sampling_plan.csv", stringsAsFactors = FALSE)',
      'stopifnot(all(c("taxon", "include", "rationale") %in% names(sampling)))',
      'stopifnot(is.logical(sampling$include), !anyNA(sampling), !anyDuplicated(sampling$taxon))',
      'study_taxa <- sampling$taxon[sampling$include]',
      'stopifnot(length(study_taxa) >= 3L)'
    ),
    phylogeny = c(
      '# Requires ape installed separately; use a local rooted, dated extant-only tree.',
      '# Branch lengths must be in millions of years. Review dating provenance separately.',
      'tree <- ape::read.tree("data/study_tree.nwk")',
      'stopifnot(inherits(tree, "phylo"), ape::is.rooted(tree), ape::is.ultrametric(tree))',
      'stopifnot(!anyDuplicated(tree$tip.label), all(is.finite(tree$edge.length)),',
      '          length(tree$edge.length) == nrow(tree$edge), all(tree$edge.length > 0))'
    ),
    traits = c(
      '# Local CSV: taxon and body_size, in one researcher-approved positive measurement unit.',
      'traits <- utils::read.csv("data/body_size.csv", stringsAsFactors = FALSE)',
      'stopifnot(all(c("taxon", "body_size") %in% names(traits)))',
      'stopifnot(!anyNA(traits$taxon), !anyDuplicated(traits$taxon), is.numeric(traits$body_size))',
      'stopifnot(all(is.finite(traits$body_size)), all(traits$body_size > 0))'
    ),
    matching = c(
      '# Default exact-identifier procedure; adapt to the recorded researcher procedure.',
      '# Stop for missing study taxa; never silently drop unmatched study observations.',
      'missing_tree <- setdiff(study_taxa, tree$tip.label)',
      'missing_traits <- setdiff(study_taxa, traits$taxon)',
      'print(list(missing_tree = missing_tree, missing_traits = missing_traits))',
      'stopifnot(length(missing_tree) == 0L, length(missing_traits) == 0L)',
      'exclusions <- list(tree = setdiff(tree$tip.label, study_taxa),',
      '                   traits = setdiff(traits$taxon, study_taxa))',
      'print(exclusions)',
      'approve_exclusions <- FALSE # Set TRUE only after reviewing the listed exclusions.',
      'if (any(lengths(exclusions) > 0L) && !approve_exclusions) stop("Review exclusions first")',
      'aligned_tree <- ape::keep.tip(tree, study_taxa)',
      'aligned_traits <- traits[match(aligned_tree$tip.label, traits$taxon), , drop = FALSE]',
      'stopifnot(identical(aligned_tree$tip.label, aligned_traits$taxon))'
    ),
    assumptions = c(
      '# The matching operation must precede this step; no implicit matching is performed.',
      'if (!exists("aligned_tree") || !exists("aligned_traits")) stop("Tree-trait matching required")',
      'stopifnot(identical(aligned_tree$tip.label, aligned_traits$taxon))',
      'approve_log_scale <- FALSE # Review log transformation and Brownian assumptions.',
      'if (!approve_log_scale) stop("Researcher approval of trait scale required")',
      'y <- stats::setNames(log(aligned_traits$body_size), aligned_traits$taxon)',
      'depth <- ape::node.depth.edgelength(aligned_tree)',
      'tree_height <- max(depth[seq_along(aligned_tree$tip.label)])',
      'older <- tree_height - depth[aligned_tree$edge[, 1]]',
      'younger <- tree_height - depth[aligned_tree$edge[, 2]]',
      'eocene_overlap <- pmax(0, pmin(older, eocene_ma[2]) - pmax(younger, eocene_ma[1]))',
      'stopifnot(sum(eocene_overlap) > 0, sum(aligned_tree$edge.length - eocene_overlap) > 0)',
      '# Temporal coverage alone does not establish rate identifiability or model adequacy.'
    ),
    baseline = c(
      '# Gaussian Brownian-motion maximum likelihood; ancestral mean is profiled out.',
      'bm_nll <- function(log_rate, covariance) {',
      '  v <- exp(log_rate) * covariance',
      '  r <- chol(v)',
      '  inv <- chol2inv(r)',
      '  mu <- sum(inv %*% y) / sum(inv)',
      '  residual <- y - mu',
      '  as.numeric((length(y) * log(2 * pi) + 2 * sum(log(diag(r))) +',
      '              crossprod(residual, inv %*% residual)) / 2)',
      '}',
      'covariance <- ape::vcv.phylo(aligned_tree)[names(y), names(y)]',
      'initial_rate <- log(stats::var(y) / tree_height)',
      'stopifnot(is.finite(initial_rate))',
      'baseline <- stats::optim(initial_rate, bm_nll, covariance = covariance, method = "BFGS")',
      'stopifnot(baseline$convergence == 0L)',
      'baseline_rate <- exp(baseline$par)'
    ),
    alternative = c(
      '# Integrate an Eocene rate multiplier across each branch, including boundary crossings.',
      '# This assumes an extant-only ultrametric tree and a fixed, reviewed interval.',
      'alternative_nll <- function(par) {',
      '  rate_tree <- aligned_tree',
      '  rate_tree$edge.length <- aligned_tree$edge.length + (exp(par[2]) - 1) * eocene_overlap',
      '  covariance <- ape::vcv.phylo(rate_tree)[names(y), names(y)]',
      '  bm_nll(par[1], covariance)',
      '}',
      'alternative <- stats::optim(c(baseline$par, 0), alternative_nll, method = "BFGS", hessian = TRUE)',
      'stopifnot(alternative$convergence == 0L)',
      'eocene_multiplier <- exp(alternative$par[2])',
      '# Inspect identifiability and repeat with multiple starting points before inference.',
      'print(eigen(alternative$hessian, symmetric = TRUE)$values)'
    ),
    comparison = c(
      '# Suggested criterion: AIC with the same observations and ML likelihood in both fits.',
      '# Parameter counts include the estimated ancestral mean: 2 baseline, 3 alternative.',
      'comparison <- data.frame(model = c("Constant rate", "Eocene multiplier"),',
      '                         k = c(2L, 3L), nll = c(baseline$value, alternative$value))',
      'comparison$AIC <- 2 * comparison$k + 2 * comparison$nll',
      'comparison$delta_AIC <- comparison$AIC - min(comparison$AIC)',
      'print(comparison)',
      '# AIC is not a significance test. Specify uncertainty and calibration separately.'
    ),
    evaluation = c(
      '# Summarize the direction and relative fit without automatically accepting a hypothesis.',
      'interpretation <- list(hypothesis = hypothesis, prediction = prediction,',
      '  background_rate = exp(alternative$par[1]), eocene_multiplier = eocene_multiplier,',
      '  estimated_direction = if (eocene_multiplier > 1) "Acceleration" else "No acceleration",',
      '  model_comparison = comparison, exclusions = exclusions,',
      '  researcher_conclusion = NA_character_)',
      'print(interpretation)',
      '# Add uncertainty, diagnostics, sensitivity to tree dating and sampling, and limitations.',
      '# Rate variation alone does not establish an Eocene causal mechanism.'
    ),
    asr_hypothesis = c(
      '# Record the hypothesis, the target internal node, and the reference bounds it is judged against.',
      'hypothesis <- "Was the ancestor of Australaves a medium-sized bird?"',
      'reference_bounds <- c(small = NA_real_, large = NA_real_) # Supply reviewed reference body sizes (e.g. wren, ostrich).',
      'stopifnot(all(is.finite(reference_bounds)), reference_bounds[["small"]] < reference_bounds[["large"]])',
      'australaves_tips <- character(0) # Supply the tip labels spanning Australaves in aligned_tree.',
      'stopifnot(length(australaves_tips) >= 2L) # A most-recent-common-ancestor needs at least two tips.'
    ),
    asr_assumptions = c(
      '# The matching operation must precede this step; no implicit matching is performed.',
      'if (!exists("aligned_tree") || !exists("aligned_traits")) stop("Tree-trait matching required")',
      'stopifnot(identical(aligned_tree$tip.label, aligned_traits$taxon))',
      'stopifnot(all(australaves_tips %in% aligned_tree$tip.label))',
      'mrca_node <- ape::getMRCA(aligned_tree, australaves_tips)',
      'stopifnot(!is.null(mrca_node))',
      'approve_log_scale <- FALSE # Review log transformation and Brownian-motion assumptions.',
      'if (!approve_log_scale) stop("Researcher approval of trait scale required")',
      'y <- stats::setNames(log(aligned_traits$body_size), aligned_traits$taxon)',
      '# A single-rate Brownian-motion reconstruction is the default; it does not allow for',
      '# rate shifts elsewhere on the tree, which would bias the ancestral estimate at this node.'
    ),
    asr_reconstruction = c(
      '# Ancestral state reconstruction under Brownian motion; REML profiles out the root state.',
      'fit <- ape::ace(y, aligned_tree, type = "continuous", method = "REML", CI = TRUE)',
      'stopifnot(!anyNA(fit$ace))',
      'node_index <- mrca_node - ape::Ntip(aligned_tree)',
      'ancestral_estimate <- fit$ace[[node_index]]',
      'ancestral_ci95 <- fit$CI95[node_index, ]',
      'print(list(estimate_log_scale = ancestral_estimate, CI95_log_scale = ancestral_ci95))'
    ),
    asr_evaluation = c(
      '# Judge the reconstructed ancestral state against the reviewed reference bounds, not a p-value.',
      'estimate_supports_medium <- ancestral_estimate > log(reference_bounds[["small"]]) &&',
      '  ancestral_estimate < log(reference_bounds[["large"]])',
      'ci_excludes_extremes <- ancestral_ci95[[1]] > log(reference_bounds[["small"]]) &&',
      '  ancestral_ci95[[2]] < log(reference_bounds[["large"]])',
      'interpretation <- list(hypothesis = hypothesis, target_node = mrca_node,',
      '  ancestral_estimate_log = ancestral_estimate, ci95_log = ancestral_ci95,',
      '  point_estimate_supports_medium = estimate_supports_medium,',
      '  ci_excludes_extremes = ci_excludes_extremes,',
      '  researcher_conclusion = NA_character_)',
      'print(interpretation)',
      '# A single-model, single-node reconstruction; add uncertainty from tree topology, dating,',
      '# and rate heterogeneity before drawing a biological conclusion.'
    )
  )
  if (!id %in% names(snippets)) stop("No R code suggestion defined for operation: ", id)
  paste(snippets[[id]], collapse = "\n")
}
