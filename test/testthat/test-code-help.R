root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
for (file in c("operation_code.R", "workflow_library.R", "logic_validator.R", "code_help.R")) {
  source(file.path(root, "R", file), local = TRUE)
}

testthat::test_that("offline help covers every operation without changing its code", {
  workflows <- list(insert_matching_operation(eocene_workflow(), "Review exact identifiers"),
                    insert_matching_operation(australaves_workflow(), "Review exact identifiers"))
  for (workflow in workflows) {
    original <- workflow
    for (node in workflow$nodes) {
      testthat::expect_false(grepl("No explanation", operation_explanation(node$id)))
      testthat::expect_match(code_help_reply(node, "Explain this operation"), operation_explanation(node$id), fixed = TRUE)
      testthat::expect_match(code_help_reply(node, "Required inputs"), node$required_inputs[[1]], fixed = TRUE)
      testthat::expect_match(code_help_reply(node, "What assumptions should I review?"), node$assumptions, fixed = TRUE)
      testthat::expect_match(code_help_reply(node, "Why does it stop?"), "does not inspect your R session", fixed = TRUE)
    }
    testthat::expect_identical(workflow, original)
  }
})

testthat::test_that("unsupported and invalid questions get explicit boundaries", {
  node <- eocene_workflow()$nodes[[1]]
  testthat::expect_match(code_help_reply(node, ""), "Enter a question")
  testthat::expect_match(code_help_reply(node, NA_character_), "Enter a question")
  testthat::expect_match(code_help_reply(node, paste(rep("x", 1001), collapse = "")), "1,000")
  testthat::expect_match(code_help_reply(node, "Write a poem"), "prepared explanations")
})
