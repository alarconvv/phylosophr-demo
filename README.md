# phyloSophR

A local R Shiny conceptual prototype for a PhD proposal defense.

## Run locally

Requires R and the `shiny`, `bslib`, `visNetwork`, `jsonlite`, and `ggplot2` packages installed in your R library.
From this directory, run:

```sh
Rscript -e 'shiny::runApp(".", host = "127.0.0.1", port = 3838, launch.browser = FALSE)'
```

Open http://127.0.0.1:3838 in your browser. Once dependencies are installed,
the application runs without internet access; fonts and assets are local.

## Current scope

Stage 1 provides an editable hypothesis and three selectable examples.
Stage 2 deterministically highlights recognized terms and displays structured
concepts for those examples. Unsupported input is explicitly identified.
Stage 3 assembles the Eocene/body-size workflow as nine directed operations, intentionally omitting tree-and-trait matching.
Click a node or use the operation selector to inspect its metadata. Download
the same R-list specification as JSON using the workflow download button.
Other hypotheses do not yet have workflow definitions.

Stage 4 runs a deterministic validation rule only when Validate workflow is
clicked. It reports the missing matching operation. Accept suggestion inserts it; Modify
opens a procedure editor and requires explicit application. Continue without
change opens the power profile with the warning retained. A session-local
Decision Log records the choice and is visible in both views. Selecting a new
hypothesis resets its workflow and log.

Stage 5 reads illustrative precomputed values from `data/power_results.csv`.
The sample-size slider selects table rows; no interpolation or simulations run.
At 100 taxa, illustrative power is 0.62; the target is 0.80. These are not
empirical findings or hypothesis-specific estimates.

Stage 6 summarizes the current hypothesis, entities, final DAG, researcher
decisions, and selected power value. The experimental design JSON is generated
from the live workflow and session state. R, Quarto, and provenance cards
provide labeled demonstration previews. No analyses, machine learning, or
simulations are executed.

A persistent six-stage indicator highlights the current step: HYPOTHESIS →
UNDERSTAND → BUILD → CHECK → TEST → DOCUMENT. All visual dependencies are served locally by R packages.

## Suggested R analysis code

Every DAG operation exposes **Suggested R code** in the operation inspector.
The **Annotated R analysis template** preview and its `.R` download concatenate
those suggestions in the current DAG order; workflow JSON also includes each
node's `r_code`. The accepted matching operation is included only after explicit
researcher acceptance. If matching is declined, the template stops immediately.
Custom matching instructions are preserved as comments; the default code must
be adapted manually to implement a custom procedure.

The app never executes these suggestions. Running them separately requires
`ape`, local `data/sampling_plan.csv` (taxon, logical include, rationale),
`data/mammal_tree.nwk`, and `data/body_size.csv` (taxon, positive numeric body_size
in one consistent unit). The suggested model assumes a rooted, dated,
ultrametric extant-only tree with branch lengths in Ma, a reviewed log trait
scale, and Gaussian Brownian motion. Supply reviewed Eocene boundaries and
explicitly approve exclusions and the trait scale before running. The alternative
integrates a rate multiplier over branch portions overlapping that interval.
AIC compares the two ML fits; uncertainty, identifiability, model adequacy,
measurement error, fossils, and dating sensitivity require further work. These
are conceptual code suggestions, not a validated scientific analysis pipeline.

## Offline code-help chatbot

Use **Ask about the R code** from workflow stages or the annotated template
preview. Select a current DAG operation and type a question, or use the
explanation, required-inputs, and assumptions prompts. Answers come from a
fixed local catalogue and simple topic matching, explicitly labeled Conceptual
Prototype; there is no language model, external API, or code execution.
Unsupported questions receive a scope explanation. Chat history keeps the
latest 20 exchanges in the session, with the newest first; Clear chat, a new
hypothesis, or Restart Demo clears it. The helper never changes methodological
choices, code, or the workflow.
