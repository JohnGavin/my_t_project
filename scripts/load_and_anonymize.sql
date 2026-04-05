-- Load confidential patient data into DuckDB (network-isolated container)
-- Anonymize: remove names, NHS numbers, postcodes, dates of birth
-- Preserve: clinical values, diagnosis, comments (lab errors matter)

CREATE TABLE raw_patients AS
SELECT * FROM read_csv('/data/confidential_patients.csv', delim='|', header=true);

-- Anonymize and export
COPY (
  SELECT
    -- Keep anonymized ID
    patient_id,
    -- Remove: name, nhs_number, date_of_birth, postcode
    -- Derive age band instead of DOB
    CASE
      WHEN date_of_birth IS NULL THEN 'Unknown'
      WHEN DATEDIFF('year', CAST(date_of_birth AS DATE), CURRENT_DATE) < 40 THEN '18-39'
      WHEN DATEDIFF('year', CAST(date_of_birth AS DATE), CURRENT_DATE) < 60 THEN '40-59'
      WHEN DATEDIFF('year', CAST(date_of_birth AS DATE), CURRENT_DATE) < 80 THEN '60-79'
      ELSE '80+'
    END AS age_band,
    -- Keep first half of postcode only (area level)
    REGEXP_EXTRACT(postcode, '^[A-Z]{1,2}\d') AS postcode_area,
    -- Clinical data preserved as-is
    diagnosis,
    hba1c,
    creatinine,
    egfr,
    comment
  FROM raw_patients
) TO '/output/anonymized_patients.csv' (HEADER, DELIMITER '|');

SELECT 'Anonymized ' || COUNT(*) || ' records' AS status FROM raw_patients;
