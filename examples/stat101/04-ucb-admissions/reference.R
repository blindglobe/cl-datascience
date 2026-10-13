# Example 04: UCBAdmissions - graduate admissions at Berkeley, fall 1973.
# Data: datasets::UCBAdmissions (Bickel, Hammel and O'Connell 1975), the six
# largest departments, as counts: Admit x Gender x Dept.
source("reference-lib.R")
ucb <- as.data.frame(UCBAdmissions)       # Admit, Gender, Dept, Freq
write_data(ucb)

section("Data")
report("n_rows", nrow(ucb))
report("n_applicants", sum(ucb$Freq))

section("A. Pooled over departments")
pooled <- margin.table(UCBAdmissions, c(1, 2))
report("admit_rate_pooled", prop.table(pooled, 2)["Admitted", ])
or_pooled <- (pooled["Admitted", "Male"] * pooled["Rejected", "Female"]) /
             (pooled["Admitted", "Female"] * pooled["Rejected", "Male"])
report("odds_ratio_male_vs_female_pooled", or_pooled)
report("chisq_pooled_p", chisq.test(pooled)$p.value)

section("B. Within departments")
rate <- prop.table(UCBAdmissions, c(2, 3))["Admitted", , ]
report("admit_rate_male_by_dept", rate["Male", ])
report("admit_rate_female_by_dept", rate["Female", ])
report("depts_where_women_admitted_more", sum(rate["Female", ] > rate["Male", ]))
apps <- margin.table(UCBAdmissions, c(2, 3))
report("female_share_of_applicants_by_dept", prop.table(apps, 2)["Female", ])
report("overall_admit_rate_by_dept",
       prop.table(margin.table(UCBAdmissions, c(1, 3)), 2)["Admitted", ])

section("C. Stratified by department: Mantel-Haenszel")
mh <- mantelhaen.test(UCBAdmissions)
report("odds_ratio_male_vs_female_mh", unname(mh$estimate))
report("mh_p", mh$p.value)

section("D. Is the gender effect the same in every department?")
ucb$admitted <- ucb$Admit == "Admitted"
add <- glm(admitted ~ Gender + Dept, family = binomial, weights = Freq, data = ucb)
int <- glm(admitted ~ Gender * Dept, family = binomial, weights = Freq, data = ucb)
report("gender_by_dept_interaction_p", anova(add, int, test = "Chisq")[2, "Pr(>Chi)"])
report("odds_ratio_female_vs_male_dept_A", exp(coef(int)[["GenderFemale"]]))

finish()
