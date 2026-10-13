# Example 03: ToothGrowth - vitamin C dose and delivery method in guinea pigs.
# Data: datasets::ToothGrowth (Crampton 1947). 60 animals; each received one
# of three doses (0.5, 1, 2 mg/day) by one of two methods (OJ = orange
# juice, VC = ascorbic acid). Columns: len (odontoblast length), supp, dose.
source("reference-lib.R")
write_data(ToothGrowth)
tg <- ToothGrowth

section("Data")
report("n_rows", nrow(tg))
report("animals_per_cell", unique(as.vector(table(tg$supp, tg$dose))))
m <- with(tg, tapply(len, list(supp, dose), mean))
report("mean_len_OJ_by_dose", m["OJ", ])
report("mean_len_VC_by_dose", m["VC", ])

section("A. The designed analysis: two-way ANOVA, dose as a factor")
a <- summary(aov(len ~ supp * factor(dose), data = tg))[[1]]
report("anova_F", setNames(a[1:3, "F value"], c("supp", "dose", "supp:dose")))
report("anova_p", setNames(a[1:3, "Pr(>F)"], c("supp", "dose", "supp:dose")))

section("B. Dose as a straight line is not enough (lack of fit)")
lin <- lm(len ~ supp * dose, data = tg)
fac <- lm(len ~ supp * factor(dose), data = tg)
report("lack_of_fit_p", anova(lin, fac)[2, "Pr(>F)"])

section("C. The impossible direction: lm(dose ~ len) also 'works'")
wrong <- lm(dose ~ len, data = tg)
report("dose_on_len_slope", unname(coef(wrong)[2]))
report("dose_on_len_p", summary(wrong)$coefficients[2, 4])
report("cor_len_dose", cor(tg$len, tg$dose))

finish()
