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


-- SCHEMA: refs

    -- TABLE: uppies_codes
        -- Create Table
        CREATE TABLE refs.uppies_codes (
            id serial4 NOT NULL,
            created_at timestamptz NOT NULL DEFAULT now(),
            updated_at timestamptz NOT NULL DEFAULT now(),
            code int4 NOT NULL,
            description varchar NULL,
            "name" varchar NULL,
            "type" varchar NULL,
            "group" varchar NULL,
            CONSTRAINT uppies_codes_pk_id PRIMARY KEY (id),
            CONSTRAINT uppies_codes_un_code UNIQUE (code)
        );

        -- Create Indexes

        -- Add Column Comments
        COMMENT ON COLUMN refs.uppies_codes.description IS 'What the code means';
        COMMENT ON COLUMN refs.uppies_codes."name" IS 'Common name of code';
        COMMENT ON COLUMN refs.uppies_codes."type" IS 'Type of status code';
        COMMENT ON COLUMN refs.uppies_codes."group" IS 'Code Groupings';

        -- Create Triggers
        CREATE TRIGGER uppies_codes_updated_at BEFORE
            UPDATE ON refs.uppies_codes FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- END SCHEMA: refs


-- SCHEMA:  targets

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
            CONSTRAINT domains_un UNIQUE (domain)
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
            CONSTRAINT urls_fk FOREIGN KEY (domain_id) REFERENCES targets.domains(id)
        );

        -- Create Indexes
        CREATE INDEX urls_active_main_idx ON targets.urls USING btree (active_main);
        CREATE INDEX urls_domain_id_idx ON targets.urls USING btree (domain_id);
        CREATE INDEX urls_is_objective_idx ON targets.urls USING btree (is_objective);

        -- Table Triggers

        CREATE TRIGGER urls_updated_at BEFORE
            UPDATE ON targets.urls FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- END SCHEMA: targets

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


    -- TABLE:   rules
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

-- END SCHEMA: axe





-- SCHEMA: results

    -- TABLE:   scan_uppies
        -- Create Table
        CREATE TABLE results.scan_uppies (
            id bigserial NOT NULL,
            created_at timestamptz NOT NULL DEFAULT now(),
            updated_at timestamptz NOT NULL DEFAULT now(),
            url_id int4 NOT NULL,
            status_code int4 NOT NULL,
            content_type varchar NULL,
            response_time float8 NULL,
            charset varchar NULL,
            page_last_modified timestamptz NULL,
            content_length int8 NULL,
            "server" varchar NULL,
            x_powered_by varchar NULL,
            x_content_type_options varchar NULL,
            x_frame_options varchar NULL,
            x_xss_protection varchar NULL,
            content_security_policy varchar NULL,
            strict_transport_security varchar NULL,
            etag varchar NULL,
            CONSTRAINT uppies_pk PRIMARY KEY (id),
            CONSTRAINT scan_uppies_fk_status_code FOREIGN KEY (status_code) REFERENCES refs.uppies_codes(code),
            CONSTRAINT scan_uppies_fk_url_id FOREIGN KEY (url_id) REFERENCES targets.urls(id)
        );

        -- Create Indexes
        CREATE INDEX scan_uppies_created_at_idx ON results.scan_uppies USING btree (created_at);
        CREATE INDEX scan_uppies_status_code_idx ON results.scan_uppies USING btree (status_code);
        CREATE INDEX scan_uppies_url_id_idx ON results.scan_uppies USING btree (url_id);

        -- Add Column Comments

        -- Create Triggers
        CREATE TRIGGER scan_uppies_updated_at BEFORE
            UPDATE ON results.scan_uppies FOR EACH ROW EXECUTE FUNCTION update_updated_at();
-- END SCHEMA: results

GRANT SELECT ON ALL TABLES IN SCHEMA axe, targets, events, orgs, refs, results TO grafanareader;



-- END a11ydata Database


-- Begin grafana database
-- Create & Setup Grafana Database
CREATE DATABASE grafana;

-- Create & Grant Users
CREATE USER grafananalytics WITH PASSWORD 'zdr567NXphswuZe';
GRANT ALL PRIVILEGES ON DATABASE grafana TO grafananalytics;

-- Grant usage on schema public
GRANT USAGE ON SCHEMA public TO grafananalytics;

-- Grant create on schema public
GRANT CREATE ON SCHEMA public TO grafananalytics;

-- Alter default privileges
ALTER DEFAULT PRIVILEGES FOR ROLE grafananalytics IN SCHEMA public GRANT ALL ON TABLES TO grafananalytics;

