# 02 cars: stopping distance against speed

**Question.** How much longer is the stopping distance per extra mph?

**Data.** `datasets::cars`: 50 cars of the 1920s, `speed` (mph) and `dist`
(ft). Ezekiel (1930).

**The trap.** The spread of distances grows with speed. Whether that
matters depends on what the regression is for. This is Rossini's
point: a method whose assumptions are violated is fine as long as it is
clear which of its outputs rely on them.

## What R says (reference.out)

| Output | Value | Needs constant spread? |
|---|---|---|
| slope | 3.93 ft per mph | no |
| slope SE, classical / HC3 robust | 0.4155 / 0.4275 | classical: yes |
| 95% CI, classical / robust | 3.10..4.77 / 3.07..4.79 | classical: yes |
| residual SD at 4-12 / 13-18 / 19-25 mph | 8.6 / 17.2 / 18.1 ft | |
| Breusch-Pagan | 3.21, p = 0.073 | |
| prediction interval at 5 mph | -30.3 .. 34.5 ft | yes |
| quadratic term (physics: dist ~ speed^2) | p = 0.136 | |

For the slope and even its inference, the violation hardly matters: the
robust SE is 3% larger. For prediction it matters a lot: the interval at
5 mph includes negative stopping distances and is twice as wide as the
spread at low speed.

## What the wish version asks for (wish.lisp)

- Plain fit: identical to `lm`, no warnings.
- `:purpose :trend`: no warnings at all.
- `:purpose :inference`: a *suggestive* warning (p = 0.07) with the robust
  alternative and the note that the conclusion does not change.
- `:purpose :prediction`: a clear warning that the interval leaves the
  declared domain (`dist >= 0`) and that its width is wrong at both ends.
- A physics hint (`dist` grows like `speed^2`) is shown next to the data's
  verdict (not contradicted, not confirmed).

## What the planner says (plan.lisp, tests/stat101-tests.lisp)

The purpose is part of the question: three goals for one regression.

| Known | Asked | Plans |
|---|---|---|
| nothing | trend | ols-fit |
| nothing | inference | assume-rows-independent, ols-fit, robust-se; or the same with assume-constant-spread and classical-se |
| rows independent | inference | ols-fit, robust-se; or ols-fit, assume-constant-spread, classical-se |
| spread grows with speed (after a check) | inference | assume-rows-independent, ols-fit, robust-se |
| nothing | prediction | assume-rows-independent, ols-fit, assume-constant-spread, normal-prediction-interval |
| spread grows with speed | prediction | assume-rows-independent, ols-fit, spread-model-prediction-interval |

The check of the spread depends on the values, so it is not planned: its
result enters as a fact (`spread-checked`) and the question is planned
again. The same holds for the domain check: whether a prediction interval
leaves `dist >= 0` is known only after computing it (at 5 mph it does, at
25 mph it does not).

## Findings

| Hint needed | Belongs to | Note |
|---|---|---|
| purpose, per-output validity | models | the core of this example |
| value domain (`dist >= 0`) | statframe | new |
| units | statframe | used to word the result ("ft per mph") |
| subject-matter model hint | statframe | stored with provenance (`:source`) |
| graded warnings | checks | p = 0.07 must not read like p = 1e-10 |

Open: is "graded" a fixed scale (note / suggestive / clear) or a number?
