library(shiny)
source("R/hypothesis_parser.R", local = TRUE)
source("R/operation_code.R", local = TRUE)
source("R/code_help.R", local = TRUE)
source("R/workflow_library.R", local = TRUE)
source("R/logic_validator.R", local = TRUE)
source("R/power_profile.R", local = TRUE)
source("R/export_demo.R", local = TRUE)
power_results <- read_power_results()

example_hypotheses <- c(
  "Test if body size evolution accelerated during the Eocene in mammals.",
  "Was the ancestor of Australaves a medium-sized bird?",
  "Is body size associated with habitat after accounting for phylogeny?"
)
example_topics <- c("Evolutionary rates", "Ancestral states", "Trait associations")

ui <- bslib::page_fluid(
  title = "phyloSophR | Hypothesis Input",
  theme = bslib::bs_theme(version = 5, bootswatch = "flatly",
                         bg = "#ECF0F1", fg = "#212529",
                         base_font = bslib::font_google("IBM Plex Sans"),
                         code_font = bslib::font_google("IBM Plex Mono")),
  tags$head(tags$link(rel = "stylesheet", href = "custom.css"), tags$script(src = "demo.js")),
  div(class = "app-shell",
    tags$header(class = "page-header",
      div(class = "header-top",
        div(class = "brand-row",
          tags$img(src = "logo.png", class = "brand-logo", alt = "", width = "52", height = "52"),
          div(
            h1(tags$span(class = "brand", "phyloSophR"),
               "A phylogenetic comparative experimental design assistant"),
            p(class = "page-subtitle", "From a hypothesis to a reproducible experimental design")
          )
        ),
        div(class = "header-actions",
          span(class = "prototype-badge", "Conceptual Prototype"),
          actionButton("restart_demo", "Restart Demo", class = "btn-outline-primary restart-button")
        )
      )
    ),
    uiOutput("stage_indicator"),
    conditionalPanel(
      condition = "output.current_stage == 1",
      tags$main(class = "workspace",
        div(class = "section-heading",
          h2("A biological question. An explicit design."),
          p("Describe the relationship or evolutionary pattern you want to investigate.")
        ),
        textAreaInput("hypothesis", "What is your biological hypothesis?",
                      value = example_hypotheses[[1]], width = "100%", rows = 4),
        div(class = "examples-heading", "Or start with an example"),
        div(class = "example-grid",
          lapply(seq_along(example_hypotheses), function(i) {
            actionButton(paste0("example_", i), class = "example-card",
              label = tagList(span(class = "example-topic", example_topics[[i]]),
                              span(class = "example-text", example_hypotheses[[i]]),
                              span(class = "example-action", "Use hypothesis →")))
          })
        ),
        div(class = "action-row",
          p(class = "helper-text", "Your hypothesis is the starting point. Methodological decisions remain yours."),
          actionButton("analyze", "Analyze hypothesis", class = "btn-primary analyze-button")
        ),
        div(class = "input-error", role = "alert", textOutput("input_error"))
      )
    ),
    conditionalPanel(
      condition = "output.current_stage == 2",
      tags$main(class = "workspace stage-panel",
        h2("Hypothesis Parsing"),
        p("Review the recognized terms and the structured interpretation of your question."),
        div(class = "examples-heading", "Original hypothesis"),
        tags$blockquote(textOutput("submitted_hypothesis")),
        uiOutput("parsed_hypothesis"),
        tags$details(class = "system-explanation",
          tags$summary("What happens in the full system?"),
          p("In the complete phyloSophR architecture, domain-specific language models will extract these entities and relations directly from free text. This prototype shows the output that step is expected to produce, using three fixed examples rather than live extraction.")
        ),
        div(class = "action-row",
          actionButton("back", "← Back to hypothesis", class = "btn-outline-primary"),
          uiOutput("build_control")
        )
      )
    ),
    conditionalPanel(
      condition = "output.current_stage == 3",
      tags$main(class = "workspace stage-panel",
        h2("Workflow Assembly"),
        p("An explicit sequence of analytical operations. Select a node to inspect its purpose, inputs, and assumptions."),
        uiOutput("workflow_content"),
        actionButton("back_to_parsing", "← Back to parsing", class = "btn-outline-primary")
      )
    ),
    conditionalPanel(
      condition = "output.current_stage == 4",
      tags$main(class = "workspace",
        h2("Logic Validation"),
        p("A human-in-the-loop checkpoint: review the design before proceeding to analysis."),
        div(`aria-live` = "polite", `aria-atomic` = "true", uiOutput("validation_result")),
        uiOutput("decision_log_panel"),
        uiOutput("power_continue"),
        actionButton("back_to_workflow", "← Back to workflow", class = "btn-outline-primary")
      )
    ),
    conditionalPanel(
      condition = "output.current_stage == 5",
      tags$main(class = "workspace",
        h2("Power Profile"),
        p("Illustrative, precomputed results: see how sample size affects statistical power in a fixed conceptual scenario. These values are not empirical findings or power estimates for your actual study."),
        div(class = "power-layout",
          div(class = "power-chart", plotOutput("power_plot", height = "380px")),
          div(class = "power-controls",
            sliderInput("sample_size", "Proposed sample size (taxa)",
              min = min(power_results$taxa), max = max(power_results$taxa),
              value = 100, step = diff(power_results$taxa)[[1]], sep = ""),
            uiOutput("power_summary")
          )
        ),
        uiOutput("power_workflow_warning"),
        p(class = "power-note", "Precomputed results are used for this conceptual prototype. The complete architecture will generate hypothesis-specific simulations from workflow parameters."),
        div(class = "action-row",
          actionButton("back_to_validation", "← Back to validation", class = "btn-outline-primary"),
          actionButton("view_outputs", "View reproducible outputs", class = "btn-primary analyze-button"))
      )
    ),
    conditionalPanel(
      condition = "output.current_stage == 6",
      tags$main(class = "workspace",
        span(class = "prototype-badge", "Conceptual Prototype"),
        h2("Experimental design ready for preregistration"),
        p("Review the full specification and any unresolved warnings before an actual preregistration. Committing to this design before data collection is what makes it resistant to p-hacking and HARKing."),
        uiOutput("final_summary"),
        tags$details(class = "final-dag", open = "open",
          tags$summary("Final DAG"),
          div(role = "img",
            `aria-label` = "Final visual diagram of the experimental design workflow, matching the operations already listed above and in the Decision Log.",
            visNetwork::visNetworkOutput("final_graph", height = "470px"))),
        uiOutput("final_decisions"),
        h3(class = "export-heading", "Reproducible Outputs"),
        div(class = "export-grid",
          div(class = "export-card", span(class = "status-tag status-tag--live", "Live export"), h3("Experimental design JSON"),
            p("The full session record: hypothesis, extracted entities, current DAG, decision log, and illustrative power selection."),
            downloadButton("final_json", "Download JSON")),
          div(class = "export-card", span(class = "status-tag status-tag--preview", "Demonstration preview"), h3("Annotated R analysis template"),
            p("Suggested R code for every operation in the current DAG, with explicit researcher review checkpoints."),
            actionButton("preview_r", "Preview R template", class = "btn-outline-primary"),
            downloadButton("analysis_r", "Download R template")),
          div(class = "export-card", span(class = "status-tag status-tag--preview", "Demonstration preview"), h3("Quarto preregistration report"),
            p("A draft structure reflecting this session’s experimental design."),
            actionButton("preview_quarto", "Preview Quarto report", class = "btn-outline-primary")),
          div(class = "export-card", span(class = "status-tag status-tag--preview", "Demonstration preview"), h3("Decision/provenance log"),
            p("Researcher choices, timestamps, warnings, and the power-data source."),
            actionButton("preview_log", "Preview provenance log", class = "btn-outline-primary"))
        ),
        actionButton("back_to_power", "← Back to power profile", class = "btn-outline-primary")
      )
    ),
    conditionalPanel(condition = "output.current_stage >= 3",
      div(class = "code-help-launch",
        actionButton("open_code_help", "Ask about the R code", class = "btn-outline-primary"),
        span(class = "helper-text", "Offline code-help chatbot · Conceptual Prototype"))),
    tags$footer(class = "page-footer",
      span("phyloSophR · PhD proposal demonstration"),
      span("Local prototype · No external services")
    )
  )
)

server <- function(input, output, session) {
  stage <- reactiveVal(1L)
  submitted <- reactiveVal("")
  error <- reactiveVal("")
  code_chat <- reactiveVal(list())

  output$current_stage <- renderText(stage())
  outputOptions(output, "current_stage", suspendWhenHidden = FALSE)
  output$stage_indicator <- renderUI({
    labels <- c("HYPOTHESIS", "UNDERSTAND", "BUILD", "CHECK", "TEST", "DOCUMENT")
    tags$nav(class = "progress-navigation", `aria-label` = "Experimental design progress",
      tags$ol(class = "progress-stages", lapply(seq_along(labels), function(i) {
        tags$li(class = paste("progress-stage", if (i == stage()) "is-current" else ""),
          `aria-current` = if (i == stage()) "step" else NULL,
          span(class = "progress-number", sprintf("%02d", i)),
          span(class = "progress-label", labels[[i]]))
      }))
    )
  })

  lapply(seq_along(example_hypotheses), function(i) {
    observeEvent(input[[paste0("example_", i)]], {
      updateTextAreaInput(session, "hypothesis", value = example_hypotheses[[i]])
      error("")
    })
  })
  observeEvent(input$hypothesis, { error("") }, ignoreInit = TRUE)
  observeEvent(input$analyze, {
    req(stage() == 1L, !is.null(input$hypothesis))
    hypothesis <- trimws(input$hypothesis)
    if (nchar(hypothesis) > 2000L) {
      error("Please keep the hypothesis under 2,000 characters.")
      return()
    }
    if (!nzchar(hypothesis)) {
      error("Please enter a biological hypothesis before continuing.")
      return()
    }
    error("")
    if (identical(submitted(), hypothesis)) reset_design(hypothesis)
    submitted(hypothesis)
    stage(2L)
  })
  observeEvent(input$back, { req(stage() == 2L); stage(1L) })
  parsed <- reactive(parse_hypothesis(submitted()))
  output$parsed_hypothesis <- renderUI({
    result <- parsed()
    if (is.null(result)) {
      return(div(class = "unsupported-message", role = "status",
        "This hypothesis is not one of the three demonstration examples. Go back and select an example to view its structured output."))
    }
    tagList(
      div(class = "examples-heading", "Recognized terms · deterministic demonstration"),
      div(class = "recognized-hypothesis", highlight_hypothesis(submitted(), result$terms)),
      div(class = "examples-heading", "Extracted concepts"),
      div(class = "concept-grid", lapply(names(result$concepts), function(label) {
        div(class = "concept-card", span(class = "concept-label", label),
            span(class = "concept-value", result$concepts[[label]]))
      }))
    )
  })
  output$build_control <- renderUI({
    if (is.null(parsed())) return(NULL)
    actionButton("build", "Build experimental design", class = "btn-primary analyze-button")
  })
  observeEvent(input$build, {
    req(stage() == 2L, !is.null(parsed()))
    stage(3L)
  })
  workflow <- reactiveVal(NULL)
  validation <- reactiveVal(NULL)
  decision_log <- reactiveVal(list())
  review_status <- reactiveVal("pending")
  reset_design <- function(hypothesis = "") {
    result <- parse_hypothesis(hypothesis)
    class <- if (is.null(result)) NA_character_ else result$concepts[["Hypothesis class"]]
    workflow(switch(class, "Trait evolution" = eocene_workflow(),
                     "Ancestral state" = australaves_workflow(), NULL))
    validation(NULL)
    decision_log(list())
    code_chat(list())
    review_status("pending")
    selected_node(if (is.null(workflow())) "hypothesis" else workflow()$nodes[[1]]$id)
    updateSliderInput(session, "sample_size", value = 100)
  }
  observeEvent(submitted(), { reset_design(submitted()) }, ignoreNULL = FALSE)
  observeEvent(input$restart_demo, {
    removeModal()
    reset_design()
    submitted("")
    error("")
    updateTextAreaInput(session, "hypothesis", value = example_hypotheses[[1]])
    stage(1L)
    session$sendCustomMessage("demo-reset", list())
  }, priority = 100)
  observeEvent(stage(), { session$sendCustomMessage("demo-stage", list()) })
  observeEvent(input$validate_workflow, {
    req(stage() == 3L, !is.null(workflow()))
    stage(4L)
    validation(validate_workflow_logic(workflow()))
  })
  record_decision <- function(action, detail, warning) {
    entry <- list(time = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
      action = action, detail = detail, warning = warning,
      rule = "tree_trait_alignment_required")
    decision_log(append(decision_log(), list(entry)))
  }
  apply_matching <- function(purpose, action) {
    req(stage() == 4L, review_status() == "pending", !is.null(workflow()))
    workflow(insert_matching_operation(workflow(), purpose))
    record_decision(action, paste("Inserted Match tree and trait data after Obtain body-size data.", purpose), "Resolved in design; analysis has not been executed.")
    review_status("accepted")
    validation(validate_workflow_logic(workflow()))
  }
  observeEvent(input$accept_suggestion, {
    apply_matching("Align tree tips and trait rows by taxon; document discrepancies and exclusions.", "Accepted suggestion")
  })
  observeEvent(input$modify_suggestion, {
    req(stage() == 4L, review_status() == "pending")
    showModal(modalDialog(title = "Modify matching operation",
      p("Specify how taxon matching should be performed. The operation will be inserted after body-size data collection only when you apply it."),
      textAreaInput("matching_purpose", "Matching procedure / purpose",
        value = "Align tree tips and trait rows by taxon; document discrepancies and exclusions.", rows = 4, width = "100%"),
      footer = tagList(modalButton("Cancel"), actionButton("apply_modified", "Apply modified suggestion", class = "btn-primary"))))
  })
  observeEvent(input$apply_modified, {
    req(input$matching_purpose)
    purpose <- trimws(input$matching_purpose)
    if (!nzchar(purpose)) {
      showNotification("Enter a matching procedure before applying.", type = "warning")
      return()
    }
    apply_matching(purpose, "Applied modified suggestion")
    removeModal()
  })
  observeEvent(input$continue_unchanged, {
    req(stage() == 4L, review_status() == "pending", validation(), !validation()$valid)
    record_decision("Continued without change", "Researcher retained the original workflow.", validation()$reason)
    review_status("declined")
    stage(5L)
  })
  output$validation_result <- renderUI({
    req(stage() == 4L, validation())
    result <- validation()
    if (result$valid) return(div(class = "validation-finding is-resolved", role = "status",
      h3("Matching operation added"),
      p("The design now includes taxon matching before model fitting. This resolves the demonstration rule; no data checks or analyses have been executed.")))
    div(class = "validation-finding", role = "alert",
      span(class = "status-tag status-tag--warning", "Researcher review required"),
      h3(result$title), p(result$reason),
      tags$dl(tags$dt("Suggested operation"), tags$dd(result$suggestion)),
      if (review_status() == "pending") div(class = "review-actions",
        actionButton("accept_suggestion", "Accept suggestion", class = "btn-primary"),
        actionButton("modify_suggestion", "Modify", class = "btn-outline-primary"),
        actionButton("continue_unchanged", "Continue without change", class = "btn-outline-secondary")
      ) else p("Warning retained: researcher chose to continue without changing the workflow.")
    )
  })
  log_ui <- function() {
    entries <- decision_log()
    tags$section(class = "decision-log", `aria-label` = "Decision Log",
      h3("Decision Log"),
      if (!length(entries)) p("No decisions recorded. The workflow is unchanged.") else
        tagList(lapply(entries, function(entry) {
          div(class = "decision-entry", strong(entry$action),
            div(class = "decision-time", entry$time), p(entry$detail), p(entry$warning))
        }))
    )
  }
  output$power_continue <- renderUI({
    if (review_status() == "pending") return(NULL)
    div(class = "workflow-download", actionButton("view_power", "Explore power profile", class = "btn-primary analyze-button"))
  })
  observeEvent(input$view_power, {
    req(stage() == 4L, review_status() != "pending")
    stage(5L)
  })
  observeEvent(input$back_to_validation, { req(stage() == 5L); stage(4L) })
  selected_power <- reactive({
    req(input$sample_size)
    validate(need(input$sample_size %in% power_results$taxa, "Select a sample size from the slider."))
    power_at_sample_size(power_results, input$sample_size)
  })
  output$power_plot <- renderPlot({
    req(input$sample_size)
    selected_power()
    plot_power_profile(power_results, input$sample_size)
  }, res = 110, alt = "Illustrative statistical power by number of taxa, with a horizontal target of 0.80 and the selected sample size highlighted.")
  output$power_summary <- renderUI({
    value <- selected_power()
    div(class = "power-summary", role = "status", `aria-live` = "polite",
      h3(sprintf("Illustrative estimate: power = %.2f", value)),
      if (value < 0.80) tagList(
        p(class = "power-warning", "Warning: this design does not reach the target power of 0.80."),
        p("Consider increasing taxon sampling.")
      ) else p(class = "power-success", "Target power reached."),
      p(class = "helper-text", paste("Fixed demonstration effect size:", unique(power_results$effect_size),
        "· Slider uses only sample sizes in the precomputed table."))
    )
  })
  output$power_workflow_warning <- renderUI({
    if (review_status() != "declined") return(NULL)
    div(class = "unsupported-message", "Unresolved workflow warning: tree-and-trait matching is still missing. Reaching the illustrative power target does not resolve this gap.")
  })
  design_export <- reactive({
    req(workflow(), parsed(), input$sample_size)
    build_design_export(workflow(), submitted(), parsed()$concepts,
      decision_log(), input$sample_size, selected_power())
  })
  observeEvent(input$view_outputs, {
    req(stage() == 5L, workflow())
    stage(6L)
  })
  observeEvent(input$back_to_power, { req(stage() == 6L); stage(5L) })
  output$final_summary <- renderUI({
    design <- design_export()
    tagList(
      h3(class = "export-heading", "Hypothesis"), tags$blockquote(design$hypothesis),
      h3(class = "export-heading", "Extracted entities"),
      div(class = "concept-grid", lapply(names(design$extracted_entities), function(label) {
        div(class = "concept-card", span(class = "concept-label", label),
          span(class = "concept-value", design$extracted_entities[[label]]))
      })),
      h3(class = "export-heading", "Power Profile summary"),
      p(sprintf("Proposed sample size: %s taxa · Estimated power = %.2f · Target = 0.80",
        design$power_profile$taxa, design$power_profile$estimated_power)),
      p(if (selected_power() >= 0.80) "Target power reached." else
        "Warning: this design does not reach the target power of 0.80. Consider increasing taxon sampling."),
      p(class = "helper-text", "Illustrative precomputed values only; not empirical or hypothesis-specific results."),
      if (review_status() == "declined") div(class = "unsupported-message",
        "Unresolved workflow warning: tree-and-trait matching remains absent by researcher decision.")
    )
  })
  output$final_decisions <- renderUI(log_ui())
  output$final_graph <- visNetwork::renderVisNetwork({
    req(workflow())
    presentation_workflow_graph(workflow())
  })
  output$final_json <- downloadHandler(
    filename = function() "phylosophr-experimental-design.json",
    content = function(file) writeLines(workflow_to_json(design_export()), file, useBytes = TRUE),
    contentType = "application/json"
  )
  output$analysis_r <- downloadHandler(
    filename = function() "phylosophr-analysis-template.R",
    content = function(file) writeLines(analysis_template_preview(design_export()), file, useBytes = TRUE),
    contentType = "text/plain"
  )
  show_preview <- function(title, text) {
    showModal(modalDialog(title = title, size = "l",
      p(class = "prototype-badge", "Conceptual Prototype · Demonstration preview"),
      tags$pre(class = "export-preview", text), easyClose = TRUE,
      footer = tagList(actionButton("preview_code_help", "Ask about the R code", class = "btn-outline-primary"), modalButton("Close"))))
  }
  open_code_chat <- function() {
    req(workflow())
    nodes <- workflow()$nodes
    showModal(modalDialog(title = "R code-help chatbot", size = "l", easyClose = TRUE,
      p(class = "prototype-badge", "Conceptual Prototype · Offline, prepared explanations · No AI model"),
      p("Select an operation and ask about its suggested R code. Your questions stay in this session; the chatbot does not execute code or change the design."),
      selectInput("help_operation", "Operation to explain",
        choices = stats::setNames(vapply(nodes, `[[`, character(1), "id"),
          vapply(nodes, `[[`, character(1), "operation")), selected = selected_node()),
      uiOutput("code_chat_history"),
      textAreaInput("code_question", "Your question", rows = 2, width = "100%",
        placeholder = "For example: Why might this code stop?"),
      div(class = "review-actions",
        actionButton("code_ask", "Send question", class = "btn-primary",
          onclick = "Shiny.setInputValue('code_question', document.getElementById('code_question').value, {priority: 'event'});"),
        actionButton("code_explain", "Explain this operation", class = "btn-outline-primary"),
        actionButton("code_inputs", "Show required inputs", class = "btn-outline-primary"),
        actionButton("code_assumptions", "Show assumptions to review", class = "btn-outline-primary")),
      footer = tagList(actionButton("clear_code_chat", "Clear chat", class = "btn-outline-secondary"), modalButton("Close"))))
  }
  observeEvent(input$open_code_help, { open_code_chat() })
  observeEvent(input$preview_code_help, { open_code_chat() })
  answer_code_question <- function(question) {
    req(workflow(), input$help_operation)
    nodes <- workflow()$nodes
    index <- which(vapply(nodes, function(node) identical(node$id, input$help_operation), logical(1)))
    req(length(index) == 1L)
    node <- nodes[[index]]
    if (is.null(question) || !nzchar(trimws(question)) || nchar(question) > 1000L) {
      showNotification("Enter a question of 1–1,000 characters.", type = "warning")
      return()
    }
    entry <- list(operation = node$operation, question = question, answer = code_help_reply(node, question))
    code_chat(tail(append(code_chat(), list(entry)), 20L))
    updateTextAreaInput(session, "code_question", value = "")
  }
  observeEvent(input$code_ask, { answer_code_question(input$code_question) })
  observeEvent(input$code_explain, { answer_code_question("Explain this operation") })
  observeEvent(input$code_inputs, { answer_code_question("What inputs do I need?") })
  observeEvent(input$code_assumptions, { answer_code_question("What assumptions should I review?") })
  observeEvent(input$clear_code_chat, { code_chat(list()) })
  output$code_chat_history <- renderUI({
    entries <- rev(code_chat())
    div(class = "code-chat-history", role = "log", `aria-live` = "polite",
      if (!length(entries)) p("Ask a question to see an explanation here.") else
        lapply(entries, function(entry) {
          div(class = "code-chat-exchange",
            p(class = "eyebrow", entry$operation),
            p(strong("You: "), entry$question),
            div(class = "code-chat-answer", strong("Code helper: "), entry$answer))
        }))
  })
  observeEvent(input$preview_r, {
    req(stage() == 6L)
    show_preview("Annotated R analysis template", analysis_template_preview(design_export()))
  })
  observeEvent(input$preview_quarto, {
    req(stage() == 6L)
    show_preview("Quarto preregistration report", preregistration_preview(design_export()))
  })
  observeEvent(input$preview_log, {
    req(stage() == 6L)
    design <- design_export()
    show_preview("Decision/provenance log", jsonlite::toJSON(list(
      prototype = "Conceptual Prototype", hypothesis = design$hypothesis,
      decisions = design$decision_log, power_source = design$power_profile,
      workflow_status = design$status), auto_unbox = TRUE, pretty = TRUE))
  })
  output$decision_log_panel <- renderUI(log_ui())
  output$workflow_decisions <- renderUI(log_ui())
  observeEvent(input$back_to_workflow, { req(stage() == 4L); stage(3L) })
  selected_node <- reactiveVal("hypothesis")
  output$workflow_content <- renderUI({
    design <- workflow()
    if (is.null(design)) {
      return(div(class = "unsupported-message",
        "Workflow assembly is currently available for the Eocene/body-size and Australaves ancestral-state examples only. Go back to the Hypothesis step and select one of those examples to continue."))
    }
    tagList(
      div(class = "workflow-caption", paste(length(design$nodes), "operations · Directed sequence · Design only, no analyses executed")),
      div(class = "workflow-layout",
        div(class = "workflow-canvas", role = "img",
          `aria-label` = "Visual diagram of the workflow operations in sequence. Not keyboard operable; use the ‘Inspect an operation’ dropdown to browse the same information.",
          visNetwork::visNetworkOutput("workflow_graph", height = "470px", width = "100%")),
        tags$aside(class = "workflow-inspector", `aria-label` = "Operation details",
          selectInput("node_picker", "Inspect an operation",
            choices = stats::setNames(vapply(design$nodes, `[[`, character(1), "id"),
                                     vapply(design$nodes, `[[`, character(1), "operation")),
            selected = design$nodes[[1]]$id),
          uiOutput("node_metadata")
        )
      ),
      tags$details(class = "compact-log", tags$summary("Decision Log"), uiOutput("workflow_decisions")),
      div(class = "action-row workflow-download",
        downloadButton("workflow_json", "Download workflow JSON"),
        actionButton("validate_workflow", "Validate workflow", class = "btn-primary analyze-button"))
    )
  })
  output$workflow_graph <- visNetwork::renderVisNetwork({
    req(workflow())
    network <- presentation_workflow_graph(workflow())
    visNetwork::visEvents(network, selectNode =
      "function(params) { Shiny.setInputValue('graph_node', params.nodes[0], {priority: 'event'}); }")
  })
  observeEvent(input$graph_node, {
    req(workflow())
    ids <- vapply(workflow()$nodes, `[[`, character(1), "id")
    req(input$graph_node %in% ids)
    selected_node(input$graph_node)
    updateSelectInput(session, "node_picker", selected = input$graph_node)
  })
  observeEvent(input$node_picker, {
    req(stage() == 3L, workflow(), input$node_picker)
    req(input$node_picker %in% vapply(workflow()$nodes, `[[`, character(1), "id"))
    selected_node(input$node_picker)
    visNetwork::visSelectNodes(visNetwork::visNetworkProxy("workflow_graph"), id = input$node_picker)
  })
  output$node_metadata <- renderUI({
    req(workflow())
    nodes <- workflow()$nodes
    match <- which(vapply(nodes, function(node) identical(node$id, selected_node()), logical(1)))
    req(length(match) == 1L)
    node <- nodes[[match]]
    fields <- c("Operation" = "operation", "Purpose" = "purpose",
                "Required inputs" = "required_inputs", "Expected output" = "expected_output",
                "Assumptions" = "assumptions")
    tagList(tags$dl(lapply(names(fields), function(label) {
      values <- node[[fields[[label]]]]
      tagList(tags$dt(label), tags$dd(if (length(values) > 1L) {
        tags$ul(lapply(values, tags$li))
      } else values))
    })),
      tags$details(class = "operation-code",
        tags$summary("Suggested R code"),
        p(class = "helper-text", "Conceptual Prototype · Run in DAG order after reviewing inputs and methodological choices. Code is not executed by this app."),
        tags$pre(class = "export-preview", node$r_code))
    )
  })
  output$workflow_json <- downloadHandler(
    filename = function() "phylosophr-eocene-workflow.json",
    content = function(file) {
      req(workflow())
      writeLines(workflow_to_json(workflow()), file, useBytes = TRUE)
    }, contentType = "application/json"
  )
  observeEvent(input$back_to_parsing, { req(stage() == 3L); stage(2L) })
  output$input_error <- renderText(error())
  output$submitted_hypothesis <- renderText(submitted())
}

shinyApp(ui, server)
