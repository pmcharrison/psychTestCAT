% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{assert_global_is_null}
\alias{assert_global_is_null}
\title{Assert that a global variable is NULL}
\usage{
assert_global_is_null(key, state)
}
\arguments{
\item{key}{(Character scalar)
Identifies the global variable to be checked.}

\item{state}{A psychTestR state object.}
}
\description{
This function checks whether a specified global variable
in a psychTestR state object is \code{NULL}.
If so, it throws an error.
}
