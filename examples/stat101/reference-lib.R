# Shared helpers for the reference analyses (examples/stat101/*/reference.R).
# Run from examples/stat101/ so the uvr project is used:
#   uvr run 01-sleep/reference.R > 01-sleep/reference.out
# or all of them with ./run-references.sh.
#
# report() prints a labelled value and remembers it; finish() writes the
# remembered values to expected.json next to the script. These are the
# numbers a working Lisp version must reproduce.

.file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
example_dir <- dirname(.file)
.expected <- list()

section <- function(title) cat("\n## ", title, "\n", sep = "")

report <- function(key, value, digits = 7) {
  if (!is.null(.expected[[key]])) stop("report(): key reported twice: ", key)
  # named vectors become JSON objects, so the names are kept
  .expected[[key]] <<- if (is.null(names(value))) value else as.list(value)
  shown <- if (is.numeric(value)) format(value, digits = digits) else as.character(value)
  if (!is.null(names(value))) shown <- paste0(names(value), "=", shown)
  cat(sprintf("%-34s %s\n", key, paste(shown, collapse = "  ")))
  invisible(value)
}

write_data <- function(df, name = "data.csv")
  write.csv(df, file.path(example_dir, name), row.names = FALSE)

finish <- function()
  jsonlite::write_json(list(r_version = R.version.string, values = .expected),
                       file.path(example_dir, "expected.json"),
                       auto_unbox = TRUE, digits = NA, pretty = TRUE)

cat("# ", R.version.string, "\n", sep = "")
