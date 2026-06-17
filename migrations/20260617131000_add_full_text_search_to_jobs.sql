-- STEP 1: Add the new tsvector column to the jobs table.
ALTER TABLE jobs ADD COLUMN search_tsv tsvector;

-- STEP 2: Create a function that will be used by the trigger to populate the search_tsv column.
-- This function concatenates various text fields from the beckn_structure JSONB column
-- into a single searchable document.
CREATE OR REPLACE FUNCTION update_jobs_search_tsv()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_tsv :=
        to_tsvector('simple', COALESCE(NEW.beckn_structure #>> '{descriptor,name}', '')) ||
        to_tsvector('simple', COALESCE(NEW.beckn_structure #>> '{tags,industry}', '')) ||
        to_tsvector('simple', COALESCE(NEW.beckn_structure #>> '{tags,role}', '')) ||
        to_tsvector('simple', COALESCE(NEW.beckn_structure #>> '{tags,jobDetails,title}', '')) ||
        to_tsvector('simple', COALESCE(NEW.beckn_structure #>> '{locations,city}', '')) ||
        to_tsvector('simple', COALESCE(NEW.beckn_structure #>> '{locations,state}', '')) ||
        to_tsvector('simple', COALESCE(NEW.beckn_structure #>> '{tags,basicInfo,jobProviderName}', ''));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- STEP 3: Create a trigger that automatically calls the function on every insert or update.
-- This ensures the search_tsv column is always kept in sync with the source data.
CREATE TRIGGER tsvectorupdate
BEFORE INSERT OR UPDATE ON jobs
FOR EACH ROW EXECUTE FUNCTION update_jobs_search_tsv();

-- STEP 4: Back-fill the search_tsv column for all existing jobs in the table.
-- This fires the trigger for every existing row, populating the new column.
UPDATE jobs SET id = id;

-- STEP 5: Create the necessary indexes for performance.
-- GIN index on the new tsvector column for ultra-fast full-text search.
CREATE INDEX jobs_search_tsv_idx ON jobs USING GIN (search_tsv);

-- B-Tree index to optimize sorting by creation date, which is still needed.
CREATE INDEX idx_jobs_active_created_at_desc ON jobs (is_active, created_at DESC);
