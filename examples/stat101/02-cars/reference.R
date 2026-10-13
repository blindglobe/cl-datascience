# Example 02: cars - stopping distance against speed.
# Data: datasets::cars (Ezekiel 1930; cars of the 1920s).
# Columns: speed (mph), dist (stopping distance, ft).
source("reference-lib.R")
write_data(cars)

section("Data")
report("n_rows", nrow(cars))

section("A. Ordinary least squares: lm(dist ~ speed)")
fit <- lm(dist ~ speed, data = cars)
s <- summary(fit)
report("intercept", unname(coef(fit)[1]))
report("slope", unname(coef(fit)[2]))
report("slope_se_classical", s$coefficients["speed", "Std. Error"])
report("slope_p_classical", s$coefficients["speed", "Pr(>|t|)"])
report("slope_ci_classical", unname(confint(fit)["speed", ]))
report("r_squared", s$r.squared)

section("B. Does the spread grow with speed? (residual SD by speed band)")
band <- cut(cars$speed, c(0, 12, 18, Inf), labels = c("4-12", "13-18", "19-25"))
report("residual_sd_by_band", tapply(resid(fit), band, sd))
# Studentized Breusch-Pagan (Koenker), as lmtest::bptest computes by default
aux <- lm(resid(fit)^2 ~ speed, data = cars)
bp <- nrow(cars) * summary(aux)$r.squared
report("breusch_pagan_stat", bp)
report("breusch_pagan_p", pchisq(bp, df = 1, lower.tail = FALSE))

section("C. Same slope, heteroscedasticity-robust standard error (HC3)")
X <- model.matrix(fit); e <- resid(fit); h <- hatvalues(fit)
bread <- solve(crossprod(X))
V <- bread %*% crossprod(X * (e / (1 - h))) %*% bread
se_hc3 <- sqrt(diag(V))[["speed"]]
report("slope_se_hc3", se_hc3)
report("slope_ci_hc3", coef(fit)[["speed"]] + c(-1, 1) * qt(0.975, fit$df.residual) * se_hc3)

section("D. Prediction intervals assume constant spread")
pi <- predict(fit, data.frame(speed = c(5, 25)), interval = "prediction")
report("prediction_interval_speed_5", unname(pi[1, ]))
report("prediction_interval_speed_25", unname(pi[2, ]))

section("E. Physics says distance grows with speed squared")
fit2 <- lm(dist ~ speed + I(speed^2), data = cars)
report("quadratic_coefficients", unname(coef(fit2)))
report("quadratic_term_p", summary(fit2)$coefficients[3, 4])

finish()
