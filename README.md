# Toronto Marijuana Possession Arrests: Who Gets Released with a Summons?

A logistic regression study of arrests for simple possession of small amounts of marijuana in Toronto. The final project for MATH 449 (Categorical Data Analysis) at San Francisco State University, Spring 2023.

📄 **Full report:** [`report/toronto_arrests_logistic_regression_report.pdf`](report/toronto_arrests_logistic_regression_report.pdf)
💻 **Analysis code:** [`toronto_arrests_logistic_regression.Rmd`](toronto_arrests_logistic_regression.Rmd)

## Problem

When someone is arrested for simple possession, police can either release them with a summons (a court appearance notice) or hold them. This project looks at how the chance of release with a summons relates to an arrestee's:

- race
- sex
- age
- year of arrest
- employment status
- citizenship status
- number of **checks**: how many times their name appeared in police databases

## Data

The `Arrests` dataset from the R package **carData** ([CRAN](https://cran.r-project.org/package=carData), [Rdatasets CSV](https://vincentarelbundock.github.io/Rdatasets/csv/carData/Arrests.csv)). It has 5,226 individual arrests and 8 variables:

| Variable   | Coding used in the analysis          |
|------------|--------------------------------------|
| `released` | 1 = Yes, 0 = No (response)           |
| `colour`   | 1 = White, 0 = Black                 |
| `sex`      | 1 = Male, 0 = Female                 |
| `employed` | 1 = Yes, 0 = No                      |
| `citizen`  | 1 = Yes, 0 = No                      |
| `year`     | 1997–2002                            |
| `age`      | 12–66                                |
| `checks`   | 0–6                                  |

The data isn't included in this repo. Save it as `data/Arrests.csv` in one of these ways:

```bash
# Option A (recommended): export it from carData, which gives exactly the 8 columns
Rscript -e 'write.csv(carData::Arrests, "data/Arrests.csv", row.names = FALSE)'

# Option B: download the Rdatasets CSV (it adds a `rownames` column, which the analysis ignores)
curl -L -o data/Arrests.csv https://vincentarelbundock.github.io/Rdatasets/csv/carData/Arrests.csv
```

## Approach

1. **Full model.** Fit a binomial GLM (logit link) on all seven predictors.
2. **Variable selection.** Use `MASS::stepAIC` to choose the model **M1**: `released ~ colour + employed + citizen + checks`.
3. **Class imbalance.** Only 892 of the 5,226 arrestees (≈17%) were *not* released. To balance the classes, take a random sample of 1,000 released cases plus all 892 not-released cases, and refit the same formula on that sample. This gives model **M2**.
4. **Inference on M2:**
   - likelihood-ratio test against the intercept-only model
   - profile-likelihood 95% confidence intervals
   - odds ratios
5. **Classification:**
   - confusion tables at cutoffs π₀ = 0.5 and π₀ = #(Y=1)/n
   - ROC curves, AUC and the best cutoff for M1 and M2 (`Epi::ROC`)
6. **Validation.** Leave-one-out cross-validation (`caret`) and 10-fold cross-validation (`DAAG::cv.binary`).
7. **Link functions.** Compare the logit link with probit. The identity link could not be fit on the balanced data.

## Key results

All numbers below come from the printed output in the [report](report/toronto_arrests_logistic_regression_report.pdf).

**Variable selection:**
- `stepAIC` dropped sex, year and age. AIC went from 4315.1 for the full model to 4309.3 for M1.
- In M1, colour, employment, citizenship and checks are all significant at p < 0.001.

**Odds ratios (M2, balanced data):**

| Predictor | Odds ratio | 95% CI for coefficient (log-odds) |
|-----------|-----------:|-----------------------------------|
| colour (White vs Black) | 1.54 | 0.210 – 0.656 |
| employed (Yes vs No)    | 2.15 | 0.539 – 0.993 |
| citizen (Yes vs No)     | 1.90 | 0.380 – 0.911 |
| checks (per additional check) | 0.687 | −0.441 – −0.311 |

With the other predictors held fixed, the odds of release with a summons are:
- higher for White arrestees than for Black arrestees
- higher for employed arrestees and for citizens
- lower with each additional police-database check

M2 fits much better than the intercept-only model. The likelihood-ratio test gives a deviance drop of 309.06 on 4 df, p < 2.2e-16.

**Example predicted probabilities (M2):**
- A Black, unemployed non-citizen with 0 checks: **0.37**
- A White, employed citizen with 1 check: **0.72**

**Classification on the balanced data (M2):**

| Cutoff π₀ | Sensitivity | Specificity | Accuracy |
|-----------|------------:|------------:|---------:|
| 0.5       | 0.724 | 0.614 | 0.672 |
| #(Y=1)/n ≈ 0.53 | 0.700 | 0.638 | 0.671 |

**ROC:**

| Model | AUC | Best cutoff | Sensitivity | Specificity |
|-------|----:|------------:|------------:|------------:|
| M1 (full data)     | 0.724 | 0.856 | 59.0% | 77.2% |
| M2 (balanced data) | 0.728 | 0.569 | 59.5% | 77.2% |

**Cross-validation:**
- 10-fold CV accuracy: **0.828** for M1 and **0.672** for M2. M1's higher accuracy partly reflects the imbalanced data, where only 17% of arrestees were not released.
- LOOCV on M2: RMSE 0.460, R² 0.149, MAE 0.423.

**Probit link.** Probit and logit give very similar fits on the balanced data: AIC 2319 for probit and 2317.6 for logit.

> **Reproducibility note:** the balanced sample for M2 is drawn with `sample()` and no fixed seed. That means M2's coefficients and the metrics that depend on it will differ slightly each time the report is knit. The report notes that the signs of the effects and the conclusions stay the same.

## How to run

Requirements: R and [pandoc](https://pandoc.org/). RStudio bundles pandoc.

```bash
# 1. Install R packages
Rscript install_packages.R

# 2. Get the data (see "Data" above)
Rscript -e 'write.csv(carData::Arrests, "data/Arrests.csv", row.names = FALSE)'

# 3. Knit the analysis
Rscript -e 'rmarkdown::render("toronto_arrests_logistic_regression.Rmd", output_format = "html_document")'
```

The data folder is set by `DATA_DIR` at the top of the Rmd. It defaults to `data/`. To point it somewhere else, set the environment variable:

```bash
DATA_DIR=/path/to/folder Rscript -e 'rmarkdown::render("toronto_arrests_logistic_regression.Rmd", output_format = "html_document")'
```

## Repository structure

```
.
├── toronto_arrests_logistic_regression.Rmd   # analysis (R Markdown)
├── install_packages.R                        # installs required R packages
├── data/                                     # put Arrests.csv here (not committed)
└── report/
    └── toronto_arrests_logistic_regression_report.pdf   # knitted final report
```

## Authors

Dona Inayyah & Bryan Thorne. MATH 449, San Francisco State University, Spring 2023.
