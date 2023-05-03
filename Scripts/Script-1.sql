
-- 
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to each table
CREATE TRIGGER update_updated_at
BEFORE UPDATE ON staging.urls
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();




-- a11yPython User
GRANT SELECT ON meta.domains TO a11yPython;
GRANT INSERT ON staging.urls TO a11yPython;


SELECT "domain" 
FROM meta.domains
WHERE crawl = TRUE;


SELECT count(DISTINCT(url)),
count (url )
FROM staging.urls u ;


-- Delete duplicate urls from staging.urls
DELETE FROM staging.urls
WHERE url IN (
    SELECT url FROM (
        SELECT url,
        ROW_NUMBER() OVER (
            PARTITION BY url
            ORDER BY id DESC
        ) AS row_num
        FROM staging.urls
    ) t
    WHERE t.row_num > 1
);



-- FUNCTIONS

-- Update Last Crawl At in Domains
CREATE OR REPLACE FUNCTION update_last_crawl_at() RETURNS trigger AS $$
BEGIN
    UPDATE meta.domains
    SET last_crawl_at = NEW.created_at
    WHERE domain = NEW.domain;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- delete offsite urls
CREATE TRIGGER offsite_links_trigger
AFTER INSERT ON staging.offsite_links
FOR EACH ROW
EXECUTE FUNCTION delete_from_staging_urls();







-- process
CREATE OR REPLACE FUNCTION process_staging_urls() RETURNS void AS $$
	DECLARE
	  record RECORD;
	  domain_var TEXT;
	BEGIN
	  -- Loop through each row in the staging.urls table
	  FOR record IN SELECT * FROM staging.urls
	  LOOP
	    -- Get the domain associated with the current row's python_uuid
	    SELECT domain INTO STRICT domain_var FROM results.crawls WHERE python_uuid = record.python_uuid;
	
	    -- Check if the url is an offsite link
	    IF NOT (record.url ~ ('^https?://' || domain_var) OR record.url ~ '^https?://localhost') THEN
	      -- If it is an offsite link, insert it into the staging.offsite_links table
	      INSERT INTO staging.offsite_links (url, source_url, source_domain, python_uuid)
	      VALUES (record.url, record.source_url, domain_var, record.python_uuid);
	    END IF;
	  END LOOP;
	END;
$$ LANGUAGE plpgsql;


SELECT process_staging_urls();



--- Delete offsite from process_staging_urls 
CREATE OR REPLACE FUNCTION delete_from_staging_urls() RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM staging.urls WHERE source_url = NEW.source_url AND url = NEW.url;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;







-- Triggers
CREATE TRIGGER update_last_crawl_at_trigger
AFTER INSERT ON results.offsite_links 
FOR EACH ROW
EXECUTE FUNCTION update_last_crawl_at();


-- Process Offsite_urls from staging.urls u 
SELECT process_staging_urls();


-- Get Total Count of URLs
SELECT *
FROM staging.urls
WHERE axe_scanned_at > NOW() - INTERVAL '5 minutes' ;






-- Get Results by Domain
SELECT crawls.domain AS "Domain",
    COUNT(urls.id) AS "Total",
    COUNT(CASE WHEN urls.updated_at >= urls.created_at 
        AND urls.updated_at > NOW() - INTERVAL '5 minutes' 
            THEN urls.id ELSE NULL END) AS "Recent Count"
FROM results.crawls
LEFT JOIN staging.urls ON crawls.python_uuid = urls.python_uuid
GROUP BY crawls.DOMAIN
ORDER BY "Recent Count" DESC;




SELECT url
FROM staging.urls
WHERE url LIKE '%wayback%'
OR url LIKE '%archive.org%'
OR url LIKE '%webcitation.org%';




-- Get Document Types
SELECT 
    CASE 
        WHEN url LIKE '%.pdf' THEN 'pdf'
        WHEN url LIKE '%.doc' THEN 'doc'
        WHEN url LIKE '%.docx' THEN 'docx'
        WHEN url LIKE '%.ppt' THEN 'ppt'
        WHEN url LIKE '%.pptx' THEN 'pptx'
        WHEN url LIKE '%.xls' THEN 'xls'
        WHEN url LIKE '%.xlsx' THEN 'xlsx'
        WHEN url LIKE '%.csv' THEN 'csv'
        WHEN url LIKE '%.zip' THEN 'zip'
        WHEN url LIKE '%.pages' THEN 'pages'
    END AS "file type",
    COUNT(*) AS "total count",
    COUNT(CASE WHEN created_at > NOW() - INTERVAL '5 minutes' THEN 1 ELSE NULL END) AS "5 minute count"
FROM staging.doc_urls
WHERE url LIKE '%.pdf' 
    OR url LIKE '%.doc' 
    OR url LIKE '%.docx' 
    OR url LIKE '%.ppt' 
    OR url LIKE '%.pptx' 
    OR url LIKE '%.xls' 
    OR url LIKE '%.xlsx' 
    OR url LIKE '%.csv' 
    OR url LIKE '%.zip' 
    OR url LIKE '%.pages'
GROUP BY "file type";


SELECT domain, last_crawl_at FROM meta.domains WHERE crawl = TRUE AND active = TRUE ORDER BY last_crawl_at ASC NULLS FIRST LIMIT 5;

SELECT url, id as "url_id" FROM staging.urls WHERE active=true AND NOT scanned_by_axe ORDER BY created_at DESC LIMIT 5;

SELECT count(*)
FROM results.items
WHERE pyaxe_uuid = 'bd621765-18c3-4782-a9ff-23c6f4e0fe65';

SELECT count(*)
FROM staging.urls
where






SELECT * FROM results.crawls c 
WHERE python_uuid = '9c31d7f5-2893-42f2-b925-ccac12ff4f99';




-- Recently Added Rows to Sub-Tables
SELECT
    (SELECT COUNT(*) FROM staging.bad_urls WHERE created_at >= NOW() - INTERVAL '10 minutes') AS bad_urls_count,
    (SELECT COUNT(*) FROM staging.doc_urls WHERE created_at >= NOW() - INTERVAL '10 minutes') AS doc_urls_count,
    (SELECT COUNT(*) FROM staging.image_urls WHERE created_at >= NOW() - INTERVAL '10 minutes') AS image_urls_count,
    (SELECT COUNT(*) FROM staging.urls WHERE created_at >= NOW() - INTERVAL '10 minutes') AS urls_count;
   
   -- Get Results by Domain
SELECT crawls.domain AS "Domain",
    COUNT(urls.id) AS "Total",
    COUNT(CASE WHEN urls.updated_at >= urls.created_at 
        AND urls.updated_at > NOW() - INTERVAL '5 minutes' 
            THEN urls.id ELSE NULL END) AS "Recent Count"
FROM results.crawls
LEFT JOIN staging.urls ON crawls.python_uuid = urls.python_uuid
GROUP BY crawls.DOMAIN
ORDER BY "Recent Count" DESC;
   
   
   -- Recently Added Rows to Sub-Tables
SELECT
    (SELECT COUNT(*) FROM staging.bad_urls) AS bad_urls_count,
    (SELECT COUNT(*) FROM staging.doc_urls) AS doc_urls_count,
    (SELECT COUNT(*) FROM staging.image_urls) AS image_urls_count,
    (SELECT COUNT(*) FROM staging.urls) AS urls_count;
   
   SELECT url, id as "url_id" FROM staging.urls WHERE active=true AND NOT scanned_by_axe ORDER BY created_at DESC LIMIT 1;
  
  ALTER TABLE results.nodes
ALTER COLUMN target TYPE VARCHAR(255);

ALTER TABLE results.nodes ADD COLUMN data JSON;


  
-- Axe Check Metrics

SELECT
    (SELECT COUNT(*) FROM results.scans WHERE created_at >= NOW() - INTERVAL '10 minutes') AS recent_scans,
    
    
    (SELECT COUNT(*) FROM staging.doc_urls WHERE created_at >= NOW() - INTERVAL '10 minutes') AS doc_urls_count,
    (SELECT COUNT(*) FROM staging.image_urls WHERE created_at >= NOW() - INTERVAL '10 minutes') AS image_urls_count,
    (SELECT COUNT(*) FROM staging.urls WHERE created_at >= NOW() - INTERVAL '10 minutes') AS urls_count;


SELECT count (url) AS "Scans"
FROM results.scans;
WHERE created_at >= NOW() - INTERVAL '10 minutes';



   
   

   SELECT DISTINCT count(url)
   FROM staging.bad_urls
   WHERE python_uuid = 'f35da7b1-270e-41bc-a12e-a10c6c9c43e4';

   SELECT url
   -- count(*)
   FROM staging.image_urls iu
   WHERE created_at >= NOW() - INTERVAL '5 minutes';
  

  
  
  

SELECT 'crawls' as table_name, count(*) as total_rows FROM results.crawls
UNION ALL
SELECT 'items' as table_name, count(*) as total_rows FROM results.items
UNION ALL
SELECT 'nodes' as table_name, count(*) as total_rows FROM results.nodes
UNION ALL
SELECT 'scans' as table_name, count(*) as total_rows FROM results.scans
UNION ALL
SELECT 'subnodes' as table_name, count(*) as total_rows FROM results.subnodes
UNION ALL
SELECT 'urls' as table_name, count(*) as total_rows FROM staging.urls;



SELECT count(*)
FROM staging.urls u 
WHERE url LIKE '%usa.gov%';

sel











SELECT domain, last_crawl_at
FROM meta.domains
WHERE crawl = TRUE AND active = TRUE
ORDER BY last_crawl_at ASC NULLS FIRST
LIMIT 1;

SELECT domain, last_crawl_at FROM meta.domains WHERE crawl = TRUE AND active = TRUE ORDER BY last_crawl_at ASC NULLS FIRST LIMIT 1;

   
   
   
   
   
   
   
   
   -- Scratch
   


-- Testing Domain Selection
SELECT "domain"
FROM meta.domains
WHERE crawl = TRUE 
ORDER BY last_crawl_at ASC 
LIMIT 1;



-- Select counts from delete_from_staging_url
SELECT COUNT(*) 
FROM staging.urls u 
WHERE created_at >= NOW() - INTERVAL '30 minutes';









SELECT * FROM staging.urls
WHERE url LIKE 'https://cms.gov/CCIIO/Programs-and-Initiatives/Premium-Stabiliza%';






-- Fix Staging.URLs

		-- Copy doc urls to doc_urls
			INSERT INTO staging.doc_urls (url, source_url, python_uuid)
	    SELECT url, source_url, python_uuid
	    FROM staging.urls
		  WHERE url LIKE '%.pdf'
		   OR url LIKE '%.doc'
		   OR url LIKE '%.docx'
		   OR url LIKE '%.ppt'
		   OR url LIKE '%.pptx'
		   OR url LIKE '%.xls'
		   OR url LIKE '%.xlsx'
		   OR url LIKE '%.xml'
		   OR url LIKE '%.csv'
		   OR url LIKE '%.zip'
		   OR url LIKE '%.pages'
	    ON CONFLICT (url) DO UPDATE SET
	        source_url = EXCLUDED.source_url,
	        python_uuid = EXCLUDED.python_uuid;

	
						-- Delete docs from urls
						DELETE FROM staging.urls 
						WHERE url LIKE '%.pdf' OR url LIKE '%.doc' OR url LIKE '%.docx' OR 
						      url LIKE '%.ppt' OR url LIKE '%.pptx' OR url LIKE '%.xls' OR 
						      url LIKE '%.xlsx' OR url LIKE '%.xml' OR url LIKE '%.csv' OR 
						      url LIKE '%.zip' OR url LIKE '%.pages';
	
						     
						     
						     
		-- Copy Image URLs to image_urls
		INSERT INTO staging.image_urls (url, source_url, python_uuid)
		SELECT url, source_url, python_uuid
		FROM staging.urls
		WHERE url LIKE '%.jpg'
		   OR url LIKE '%.jpeg'
		   OR url LIKE '%.png'
		   OR url LIKE '%.gif'
		   OR url LIKE '%.svg'
		   OR url LIKE '%.bmp'
		ON CONFLICT (url) DO UPDATE SET
		    source_url = EXCLUDED.source_url,
		    python_uuid = EXCLUDED.python_uuid;
		  
						  	-- Delete images from urls
						  	DELETE FROM staging.urls
							WHERE url LIKE '%.jpg'
							   OR url LIKE '%.jpeg'
							   OR url LIKE '%.png'
							   OR url LIKE '%.gif'
							   OR url LIKE '%.svg'
							   OR url LIKE '%.bmp';
		  
		  
		  
SELECT count(*)
	    FROM staging.urls
		  WHERE url LIKE '%.pdf'
		   OR url LIKE '%.doc'
		   OR url LIKE '%.docx'
		   OR url LIKE '%.ppt'
		   OR url LIKE '%.pptx'
		   OR url LIKE '%.xls'
		   OR url LIKE '%.xlsx'
		   OR url LIKE '%.xml'
		   OR url LIKE '%.csv'
		   OR url LIKE '%.zip'
		   OR url LIKE '%.pages';

		  -- Scratch
			SELECT DISTINCT (type)
			FROM results.items i ;
	
		  
		  

--- Big Metrics
		  
		  
		  -- Axe Checks
		  
		     -- Get Results by Domain
							
					SELECT crawls.domain AS "Domain",
					    COUNT(scans.id) AS "Total Scans"
							FROM results.crawls
								LEFT JOIN staging.urls ON crawls.python_uuid = urls.python_uuid
								LEFT JOIN results.scans ON urls.id = scans.url_id
							GROUP BY crawls.domain
							ORDER BY "Total Scans" DESC;

						
						SELECT crawls.domain AS "Domain",
       COUNT(DISTINCT scans.id) AS "Total Scans",
       COUNT(DISTINCT items.id) AS "Total Items",
       COUNT(DISTINCT nodes.id) AS "Total Nodes",
       COUNT(DISTINCT subnodes.subnodes_id) AS "Total Subnodes"
FROM results.crawls
LEFT JOIN staging.urls ON crawls.python_uuid = urls.python_uuid
LEFT JOIN results.scans ON scans.pyaxe_uuid = urls.python_uuid
LEFT JOIN results.items ON items.pyaxe_uuid = scans.pyaxe_uuid
LEFT JOIN results.nodes ON nodes.pyaxe_uuid = scans.pyaxe_uuid
LEFT JOIN results.subnodes ON subnodes.pyaxe_uuid = scans.pyaxe_uuid
GROUP BY crawls.domain
ORDER BY crawls.domain;


SELECT 
    crawls.domain AS domain,
    COUNT(DISTINCT scans.id) AS total_scans,
    COUNT(DISTINCT items.id) AS total_items,
    COUNT(DISTINCT nodes.id) AS total_nodes,
    COUNT(DISTINCT subnodes.id) AS total_subnodes,
    COUNT(DISTINCT CASE WHEN results.items.type = 'violations' THEN items.id::varchar END) AS violations,
	COUNT(DISTINCT CASE WHEN results.items.type = 'passes' THEN items.id::varchar END) AS passes,
	COUNT(DISTINCT CASE WHEN results.items.type = 'incomplete' THEN items.id::varchar END) AS incomplete,
	COUNT(DISTINCT CASE WHEN results.items.type = 'inapplicable' THEN items.id::varchar END) AS inapplicable,
    COUNT(DISTINCT CASE WHEN nodes.impact = 'critical' THEN nodes.id END) AS critical_nodes,
    COUNT(DISTINCT CASE WHEN nodes.impact = 'serious' THEN nodes.id END) AS serious_nodes,
    COUNT(DISTINCT CASE WHEN nodes.impact = 'moderate' THEN nodes.id END) AS moderate_nodes,
    COUNT(DISTINCT CASE WHEN nodes.impact = 'minor' THEN nodes.id END) AS minor_nodes,
    COUNT(DISTINCT CASE WHEN nodes.impact = 'suggestion' THEN nodes.id END) AS suggestion_nodes,
    COUNT(DISTINCT CASE WHEN subnodes.node_type = 'all' THEN subnodes.id END) AS all_subnodes,
    COUNT(DISTINCT CASE WHEN subnodes.node_type = 'any' THEN subnodes.id END) AS any_subnodes,
    COUNT(DISTINCT CASE WHEN subnodes.node_type = 'none' THEN subnodes.id END) AS none_subnodes
FROM 
    results.crawls crawls
    JOIN staging.urls urls ON crawls.python_uuid = urls.python_uuid
    JOIN results.scans scans ON urls.id = scans.url_id
    LEFT JOIN results.items items ON scans.pyaxe_uuid = items.pyaxe_uuid
    LEFT JOIN results.nodes nodes ON items.id = nodes.piwho_uuid
    LEFT JOIN results.subnodes subnodes ON nodes.id = subnodes.nodey_uuid
GROUP BY 
    crawls.domain;


   
   SELECT DISTINCT unnest(items.tags) AS tag
FROM results.items
JOIN results.scans ON items.pyaxe_uuid = scans.pyaxe_uuid
JOIN staging.urls ON scans.url_id = urls.id
JOIN results.crawls ON urls.python_uuid = crawls.python_uuid
WHERE crawls.domain = 'bentleyhensel.com';


-- Select Distinct Tags
INSERT INTO meta.matches (source, type)
SELECT DISTINCT UNNEST(tags), 'axe_tag'
FROM results.items;
ON CONFLICT (source) DO NOTHING;






-- Get Types by Tag
SELECT DISTINCT (tag),
    COUNT(DISTINCT CASE WHEN items.type = 'violations' THEN items.id END) AS violations,
    COUNT(DISTINCT CASE WHEN items.type = 'passes' THEN items.id END) AS passes,
    COUNT(DISTINCT CASE WHEN items.type = 'incomplete' THEN items.id END) AS incomplete,
    COUNT(DISTINCT CASE WHEN items.type = 'inapplicable' THEN items.id END) AS inapplicable
FROM results.items
	JOIN results.scans ON items.pyaxe_uuid = scans.pyaxe_uuid
	JOIN staging.urls ON scans.url_id = urls.id
    CROSS JOIN UNNEST(items.tags) AS tag
--WHERE urls.url like '%civic%'
GROUP BY tag
ORDER BY tag ASC;










