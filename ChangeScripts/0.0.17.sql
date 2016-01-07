/******************************************************************
Change Script 0.0.17
Date: 01/07/16

    1. New land_use types
    2. Update old land_use types

******************************************************************/

UPDATE pg_enum
SET enumlabel = 'commercial'
WHERE enumlabel = 'Commercial'
AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'land_use');
UPDATE pg_enum
SET enumlabel = 'residential'
WHERE enumlabel = 'Residential'
AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'land_use');

ALTER TYPE land_use ADD VALUE 'agriculture';
ALTER TYPE land_use ADD VALUE 'grazing';
ALTER TYPE land_use ADD VALUE 'community land';
ALTER TYPE land_use ADD VALUE 'other';