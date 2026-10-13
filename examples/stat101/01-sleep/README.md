# 01 sleep: two drugs, ten patients

**Question.** Does drug 2 give more extra sleep than drug 1?

**Data.** `datasets::sleep`: 10 patients, each given both drugs; `extra` =
extra hours of sleep compared with control. Cushny and Peebles (1905),
used by Student (1908) in the paper that introduced the t-test.

**The trap.** The table looks like two groups of 10. It is 10 pairs. The
default call in R, `t.test(extra ~ group)`, ignores the pairing.

## What R says (reference.out)

| Analysis | Estimate | Test | p |
|---|---|---|---|
| Welch, pairing ignored (R default) | 1 - 2 = -1.58 | t = -1.86, df 17.8 | 0.079 |
| Paired t-test | 2 - 1 = 1.58 | t = 4.06, df 9 | 0.0028 |
| Wilcoxon signed-rank (paired) | | V = 45 | 0.0091 |

The two measurements of a patient correlate (r = 0.80); pairing removes
that patient-to-patient variation. Since R 4.4, `t.test(extra ~ group,
paired = TRUE)` is an error ("cannot use 'paired' in formula method"):
R itself moved pairing out of the formula and into the data layout.

## What the wish version asks for (wish.lisp)

- A plain tibble gives R's Welch answer silently.
- One declaration, `:structure (:repeated :by :id :within :group)`, makes
  the same `compare` call choose the paired test and list the signed-rank
  test as an alternative.
- With checks on and nothing declared, a detector reports "rows may be
  paired" instead of assuming it.

## What the planner says (plan.lisp, tests/stat101-tests.lisp)

| Known | Plan |
|---|---|
| nothing | **assume-rows-independent**, welch-t-test |
| rows declared independent | welch-t-test |
| each patient got both drugs (`repeated-by> sleep id group`) | paired-t-test, or signed-rank-test |

The plain case is R's default, with the assumption R makes silently
written into the plan. Declaring the pairing removes the Welch plan
altogether: the assumption it needs contradicts what is known.

## Findings

| Hint needed | Belongs to | Note |
|---|---|---|
| repeated-measures structure | statframe | frame-level, not column-level |
| contrast direction | statproc | R's sign differs between the two calls (-1.58 vs 1.58); `compare` must print which group minus which |
| possible-pairing detector | statproc (check) | heuristic, so only a warning, never a silent switch |

Open: should the declaration live on the frame (`as-statframe`) or be a
wrapper around the data at call time? Here the frame was enough.
