# An explicit, auditable design specification. No analysis runs here.
eocene_workflow <- function() {
  node <- function(id, operation, purpose, required_inputs, expected_output, assumptions) {
    list(id = id, operation = operation, purpose = purpose,
         required_inputs = required_inputs, expected_output = expected_output,
         assumptions = assumptions, r_code = operation_r_code(id))
  }
  nodes <- list(
    node("hypothesis", "Research hypothesis",
         "Specify the proposed Eocene increase in mammalian body-size evolutionary rate.",
         "Researcher's biological question", "Explicit rate-variation hypothesis",
         "Acceleration refers to evolutionary variance per unit time, not necessarily an increase in mean body size."),
    node("group", "Define study group",
         "Set the mammalian sampling scope and inclusion criteria.",
         c("Hypothesis", "Taxonomic scope and sampling criteria"), "Documented study taxa",
         "Sampling and exclusions must be justified by the researcher."),
    node("phylogeny", "Obtain dated phylogeny",
         "Provide a dated evolutionary framework spanning the interval of interest.",
         c("Study taxa", "Dated phylogeny and provenance"), "Time-calibrated tree",
         "Branch lengths represent time; dating uncertainty and Eocene coverage require review."),
    node("traits", "Obtain body-size data",
         "Assemble comparable body-size observations for the study taxa.",
         c("Study taxa", "Body-size measurements, units, and sources"), "Trait table with provenance",
         "Measurements are comparable; missingness, measurement error, and fossil inclusion need explicit treatment."),
    node("assumptions", "Validate phylogenetic assumptions",
         "Review temporal coverage, branch lengths, sampling, and trait transformations.",
         c("Aligned dataset", "Proposed model assumptions"), "Assumption checklist requiring researcher review",
         "Passing a checklist does not establish model adequacy; uncertainty remains explicit."),
    node("baseline", "Fit baseline evolutionary model",
         "Specify a constant-rate Brownian-motion reference model.",
         c("Reviewed dataset", "Researcher-approved trait scale"), "Baseline fit and parameter estimates (planned)",
         "A constant variance rate and Brownian increments are suitable as a reference, subject to diagnostics."),
    node("alternative", "Fit rate-variable alternative",
         "Specify an Eocene rate multiplier relative to the background rate.",
         c("Same reviewed dataset", "Defined Eocene interval", "Baseline specification"), "Alternative fit and Eocene rate estimate (planned)",
         "Branches crossing interval boundaries are handled explicitly; the rate contrast must be identifiable."),
    node("comparison", "Compare models",
         "Assess support for rate variation with a justified comparison criterion.",
         c("Baseline fit", "Alternative fit", "Comparison protocol"), "Model comparison and uncertainty summary (planned)",
         "Fits use identical observations and compatible likelihoods; complexity and calibration are considered."),
    node("evaluation", "Evaluate biological hypothesis",
         "Interpret evidence for acceleration during the Eocene within the design's limitations.",
         c("Model comparison", "Estimated rate contrast", "Diagnostics and uncertainty"), "Qualified biological interpretation (planned)",
         "Support for rate variation is not proof of a causal Eocene mechanism; direction and uncertainty must be evaluated.")
  )
  ids <- vapply(nodes, `[[`, character(1), "id")
  list(schema_version = "1.0", scenario = "eocene_body_size",
       label = "Conceptual Prototype", status = "Design specification; not executed",
       first_analysis_node = "baseline", nodes = nodes,
       edges = lapply(seq_len(length(ids) - 1L), function(i) {
         list(from = ids[[i]], to = ids[[i + 1L]], relationship = "precedes")
       }))
}

# An explicit, auditable design specification for an ancestral-state hypothesis at a single
# internal node, rather than the rate-comparison shape of eocene_workflow().
australaves_workflow <- function() {
  node <- function(id, operation, purpose, required_inputs, expected_output, assumptions) {
    list(id = id, operation = operation, purpose = purpose,
         required_inputs = required_inputs, expected_output = expected_output,
         assumptions = assumptions, r_code = operation_r_code(id))
  }
  nodes <- list(
    node("asr_hypothesis", "Research hypothesis",
         "Specify that the Australaves ancestor was medium-sized, relative to a small- and a large-bodied reference relative.",
         "Researcher's biological question", "Explicit ancestral-state hypothesis with reference bounds",
         "“Medium-sized” is only meaningful relative to the two reference body sizes the researcher supplies."),
    node("group", "Define study group",
         "Set the avian sampling scope, including the Australaves tips and enough outgroup taxa to place their ancestor.",
         c("Hypothesis", "Taxonomic scope and sampling criteria"), "Documented study taxa",
         "Sampling and exclusions must be justified by the researcher."),
    node("phylogeny", "Obtain dated phylogeny",
         "Provide a dated tree spanning Australaves and enough outgroups to resolve their common ancestor.",
         c("Study taxa", "Dated phylogeny and provenance"), "Time-calibrated tree",
         "Branch lengths represent time; dating uncertainty and topological support near this node require review."),
    node("traits", "Obtain body-size data",
         "Assemble comparable body-size observations for the study taxa.",
         c("Study taxa", "Body-size measurements, units, and sources"), "Trait table with provenance",
         "Measurements are comparable; missingness, measurement error, and fossil inclusion need explicit treatment."),
    node("asr_assumptions", "Validate reconstruction assumptions",
         "Confirm the target ancestral node, trait scale, and the single-rate model this reconstruction assumes.",
         c("Aligned dataset", "Target clade tip labels"), "Assumption checklist requiring researcher review",
         "A single Brownian rate across the tree is assumed; local rate shifts near this node are not modeled."),
    node("asr_reconstruction", "Reconstruct ancestral state",
         "Estimate the body size, with a confidence interval, at the Australaves ancestor.",
         c("Reviewed dataset", "Researcher-approved trait scale", "Target node"), "Ancestral estimate and interval (planned)",
         "The reconstruction is conditional on the chosen model and the input tree; it is not a fossil observation."),
    node("asr_evaluation", "Evaluate biological hypothesis",
         "Judge the reconstructed ancestor against the reference bounds within the design's limitations.",
         c("Ancestral estimate and interval", "Reference body-size bounds"), "Qualified biological interpretation (planned)",
         "Falling inside the reference bounds is not proof of the ancestral condition; tree, dating, and rate uncertainty must be evaluated.")
  )
  ids <- vapply(nodes, `[[`, character(1), "id")
  list(schema_version = "1.0", scenario = "australaves_ancestral_state",
       label = "Conceptual Prototype", status = "Design specification; not executed",
       first_analysis_node = "asr_reconstruction", nodes = nodes,
       edges = lapply(seq_len(length(ids) - 1L), function(i) {
         list(from = ids[[i]], to = ids[[i + 1L]], relationship = "precedes")
       }))
}

workflow_to_json <- function(workflow) {
  jsonlite::toJSON(workflow, auto_unbox = TRUE, pretty = TRUE)
}

workflow_graph_data <- function(workflow) {
  list(
    nodes = data.frame(
      id = vapply(workflow$nodes, `[[`, character(1), "id"),
      label = vapply(workflow$nodes, `[[`, character(1), "operation"),
      level = seq_along(workflow$nodes), stringsAsFactors = FALSE
    ),
    edges = data.frame(
      from = vapply(workflow$edges, `[[`, character(1), "from"),
      to = vapply(workflow$edges, `[[`, character(1), "to"),
      arrows = "to", stringsAsFactors = FALSE
    )
  )
}

# Fixed two-column path: stable across renders, with no physics or random layout.
presentation_workflow_graph <- function(workflow) {
  graph <- workflow_graph_data(workflow)
  n <- nrow(graph$nodes)
  split <- ceiling(n / 2)
  graph$nodes$level <- NULL
  graph$nodes$x <- c(rep(0, split), rep(330, n - split))
  graph$nodes$y <- c(seq(0, by = 90, length.out = split),
                   rev(seq(0, by = 90, length.out = n - split)))
  graph$nodes$label <- vapply(seq_len(n), function(i) {
    paste0(sprintf("%02d", i), "  ", paste(strwrap(graph$nodes$label[[i]], width = 25), collapse = "\n"))
  }, character(1))
  graph$nodes$fixed <- TRUE
  network <- visNetwork::visNetwork(graph$nodes, graph$edges, background = "#ECF0F1")
  network <- visNetwork::visNodes(network, shape = "box", margin = 10,
    widthConstraint = list(minimum = 240, maximum = 240),
    font = list(size = 19, face = "IBM Plex Sans", color = "#2C3E50"),
    color = list(background = "#ffffff", border = "#54696A",
      highlight = list(background = "#DEE2E6", border = "#2C3E50")))
  network <- visNetwork::visEdges(network, arrows = "to", smooth = FALSE, color = "#54696A")
  network <- visNetwork::visPhysics(network, enabled = FALSE)
  network <- visNetwork::visLayout(network, randomSeed = 1, improvedLayout = FALSE)
  visNetwork::visInteraction(network, dragNodes = FALSE, dragView = FALSE, zoomView = FALSE)
}
