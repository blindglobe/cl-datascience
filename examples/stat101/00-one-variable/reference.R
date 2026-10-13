# Example 00: one variable - A.J. Rossini's two datasets from
# examples/1d-analysis.lisp: a categorical sequence (stanzas of a song) and
# a continuous one (how far off pitch a guitar string plays).
# The sketch writes the numbers as 1.2d etc.; here they are 1.2, 0.8, ...
source("reference-lib.R")
stanza <- c("A", "B", "A", "B", "C", "B")
pitch  <- c(1.2, 0.8, 1.0, 3.2, -2.9)
write_data(data.frame(position = seq_along(stanza), stanza = stanza), "stanza.csv")
write_data(data.frame(position = seq_along(pitch), pitch = pitch), "pitch.csv")

section("Categorical: stanza")
tab <- table(stanza)
report("stanza_n", length(stanza))
report("stanza_levels", names(tab))
report("stanza_counts", c(tab))
report("stanza_proportions", c(prop.table(tab)))
report("stanza_most_common", names(tab)[which.max(tab)])
# "how wrong we could be": exact 95% interval for the share of the most
# common value, if stanzas were drawn at random
report("stanza_ci_share_most_common", binom.test(max(tab), length(stanza))$conf.int[1:2])

section("Continuous: pitch")
n <- length(pitch)
report("pitch_n", n)
report("pitch_mean", mean(pitch))
report("pitch_sd", sd(pitch))
report("pitch_median", median(pitch))
report("pitch_ci_mean", t.test(pitch)$conf.int[1:2])
# where the next value should fall if values are independent draws from a
# normal process: prediction interval for one new observation
half <- qt(0.975, n - 1) * sd(pitch) * sqrt(1 + 1 / n)
report("pitch_prediction_interval_next", mean(pitch) + c(-1, 1) * half)

finish()
