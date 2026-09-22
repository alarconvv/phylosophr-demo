# Fixed demonstration outputs, not NLP predictions.
parse_hypothesis <- function(hypothesis) {
  normalize <- function(x) tolower(gsub("[[:space:]]+", " ", trimws(x)))
  scenarios <- list(
    list(
      hypothesis = "Test if body size evolution accelerated during the Eocene in mammals.",
      terms = c("body size", "accelerated", "Eocene", "mammals"),
      concepts = c("Trait" = "Body size", "Taxonomic group" = "Mammals",
                   "Evolutionary process" = "Rate variation", "Temporal context" = "Eocene",
                   "Hypothesis class" = "Trait evolution")
    ),
    list(
      hypothesis = "Was the ancestor of Australaves a medium-sized bird?",
      terms = c("ancestor", "Australaves", "medium-sized"),
      concepts = c("Trait" = "Body size", "Taxonomic group" = "Australaves",
                   "Evolutionary process" = "Ancestral state reconstruction",
                   "Proposed ancestral state" = "Medium-sized",
                   "Hypothesis class" = "Ancestral state")
    ),
    list(
      hypothesis = "Is body size associated with habitat after accounting for phylogeny?",
      terms = c("body size", "associated with", "habitat", "phylogeny"),
      concepts = c("Trait" = "Body size", "Predictor" = "Habitat",
                   "Relationship" = "Association", "Adjustment" = "Phylogeny",
                   "Hypothesis class" = "Phylogenetic association")
    )
  )
  for (scenario in scenarios) {
    if (identical(normalize(hypothesis), normalize(scenario$hypothesis))) {
      return(scenario)
    }
  }
  NULL
}

# Assemble text nodes and mark tags; never interpret hypothesis text as HTML.
highlight_hypothesis <- function(hypothesis, terms) {
  pieces <- list()
  remaining <- hypothesis
  while (nzchar(remaining)) {
    positions <- vapply(terms, function(term) {
      as.integer(regexpr(tolower(term), tolower(remaining), fixed = TRUE)[1])
    }, integer(1))
    if (!any(positions > 0L)) {
      pieces <- append(pieces, list(remaining))
      break
    }
    positions[positions < 0L] <- .Machine$integer.max
    term_index <- which.min(positions)
    start <- positions[[term_index]]
    end <- start + nchar(terms[[term_index]]) - 1L
    if (start > 1L) pieces <- append(pieces, list(substr(remaining, 1L, start - 1L)))
    pieces <- append(pieces, list(shiny::tags$mark(substr(remaining, start, end))))
    remaining <- substring(remaining, end + 1L)
  }
  shiny::tagList(pieces)
}
