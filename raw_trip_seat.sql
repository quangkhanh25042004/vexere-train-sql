CREATE OR REPLACE TABLE `test-data-analyst-514016.vexere.raw_trip_seat` AS
WITH s AS (
  SELECT
    event_id,
    event_date,
    device_id,
    distance_group,
    CONCAT(JSON_VALUE(product_trip, '$.from_station'), '>',
           JSON_VALUE(product_trip, '$.to_station'))                          AS route_code,
    SAFE_CAST(SUBSTR(JSON_VALUE(product_trip, '$.trip_departure_time'), 1, 19) AS DATETIME) AS dep_time,
    IFNULL(SAFE_CAST(JSON_VALUE(product_trip, '$.train_available_seat.NGM') AS INT64), 0) AS avail_ngm,
    IFNULL(SAFE_CAST(JSON_VALUE(product_trip, '$.train_available_seat.NAC') AS INT64), 0) AS avail_nac,
    IFNULL(SAFE_CAST(JSON_VALUE(product_trip, '$.train_available_seat.NAM') AS INT64), 0) AS avail_nam,
    IFNULL(SAFE_CAST(JSON_VALUE(product_trip, '$.train_total_seat.NGM') AS INT64), 0)     AS total_ngm,
    IFNULL(SAFE_CAST(JSON_VALUE(product_trip, '$.train_total_seat.NAC') AS INT64), 0)     AS total_nac,
    IFNULL(SAFE_CAST(JSON_VALUE(product_trip, '$.train_total_seat.NAM') AS INT64), 0)     AS total_nam
  FROM `test-data-analyst-514016.vexere.raw_overview_daily`
  WHERE event_name = 'trip_select' AND product_trip IS NOT NULL
)
SELECT
  *,
  DATE(dep_time)                                       AS trip_date,
  EXTRACT(HOUR FROM dep_time)                          AS dep_hour,
  DATE_DIFF(DATE(dep_time), event_date, DAY)           AS lead_days,
  CASE
    WHEN DATE_DIFF(DATE(dep_time), event_date, DAY) <= 0  THEN '1. Trong ngày'
    WHEN DATE_DIFF(DATE(dep_time), event_date, DAY) <= 3  THEN '2. 1–3 ngày'
    WHEN DATE_DIFF(DATE(dep_time), event_date, DAY) <= 7  THEN '3. 4–7 ngày'
    WHEN DATE_DIFF(DATE(dep_time), event_date, DAY) <= 14 THEN '4. 8–14 ngày'
    WHEN DATE_DIFF(DATE(dep_time), event_date, DAY) <= 30 THEN '5. 15–30 ngày'
    ELSE '6. Trên 30 ngày'
  END                                                  AS lead_bucket,
  avail_ngm + avail_nac + avail_nam                    AS avail_total,
  total_ngm + total_nac + total_nam                    AS total_total,
  IF((total_ngm + total_nac + total_nam) > 0
     AND (avail_ngm + avail_nac + avail_nam) * 10 < (total_ngm + total_nac + total_nam), 1, 0) AS is_low
FROM s;
