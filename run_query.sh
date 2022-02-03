#!/bin/sh

# set start_date and end_date of data used for the report query
start_date=2019-01-01
end_date=2019-12-31

PGPASSFILE=.pgpass \
psql \
-h asdc.immap.org \
-p 5432 \
-d geonode_data \
-U geonode \
-f base\ query.sql \
-f product\ delivered.sql \
-v exc_edu=true \
-v output_prefix='ASDC - ' \
-v start_date=$start_date \
-v end_date=$end_date

PGPASSFILE=.pgpass \
psql \
-h anhdc.andma.gov.af \
-p 5432 \
-d geonode_data \
-U geonode \
-f base\ query\ ANHDC.sql \
-f product\ delivered.sql \
-v exc_edu=true \
-v output_prefix='ANHDC - ' \
-v start_date=$start_date \
-v end_date=$end_date