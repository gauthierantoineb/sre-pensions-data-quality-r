#!/usr/bin/env Rscript
if (!requireNamespace("testthat", quietly = TRUE)) stop("Installer testthat.")
testthat::test_dir("tests/testthat", reporter = "summary")
