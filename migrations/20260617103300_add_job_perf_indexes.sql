-- Add pg_trgm extension to support fuzzy string matching and ILIKE performance
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Index to optimize sorting and filtering by active status
-- This is a critical index for the v3 search performance when no profile is provided
CREATE INDEX idx_jobs_active_created_at_desc ON jobs (is_active, created_at DESC);

-- GIN index on the beckn_structure column to accelerate text searches within the JSONB
-- using the gin_trgm_ops for ILIKE and fuzzy matching performance.
CREATE INDEX idx_jobs_beckn_structure_gin ON jobs USING GIN (beckn_structure jsonb_path_ops);
