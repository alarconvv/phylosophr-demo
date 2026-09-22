# Reports findings without changing the design. Each workflow names its own first
# model-fitting node (default "baseline") so this rule applies beyond the Eocene scenario.
validate_workflow_logic <- function(workflow) {
  ids <- vapply(workflow$nodes, `[[`, character(1), "id")
  model_node <- if (is.null(workflow$first_analysis_node)) "baseline" else workflow$first_analysis_node
  missing_match <- all(c("phylogeny", "traits", model_node) %in% ids) &&
    (!"matching" %in% ids || match("matching", ids) > match(model_node, ids))
  if (!missing_match) return(list(valid = TRUE))
  list(valid = FALSE, rule = "tree_trait_alignment_required",
       title = "Potential workflow gap detected",
       reason = "Trait data and phylogeny should be checked for matching taxa before model fitting.",
       suggestion = "Match tree and trait data")
}

# Called only after an explicit researcher action.
insert_matching_operation <- function(workflow, purpose) {
  ids <- vapply(workflow$nodes, `[[`, character(1), "id")
  if ("matching" %in% ids) return(workflow)
  node <- list(id = "matching", operation = "Match tree and trait data",
    purpose = purpose,
    required_inputs = c("Time-calibrated phylogeny", "Body-size trait table"),
    expected_output = "Tree and trait data aligned by taxon, with exclusions documented",
    assumptions = "Taxonomic identifiers can be reconciled; exclusions require researcher review.",
    r_code = operation_r_code("matching"))
  workflow$nodes <- append(workflow$nodes, list(node), after = match("traits", ids))
  ids <- vapply(workflow$nodes, `[[`, character(1), "id")
  workflow$edges <- lapply(seq_len(length(ids) - 1L), function(i) {
    list(from = ids[[i]], to = ids[[i + 1L]], relationship = "precedes")
  })
  workflow
}
