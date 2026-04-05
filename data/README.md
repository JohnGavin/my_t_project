# Data Directory

Place `confidential_patients.csv` here (pipe-delimited).
This file contains PHI and is excluded from git via `.gitignore`.

The pipeline anonymizes it inside a `--network=none` Docker container
before any analysis touches it.
