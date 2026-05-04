USE logis_db;
SHOW VARIABLES LIKE 'secure_file_priv';
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/logistics_dataset.csv'
INTO TABLE logis_1
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(shipment_id, shipment_date, carrier, origin_city, destination_city,@weight_kg,
@delivery_days,status,product_category,@shipping_cost_usd, delivery_notes)
SET weight_kg = NULLIF(@weight_kg,''),
	delivery_days = NULLIF(@delivery_days,''),
    shipping_cost_usd = NULLIF(@shipping_cost_usd,'');

-- PREVIEW THE FIRST TEN ROWS OF THE DATASET
SELECT * FROM logis_db.logis_1 LIMIT 10;

-- COUNT THE TOTAL NUMBER OF ROWS IN THE DATASET
SELECT COUNT(*) FROM logis_1;
-- THERE ARE 10000 RECORDS AND 11 COLUMNS IN THE DATASET

/* DATA QUALITY CHECK*/
	-- STEP 1: NUMBER OF MISSING/NULL AND BLANK STRING
SELECT 
	SUM(CASE WHEN shipment_date IS NULL THEN 1 ELSE 0 END) AS missing_shipmentdate,
    SUM(CASE WHEN carrier IS NULL OR carrier = '' THEN 1 ELSE 0 END) AS missing_carrier,
    SUM(CASE WHEN origin_city IS NULL OR origin_city = '' THEN 1 ELSE 0 END) AS missing_origincity,
    SUM(CASE WHEN destination_city IS NULL OR destination_city = '' THEN 1 ELSE 0 END) AS missing_destinationcity,
    SUM(CASE WHEN weight_kg IS NULL  THEN 1 ELSE 0 END) AS missing_weight_kg,
    SUM(CASE WHEN delivery_days IS NULL  THEN 1 ELSE 0 END) AS missing_delivery_days,
    SUM(CASE WHEN `status` IS NULL OR `status` = '' THEN 1 ELSE 0 END) AS missing_status,
    SUM(CASE WHEN product_category IS NULL OR product_category = '' THEN 1 ELSE 0 END) AS missing_productcategory,
    SUM(CASE WHEN shipping_cost_usd IS NULL  THEN 1 ELSE 0 END) AS missing_shippingcost,
    SUM(CASE WHEN delivery_notes IS NULL OR delivery_notes = '' THEN 1 ELSE 0 END) AS missing_delivery_note
    FROM logis_1;

-- STEP 2 : DUPLICATE CHECK
	SELECT shipment_id
    FROM logis_1
    GROUP BY shipment_id
    HAVING COUNT(*) > 1;
    
    WITH dup_cte AS (
		 SELECT *,
			     ROW_NUMBER() OVER(PARTITION BY shipment_id ORDER BY shipment_id) AS rnk
		 FROM logis_1)
         SELECT COUNT(*)
         FROM dup_cte
         WHERE rnk > 1;
/* THERE 192 DUPLICATES IN THE DATASET*/

-- STEP 3: INCONSISTENT FORMAT CHECK(CATEGORICAL COLUMN)
	-- CARRIER 
		SELECT DISTINCT CONVERT(carrier USING utf8mb4) COLLATE utf8mb4_bin AS carrier
        FROM logis_1;
/* BlueDart -- Blue Dart, FEDEX -- FedEx, ups -- UPS, blue dart -- Blue Dart, dhl -- DHL,TRIM WHITESPACE*/

	-- ORIGIN_CITY
		SELECT DISTINCT CONVERT(origin_city USING utf8mb4)collate utf8mb4_bin AS origin_city
        FROM logis_1;
        
	-- DESTINATION_CITY
		SELECT DISTINCT CONVERT(destination_city USING utf8mb4) COLLATE utf8mb4_bin AS destination_city
        FROM logis_1;
        
	-- STATUS
		SELECT DISTINCT CONVERT(`status` USING utf8mb4)COLLATE utf8mb4_bin AS `status`
        FROM logis_1;
	
    -- PRODUCT_CATEGORY
		SELECT DISTINCT CONVERT(product_category USING utf8mb4)COLLATE utf8mb4_bin AS product_category
        FROM logis_1;
	
-- STEP 3: INVALID VALUE IN NUMERICAL COLUMN CHECK
		-- weight_kg
			SELECT *, ROUND(w.missing_data * 100 / (SELECT COUNT(*) FROM logis_1),2) AS pct_missing_data
            FROM (SELECT
				'weight_kg' AS column_logistic,
				SUM(CASE WHEN weight_kg < 0 THEN 1 END) AS invalid_data,
                SUM(CASE WHEN weight_kg > 500 THEN 1 END) AS extreme_data,
                SUM(CASE WHEN weight_kg  IS NULL THEN 1 END) AS missing_data
			FROM logis_1) AS w
            
			UNION ALL
			
            SELECT 
				*, ROUND(D.missing_data * 100 / (SELECT COUNT(*) FROM logis_1),2)
                FROM (SELECT 'delivery_days' AS column_logistic,
				SUM(CASE WHEN delivery_days <= 0 THEN 1 END ),
                SUM(CASE WHEN delivery_days > 60 THEN 1 END),
                SUM(CASE WHEN delivery_days IS NULL THEN 1 END) AS missing_data 
			FROM logis_1) AS D
            
            UNION ALL
            
            SELECT *,  ROUND(S.missing_data * 100 / (SELECT COUNT(*) FROM logis_1),2)
            FROM (SELECT 
				'shipping_cost_usd' AS column_logistic,
                SUM(CASE WHEN shipping_cost_usd <= 0 THEN 1 END),
                0,
                SUM(CASE WHEN shipping_cost_usd IS NULL THEN 1 END) AS missing_data 
			FROM logis_1) S;
				
	-- STEP 3: INCONSISTENT DATE FORMAT CHECK
		
        SELECT shipment_date
        FROM (SELECT DISTINCT shipment_date 
			  FROM logis_1
			  WHERE shipment_date IS NOT NULL AND shipment_date != '') AS D
		WHERE shipment_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND
			  shipment_date NOT REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND
              shipment_date NOT REGEXP '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$' AND 
              shipment_date NOT REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' AND
              shipment_date NOT REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$';
/* THERE ARE FIVE DIFFERENT DATE FORMAT IN SHIPMENT_DATE */

DESCRIBE logis_1; -- delivery_days data_type needs to be change to INT, shipment_date to DATE

/* DATA CLEANING* */
-- CREATE A COPY OF THE DATASET 

CREATE TABLE logis_2 LIKE logis_1;

ALTER TABLE logis_2
ADD COLUMN rn INT;

INSERT INTO logis_2
SELECT *, ROW_NUMBER() OVER(PARTITION BY shipment_id ORDER BY shipment_id) as rn
FROM logis_1;

-- REMOVE DUPLICATE ROWS
SET SQL_SAFE_UPDATES = 0;

DELETE FROM logis_2
WHERE rn > 1;

ALTER TABLE logis_2
DROP COLUMN rn;

SELECT * FROM logis_2;

-- FIX INCONSISTENT STRING FORMAT
	SELECT DISTINCT CONVERT(carrier USING utf8mb4) COLLATE utf8mb4_bin AS carrier
        FROM logis_2;
-- CARRIER 
UPDATE logis_2
SET carrier = CASE 
    WHEN TRIM(LOWER(carrier)) COLLATE utf8mb4_bin = 'fedex'      THEN 'FedEx'
    WHEN TRIM(LOWER(carrier)) COLLATE utf8mb4_bin = 'blue dart'  THEN 'Blue Dart'
    WHEN TRIM(LOWER(carrier)) COLLATE utf8mb4_bin = 'bluedart'   THEN 'Blue Dart'
    WHEN TRIM(LOWER(carrier)) COLLATE utf8mb4_bin = 'ups'        THEN 'UPS'
    WHEN TRIM(LOWER(carrier)) COLLATE utf8mb4_bin = 'dhl'        THEN 'DHL'
    WHEN TRIM(LOWER(carrier)) COLLATE utf8mb4_bin = 'aramex'     THEN 'Aramex'
    WHEN TRIM(LOWER(carrier)) COLLATE utf8mb4_bin = 'dtdc'       THEN 'DTDC'
    WHEN TRIM(LOWER(carrier)) COLLATE utf8mb4_bin = 'ekart'      THEN 'Ekart'
    WHEN TRIM(LOWER(carrier)) COLLATE utf8mb4_bin  = 'delhivery'  THEN 'Delhivery'
    WHEN TRIM(LOWER(carrier)) COLLATE utf8mb4_bin = 'xpressbees' THEN 'XpressBees'
    ELSE carrier
END;

-- STATUS
UPDATE logis_2
SET status = CASE WHEN TRIM(LOWER(status)) = 'pending' THEN 'Pending'
				  WHEN TRIM(LOWER(status)) = 'delivered' THEN 'Delivered'
                  WHEN TRIM(LOWER(status)) = 'returned' THEN 'Returned'
                  WHEN TRIM(LOWER(status)) = 'in transit' THEN 'In Transit'
				  ELSE status
			 END;

SELECT DISTINCT CONVERT(`status` USING utf8mb4)COLLATE utf8mb4_bin AS `status`
FROM logis_2;                  

SELECT * FROM logis_2;

-- STANDARDIZE DATE FORMAT 
SELECT 
shipment_date
FROM logis_2
WHERE shipment_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

UPDATE logis_2
SET shipment_date = CASE WHEN shipment_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND CAST(substring_index(shipment_date, '-' , 1) AS UNSIGNED) > 12 THEN STR_TO_DATE(shipment_date, '%d-%m-%Y')
     WHEN shipment_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND CAST(SUBSTRING_INDEX(shipment_date, '-' , 1) AS UNSIGNED) <= 12 THEN 
STR_TO_DATE(shipment_date, '%m-%d-%Y')
	 WHEN shipment_date REGEXP '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$'THEN STR_TO_DATE(shipment_date, '%d-%b-%Y')
     WHEN shipment_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(shipment_date, '%Y-%m-%d')
     WHEN shipment_date REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$'THEN STR_TO_DATE(shipment_date, '%Y/%m/%d')
     WHEN shipment_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' AND CAST(SUBSTRING_INDEX(shipment_date, '/',1) AS UNSIGNED) > 12 
     THEN STR_TO_DATE(shipment_date, '%d/%m/%Y')
     WHEN shipment_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' AND CAST(SUBSTRING_INDEX(shipment_date, '/',1) AS UNSIGNED) <= 12 
     THEN STR_TO_DATE(shipment_date, '%m/%d/%Y') ELSE NULL
     END;

-- FIXING DATATYPE
SET SQL_SAFE_UPDATES = 0;

UPDATE logis_2
SET delivery_days = FLOOR(CAST(delivery_days AS DECIMAL(10,2)));

ALTER TABLE logis_2
MODIFY shipment_date DATE,
MODIFY delivery_days INT; 

-- FLAG EXTREME VALUES IN WEIGHT_KG AND DELIVERY_DAYS
ALTER TABLE logis_2
ADD COLUMN weight_kg_flag TINYINT DEFAULT 0,
ADD COLUMN delivery_days_flag TINYINT DEFAULT 0;

UPDATE logis_2
SET weight_kg_flag = 1,
	weight_kg = 500			-- cap
WHERE weight_kg >  500;

UPDATE logis_2
SET delivery_days_flag = 1,
	delivery_days = 60			-- cap
WHERE delivery_days > 60;

-- HANDLE INVALID ENTRIES AND NULLs
-- REPLACE THE NEGATIVE NUMBERS IN WEIGHT_KG WITH ABSOLUTE NUMBERS

-- Convert empty strings in carrier to NULL
SET SQL_SAFE_UPDATES = 0;

UPDATE logis_2
SET carrier = COALESCE(NULLIF(carrier, ''),'Unknown'),
    destination_city = COALESCE(NULLIF(destination_city, ''),'Unknown'),
    origin_city = COALESCE(NULLIF(origin_city, ''),'Unknown'),
    `status` = COALESCE(NULLIF(`status`, ''),'Unknown'),
    product_category = COALESCE(NULLIF(product_category, ''),'Unknown');


-- HANDLE NEGATIVE INVALID VALUES IN WEIGHT_KG
UPDATE logis_2
SET weight_kg = ABS(weight_kg)
WHERE weight_kg < 0;

-- REPLACE THE NEGATIVE NUMBERS IN shipping_cost_usd WITH ABSOLUTE NUMBERS 
UPDATE logis_2
SET shipping_cost_usd  = ABS(shipping_cost_usd )
WHERE shipping_cost_usd < 0;

-- REPLACE NULLS IN WEIGHT_KG WITH THE MEDIAN OF WEIGHT_KG OF OF THEIR PRODUCT_CATEGORY
SET SQL_SAFE_UPDATES = 0;

WITH ordered AS (
	SELECT product_category, weight_kg,
		   ROW_NUMBER() OVER(PARTITION BY product_category ORDER BY weight_kg) AS rn,
           COUNT(*) OVER(PARTITION BY product_category) AS cnt
    FROM logis_2
    WHERE weight_kg IS NOT NULL AND product_category != ''
),
median AS (
	SELECT product_category,cnt, AVG(weight_kg) AS weight
    FROM ordered 
    WHERE rn IN (FLOOR((cnt+2)/2), FLOOR((cnt+1)/2))
    GROUP BY product_category
) 
UPDATE logis_2 l
JOIN median m
	ON l.product_category = m.product_category
SET l.weight_kg = m.weight
WHERE l.weight_kg IS NULL;

SELECT *
FROM logis_2
WHERE weight_kg IS NULL;

-- REPLACE THE NULLS IN DELIVERY_DAYS WITH THE MEDIAN DELIVERY_DAYS OF EACH ROUTE AND CARRIER
-- delivery_days
UPDATE logis_2 l
JOIN (
    WITH base AS (
        SELECT shipment_id, carrier, origin_city, 
               destination_city, delivery_days
        FROM logis_2
        WHERE delivery_days IS NOT NULL
        AND carrier         IS NOT NULL
        AND origin_city     IS NOT NULL
        AND destination_city IS NOT NULL
    ),
    rank1 AS (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY origin_city, destination_city, carrier
                ORDER BY delivery_days
            ) AS rn,
            COUNT(*) OVER (
                PARTITION BY origin_city, destination_city, carrier
            ) AS cnt
        FROM base
    )
    SELECT 
        carrier,
        origin_city,
        destination_city,
        AVG(delivery_days) AS median_val,
        MAX(cnt)           AS cnt
    FROM rank1
    WHERE rn IN (FLOOR((cnt+1)/2), FLOOR((cnt+2)/2))
    GROUP BY carrier, origin_city, destination_city

) AS m
ON  l.origin_city       = m.origin_city
AND l.destination_city  = m.destination_city
AND l.carrier           = m.carrier
SET l.delivery_days = m.median_val
WHERE l.delivery_days IS NULL;


SELECT * FROM logis_2
WHERE delivery_dayS IS NULL;


-- SHIPPING_COST_USD

UPDATE logis_2 l
JOIN (
    WITH base AS (
        SELECT 
            shipment_id, carrier, origin_city,
            destination_city, weight_kg, shipping_cost_usd
        FROM logis_2
        WHERE shipping_cost_usd IS NOT NULL
        AND   weight_kg         IS NOT NULL
        AND   weight_kg         > 0
        AND   carrier           IS NOT NULL
        AND   origin_city       IS NOT NULL
        AND   destination_city  IS NOT NULL
    ),
    cost_rate AS (
        SELECT *,
            ROUND(shipping_cost_usd / weight_kg, 2) AS cost_per_kg
        FROM base
    ),
    ranked AS (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY origin_city, destination_city, carrier
                ORDER BY cost_per_kg
            ) AS rn,
            COUNT(*) OVER (
                PARTITION BY origin_city, destination_city, carrier
            ) AS cnt
        FROM cost_rate
    ),
    median_cost AS (
        SELECT 
            carrier,
            origin_city,
            destination_city,
            ROUND(AVG(cost_per_kg), 2) AS median_rate,
            MAX(cnt)                   AS cnt
        FROM ranked
        WHERE rn IN (FLOOR((cnt+1)/2), FLOOR((cnt+2)/2))
        GROUP BY origin_city, destination_city, carrier
    )
    SELECT 
        carrier,
        origin_city,
        destination_city,
        median_rate
    FROM median_cost

) AS m
ON  l.origin_city      = m.origin_city
AND l.destination_city = m.destination_city
AND l.carrier          = m.carrier

SET l.shipping_cost_usd = ROUND(l.weight_kg * m.median_rate, 2)

WHERE l.shipping_cost_usd IS NULL
AND   l.weight_kg         IS NOT NULL
AND   l.weight_kg         > 0;


SELECT 
	SUM(CASE WHEN shipment_date IS NULL THEN 1 ELSE 0 END) AS missing_shipmentdate,
    SUM(CASE WHEN carrier IS NULL OR carrier = '' THEN 1 ELSE 0 END) AS missing_carrier,
    SUM(CASE WHEN origin_city IS NULL OR origin_city = '' THEN 1 ELSE 0 END) AS missing_origincity,
    SUM(CASE WHEN destination_city IS NULL OR destination_city = '' THEN 1 ELSE 0 END) AS missing_destinationcity,
    SUM(CASE WHEN weight_kg IS NULL  THEN 1 ELSE 0 END) AS missing_weight_kg,
    SUM(CASE WHEN delivery_days IS NULL  THEN 1 ELSE 0 END) AS missing_delivery_days,
    SUM(CASE WHEN `status` IS NULL OR `status` = '' THEN 1 ELSE 0 END) AS missing_status,
    SUM(CASE WHEN product_category IS NULL OR product_category = '' THEN 1 ELSE 0 END) AS missing_productcategory,
    SUM(CASE WHEN shipping_cost_usd IS NULL  THEN 1 ELSE 0 END) AS missing_shippingcost,
    SUM(CASE WHEN delivery_notes IS NULL OR delivery_notes = '' THEN 1 ELSE 0 END) AS missing_delivery_note
    FROM logis_2;
    
    SELECT * FROM logis_2 ;
    