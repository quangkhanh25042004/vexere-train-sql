CREATE OR REPLACE TABLE `test-data-analyst-514016.vexere.raw_route_result` AS
SELECT
  event_id,
  event_date,
  device_id,
  trip_search_type,
  total_quantity,
  CASE WHEN total_quantity = 1 THEN '1 khách'
       WHEN total_quantity BETWEEN 2 AND 3 THEN '2–3 khách'
       WHEN total_quantity >= 4 THEN '4+ khách' END AS pax_group,
  DATE(SAFE_CAST(trip_search_date AS DATETIME))                              AS trip_date,
  DATE_DIFF(DATE(SAFE_CAST(trip_search_date AS DATETIME)), event_date, DAY)  AS lead_days,
  CASE
    WHEN trip_search_date IS NULL THEN '7. Không xác định'
    WHEN DATE_DIFF(DATE(SAFE_CAST(trip_search_date AS DATETIME)), event_date, DAY) < 0  THEN '0. Ngày đã qua'
    WHEN DATE_DIFF(DATE(SAFE_CAST(trip_search_date AS DATETIME)), event_date, DAY) = 0  THEN '1. Trong ngày'
    WHEN DATE_DIFF(DATE(SAFE_CAST(trip_search_date AS DATETIME)), event_date, DAY) <= 3  THEN '2. 1–3 ngày'
    WHEN DATE_DIFF(DATE(SAFE_CAST(trip_search_date AS DATETIME)), event_date, DAY) <= 7  THEN '3. 4–7 ngày'
    WHEN DATE_DIFF(DATE(SAFE_CAST(trip_search_date AS DATETIME)), event_date, DAY) <= 14 THEN '4. 8–14 ngày'
    WHEN DATE_DIFF(DATE(SAFE_CAST(trip_search_date AS DATETIME)), event_date, DAY) <= 30 THEN '5. 15–30 ngày'
    ELSE '6. Trên 30 ngày'
  END AS lead_bucket,
  CONCAT(
    IF(REGEXP_REPLACE(TRIM(CAST(from_search_name AS STRING)), r'^Ga\s+', '') = 'Sài Gòn', 'Hồ Chí Minh',
       REGEXP_REPLACE(TRIM(CAST(from_search_name AS STRING)), r'^Ga\s+', '')),
    ' → ',
    IF(REGEXP_REPLACE(TRIM(CAST(to_search_name AS STRING)), r'^Ga\s+', '') = 'Sài Gòn', 'Hồ Chí Minh',
       REGEXP_REPLACE(TRIM(CAST(to_search_name AS STRING)), r'^Ga\s+', ''))
  ) AS route,
  SAFE_CAST(JSON_VALUE(route_page_result, '$.total_trip') AS INT64)          AS total_trip,
  IF(SAFE_CAST(JSON_VALUE(route_page_result, '$.total_trip') AS INT64) = 0, 1, 0) AS is_zero
FROM `test-data-analyst-514016.vexere.raw_overview_daily`
WHERE event_name = 'view_load' AND screen_name = 'route';
