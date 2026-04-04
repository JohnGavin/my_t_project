-- my_t_project — main pipeline script
--
-- Run with: t run src/pipeline.t

-- import my_stats
-- import data_utils[read_clean, normalize]

-- p = pipeline {
--   raw = read_csv("data/dataset.csv")
--   clean = read_clean(raw)              -- uses imported function
--   normed = normalize(clean)            -- uses imported function
--   result = weighted_mean(normed.$x, normed.$w)  -- uses imported function
-- }

-- build_pipeline(p)

print("Hello from my_t_project pipeline!")
