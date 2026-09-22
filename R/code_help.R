# Offline explanation catalogue. No model, external requests, or code execution.
operation_explanation <- function(id) {
  explanations <- c(
    hypothesis = "The code records the question and predicted direction of the rate contrast. eocene_ma stores younger and older boundaries in millions of years. NA_real_ deliberately leaves them unset. stopifnot checks that you supplied finite, ordered boundaries; the prototype does not choose them for you.",
    group = "read.csv loads your local sampling plan. The checks require taxon, include, and rationale columns, logical inclusion flags, no missing values, and unique taxa. The include flags select study_taxa. At least three taxa are required by this example; that minimum is not evidence of adequate power.",
    phylogeny = "ape::read.tree reads a local Newick file. The checks require a rooted, ultrametric tree with unique tip labels and finite positive branch lengths. Ultrametric means all tips have the same distance from the root. This example assumes extant taxa and lengths in millions of years; the code cannot verify the units or dating provenance.",
    traits = "read.csv loads the local trait table. The checks require taxon identifiers and numeric body_size measurements, unique nonmissing identifiers, and finite positive sizes. Positivity is necessary for the later log transformation. Consistent measurement units and comparable observations still require your review.",
    matching = "setdiff identifies study taxa missing from the tree or trait table and lists observations outside your sampling plan. Missing study taxa stop execution. Extra taxa may be excluded only after you review them and set approve_exclusions to TRUE. keep.tip retains the approved study taxa; match reorders trait rows to tree-tip order, and identical checks that alignment. This is exact identifier matching, not automatic synonym resolution. Custom procedures recorded in the decision log must be implemented manually in the suggested code.",
    assumptions = "The code requires aligned tree and trait objects and checks their taxon order. approve_log_scale starts FALSE so the log transformation needs explicit review. log transforms body size, and setNames attaches taxon identifiers. Node depths are converted to branch ages; pmin, pmax, and the reviewed interval boundaries calculate how much of each branch overlaps the Eocene. Both Eocene and background exposure must exist. These checks do not establish model adequacy or identifiability.",
    baseline = "bm_nll computes a Gaussian Brownian-motion negative log likelihood. v is the tree covariance scaled by a positive evolutionary rate. chol and chol2inv provide a Cholesky factor and inverse; mu is the estimated ancestral mean accounting for covariance. The likelihood combines its normalization, covariance determinant, and covariance-weighted residuals. optim minimizes this function using BFGS on a log rate, and exp converts the fitted parameter back to a positive rate. A convergence code of zero is checked, but adequacy still needs diagnostics.",
    alternative = "The alternative estimates a background rate and an Eocene multiplier. Each branch keeps its background length and receives an extra (multiplier - 1) times its Eocene overlap. Thus branches crossing interval boundaries are split by their exposure rather than assigned wholly to one period. vcv.phylo builds the resulting covariance and bm_nll evaluates it. optim jointly estimates both log parameters. exp(par[2]) gives the multiplier: above one indicates estimated acceleration. Hessian eigenvalues help inspect local curvature; they are not a complete identifiability or uncertainty analysis.",
    comparison = "The table compares maximum-likelihood fits using AIC = 2k + 2 times the negative log likelihood. k is two for the baseline (mean and rate) and three for the alternative (mean, background rate, multiplier). delta_AIC subtracts the smallest AIC so the best relative fit has zero. Both fits must use the same observations and likelihood convention. AIC is a relative model comparison, not a p-value or proof of acceleration.",
    evaluation = "The interpretation list collects the question, predicted contrast, estimated background rate, Eocene multiplier, model comparison, and exclusions. The direction label depends only on whether the estimated multiplier exceeds one; it does not establish statistical support. researcher_conclusion remains unset so you can assess uncertainty, diagnostics, sensitivity, and biological limitations before concluding. No causal Eocene mechanism is established by this code.",
    asr_hypothesis = "The code records the question, the reference body-size bounds it will be judged against (e.g. a small-bodied and a large-bodied relative), and the tip labels spanning Australaves. reference_bounds and australaves_tips are left unset by design; the prototype does not choose your comparison taxa or reference sizes for you. getMRCA later needs at least two tips to define an ancestor.",
    asr_assumptions = "The code requires aligned tree and trait objects and checks the Australaves tips are present in the alignment. ape::getMRCA locates the internal node representing their common ancestor; a NULL result means the tips don't share a unique ancestor in this tree. approve_log_scale starts FALSE so the log transformation needs explicit review, matching the same trait-scale check used elsewhere. The comment on rate homogeneity is a real limitation: a single-rate Brownian model assumes the evolutionary rate at this node matches the rest of the tree.",
    asr_reconstruction = "ape::ace fits a continuous-trait ancestral state reconstruction under Brownian motion; method='REML' profiles out the root state the way the baseline rate model does elsewhere. CI=TRUE requests 95% confidence intervals for every internal node. node_index converts the MRCA's overall node number into ace's internal-node row index (ape numbers tips first, then internal nodes). The result is a point estimate and interval in log scale, not yet compared to any reference body size.",
    asr_evaluation = "The code compares the reconstructed ancestral estimate, and separately its confidence interval, against the log-transformed reference bounds from the hypothesis step. estimate_supports_medium checks only the point estimate; ci_excludes_extremes is the stricter check that the whole interval avoids both reference extremes. Neither is a significance test against a null hypothesis. researcher_conclusion remains unset so you can weigh tree, dating, and rate-homogeneity uncertainty before concluding."
  )
  if (!id %in% names(explanations)) return("No explanation is available for this operation.")
  unname(explanations[[id]])
}

code_help_reply <- function(node, question) {
  if (length(question) != 1L || is.na(question) || !nzchar(trimws(question))) {
    return("Enter a question or choose Explain this operation.")
  }
  if (nchar(question) > 1000L) return("Please keep your question within 1,000 characters.")
  q <- tolower(trimws(question))
  if (grepl("input|file|data need|required|package", q)) {
    return(paste("Required inputs:", paste(node$required_inputs, collapse = "; "),
      "\n\n", operation_explanation(node$id),
      "\n\nRun the template separately in DAG order with local files. The suggested analysis uses base R and ape; this chat neither loads files nor runs code."))
  }
  if (grepl("assumption|review|limitation|safe", q)) {
    return(paste("Researcher review:", paste(node$assumptions, collapse = "; "),
      "\n\n", operation_explanation(node$id)))
  }
  if (grepl("stop|error|fail|na_real|approve", q)) {
    return(paste("stop() deliberately halts execution; stopifnot() halts when a required condition fails. Unset interval boundaries, missing inputs, mismatched taxa, or unapproved choices can trigger these checkpoints. Do not remove a check simply to continue.",
      "\n\nFor this operation:", operation_explanation(node$id),
      "\n\nThis offline help does not inspect your R session or diagnose arbitrary errors."))
  }
  if (grepl("explain|how|what|why|code|function|step|mean|does", q)) {
    return(paste("Prepared explanation for the selected operation (not a generated answer to arbitrary R questions):",
      operation_explanation(node$id), sep = "\n\n"))
  }
  "This conceptual chatbot provides prepared explanations for the selected DAG operation only. Try: Explain this operation; What inputs do I need?; Why might it stop?; or What assumptions should I review? It cannot execute, modify, or explain arbitrary pasted R code."
}
