ALTER TABLE jobs ADD COLUMN search_tsv tsvector;

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

CREATE TRIGGER tsvectorupdate
BEFORE INSERT OR UPDATE ON jobs
FOR EACH ROW EXECUTE FUNCTION update_jobs_search_tsv();

UPDATE jobs SET id = id;

CREATE INDEX jobs_search_tsv_idx ON jobs USING GIN (search_tsv);

CREATE INDEX idx_jobs_active_created_at_desc ON jobs (is_active, created_at DESC);
