-- my_t_project pipeline
--
-- Demonstrates: T package import + R analysis + DuckDB anonymization in OrbStack
--
-- Data flow:
--   1. Shell: DuckDB in --network=none container anonymizes confidential CSV
--   2. T: Import hello_t package, greet the pipeline
--   3. T: Read anonymized data
--   4. R: Compute clinical summary statistics (dplyr)
--   5. T: Combine greeting + summary into final report

p = pipeline {
  -- Step 1: Anonymize confidential data inside network-isolated container
  -- Raw PHI never leaves the container; only anonymized output is written
  anonymized = shn(
    command = <{
      docker run --rm \
        --network=none \
        --memory=2g \
        -v "$PROJECT_DIR/data:/data:ro" \
        -v "$PROJECT_DIR/scripts:/scripts:ro" \
        -v "$PROJECT_DIR/outputs:/output" \
        duckdb/duckdb:latest \
        duckdb -cmd ".read /scripts/load_and_anonymize.sql" 2>&1
      cat "$PROJECT_DIR/outputs/anonymized_patients.csv"
    }>,
    serializer = ^text
  )

  -- Step 2: Read anonymized CSV into T DataFrame
  patients = read_csv("outputs/anonymized_patients.csv", separator = "|")

  -- Step 3: R node — clinical summary by diagnosis
  -- Consumes Arrow-serialized anonymized data (no PHI)
  clinical_summary = rn(
    command = <{
      library(dplyr)
      clinical_summary <- patients |>
        mutate(
          hba1c_num = suppressWarnings(as.numeric(gsub("[<>]", "", hba1c))),
          egfr_num = suppressWarnings(as.numeric(gsub("[<>]", "", egfr)))
        ) |>
        group_by(diagnosis) |>
        summarize(
          n_patients = n(),
          mean_hba1c = round(mean(hba1c_num, na.rm = TRUE), 1),
          mean_egfr = round(mean(egfr_num, na.rm = TRUE), 1),
          n_lab_errors = sum(grepl("error|unable|repeat", comment, ignore.case = TRUE)),
          .groups = "drop"
        )
    }>,
    serializer = ^arrow
  )

  -- Step 4: Combine into final output
  report = shn(
    command = <{
      echo "=== Pipeline Report ==="
      echo ""
      echo "Anonymization: DuckDB in --network=none OrbStack container"
      echo "PHI removed: names, NHS numbers, DOB, full postcodes"
      echo "Preserved: age bands, postcode areas, clinical values, lab comments"
      echo ""
      echo "=== Clinical Summary ==="
      cat "$T_NODE_clinical_summary/artifact"
      echo ""
      echo "=== Pipeline Complete ==="
    }>,
    serializer = ^text
  )
}

build_pipeline(p, verbose = 1)
pipeline_copy()
