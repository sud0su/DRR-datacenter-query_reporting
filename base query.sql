CREATE TEMPORARY TABLE tmptbl_raw_product_delivered AS
    select 
        "matrix_matrix"."created",
        "matrix_matrix"."action",
        "people_profile"."org_type", 
        "people_profile"."organization", 
        "people_profile"."org_acronym",
        "people_profile"."org_name_status",
        "people_profile"."username"
    FROM "matrix_matrix" 
        INNER JOIN "people_profile" ON ( "matrix_matrix"."user_id" = "people_profile"."id" ) 
        LEFT OUTER JOIN "base_resourcebase" ON ( "matrix_matrix"."resourceid_id" = "base_resourcebase"."id" ) 
    WHERE NOT ("people_profile"."username" IN ('admin', 'dodiws', 'dodiwsreg', 'rafinkanisa', 'boedy1996', 'razinal', 'khalidUsman', 'tester'))
        and ( NOT ( people_profile.org_acronym is NULL )
        AND NOT ( people_profile.org_acronym = '' AND people_profile.org_acronym is NOT NULL )
        AND NOT ( LOWER(people_profile.org_acronym) = 'immap') )
--         and "matrix_matrix"."created" <= '2019-12-31' 
and EXTRACT(YEAR from "created") <= 2021
        and action not like '%security%'
        -- and "matrix_matrix"."created" <= '2020-09-30' 
;
