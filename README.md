
<!-- README.md is generated from README.Rmd. Please edit that file -->
<head>
<link rel="stylesheet" type="text/css" href="https://raw.githubusercontent.com/Ehyaei/Robustness-implies-Fairness/main/style.css">
</head>

<a href={https://github.com/Ehyaei/RTLNotes}><img src="images/counterfactualsvg.svg" alt="RTLNotes logo" align="right" width="160" style="padding: 0 15px; float: right;"/>

# Robustness Implies Fairness in Causal Algorithmic Recourse

This project implements the paper “Robustness implies Fairness in Casual
Algorithmic Recourse” using the R language.

This study explores the concept of individual fairness and adversarial
robustness in causal algorithmic recourse and addresses the challenge of
achieving both. To resolve the challenges, we propose a new framework
for defining adversarially robust recourse.

The new setting views the protected feature as a pseudometric and
demonstrates that individual fairness is a special case of adversarial
robustness. Finally, we introduce the fair robust recourse problem to
achieve both desirable properties and show how it can be satisfied both
theoretically and empirically.

If you find it useful, please consider citing:

    @misc{https://doi.org/10.48550/arxiv.2302.03465,
      doi = {10.48550/ARXIV.2302.03465},
      url = {https://arxiv.org/abs/2302.03465},
      author = {Ehyaei, Ahmad-Reza and Karimi, Amir-Hossein and 
      Schölkopf, Bernhard and Maghsudi, Setareh},
      title = {Robustness Implies Fairness in Casual Algorithmic Recourse},
      publisher = {arXiv},
      year = {2023},
    }

# Experiments

In our experiments, we validate our claims through experiments and
assess the effects of different recourse definitions on individual
fairness. At first, we perform numerical simulations on various models
and classifiers. Next, we apply our findings to both a real-world and
semi-synthetic dataset as a case study. The codes and instructions for
reproducing our experiments are available at
[Github](https://github.com/Ehyaei/Robustness-implies-Fairness).

## Numerical Simulation

Since the recourse actions require knowledge of the underlying SCM, we
begin by defining two linear and non-linear ANM models for the SCM. In
our experiments, we utilize two non-protected continuous features
($X_i$) and a binary protected attribute ($A$) with a value of either 0
or 1. The structural equations of linear SCM (LIN) is given by:

$$\begin{cases}
A := U_A, &             U_A \sim \mathcal{R}(0.5)   \\
X_1 := 2A + U_1, &  U_1\sim \mathcal{N}(0,1)    \\
X_2 := A-X_1 + U_2, &           U_2 \sim \mathcal{N}(0,1)
\end{cases}$$

For the non-linear SCM (ANM) the following structural equations:

$$
\begin{cases}
A := U_A, &             U_A \sim \mathcal{R}(0.5)   \\
X_1 := 2A^2 + U_1, &    U_1\sim \mathcal{N}(0,1)    \\
X_2 := AX_1 + U_2, &            U_2 \sim \mathcal{N}(0,1)
\end{cases}$$

where $\mathcal{R}(p)$ is Rademacher random variables with probability
$p$ and $\mathcal{N}(\mu,\sigma^2)$ is normal r.v. with mean $\mu$ and
variance $\sigma^2$. To see, modified or define new SCM, see the script
`utils/scm_models.R`.

To add the ground truth label, we consider both linear and non-linear
functions in the form of $Y = sign(f(v,w) - b)$, where
$w \in \mathbb{R}^{n+1}$ is coefficient of $V_i$ and $b \in \mathbb{R}$.
We also examine an unaware baseline where $h$ does not depend on
protected variable $A$. The label functions formula is given by:

$$h(A, X_1,X_2,X_3) = 
\begin{cases}
\textrm{sign}(A + X_1 + X_2 < 0)    &  \text{Linear and Aware}      \\ 
\textrm{sign}(X_1 + X_2 < 0)        &  \text{Linear and Unaware}    \\ 
\textrm{sign}((A + X_1 + X_2)^2 <2) &  \text{Non-Linear and Aware}\\
\textrm{sign}((X_1 + X_2)^2 <2)     & \text{Non-Linear and Unaware}
\end{cases}$$

The file named `utils/labels.R` holds the label functions. For each
model, we generate 10,000 samples through utilizing the structural
equations of the SCMs. The following presents two examples of data
generation.

<div style="”width:100%”">

<img src="images/19: SCM:ANM__label:LIN__w:aware__b:0.svg" width="45%" align="center"/>
<img src="images/64: SCM:ANM__label:NLM__w:aware__b:2.svg" width="45%" align="center"/>

</div>

For each dataset, we split the samples into 80% for training and 20% for
testing. Then, we train a logistic regression (LR), support vector
machine (SVM), and gradient boosting machine (GBM) using all features or
just the non-protected features $\mathbf{X}$ as an unaware baseline. We
use the \\citet{h2o.ai} package to train models and the
\\textit{h2o.grid} for tuning hyperparameters with the below searching
parameters:

-   **GLM**: use `alpha = seq(0, 1, 0.1)` with `lambda_search = TRUE`.
-   **SVM**: set `gamma = 0.01` , `rank_ratio = 0.1`, and use a Gaussian
    kernel.
-   **GBM**: search for the optimal model among the following
    parameters: `learn_rate = c(0.01, 0.1)`, `max_depth = c(3, 5, 9)`,
    and `sample_rate = c(0.8, 1.0)`.

To find the classifier’s scripts see `utils/models.R`. The decision
boundary for the two models is displayed in the figures below.
<img src="images/16: SCM:LIN__label:LIN__w:aware__b:0_h:GBM_l:aware.svg" width="100%" align="center"/>
<img src="images/20: SCM:LIN__label:NLM__w:aware__b:2_h:GBM_l:aware.svg" width="100%" align="center"/>

We consider discrete and trivial pseudometric ($d(a,a')=0$ for all
$a,a'$) for protected feature $A$. For continuous variables and product
metric space, we use the $L_2$ norm. The cost is defined as the $L_2$
norm, with $cost(v,a) = \|v - \mathbf{CF}(v,a) \|_2$. Finally, we
evaluate the methods presented in paper for having individual fairness
by testing different perturbation radii $\Delta \in \{1, 0.5, 0.1\}$.

Since the main objective of this work is not to provide an algorithmic
solution for causal recourse, we use a brute-force search to find the
optimal action. The function for calculating recourse and robust
recourse can be found in the `utils/models.R` file. In the below the
adversarial recourse in some simulations, with $\Delta=1$, for unaware
labels and classifiers, including instances and their twins is show.

<div style="”width:100%”">

<img src="images/117: SCM:ANM__label:NLM__w:unaware__b:2_h:GBM_l:unaware_delta:1.svg" width="45%" align="center"/>
<img src="images/113: SCM:ANM__label:LIN__w:unaware__b:0_h:GBM_l:unaware_delta:1.svg" width="45%" align="center"/>

</div>

## Case Studies

We use the Adult Income Demographic dataset (ACSIncome), an updated
version of the UCI Adult dataset , which contains over 195,000 records
from California state in 2018. The data was obtained by using the
Folktables Python package . To fetch data, we used the
`utils/fetch_adult_data.py` script.

<div class="container st-container">
<h3>Data Frame Summary</h3>
<h4>ASCIncome</h4>
<strong>Dimensions</strong>: 195665 x 11
  <br/><strong>Duplicates</strong>: 5711
<br/>
<table class="table table-striped table-bordered st-table st-table-striped st-table-bordered st-multiline ">
  <thead>
    <tr>
      <th align="center" class="st-protect-top-border"><strong>Variable</strong></th>
      <th align="center" class="st-protect-top-border"><strong>Stats / Values</strong></th>
      <th align="center" class="st-protect-top-border"><strong>Freqs (% of Valid)</strong></th>
      <th align="center" class="st-protect-top-border"><strong>Graph</strong></th>
      <th align="center" class="st-protect-top-border"><strong>Missing</strong></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="left">AGEP
[numeric]</td>
      <td align="left" style="padding:8;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Mean (sd) : 42.7 (14.9)</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">min &le; med &le; max:</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">17 &le; 42 &le; 94</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">IQR (CV) : 25 (0.3)</td></tr></table></td>
      <td align="left" style="vertical-align:middle">75 distinct values</td>
      <td align="left" style="vertical-align:middle;padding:0;background-color:transparent;"><img style="border:none;background-color:transparent;padding:0;max-width:max-content;" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHYAAABVCAQAAAA2ltgCAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfnAggLMBZfJpZWAAABP0lEQVR42u2cWw7CIBBFxXR1rkBXaFfg9vTToQkN4dEZ7r3nS1NNOGUYykCavjce7t4NkKxk+9nsl/L43Q+Xnsm74bXYhm61f3qYzx9vg0aqZXNsT6/Ty42y/35eqZd5E9RY4iW1AbK5lFXKk1r5dwvJ1uZp/3xONWapZE/CeJ+6IPKYqU/HbMtsWnuLPGbq4VNP5McNqjErWVQki4pkUZEsKpJFRbKoTCy41XNVdSqE7FXVKaowliwqkkVFsqhIFhXJokIlmy0E5u7b+XNY9fjvjs+EKowli4pkUZEsKpJFJUTdOGfecbCAsvNOUlGFsWRRkSwqkkVFsqhIFhUq2YALAcvYQ0PBZccW7anCWLKoUMkGT1A5vdWppWR7q1MK4xVoedxYVrb88oCyeLI36A14puJl1BOgXxGqBCVZVH6WRDHGMY90MAAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMy0wMi0wOFQxMDo0ODoyMiswMTowMGFE8T0AAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjMtMDItMDhUMTA6NDg6MjIrMDE6MDAQGUmBAAAAAElFTkSuQmCC"></td>
      <td align="center">0
(0.0%)</td>
    </tr>
    <tr>
      <td align="left">COW
[numeric]</td>
      <td align="left" style="padding:8;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Mean (sd) : 2.1 (1.9)</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">min &le; med &le; max:</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">1 &le; 1 &le; 8</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">IQR (CV) : 2 (0.9)</td></tr></table></td>
      <td align="left" style="padding:0;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">1</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">127815</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">65.3%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">2</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">13814</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">7.1%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">3</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">15765</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">8.1%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">4</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">8300</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">4.2%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">5</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">5056</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">2.6%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">6</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">16669</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">8.5%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">7</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">7678</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">3.9%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">8</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">568</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">0.3%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr></table></td>
      <td align="left" style="vertical-align:middle;padding:0;background-color:transparent;"><img style="border:none;background-color:transparent;padding:0;max-width:max-content;" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAFcAAACXCAQAAADKKQ9TAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfnAggLMBcoIabAAAABSElEQVR42u3bUWoCMRQF0KR0da6gXaGzArenX8WMM1ODRPMenPsVf+QQbiGXtvVaMuVrNgA3Tr7bD+eQRf6tB9xSTrNtm1xWn5KVARcXFxcXFxe3Jw8vsstr3/Kx1PaJG/K5W5rnbuoyLJvr/an9X/Vx7uOaiNfkZGXAxcXFxcXFxe2JNTGc2Jwzl2HZud5Ye+LJ7yaidTlZGXBxcXFxcXFxe2JNDCc252RlSMY9HD+xRs8u9z5+ov7IJSsDLi4uLi4u7qRYE8OJzTlZGZJxd9dEzCVRyuZ2TwH/0eMfbvTg4uLi4uLiToo1MZzYnJOVIRnXH2a9M8nKgIuLi4uLi4vbE+NnOLE5Zy7DfU3E2hAH3L81EbfBycqAi4uLi4uLi9sTa2I4sTknK8OKu8S83iNu/ODi4uLi4uLi4s5ODf/EXSXZ7eK+MzdFVyx6mCp3SAAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMy0wMi0wOFQxMDo0ODoyMyswMTowMMcz+okAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjMtMDItMDhUMTA6NDg6MjMrMDE6MDC2bkI1AAAAAElFTkSuQmCC"></td>
      <td align="center">0
(0.0%)</td>
    </tr>
    <tr>
      <td align="left">SCHL
[numeric]</td>
      <td align="left" style="padding:8;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Mean (sd) : 18.5 (3.9)</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">min &le; med &le; max:</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">1 &le; 19 &le; 24</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">IQR (CV) : 5 (0.2)</td></tr></table></td>
      <td align="left" style="vertical-align:middle">24 distinct values</td>
      <td align="left" style="vertical-align:middle;padding:0;background-color:transparent;"><img style="border:none;background-color:transparent;padding:0;max-width:max-content;" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHYAAABVCAQAAAA2ltgCAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfnAggLMBcoIabAAAABSUlEQVR42u2cUQ7CIAyGi9npPIGe0J3A6+mLUyIwuwGO/v2/F2MkGR+UBjpieIgfTkd3gLKUrWeKv9hav/O7u5dQbhX/NIlhziIicle3dxXGlEWFsqhQFhXKokJZVCiLCmVRoSwqlEXFlexQBTddvRBEdq1e2GIgBpPdNxBaXK1ZyqJCWVQoiwplUaEsKpRFhbKoUBYVyqJiqAZVRluMg5A9vz5/FeNchTFlUXElazBBzbsvvBuU1ebeFFdhTFlUBl+z+5ORQdmadJTiKowpiwplUaEsKpRFxZXs8NvFbSx76XxJFUx2/X7jALK5k03b005WNn5Enxu/edKTTe1Z52NyjTy+ZrbuIdsGq8/srXk0DuPyYOXex9TfIN7GH9fsotZzRg+VzYm1rD10ltXOy9LuOLWUEPf9ZuvPZVTE2TgA+hVxtTemLCpPIro3rRIOSPUAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjMtMDItMDhUMTA6NDg6MjMrMDE6MDDHM/qJAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIzLTAyLTA4VDEwOjQ4OjIzKzAxOjAwtm5CNQAAAABJRU5ErkJggg=="></td>
      <td align="center">0
(0.0%)</td>
    </tr>
    <tr>
      <td align="left">MAR
[numeric]</td>
      <td align="left" style="padding:8;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Mean (sd) : 2.7 (1.8)</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">min &le; med &le; max:</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">1 &le; 1 &le; 5</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">IQR (CV) : 4 (0.7)</td></tr></table></td>
      <td align="left" style="padding:0;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">1</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">102442</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">52.4%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">2</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">3293</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">1.7%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">3</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">17794</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">9.1%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">4</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">3728</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">1.9%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">5</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">68408</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">35.0%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr></table></td>
      <td align="left" style="vertical-align:middle;padding:0;background-color:transparent;"><img style="border:none;background-color:transparent;padding:0;max-width:max-content;" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAEgAAABgCAQAAAAUG/yXAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfnAggLMBcoIabAAAAA3klEQVRo3u3aMQ7CMBBE0TXidJwATggnyPVCkWaxAgbbZKb4UzlN9MRaymhFWcMrJzUA0K8554e76ELdyhtQxEXAWV6e7EYGCBAgQOoAAjSa6mu/9L1lYkquQKp+neqQ+cgea0TEtfS9ak6qX0jRGD+C9AEECBAgdQABmgyiMW6IdLYb2U5jrHNsg2zuGI++VXYjAwQIECB1AAEaDTvGXUQ6e4+MHWMbpA8gQIAAqQMI0GQQjXFDpLPdyL7YMfanp3v+8X+MfffRbmSAAAECpA4gQKPx3jE6xG5kgFp5Av97G+3A0zCnAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIzLTAyLTA4VDEwOjQ4OjIzKzAxOjAwxzP6iQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMy0wMi0wOFQxMDo0ODoyMyswMTowMLZuQjUAAAAASUVORK5CYII="></td>
      <td align="center">0
(0.0%)</td>
    </tr>
    <tr>
      <td align="left">OCCP
[numeric]</td>
      <td align="left" style="padding:8;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Mean (sd) : 4020.6 (2637.2)</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">min &le; med &le; max:</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">10 &le; 4110 &le; 9830</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">IQR (CV) : 3507 (0.7)</td></tr></table></td>
      <td align="left" style="vertical-align:middle">529 distinct values</td>
      <td align="left" style="vertical-align:middle;padding:0;background-color:transparent;"><img style="border:none;background-color:transparent;padding:0;max-width:max-content;" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHYAAABVCAQAAAA2ltgCAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfnAggLMBcoIabAAAABaElEQVR42u2aQRLCIAxFxenpPIGe0J7A6+mu0BlqgRJIfv5b6Yb62g8k2PC9+eE++wdQlrLXWdIvsvN33Q3/DGME08sszaM08Ng+fUZedsNVjCmLCmVRoSwqlEWFsqi4kt01AmlfMqormSYb+5I5XYk0rmJMWVQoiwplURE/XVwV/b8y4ChVT6HiKsaURYWyqDSuxjY73+atR8+GUo6rGFMWFcqiQllUKIsKZVE5rI1jqd9S6Gs6eSqQvVroa2wUGOOR5AMv0yMXyMo06nHUGHjp6BfIlr44W7cozZjTXWM8+33iM1wtUK5kO8RYZwEhJKuvfEhv/yvZP6bvszLkHwDnrE3O1w4g2fPVw1WMKYsKZVGpXI3tlIYdZMeXhj2PDgzss/9ucF3SDMjm1OIzrjkwMCV7dRK5Wo1dyZqKcaRtCzQq2zZ7GeP5yFRqSmVljttdxTikeXmbLvPzpEepAdDvEFcxpiwqPxkGPWTaTC/oAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIzLTAyLTA4VDEwOjQ4OjIzKzAxOjAwxzP6iQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMy0wMi0wOFQxMDo0ODoyMyswMTowMLZuQjUAAAAASUVORK5CYII="></td>
      <td align="center">0
(0.0%)</td>
    </tr>
    <tr>
      <td align="left">POBP
[numeric]</td>
      <td align="left" style="padding:8;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Mean (sd) : 94.4 (123.5)</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">min &le; med &le; max:</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">1 &le; 9 &le; 554</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">IQR (CV) : 206 (1.3)</td></tr></table></td>
      <td align="left" style="vertical-align:middle">219 distinct values</td>
      <td align="left" style="vertical-align:middle;padding:0;background-color:transparent;"><img style="border:none;background-color:transparent;padding:0;max-width:max-content;" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHYAAABVCAQAAAA2ltgCAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfnAggLMBi4nrtRAAAA40lEQVR42u3cQQ6CMBQAUWt6Ok6gJ4QTcD3cFgMppJBPpjM7IsG+KqSbkpZXP72jByBWbHu5PBg3buBPih5iW+Xw8/qj4e/UOXqsl9bV31gsNbHUxFITS00sNbHUxFITS00sNbHUxFITS00sNbHUxFITS00sNbHUxFITS00sNbHUxFITS00sNbHUxFITSy23X+J8U9A2uBBs1Da4G7BRv1sI9rnbF7t6QImlJpaaWGpiqYmlVl0bT9XXCj1jkX8Jdr2onzcW+fXpONKRq7ROayq/YwS+HOpbTFAC+nbr6gElltoPE3QWXM8BMAQAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjMtMDItMDhUMTA6NDg6MjQrMDE6MDAClMQHAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIzLTAyLTA4VDEwOjQ4OjI0KzAxOjAwc8l8uwAAAABJRU5ErkJggg=="></td>
      <td align="center">0
(0.0%)</td>
    </tr>
    <tr>
      <td align="left">RELP
[numeric]</td>
      <td align="left" style="padding:8;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Mean (sd) : 2.5 (4.4)</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">min &le; med &le; max:</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">0 &le; 1 &le; 17</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">IQR (CV) : 2 (1.8)</td></tr></table></td>
      <td align="left" style="vertical-align:middle">18 distinct values</td>
      <td align="left" style="vertical-align:middle;padding:0;background-color:transparent;"><img style="border:none;background-color:transparent;padding:0;max-width:max-content;" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHYAAABVCAQAAAA2ltgCAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfnAggLMBi4nrtRAAAA7klEQVR42u3cQQ7CIBQAUTGczhPoCcsJvJ7u9GOCaYQGM8ysNLWE19boBtLjtE7n2RMQK7a/HN9s1Rf4mmZPbkQRketDl9er++xZHtBSj7FYamKpiaUmlppYamKpiaUmlppYamKpiaUmlppYamKpiaUmlppYamKpiaUmlppYamKpiaUmlppYamKpiaUmlppYarl9qIRliIxFiF+wvEWISz3GYqmJpSaWmlhquX+IYysD9874S2wNHPe3tRPbd93bZ/cA61FvYdQfsO3rXhr7Lb0Zn5/Yc/aeWbRHjaV4zgbcHCre2QT0NVvqp0cstSfQGyL5NZvqUgAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMy0wMi0wOFQxMDo0ODoyNCswMTowMAKUxAcAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjMtMDItMDhUMTA6NDg6MjQrMDE6MDBzyXy7AAAAAElFTkSuQmCC"></td>
      <td align="center">0
(0.0%)</td>
    </tr>
    <tr>
      <td align="left">WKHP
[numeric]</td>
      <td align="left" style="padding:8;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Mean (sd) : 37.9 (13)</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">min &le; med &le; max:</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">1 &le; 40 &le; 99</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">IQR (CV) : 8 (0.3)</td></tr></table></td>
      <td align="left" style="vertical-align:middle">95 distinct values</td>
      <td align="left" style="vertical-align:middle;padding:0;background-color:transparent;"><img style="border:none;background-color:transparent;padding:0;max-width:max-content;" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHYAAABVCAQAAAA2ltgCAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfnAggLMBi4nrtRAAABDElEQVR42u3cQQ6CMBQAUTGczhPoCeUEXk83JjZYJFTaT6YzG+MGfW1/1AUOz1M/naPfgFix/zemT/ab3ym51HWIBKYvPhZfZaXL+/ERKZ3V1TEWS00sNbHUxFITS00sNbHUxFITS00sNbHUxFITS00sNbHUxFITS00sNbHUxFITS00sNbHUxFITS00sNbHUxFITS60rbLUbD7+Lv/OyITb+zsuujnFX2E3HODd18ZNYCZufuuhJrIYtaTrMX2EUY3OEPOs4O1+M/XWgt8BaznzTz9l87XZ+AXucOauGTYmf9S45nGvFLOZsZ1sdqRoLuBkbW36/9/v6MqTXvwMn9ZYsywD0LdbVDwGx1F5V/CqrcjD7HQAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMy0wMi0wOFQxMDo0ODoyNCswMTowMAKUxAcAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjMtMDItMDhUMTA6NDg6MjQrMDE6MDBzyXy7AAAAAElFTkSuQmCC"></td>
      <td align="center">0
(0.0%)</td>
    </tr>
    <tr>
      <td align="left">SEX
[numeric]</td>
      <td align="left" style="padding:8;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Min  : 1</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Mean : 1.5</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Max  : 2</td></tr></table></td>
      <td align="left" style="padding:0;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">1</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">103311</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">52.8%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">2</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">92354</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">47.2%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr></table></td>
      <td align="left" style="vertical-align:middle;padding:0;background-color:transparent;"><img style="border:none;background-color:transparent;padding:0;max-width:max-content;" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAEkAAAAqCAQAAABVGr6jAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfnAggLMBi4nrtRAAAAfUlEQVRYw+3WQQqAMAxE0UQ8nSfQE+oJej3dRqEiJZhZ/NmVQnk0WYyfppapGgBpLHM87GWLtXmHZLaUgNrtJDg4SJAgQVILJEhZeTSBNvZKajxWpLoeHuqS/OCOH79p9d5NUat821nBwUGCBAmSWiBByop6q9SI4OAgfckF++kLx6NHJmkAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjMtMDItMDhUMTA6NDg6MjQrMDE6MDAClMQHAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIzLTAyLTA4VDEwOjQ4OjI0KzAxOjAwc8l8uwAAAABJRU5ErkJggg=="></td>
      <td align="center">0
(0.0%)</td>
    </tr>
    <tr>
      <td align="left">RAC1P
[numeric]</td>
      <td align="left" style="padding:8;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Mean (sd) : 3.1 (2.9)</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">min &le; med &le; max:</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">1 &le; 1 &le; 9</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">IQR (CV) : 5 (0.9)</td></tr></table></td>
      <td align="left" style="padding:0;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">1</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">121006</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">61.8%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">2</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">8557</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">4.4%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">3</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">1294</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">0.7%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">4</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">13</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">0.0%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">5</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">450</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">0.2%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">6</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">32709</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">16.7%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">7</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">637</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">0.3%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">8</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">22793</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">11.6%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">9</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">8206</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">4.2%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr></table></td>
      <td align="left" style="vertical-align:middle;padding:0;background-color:transparent;"><img style="border:none;background-color:transparent;padding:0;max-width:max-content;" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAFMAAACoCAQAAAA27hpRAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfnAggLMBnPmYvHAAABQElEQVR42u3cQY6CQBCGUTBzujmBnlBO4PWc3dia0aD00H8l71vBxrxYLEqCzNepQofRAMz9+2pPzlEX6ml+wpym79G23y53Z0WGjomZGiZmapiYqT1sSJfPPuXfm9sVM2rdnJp1s+TQl+brPM7vftRuzNv2nnaNFhk6JmZqmJipYWKmZnvfTGuOiwz9jrlcl6wv9G9mbpiYqWFipoaJmRpmz2zvPXvY3kdzVjFzw8RMDRMzNUzM1DB7Znvvme0dMzVMzNQwMVPDxEzN9t6zp8+9v2r/Z+I/+NfqiCe/igwdEzM1TMzUMDFT89z7ZlpzXGTo7r1jpoaJmRomZmqYmKnZ3nu2+t772HfQrLz3PvoXZ5GhY2KmhomZGiZmau69b6Y1xxWH7o2RGysydEzM1DAxU8PETK3i9p5bkaFj9uwH6r8uLNe+ek8AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjMtMDItMDhUMTA6NDg6MjUrMDE6MDCk48+zAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIzLTAyLTA4VDEwOjQ4OjI1KzAxOjAw1b53DwAAAABJRU5ErkJggg=="></td>
      <td align="center">0
(0.0%)</td>
    </tr>
    <tr>
      <td align="left">label
[numeric]</td>
      <td align="left" style="padding:8;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Min  : 0</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Mean : 0.4</td></tr><tr style="background-color:transparent"><td style="padding:0;margin:0;border:0" align="left">Max  : 1</td></tr></table></td>
      <td align="left" style="padding:0;vertical-align:middle"><table style="border-collapse:collapse;border:none;margin:0"><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">0</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">115330</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">58.9%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr><tr style="background-color:transparent"><td style="padding:0 2px 0 7px;margin:0;border:0" align="right">1</td><td style="padding:0 2px;border:0;" align="left">:</td><td style="padding:0 4px 0 6px;margin:0;border:0" align="right">80335</td><td style="padding:0;border:0" align="left">(</td><td style="padding:0 2px;margin:0;border:0" align="right">41.1%</td><td style="padding:0 4px 0 0;border:0" align="left">)</td></tr></table></td>
      <td align="left" style="vertical-align:middle;padding:0;background-color:transparent;"><img style="border:none;background-color:transparent;padding:0;max-width:max-content;" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAFAAAAAqCAQAAACOoRSBAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfnAggLMBnPmYvHAAAAgUlEQVRYw+2WsQ2AMAwE34jpmAAmhAmyHrQBiSYovCPddS5infIuPk7lZnILINibuR72JAe5xYugtLjdJJXblD5iBBF0gyCCbhBE0M2jzZS2LR2JugImqYOq6uBgER9dv3CNlle/NerW604fMYIIukEQQTcIIuhmrEadkfQRI/iVC9SVC8fhVR/lAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIzLTAyLTA4VDEwOjQ4OjI1KzAxOjAwpOPPswAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMy0wMi0wOFQxMDo0ODoyNSswMTowMNW+dw8AAAAASUVORK5CYII="></td>
      <td align="center">0
(0.0%)</td>
    </tr>
  </tbody>
</table>
</div>

The data processing and modeling procedures adopted in this study are
consistent with those reported in Nabi and Shpitser work. In addition,
we analyze a semi-synthetic SCM proposed in Karimi et al, based on a
loan approval scenario. For semi-synthetic data, all of the procedures
are the same as in the numerical simulations section.
