# Build exports from the current session, never a static JSON fixture.
build_design_export <- function(workflow, hypothesis, concepts, decisions, taxa, power) {
  export <- workflow
  export$hypothesis <- hypothesis
  export$extracted_entities <- as.list(concepts)
  export$decision_log <- decisions
  export$power_profile <- list(taxa = taxa, estimated_power = power, target = 0.80,
    source = "data/power_results.csv", status = "Illustrative precomputed values; not empirical results")
  export$limitations <- "Conceptual Prototype. No analyses or simulations executed. Researcher review required before actual preregistration."
  export
}

# Prefix every line of free-form researcher text so it remains an R comment.
r_comment <- function(text) {
  paste0("# ", strsplit(paste(text, collapse = "; "), "\n", fixed = TRUE)[[1]])
}

analysis_template_preview <- function(design) {
  ids <- vapply(design$nodes, `[[`, character(1), "id")
  paste(c("# phyloSophR — Conceptual Prototype",
    "# Suggested R analysis template; not executed or scientifically validated by this app.",
    "# Start in a fresh R session. Requires base R and the separately installed ape package.",
    "# Supply local files and review placeholders, assumptions, interval boundaries and exclusions.",
    "# Model suggestion: extant-only dated tree, log trait, Gaussian Brownian motion.",
    "# Fossils, measurement error and dating uncertainty require a different or extended model.",
    r_comment(paste("Hypothesis:", design$hypothesis)),
    if (!"matching" %in% ids) c(
      "# UNRESOLVED: the researcher retained a workflow without tree-and-trait matching.",
      'stop("Resolve tree-and-trait matching before running this template")'),
    unlist(lapply(design$nodes, function(node) {
      code <- node$r_code
      if (node$id == "hypothesis") {
        lines <- strsplit(code, "\n", fixed = TRUE)[[1]]
        lines[grepl("^hypothesis <-", lines)] <- paste("hypothesis <-", encodeString(design$hypothesis, quote = '\"'))
        code <- paste(lines, collapse = "\n")
      }
      c(paste0("\n# ", node$operation), r_comment(paste("Purpose:", node$purpose)),
        r_comment(paste("Required inputs:", paste(node$required_inputs, collapse = "; "))),
        if (node$id == "matching") "# Adapt the default code to the recorded procedure above; free-form edits are not translated into code.",
        code)
    }))), collapse = "\n")
}

preregistration_preview <- function(design) {
  paste(c('---', 'title: "phyloSophR conceptual preregistration draft"', 'format: html', '---',
    "", "# Conceptual Prototype", "Demonstration preview. Not a submitted or completed preregistration.",
    "", "# Hypothesis", design$hypothesis,
    "", "# Extracted entities", paste(names(design$extracted_entities), unlist(design$extracted_entities), sep = ": "),
    "", "# Planned workflow", vapply(design$nodes, function(node) paste("-", node$operation), character(1)),
    "", "# Researcher decisions", if (length(design$decision_log)) vapply(design$decision_log, function(entry) {
      paste("-", entry$action, entry$detail, entry$warning)
    }, character(1)) else "No decisions recorded.",
    "", "# Illustrative power profile", sprintf("%s taxa; illustrative power %.2f; target 0.80.",
      design$power_profile$taxa, design$power_profile$estimated_power),
    "Not empirical results or a study-specific power calculation.",
    "", "# Before preregistration", "Specify data sources, exclusions, model definitions, comparison criteria, and uncertainty handling. Resolve or justify outstanding warnings."), collapse = "\n")
}
