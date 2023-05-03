# Axe Result Tables
An overview of the various tables in the `axe` schema from `a11ydata`.

## `scans` table:
| Column Name | Axe Name | Axe Type | Column Type | Notes |
|-----------|-----------|-----------|-----------|-----------|
| id     |      | | BIGSERIAL NOT NULL    | Not in Axe, auto-generated     |
| engine_name | engine_name |  | VARCHAR(20) | |
| engine_version | engine_version | | VARCHAR(10) | |
| env_orientation_angle | env.orientation.angle | | VARCHAR(5) | |
| env_orientation_type | env.orientation.type | | VARCHAR(25) | |
| env_user_agent | env.user_agent | | VARCHAR(250) | |
| env_window_height | env.viewports.height | | INT | |
| env_window_width | env.viewports.width | | INT | |
| reporter | reporter | | VARCHAR(50) | |
| runner_name | tool.name | | VARCHAR(50) | |
| scanned_at | scanned_at | | TIMESTAMPTZ | |
| url | url | | VARCHAR(1000) | |
| url_id | | | BIGINT NOT NULL | Comes from Axe Controller, not scan |
| created_at | | | TIMESTAMPTZ | Auto Generated: NOW( ) |
| updated_at | | | TIMESTAMPTZ | Auto Generated: NOW( ) - Updated when row updated |

### Create Table



```PLpgSQL
CREATE TABLE axe.scan_data (
    id BIGSERIAL PRIMARY KEY,
    engine_name VARCHAR(20),
    engine_version VARCHAR(10),
    env_orientation_angle VARCHAR(5),
    env_orientation_type VARCHAR(25),
    env_user_agent VARCHAR(250),
    env_window_height INT,
    env_window_width INT,
    reporter VARCHAR(50),
    runner_name VARCHAR(50),
    scanned_at TIMESTAMPTZ,
    url VARCHAR(1000),
    url_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```



## `rules` table:

| Column Name | Axe Response Name | Column Type | Notes |
|-----------|-----------|-----------|-----------|
| id |      | BIGSERIAL | Not in Axe, auto-generated |
| scan_data_id |      | BIGINT | Reference to scan_data table |
| rule_type |  | VARCHAR(20) | Represents "violations", "incomplete", "inapplicable", or "passes" |
| description | description | VARCHAR(250) | |
| help | help | VARCHAR(250) | |
| help_url | helpUrl | VARCHAR(250) | |
| axe_id | id | VARCHAR(35) | Axe Rule Name |
| impact | impact | VARCHAR(25) | |
| tags | tags | JSONB | |


### Create Table

```PLpgSQL
CREATE TABLE axe.rules (
    id BIGSERIAL PRIMARY KEY,
    scan_data_id BIGINT,
    rule_type VARCHAR(20),
    description VARCHAR(250),
    help VARCHAR(250),
    help_url VARCHAR(250),
    axe_id VARCHAR(35),
    impact VARCHAR(25),
    tags JSONB,
    FOREIGN KEY (scan_data_id) REFERENCES axe.scan_data (id)
);
```


## `nodes` table:

| Column Name | Axe Response Name | Column Type | Notes |
|-----------|-----------|-----------|-----------|
| id |      | BIGSERIAL  | Not in Axe, auto-generated |
| rule_id |      | BIGINT | Reference to rules table |
| all_criteria | all | JSONB | |
| any_criteria | any | JSONB | |
| failure_summary | failureSummary | VARCHAR(250) | |
| html | html | VARCHAR(1500) | |
| impact | impact | VARCHAR(25) | |
| none_criteria | none | JSONB | |
| target | target | JSONB | |


### Create Table

```PLpgSQL
CREATE TABLE axe.nodes (
    id BIGSERIAL PRIMARY KEY,
    rule_id BIGINT NOT NULL,
    all_criteria JSONB,
    any_criteria JSONB,
    failure_summary VARCHAR(250),
    html VARCHAR(1500),
    impact VARCHAR(25),
    none_criteria JSONB,
    target JSONB,
    FOREIGN KEY (rule_id) REFERENCES axe.rules (id)
);
```


## `criteria` table:
This table's content comes directly from the `nodes` table. The content will not be inserted from Franklin's Rabbit but a PostgreSQL function handles the associated processing. For all intents and purposes, outside of PostgreSQL, this content is nothing more than a `JSONB` in `axe.nodes`.

| Column Name | Axe Response Name | Column Type | Notes |
|-----------|-----------|-----------|-----------|
| id |      | BIGSERIAL | Not in Axe, auto-generated |
| node_id |      | BIGINT | Reference to nodes table |
| criteria_type |  | varchar(4) | Represents "any", "all", or "none" |
| data |      | JSONB | |
| axe_id | id | VARCHAR(35) | Axe Rule Name |
| impact | impact | VARCHAR(25) | |
| message | message | VARCHAR(500) | |
| related_nodes | relatedNodes | JSONB | |


### Create Table

```PLpgSQL
CREATE TABLE axe.criteria (
    id BIGSERIAL PRIMARY KEY,
    node_id INT,
    criteria_type VARCHAR(4),
    data JSONB,
    axe_id VARCHAR(35),
    impact VARCHAR(25),
    message VARCHAR(500),
    related_nodes JSONB,
    FOREIGN KEY (node_id) REFERENCES axe.nodes (id)
);
```

### Processing Function
This function generates the content of the `axe.criteria` table.

```PLpgSQL
CREATE OR REPLACE FUNCTION axe.populate_criteria_from_nodes()
RETURNS VOID AS $$
DECLARE
    node_row RECORD;
    criteria_type TEXT;
    criteria_data JSONB;
BEGIN
    FOR node_row IN SELECT * FROM axe.nodes
    LOOP
        FOR criteria_type IN ARRAY['all', 'any', 'none']
        LOOP
            IF criteria_type = 'all' THEN
                criteria_data := node_row.all_criteria;
            ELSIF criteria_type = 'any' THEN
                criteria_data := node_row.any_criteria;
            ELSE
                criteria_data := node_row.none_criteria;
            END IF;

            IF criteria_data IS NOT NULL THEN
                INSERT INTO axe.criteria (node_id, criteria_type, data, axe_id, impact, message, related_nodes)
                SELECT
                    node_row.id,
                    criteria_type,
                    elem->'data',
                    elem->>'id',
                    elem->>'impact',
                    elem->>'message',
                    elem->'relatedNodes'
                FROM jsonb_array_elements(criteria_data) AS elem;
            END IF;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

```

**Trigger**
```PLpgSQL
SELECT axe.populate_criteria_from_nodes();
```

