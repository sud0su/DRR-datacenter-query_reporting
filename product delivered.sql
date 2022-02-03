CREATE TEMPORARY TABLE tmptbl_product_delivered AS
    SELECT 
        -- EXTRACT(MONTH from "created") as month,
        -- EXTRACT(YEAR from "created") as year,
        "org_type", 
        "organization", 
        -- "org_acronym",
        -- "org_name_status",
        -- "username",
        count(*) as total_product_delivered,
        sum(case 
            when action in ('Dashboard ','Dashboard  baseline','Dashboard accesibility','Dashboard accessibility','Dashboard aseline','Dashboard avalanche','Dashboard avalancheforecast','Dashboard avalancherisk','Dashboard avalche','Dashboard avalcheforecast','Dashboard baseline','Dashboard baseline/api/metadata','Dashboard baseline\','Dashboard baselinef','Dashboard bseline','Dashboard covid','Dashboard covid19','Dashboard dro7ght','Dashboard drought','Dashboard drought?','Dashboard drought?page=drought','Dashboard droughtrisk','Dashboard earthquake','Dashboard eartquake','Dashboard fllodrisk','Dashboard flloodrisk','Dashboard flo','Dashboard floodforecast','Dashboard floodrisk','Dashboard g','Dashboard landslide','Dashboard main','Dashboard mine','Dashboard naturaldisaster','Dashboard overview','Dashboard security','Dashboard security.com','Dashboard weather') then 1
            else 0
        end) as "Dashboard consultation",
        sum(case 
            when action in ('Dashboard PDF 8','Dashboard PDF accessibility','Dashboard PDF avalancheforecast','Dashboard PDF avalancherisk','Dashboard PDF avalcheforecast''Dashboard PDF baseline','Dashboard PDF drought','Dashboard PDF earthquake','Dashboard PDF floodforecast','Dashboard PDF floodrisk','Dashboard PDF landslide','Dashboard PDF main','Dashboard PDF naturaldisaster','Dashboard PDF security','Dashboard PDF weather') then 1
            else 0
        end) as "Dashboard download",
        sum(case 
            when action in ('Interactive Calculation') then 1
            else 0
        end) as "Interactive map advance use",
        sum(case 
            when action in ('Interactive Map Download') then 1
            else 0
        end) as "Interactive map download",
        sum(case 
            when action in ('View Geoexplorer') then 1
            else 0
        end) as "Interactive map use",
        sum(case 
            when action in ('Download Layer') then 1
            else 0
        end) as "Layer download",
        sum(case 
            when action in ('Download') then 1
            else 0
        end) as "Static map download",
        sum(case 
            when action in ('View') then 1
            else 0
        end) as "Static map view"
    FROM tmptbl_raw_product_delivered
    -- group by 2,1,3,4,5
    group by 1,2
    order by 1,2
    -- order by 2,1,3,4,5
;
CREATE TEMPORARY TABLE tmptbl_sum_product_delivered AS
	select 
        sum("total_product_delivered") as "total_product_delivered",
        sum("Dashboard download") as "Dashboard download",
        sum("Dashboard consultation") as "Dashboard consultation",
        sum("Interactive map advance use") as "Interactive map advance use",
        sum("Interactive map download") as "Interactive map download",
        sum("Interactive map use") as "Interactive map use",
        sum("Layer download") as "Layer download",
        sum("Static map download") as "Static map download",
        sum("Static map view") as "Static map view"
	from tmptbl_product_delivered
;
CREATE TEMPORARY TABLE tmptbl_sum_product_delivered_by_org_type AS
	select 
        "org_type", 
        count(*) as "org_count",
        sum("total_product_delivered") as total_product_delivered,
        (sum("total_product_delivered") / (SUM(sum("total_product_delivered")) OVER() )) * 100 as percent_total_product_delivered
	from tmptbl_product_delivered
    group by 1
    order by 2
;
CREATE TEMPORARY TABLE tmptbl_sum_product_delivered_by_org AS
	select 
        "organization", 
        "org_type", 
        sum("total_product_delivered") as total_product_delivered,
        (sum("total_product_delivered") / (SUM(sum("total_product_delivered")) OVER() )) * 100 as percent_total_product_delivered
	from tmptbl_product_delivered
    group by 2,1
    order by 3
;

-- psql command; set output format to csv
\pset format csv

-- set format
\pset format aligned

-- set output to file
\o :output_prefix'product_delivered_by_org_type.txt' 
select *
from tmptbl_sum_product_delivered_by_org_type
order by total_product_delivered desc;

-- \pset format aligned
\o :output_prefix'product_delivered_by_org.txt' 
select *
from tmptbl_sum_product_delivered_by_org
order by total_product_delivered desc;

\o :output_prefix'product_delivered_quarterly_andma_ingo.txt' 
select 
    to_char("created", 'YYYY."Q"Q') AS quarter,
    sum(case 
        when LOWER("organization") = 'afghanistan national disaster management authority' then 1
        else 0
    end) as "ANDMA",
    sum(case 
        when LOWER("org_type") = 'international ngo' then 1
        else 0
    end) as "INGO"
from tmptbl_raw_product_delivered
group by 1 
order by 1 
;

\o :output_prefix'number of humanitarian organizations.txt' 
WITH tmptbl_sum_product_delivered_humanitarian AS (
    select 
        "org_type",
        "org_count",
        "total_product_delivered"
    from tmptbl_sum_product_delivered_by_org_type
    where "org_type" IN (
        'International NGO', 
        'Private/NGO', 
        -- 'United Nations', 
        'Red Cross and Red Crescent Movement', 
        'National NGO'
    )
)
(
    select 
        "org_type" as "humanitarian_org_type",
        "org_count"
    from tmptbl_sum_product_delivered_humanitarian
    order by "org_count" desc
)
UNION ALL
(
    select 
        'Total',
        sum("org_count")
    from tmptbl_sum_product_delivered_humanitarian
)
;

-- \pset format aligned 
\pset expanded \pset tuples_only
-- \pset format aligned \pset expanded \pset tuples_only
\o :output_prefix'product delivered.txt' 
select 
    *,
    ("Static map download" + "Static map view")::float / group_sum_product_delivered_exc_layer_download * 100 as "Percent Static map downloads/views",
    ("Interactive map download" + "Interactive map use")::float / group_sum_product_delivered_exc_layer_download * 100 as "Percent Interactive map downloads/views",
    "Dashboard consultation"::float / group_sum_product_delivered_exc_layer_download * 100 as "Percent Dashboard consultations",
    "Dashboard download"::float / group_sum_product_delivered_exc_layer_download * 100 as "Percent Dashboard downloads",
    "Interactive map advance use"::float / group_sum_product_delivered_exc_layer_download * 100 as "Percent Interactive map advance use"
from (
    select 
        "Dashboard download"+"Dashboard consultation"+"Interactive map advance use"+"Interactive map download"+"Interactive map use"+"Static map download"+"Static map view" as group_sum_product_delivered_exc_layer_download,
        *
    from tmptbl_sum_product_delivered
) as t1;


-- get total data
\o :output_prefix'total data.txt' 
with a(total_layers) as (
    select count(layer_cat) as total_layers
    from (select COALESCE(br.category_id, 0) as layer_cat
          from layers_layer ll
                   left join base_resourcebase br on ll.resourcebase_ptr_id = br.id
          where EXTRACT(YEAR from br.date) <= 2021) total
    where layer_cat != 40
),
     b(total_interactivemaps) as (
         select count(map_cat) as total_interactivemaps
         from (select COALESCE(br.category_id, 0) as map_cat
               from maps_map mm
                        left join base_resourcebase br on mm.resourcebase_ptr_id = br.id
               where EXTRACT(YEAR from br.date) <= 2021) total
         where map_cat != 40
     ),
     c(total_staticmaps) as (
         select count(doc_cat) as total_staticmaps
         from (select COALESCE(br.category_id, 0) as doc_cat
               from documents_document dd
                        left join base_resourcebase br on dd.resourcebase_ptr_id = br.id
               where EXTRACT(YEAR from br.date) <= 2021) total
         where doc_cat != 40
     ),
     d(total_users) as (
         select count(*) as total_users
         from people_profile
         where username != 'admin'
           and EXTRACT(YEAR from date_joined) <= 2021
     ),
     e(total_users_active) as (
         select count(*) as total_users
         from people_profile
         where username != 'admin'
           and is_active = true
           and EXTRACT(YEAR from date_joined) <= 2021
     ),
     f(total_users_inactive) as (
         select count(*) as total_users
         from people_profile
         where username != 'admin'
           and is_active = false
           and EXTRACT(YEAR from date_joined) <= 2021
     )
select a.total_layers, b.total_interactivemaps, c.total_staticmaps, d.total_users, e.total_users_active, f.total_users_inactive
from a, b, c, d, e, f;

-- reset output settings
\o