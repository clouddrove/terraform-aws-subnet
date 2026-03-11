[1mdiff --git a/.github/workflows/pr-check.yml b/.github/workflows/pr-check.yml[m
[1mindex b993aa8..6dd2b41 100644[m
[1m--- a/.github/workflows/pr-check.yml[m
[1m+++ b/.github/workflows/pr-check.yml[m
[36m@@ -1,16 +1,9 @@[m
[31m-name: 'PR Validation'[m
[32m+[m[32mname: 🔍 PR Checks[m
[32m+[m
 on:[m
[31m-  pull_request_target:[m
[31m-    types:[m
[31m-      - opened[m
[31m-      - edited[m
[31m-      - synchronize[m
[31m-      - reopened[m
[32m+[m[32m  pull_request:[m
[32m+[m[32m    types: [opened, edited, synchronize, reopened][m
 [m
 jobs:[m
   pr-validation:[m
[31m-    if: github.actor != 'dependabot[bot]'[m
[31m-    uses: clouddrove/github-shared-workflows/.github/workflows/pr_checks.yml@master[m
[31m-    secrets: inherit[m
[31m-    with:[m
[31m-      subjectPattern: '^.+$'[m
[32m+[m[32m    uses: clouddrove/github-shared-workflows/.github/workflows/pr-checks.yml@master[m
\ No newline at end of file[m
[1mdiff --git a/.github/workflows/tf-checks.yml b/.github/workflows/tf-checks.yml[m
[1mindex 812b216..4f3d972 100644[m
[1m--- a/.github/workflows/tf-checks.yml[m
[1m+++ b/.github/workflows/tf-checks.yml[m
[36m@@ -9,19 +9,34 @@[m [mjobs:[m
     uses: clouddrove/github-shared-workflows/.github/workflows/tf-checks.yml@master[m
     with:[m
       working_directory: './examples/private-subnet/'[m
[32m+[m[32m      provider: aws[m
[32m+[m[32m    secrets:[m[41m [m
[32m+[m[32m      BUILD_ROLE: ${{ secrets.BUILD_ROLE }}[m
   tf-checks-basic-example:[m
     uses: clouddrove/github-shared-workflows/.github/workflows/tf-checks.yml@master[m
     with:[m
       working_directory: './examples/basic/'[m
[32m+[m[32m      provider: aws[m
[32m+[m[32m    secrets:[m[41m [m
[32m+[m[32m      BUILD_ROLE: ${{ secrets.BUILD_ROLE }}[m
   tf-checks-public-private-subnet-single-nat-gateway-example:[m
     uses: clouddrove/github-shared-workflows/.github/workflows/tf-checks.yml@master[m
     with:[m
       working_directory: './examples/public-private-subnet-single-nat-gateway/'[m
[32m+[m[32m      provider: aws[m
[32m+[m[32m    secrets:[m[41m [m
[32m+[m[32m      BUILD_ROLE: ${{ secrets.BUILD_ROLE }}[m
   tf-checks-complete-example:[m
     uses: clouddrove/github-shared-workflows/.github/workflows/tf-checks.yml@master[m
     with:[m
       working_directory: './examples/complete/'[m
[32m+[m[32m      provider: aws[m
[32m+[m[32m    secrets:[m[41m [m
[32m+[m[32m      BUILD_ROLE: ${{ secrets.BUILD_ROLE }}[m
   tf-checks-public-subnet-example:[m
     uses: clouddrove/github-shared-workflows/.github/workflows/tf-checks.yml@master[m
     with:[m
       working_directory: './examples/public-subnet/'[m
[32m+[m[32m      provider: aws[m
[32m+[m[32m    secrets:[m[41m [m
[32m+[m[32m      BUILD_ROLE: ${{ secrets.BUILD_ROLE }}[m
