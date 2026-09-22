root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
for (file in c("operation_code.R", "hypothesis_parser.R", "workflow_library.R", "logic_validator.R", "power_profile.R", "export_demo.R")) {
  source(file.path(root, "R", file), local = TRUE)
}
hypotheses <- c(
  "Test if body size evolution accelerated during the Eocene in mammals.",
  "Was the ancestor of Australaves a medium-sized bird?",
  "Is body size associated with habitat after accounting for phylogeny?"
)

is_dag <- function(workflow) {
  ids <- vapply(workflow$nodes, `[[`, character(1), "id")
  if (anyDuplicated(ids)) return(FALSE)
  edges <- workflow$edges
  if (!all(vapply(edges, function(e) e$from %in% ids && e$to %in% ids, logical(1)))) return(FALSE)
  remaining <- ids
  while (length(remaining)) {
    destinations <- vapply(edges, `[[`, character(1), "to")
    ready <- setdiff(remaining, destinations)
    if (!length(ready)) return(FALSE)
    remaining <- setdiff(remaining, ready)
    edges <- Filter(function(e) !e$from %in% ready, edges)
  }
  TRUE
}

testthat::test_that("supported hypotheses have expected classes and Eocene entities", {
  expected <- c("Trait evolution", "Ancestral state", "Phylogenetic association")
  for (i in seq_along(hypotheses)) {
    testthat::expect_identical(parse_hypothesis(hypotheses[[i]])$concepts[["Hypothesis class"]], expected[[i]])
  }
  testthat::expect_identical(parse_hypothesis(hypotheses[[1]])$concepts,
    c("Trait" = "Body size", "Taxonomic group" = "Mammals", "Evolutionary process" = "Rate variation",
      "Temporal context" = "Eocene", "Hypothesis class" = "Trait evolution"))
  testthat::expect_null(parse_hypothesis("unsupported input"))
})

testthat::test_that("validation is read-only and explicit acceptance repairs the graph", {
  original <- eocene_workflow()
  before <- original
  testthat::expect_false(validate_workflow_logic(original)$valid)
  testthat::expect_identical(original, before)
  accepted <- insert_matching_operation(original, "Match taxon identifiers")
  testthat::expect_true(validate_workflow_logic(accepted)$valid)
  testthat::expect_true(is_dag(accepted))
  testthat::expect_length(accepted$nodes, 10)
  testthat::expect_identical(accepted$edges[[4]], list(from = "traits", to = "matching", relationship = "precedes"))
  testthat::expect_identical(accepted$edges[[5]], list(from = "matching", to = "assumptions", relationship = "precedes"))
  testthat::expect_identical(insert_matching_operation(accepted, "Repeat"), accepted)
})

testthat::test_that("all available workflow variants are acyclic", {
  workflows <- list(eocene_workflow(), insert_matching_operation(eocene_workflow(), "Default matching"),
                    insert_matching_operation(eocene_workflow(), "Researcher-edited matching"),
                    australaves_workflow(), insert_matching_operation(australaves_workflow(), "Default matching"))
  for (workflow in workflows) testthat::expect_true(is_dag(workflow))
  cyclic <- eocene_workflow()
  cyclic$edges <- append(cyclic$edges, list(list(from = "evaluation", to = "hypothesis")))
  testthat::expect_false(is_dag(cyclic))
})

testthat::test_that("Australaves validation is read-only and explicit acceptance repairs the graph", {
  original <- australaves_workflow()
  before <- original
  testthat::expect_false(validate_workflow_logic(original)$valid)
  testthat::expect_identical(original, before)
  accepted <- insert_matching_operation(original, "Match taxon identifiers")
  testthat::expect_true(validate_workflow_logic(accepted)$valid)
  testthat::expect_true(is_dag(accepted))
  testthat::expect_length(accepted$nodes, 8)
  testthat::expect_identical(accepted$edges[[4]], list(from = "traits", to = "matching", relationship = "precedes"))
  testthat::expect_identical(accepted$edges[[5]], list(from = "matching", to = "asr_assumptions", relationship = "precedes"))
  testthat::expect_identical(insert_matching_operation(accepted, "Repeat"), accepted)
})

testthat::test_that("power diagnosis respects the exact boundary and CSV", {
  for (p in c(0, 0.62, 0.79999)) testthat::expect_identical(power_diagnosis(p), "LOW")
  for (p in c(0.80, 0.82, 1)) testthat::expect_identical(power_diagnosis(p), "ACCEPTABLE")
  testthat::expect_error(power_diagnosis(NA_real_))
  table <- read_power_results(file.path(root, "data", "power_results.csv"))
  testthat::expect_equal(power_at_sample_size(table, 100), 0.62)
  testthat::expect_error(power_at_sample_size(table, 101))
})

testthat::test_that("live JSON is valid and retains the original hypothesis and graph", {
  for (workflow in list(eocene_workflow(), insert_matching_operation(eocene_workflow(), "Match taxa"),
                        australaves_workflow(), insert_matching_operation(australaves_workflow(), "Match taxa"))) {
    design <- build_design_export(workflow, hypotheses[[1]], parse_hypothesis(hypotheses[[1]])$concepts, list(), 100, 0.62)
    json <- workflow_to_json(design)
    testthat::expect_true(jsonlite::validate(json))
    decoded <- jsonlite::fromJSON(json)
    testthat::expect_identical(decoded$hypothesis, hypotheses[[1]])
    testthat::expect_equal(nrow(decoded$nodes), length(workflow$nodes))
  }
})


testthat::test_that("every DAG operation exports parseable suggested code in DAG order", {
  for (workflow in list(eocene_workflow(), insert_matching_operation(eocene_workflow(), "Custom procedure\nReview exclusions"),
                        australaves_workflow(), insert_matching_operation(australaves_workflow(), "Custom procedure\nReview exclusions"))) {
    for (node in workflow$nodes) {
      testthat::expect_true(nzchar(node$r_code))
      testthat::expect_no_error(parse(text = node$r_code))
    }
    design <- build_design_export(workflow, hypotheses[[1]], list(), list(), 100, 0.62)
    template <- analysis_template_preview(design)
    testthat::expect_no_error(parse(text = template))
    positions <- vapply(workflow$nodes, function(node) regexpr(paste0("# ", node$operation, "\n"), template, fixed = TRUE)[[1]], integer(1))
    testthat::expect_true(all(diff(positions) > 0))
    testthat::expect_identical(grepl("UNRESOLVED", template), !any(vapply(workflow$nodes, function(node) node$id == "matching", logical(1))))
    decoded <- jsonlite::fromJSON(workflow_to_json(design))
    testthat::expect_true(all(nzchar(decoded$nodes$r_code)))
  }
})

testthat::test_that("suggested rate model nests the baseline at multiplier one", {
  testthat::skip_if_not_installed("ape")
  env <- new.env()
  env$aligned_tree <- ape::read.tree(text = "((a:2,b:2):3,(c:3,d:3):2);")
  env$y <- c(a = 0.1, b = 0.7, c = 1.2, d = 0.4)
  env$tree_height <- 5
  depth <- ape::node.depth.edgelength(env$aligned_tree)
  older <- 5 - depth[env$aligned_tree$edge[, 1]]
  younger <- 5 - depth[env$aligned_tree$edge[, 2]]
  env$eocene_overlap <- pmax(0, pmin(older, 4) - pmax(younger, 2))
  testthat::expect_no_error(eval(parse(text = operation_r_code("baseline")), env))
  invisible(capture.output(eval(parse(text = operation_r_code("alternative")), env)))
  testthat::expect_equal(env$alternative_nll(c(env$baseline$par, 0)), env$baseline$value)
  testthat::expect_true(is.finite(env$alternative$value))
  testthat::expect_lte(env$alternative$value, env$baseline$value + 1e-6)
})
