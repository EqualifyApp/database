-- Post Creation Scripts for A11yphant

-- Import Data
    -- FROM: start_domains TO: targets.domains
    \copy targets.domains(id, domain, active) FROM '/docker-entrypoint-initdb.d/start_domains.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

    -- FROM: start_urls TO: targets.urls
    \copy targets.urls(url, domain_id, is_objective) FROM '/docker-entrypoint-initdb.d/start_urls.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

