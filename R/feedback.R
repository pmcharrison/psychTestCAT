#' Feedback graph
#'
#' This function defines a feedback page for an adaptive test
#' created with psychTestRCAT,
#' plotting the participant's results against the results of previous participants.
#'
#' Each time that this page is seen by a participant,
#' the participant's score is written to a text file in psychTestR's
#' output directory.
#' This text file is used to build the population distribution for
#' the feedback graph, once sufficiently many people have taken the test.
#'
#' @param test_label (Character scalar)
#' Identifying label for the test (e.g. 'mdt'),
#' used to identify the file where participant results are accumulated.
#'
#' @param text_finish (Character scalar)
#' Text to display to the participant, defaults to "You finished the test!".
#'
#' @param text_score (Character scalar)
#' Text to prefix to the participant's score,
#' defaults to "Your final score:".
#'
#' @param text_rank (Character scalar)
#' Text to prefix to the participant's rank,
#' defaults to "Your rank compared to previous participants:".
#'
#' @param x_axis (Character scalar)
#' Label for the x-axis, corresponding to participant scores;
#' defaults to "Score".
#'
#' @param y_axis (Character scalar)
#' Label for the y-axis, corresponding to the count of participant scores;
#' defaults to "Count".
#'
#' @param next_button
#' (NULL or a character scalar or an object of class "shiny.tag")
#' If NULL, no next button is shown
#' (typically because the test has completed).
#' Otherwise, a button to progress to the next page is created,
#' displaying the content of this argument.
#'
#' @param digits (Integerish scalar)
#' Number of digits to which participant scores should be rounded.
#'
#' @param explain_IRT (Logical scalar)
#' If TRUE, the feedback page includes an academic explanation of
#' item response theory.
#' Currently only English language is supported.
#'
#' @return A test element suitable for inclusion in a psychTestR timeline
#' directly after \code{\link{adapt_test}}.
#' @export
cat.feedback.graph <- function(test_label,
                               text_finish = "You finished the test!",
                               text_score = "Your final score:",
                               text_rank = "Your rank compared to previous participants:",
                               x_axis = "Score",
                               y_axis = "Count",
                               next_button = NULL,
                               digits = 3L,
                               explain_IRT = TRUE) {
  stopifnot(is.scalar.character(test_label))
  loadNamespace("plotly")
  loadNamespace("ggplot2")
  c(
    cat.feedback.graph.manage_scores(test_label = test_label),
    cat.feedback.graph.display_scores(text_finish = text_finish,
                                      text_score = text_score,
                                      text_rank = text_rank,
                                      x_axis = x_axis, y_axis = y_axis,
                                      next_button = next_button,
                                      digits = digits,
                                      explain_IRT = explain_IRT)
  )
}

cat.feedback.graph.manage_scores <- function(test_label) {
  psychTestR::code_block(function(answer, opt, state, ...) {
    score <- answer$ability
    stopifnot(is.scalar.numeric(score))
    file <- file.path(psychTestR::get_supplementary_results_dir(opt),
                      paste0(test_label, "_final_scores.txt"))
    write(score, file, append = TRUE)
    all_scores <- as.numeric(read.table(file)[[1]])
    num_scores <- length(all_scores)
    rank <- cat.feedback.graph.get_rank(all_scores)
    psychTestR::set_local(key = "cat_results",
                          value = list(score = as.numeric(score),
                                       all_scores = all_scores,
                                       num_scores = num_scores,
                                       rank = rank),
                          state = state)
  })
}

cat.feedback.graph.get_rank <- function(all_scores) {
  num_scores <- length(all_scores)
  num_scores + 1L - rank(all_scores, ties.method = "max")[num_scores]
}

cat.feedback.graph.display_scores <- function(text_finish, text_score, text_rank,
                                              x_axis, y_axis,
                                              next_button, digits,
                                              explain_IRT) {
  stopifnot(is.scalar.character(x_axis),
            is.scalar.character(y_axis),
            is.scalar.character(text_finish) || is(text_finish, "shiny.tag"),
            is.scalar.character(text_score) || is(text_score, "shiny.tag"),
            is.scalar.character(text_rank) || is(text_rank, "shiny.tag"),
            is.null(next_button) || is.scalar.character(next_button) ||
              is(next_button, "shiny.tag"),
            is.scalar.integerlike(digits),
            is.scalar.logical(explain_IRT))
  psychTestR::reactive_page(function(state, ...) {
    res <- psychTestR::get_local(key = "cat_results", state = state)
    psychTestR::page(
      ui = shiny::div(
        shiny::p(text_finish),
        shiny::p(text_score, shiny::strong(round(res$score, digits = digits))),
        shiny::p(text_rank, shiny::strong(sprintf("%i/%i", res$rank, res$num_scores))),
        if (res$num_scores > 1L)
          shiny::div(
            cat.feedback.graph.plot_cat_results(res, x_axis = x_axis, y_axis = y_axis),
            if (explain_IRT)
              shiny::div(
                shiny::p(
                  "Scores are plotted on an",
                  shiny::tags$a(href = "https://en.wikipedia.org/wiki/Item_response_theory",
                                "item response theory"),
                  "metric, where the mean score in the general population is approximately 0,",
                  "and the standard deviation in the population is approximately 1."),
                shiny::p(
                  "Your score places you in the top",
                  shiny::strong(paste0(100 - round(100 * stats::pnorm(res$score)), "%")),
                  "of the general population.")
              ),
            style = "border-style: solid; border-width: 1px; background-color: white;"),
        if (!is.null(next_button))
          shiny::p(psychTestR::trigger_button("next", next_button))
      )
    )
  })
}

cat.feedback.graph.plot_cat_results <- function(res, x_axis, y_axis) {
  if (!is.list(res)) stop("<cat_results> was malformed, looking like this: ",
                          utils::capture.output(print(res)))
  num_bins <- pmax(16, ceiling(log2(res$num_scores)) + 1)
  stopifnot(is.scalar.character(x_axis),
            is.scalar.character(y_axis),
            is.list(res),
            is.numeric(res$all_scores))
  plotly::ggplotly(ggplot2::ggplot(
    data.frame(Score = res$all_scores), ggplot2::aes_string(x = "Score")
  ) + ggplot2::geom_histogram(bins = num_bins,
                              colour = "#004d66",
                              fill = "#00ace6") +
    ggplot2::geom_vline(xintercept = res$score, colour = "#e60000") +
    ggplot2::scale_x_continuous(x_axis) +
    ggplot2::scale_y_continuous(y_axis) +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid = ggplot2::element_blank()),
  height = 300)
  # panel.background = ggplot2::element_rect(fill = "#f7f7f7"))
  # width = 300, height = 300)
}