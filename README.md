
<!-- README.md is generated from README.Rmd. Please edit that file -->

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

# Experiments

In our experiments, we validate our claims through experiments and
assess the effects of different recourse definitions on individual
fairness. At first, we perform numerical simulations on various models
and classifiers. Next, we apply our findings to both a real-world and
semi-synthetic dataset as a case study. The codes and instructions for
reproducing our experiments are available at
[Github](https://github.com/Ehyaei/Robustness-implies-Fairness).

## Numerical Simulation

$\sqrt{1}$
Since the recourse actions require knowledge of the underlying SCM, we
begin by defining two linear and non-linear ANM models for the SCM. In
our experiments, we utilize two non-protected continuous features
($X_i$) and a binary protected attribute ($A$) with a value of either 0
or 1. The structural equations of linear SCM (LIN) is given by:

$$
\begin{cases}
A := U_A, &             U_A \sim \mathcal{R}(0.5)   \\
X_1 := 2A + U_1, &  U_1\sim \mathcal{N}(0,1)    \\
X_2 := A-X_1 + U_2, &           U_2 \sim \mathcal{N}(0,1)
\end{cases}
$$ For the non-linear SCM (ANM) the following structural equations:

$$
\begin{cases}
A := U_A, &             U_A \sim \mathcal{R}(0.5)   \\
X_1 := 2A^2 + U_1, &    U_1\sim \mathcal{N}(0,1)    \\
X_2 := AX_1 + U_2, &            U_2 \sim \mathcal{N}(0,1)
\end{cases}
$$ where $\mathcal{R}(p)$ is Rademacher random variables with
probability $p$ and $\mathcal{N}(\mu,\sigma^2)$ is normal r.v. with mean
$\mu$ and variance $\sigma^2$. To see, modified or define new SCM, see
the script `utils/scm_models.R`.

To add the ground truth label, we consider both linear and non-linear
functions in the form of $Y = sign(f(v,w) - b)$, where
$w \in \mathbb{R}^{n+1}$ is coefficient of $V_i$ and $b \in \mathbb{R}$.
We also examine an unaware baseline where $h$ does not depend on
protected variable $A$. The lebel functions formula is given by:

$$
h(A, X_1,X_2,X_3) = 
\begin{cases}
\textrm{sign}(A + X_1 + X_2 < 0)    &  \text{Linear and Aware}      \\ 
\textrm{sign}(X_1 + X_2 < 0)        &  \text{Linear and Unaware}    \\ 
\textrm{sign}((A + X_1 + X_2)^2 <2) &  \text{Non-Linear and Aware}\\
\textrm{sign}((X_1 + X_2)^2 <2)     & \text{Non-Linear and Unaware}
\end{cases}
$$

The file named `utils/labels.R` holds the label functions. For each
model, we generate 10,000 samples through utilizing the structural
equations of the SCMs. The following presents two examples of data
generation.

<img src="images/19: SCM:ANM__label:LIN__w:aware__b:0.svg" width="49.5%" align="left" />
<img src="images/64: SCM:ANM__label:NLM__w:aware__b:2.svg" width="49.5%" align="right" />

For each dataset, we split the samples into 80% for training and 20% for
testing. Then, we train a logistic regression (LR), support vector
machine (SVM), and gradient boosting machine (GBM) using all features or
just the non-protected features $\mathbf{X}$ as an unaware baseline. We
use the package to train models and the for tuning hyperparameters with
the below searching parameters:

-   **GLM**: use `alpha = seq(0, 1, 0.1)` with `lambda_search = TRUE`.
-   **SVM**: set `gamma = 0.01` , `rank_ratio = 0.1`, and use a Gaussian
    kernel.
-   **GBM**: search for the optimal model among the following
    parameters: `learn_rate = c(0.01, 0.1)`, `max_depth = c(3, 5, 9)`,
    and `sample_rate = c(0.8, 1.0)`.

To find the classifier’s scripts see `utils/models.R`. The decision
boundary for the two models is displayed in the figures below.
<img src="images/16: SCM:LIN__label:LIN__w:aware__b:0_h:GBM_l:aware.svg" width="100%" align="left" />
<img src="images/20: SCM:LIN__label:NLM__w:aware__b:2_h:GBM_l:aware.svg" width="100%" align="right" />

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

<img src="images/117: SCM:ANM__label:NLM__w:unaware__b:2_h:GBM_l:unaware_delta:1.svg" width="45%" align="left" />
<img src="images/113: SCM:ANM__label:LIN__w:unaware__b:0_h:GBM_l:unaware_delta:1.svg" width="45%" align="right" />
