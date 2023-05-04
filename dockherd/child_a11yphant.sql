-- Post Creation Scripts for A11yphant

-- Import Data
    -- FROM: start_domains TO: targets.domains
    COPY targets.domains(id, domain, active)
    FROM '/var/lib/postgresql/data/start_domains.csv'
    DELIMITER ','
    CSV HEADER;

    -- FROM: start_urls TO: targets.urls
    COPY targets.urls(id, url, domain_id, is_objective)
    FROM '/var/lib/postgresql/data/start_urls.csv'
    DELIMITER ','
    CSV HEADER;
