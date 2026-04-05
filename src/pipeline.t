-- my_t_project pipeline
--
-- Prerequisites: Run DuckDB anonymization first (outside Nix sandbox):
--   ./scripts/run_duckdb.sh load_and_anonymize.sql outputs
--
-- Pipeline flow:
--   1. T: Read anonymized CSV (PHI already stripped by DuckDB container)
--   2. R: Compute clinical summary statistics with dplyr
--   3. Shell: Generate final report

p = pipeline {
  -- Step 1: Read anonymized data (no PHI — safe for pipeline)
  -- Serialize as Arrow so R can deserialize it
  patients = node(
    command = read_csv("outputs/anonymized_patients.csv", separator = "|"),
    runtime = T,
    serializer = ^arrow
  )

  -- Step 2: R node — clinical summary by diagnosis
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
    deserializer = ^arrow,
    serializer = ^arrow
  )

  -- Step 3: Final report
  report = shn(
    command = <{
      echo "=== my_t_project Pipeline Report ==="
      echo ""
      echo "Data: anonymized by DuckDB in --network=none OrbStack container"
      echo "PHI removed: names, NHS numbers, DOB, full postcodes"
      echo "Preserved: age bands, postcode areas, clinical values, lab comments"
      echo ""
      echo "=== Clinical Summary by Diagnosis ==="
      cat "$T_NODE_clinical_summary/artifact"
      echo ""
      echo "=== Pipeline Complete ==="
    }>,
    serializer = ^text
  )
}

build_pipeline(p, verbose = 1)
pipeline_copy()
