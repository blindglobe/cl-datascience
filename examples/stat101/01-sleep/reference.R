# Example 01: sleep - two drugs, ten patients.
# Data: datasets::sleep (Cushny and Peebles 1905, analysed by Student 1908).
# Columns: extra (extra hours of sleep), group (drug 1 or 2), ID (patient).
source("reference-lib.R")
write_data(sleep)

section("Data")
report("n_rows", nrow(sleep))
report("n_patients", length(unique(sleep$ID)))
report("every_patient_got_both_drugs",
       all(tapply(sleep$group, sleep$ID, function(g) setequal(g, levels(sleep$group)))))
report("mean_extra_by_group", tapply(sleep$extra, sleep$group, mean))

d1 <- sleep[sleep$group == "1", ]; d1 <- d1[order(d1$ID), ]
d2 <- sleep[sleep$group == "2", ]; d2 <- d2[order(d2$ID), ]
report("cor_within_patient", cor(d1$extra, d2$extra))

section("A. Pairing ignored: t.test(extra ~ group) (Welch, R's default)")
welch <- t.test(extra ~ group, data = sleep)
report("welch_estimate_1_minus_2", unname(-diff(welch$estimate)))
report("welch_t", unname(welch$statistic))
report("welch_df", unname(welch$parameter))
report("welch_p", welch$p.value)
report("welch_ci", welch$conf.int[1:2])

section("B. Pairing used: paired t-test, drug 2 minus drug 1")
paired <- t.test(d2$extra, d1$extra, paired = TRUE)
report("paired_estimate_2_minus_1", unname(paired$estimate))
report("paired_t", unname(paired$statistic))
report("paired_df", unname(paired$parameter))
report("paired_p", paired$p.value)
report("paired_ci", paired$conf.int[1:2])

section("C. Alternative under the same declaration: Wilcoxon signed-rank")
w <- wilcox.test(d2$extra, d1$extra, paired = TRUE, exact = FALSE)
report("signed_rank_V", unname(w$statistic))
report("signed_rank_p", w$p.value)
report("n_zero_differences", sum(d2$extra - d1$extra == 0))

section("D. R itself no longer accepts pairing inside the formula")
msg <- tryCatch({ t.test(extra ~ group, data = sleep, paired = TRUE); "accepted" },
                error = function(e) conditionMessage(e))
report("formula_paired_message", msg)

finish()
