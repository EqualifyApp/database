-- Init scripts to get the elephant stampede rolling on A11yData!


-- Create Schemas
CREATE SCHEMA axe AUTHORIZATION a11ydata;
CREATE SCHEMA targets AUTHORIZATION a11ydata;
CREATE SCHEMA events AUTHORIZATION a11ydata;
CREATE SCHEMA orgs AUTHORIZATION a11ydata;
CREATE SCHEMA refs AUTHORIZATION a11ydata;
CREATE SCHEMA results AUTHORIZATION a11ydata;

-- Create & Grant Users
    -- Grafana Database User
    CREATE USER grafanareader WITH PASSWORD 'super_grafana_password';
        GRANT USAGE ON ALL SCHEMAS IN DATABASE a11ydata TO grafanareader;
        GRANT SELECT ON ALL TABLES IN SCHEMA axe, targets, events, orgs, refs, results TO grafanareader;



-- Create Initial Functions
    -- Keep updated_at accurate
        CREATE OR REPLACE FUNCTION public.update_updated_at()
         RETURNS trigger
         LANGUAGE plpgsql
        AS $function$
                        BEGIN
                          NEW.updated_at = NOW();
                          RETURN NEW;
                        END;
                        $function$
        ;
        -- End update_updated_at

-- SCHEMA:
    -- TABLE:
            -- Create Table

            -- Create Indexes

            -- Add Column Comments

            -- Create Triggers




-- SCHEMA:  targets

    -- TABLE:   targets.urls
        -- Create Table
        CREATE TABLE targets.urls (
            id bigserial NOT NULL,
            created_at timestamptz NOT NULL DEFAULT now(),
            updated_at timestamptz NOT NULL DEFAULT now(),
            url varchar NOT NULL,
            domain_id int4 NULL,
            is_objective bool NOT NULL DEFAULT false,
            active_main bool NOT NULL DEFAULT true,
            -- Scan: Tech
            active_scan_tech bool NOT NULL DEFAULT true,
            queued_at_tech timestamptz NULL,
            scanned_at_tech timestamptz NULL,
            -- Scan: Axe
            active_scan_axe bool NOT NULL DEFAULT true,
            queued_at_axe timestamptz NULL,
            scanned_at_axe timestamptz NULL,
            -- Scan: Uppies
            active_scan_uppies bool NOT NULL DEFAULT true,
            queued_at_uppies timestamptz NULL,
            scanned_at_uppies timestamptz NULL, -- formerly uppies_at
            uppies_code int4 NULL,
            -- Crawler
            active_crawler bool NOT NULL DEFAULT true,
            queued_at_crawler timestamptz NULL,
            crawled_at timestamptz NULL,
            source_url_id int4 NULL,
            recent_crawl_id int4 NULL,
            discovery_crawl_id int4 NULL,
            source_url varchar NULL,
            sitemapped bool NOT NULL DEFAULT false,
            CONSTRAINT urls_pk PRIMARY KEY (id),
            CONSTRAINT urls_un_url UNIQUE (url),
            -- CONSTRAINT urls_fk_domain FOREIGN KEY (domain_id) REFERENCES targets.domains(id),
            -- CONSTRAINT urls_fk_uppies_code FOREIGN KEY (uppies_code) REFERENCES refs.uppies_codes(code)
        );

        -- Create Indexes
        CREATE INDEX urls_active_main_idx ON targets.urls USING btree (active_main);
        -- CREATE INDEX urls_domain_id_idx ON targets.urls USING btree (domain_id);
        CREATE INDEX urls_is_objective_idx ON targets.urls USING btree (is_objective);
        -- CREATE INDEX urls_queued_at_axe_idx ON targets.urls USING btree (queued_at_axe);
        -- CREATE INDEX urls_uppies_at_idx ON targets.urls USING btree (uppies_at);

        -- Table Triggers

        CREATE TRIGGER urls_updated_at BEFORE
            UPDATE ON targets.urls FOR EACH ROW EXECUTE FUNCTION update_updated_at();

        -- CREATE TRIGGER update_discovery_crawl_id_trigger BEFORE
        --         INSERT
        --             ON
        --             targets.urls FOR EACH ROW EXECUTE FUNCTION targets.update_discovery_crawl_id();

        -- CREATE TRIGGER update_updated_at_trigger BEFORE
        --         UPDATE
        --             ON
        --             targets.urls FOR EACH ROW EXECUTE FUNCTION targets.update_updated_at();

        -- CREATE TRIGGER update_check_uppies AFTER
        --         UPDATE
        --             OF uppies_at ON
        --             targets.urls FOR EACH ROW EXECUTE FUNCTION refs.insert_check_uppies();

        -- CREATE TRIGGER set_objective_url_trigger AFTER
        --         INSERT
        --             ON
        --             targets.urls FOR EACH ROW EXECUTE FUNCTION targets.set_objective_url();

        -- CREATE TRIGGER set_domain_id_trigger AFTER
        --         INSERT
        --             ON
        --             targets.urls FOR EACH ROW
        --             WHEN ((new.domain_id IS NULL)) EXECUTE FUNCTION targets.update_domain_id();


    -- TABLE: targets.domains
        -- Create Table
        CREATE TABLE targets.domains (
            id serial4 NOT NULL, -- Primary domain identifer
            created_at timestamptz NOT NULL DEFAULT now(), -- When domain added
            updated_at timestamptz NOT NULL DEFAULT now(), -- When row updated
            "domain" varchar NOT NULL, -- Unique domain name
            active bool NULL, -- Should we analyze this domain?
            org_id int4 NULL, -- Corresponding Entity ID
            CONSTRAINT domains_pk_id PRIMARY KEY (id),
            CONSTRAINT domains_fk FOREIGN KEY (org_id) REFERENCES orgs.entities(id)
        );

        -- Create Indexes
        CREATE UNIQUE INDEX domains_domain_idx ON targets.domains USING btree (domain);
        CREATE INDEX domains_org_id_idx ON targets.domains USING btree (org_id);

        -- Add Column Comments

        COMMENT ON COLUMN targets.domains.id IS 'Primary domain identifer';
        COMMENT ON COLUMN targets.domains.created_at IS 'When domain added';
        COMMENT ON COLUMN targets.domains.updated_at IS 'When row updated';
        COMMENT ON COLUMN targets.domains."domain" IS 'Unique domain name';
        COMMENT ON COLUMN targets.domains.active IS 'Should we analyze this domain?';
        COMMENT ON COLUMN targets.domains.org_id IS 'Corresponding Entity ID';

        -- Add table triggers

        CREATE TRIGGER domains_updated_at BEFORE
            UPDATE ON targets.urls FOR EACH ROW EXECUTE FUNCTION update_updated_at();




-- SCHEMA: axe
    -- TABLE:
            -- Create Table

            -- Create Indexes

            -- Add Column Comments

            -- Create Triggers



