# Example 05: faithful - Old Faithful geyser, Yellowstone.
# Data: datasets::faithful (Haerdle 1991). 272 eruptions.
# Columns: eruptions (duration, min), waiting (minutes to the next eruption).
source("reference-lib.R")
write_data(faithful)
f <- faithful

section("A. The usual summary")
report("n_rows", nrow(f))
report("mean_eruptions", mean(f$eruptions))
report("sd_eruptions", sd(f$eruptions))
report("share_within_half_minute_of_mean",
       mean(abs(f$eruptions - mean(f$eruptions)) < 0.5))
report("shapiro_wilk_p", shapiro.test(f$eruptions)$p.value)

section("B. The distribution has two modes")
d <- density(f$eruptions)
modes <- d$x[which(diff(sign(diff(d$y))) == -2) + 1]
report("density_bandwidth", d$bw)
report("density_modes", modes)
short <- f$eruptions < 3
report("share_short_eruptions_lt_3min", mean(short))
report("mean_eruptions_short_long", c(short = mean(f$eruptions[short]),
                                      long = mean(f$eruptions[!short])))

section("C. The strong correlation comes from the two clusters")
report("cor_all", cor(f$eruptions, f$waiting))
report("cor_within_short", cor(f$eruptions[short], f$waiting[short]))
report("cor_within_long", cor(f$eruptions[!short], f$waiting[!short]))
report("slope_waiting_on_eruptions", unname(coef(lm(waiting ~ eruptions, data = f))[2]))

section("D. Row order: is it time order? (the documentation does not say)")
report("lag1_autocorrelation_eruptions", acf(f$eruptions, plot = FALSE)$acf[2])
report("lag1_autocorrelation_waiting", acf(f$waiting, plot = FALSE)$acf[2])

finish()
