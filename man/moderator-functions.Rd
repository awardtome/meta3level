\name{m3cont}
\alias{m3cont}
\alias{m3group}
\alias{m3spline}
\title{Continuous, categorical, and spline moderator analyses}
\description{Fits centered continuous moderators, categorical moderators with
intercept and no-intercept parameterizations, and ML spline comparisons.}
\usage{
m3cont(data, var, name = var, method = "REML",
  level = c("three", "single"), rho = 0.60)

m3group(data, var, ref, name = var, method = "REML",
  level = c("three", "single"), rho = 0.60)

m3spline(data, var, df = 1:3, linear = TRUE, name = var,
  level = c("three", "single"), rho = 0.60)
}
\arguments{
\item{data}{Prepared effect-size data.}
\item{var}{Moderator column name.}
\item{name}{Display name.}
\item{method}{Estimation method.}
\item{level}{Use three-level or conventional single-level random-effects analysis.}
\item{rho}{Assumed within-study sampling correlation used for single-level pooling.}
\item{ref}{Reference category.}
\item{df}{Natural-spline degrees of freedom.}
\item{linear}{Include a conventional linear model.}
}
\value{A structured moderator-analysis result.}
