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
        GRANT USAGE ON SCHEMA axe, targets, events, orgs, refs, results TO grafanareader;
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
            CONSTRAINT urls_un_url UNIQUE (url)
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
            UPDATE ON targets.domains FOR EACH ROW EXECUTE FUNCTION update_updated_at();



-- SCHEMA:  axe
    -- TABLE:   axe.scan_data
        -- Create Table
        CREATE TABLE axe.scan_data (
            id bigserial NOT NULL,
            engine_name varchar(20) NULL,
            engine_version varchar(10) NULL,
            orientation_angle varchar(5) NULL,
            orientation_type varchar(25) NULL,
            user_agent varchar(250) NULL,
            window_height int4 NULL,
            window_width int4 NULL,
            reporter varchar(50) NULL,
            runner_name varchar(50) NULL,
            scanned_at timestamptz NULL,
            url varchar NULL,
            url_id int8 NOT NULL,
            created_at timestamptz NOT NULL DEFAULT now(),
            updated_at timestamptz NOT NULL DEFAULT now(),
            CONSTRAINT scan_data_pkey PRIMARY KEY (id),
            CONSTRAINT scan_data_fk_url_id FOREIGN KEY (url_id) REFERENCES targets.urls(id)
        );

        -- Create Indexes
        CREATE INDEX scan_data_scanned_at_idx ON axe.scan_data USING btree (scanned_at);
        CREATE INDEX scan_data_url_id_idx ON axe.scan_data USING btree (url_id);

        -- Add Column Comments


        -- Create Triggers
        CREATE TRIGGER scan_data_updated_at BEFORE
            UPDATE ON axe.scan_data FOR EACH ROW EXECUTE FUNCTION update_updated_at();


    -- TABLE:
        -- Create Table
        CREATE TABLE axe.rules (
            id bigserial NOT NULL,
            scan_id int8 NULL,
            rule_type varchar(20) NULL,
            description varchar(250) NULL,
            help varchar(250) NULL,
            help_url varchar(250) NULL,
            axe_id varchar(35) NULL,
            impact varchar(25) NULL,
            tags jsonb NULL,
            nodes jsonb NULL,
            created_at timestamptz NOT NULL DEFAULT now(),
            CONSTRAINT rules_pkey PRIMARY KEY (id),
            CONSTRAINT rules_scan_data_id_fkey FOREIGN KEY (scan_id) REFERENCES axe.scan_data(id)
        );

        -- Create Indexes
        CREATE INDEX axe_rules_tags_gin_idx ON axe.rules USING gin (tags);
        CREATE INDEX rules_axe_id_idx ON axe.rules USING btree (axe_id);
        CREATE INDEX rules_rule_type_idx ON axe.rules USING btree (rule_type);
        CREATE INDEX rules_scan_id_idx ON axe.rules USING btree (scan_id);
        CREATE INDEX rules_tags_gin_idx ON axe.rules USING gin (tags jsonb_path_ops);

        -- Add Column Comments

        -- Create Triggers

-- END a11ydata Database




-- Create & Setup Grafana Database
    CREATE DATABASE grafana;

-- Create & Grant Users
    CREATE USER grafananalytics WITH PASSWORD 'zdr567NXphswuZe';
        GRANT ALL PRIVILEGES ON DATABASE grafana TO grafananalytics;
