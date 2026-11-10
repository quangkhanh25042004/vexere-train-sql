CREATE OR REPLACE TABLE `test-data-analyst-514016.vexere.raw_overview_daily` AS
SELECT
  SAFE_CAST(event_time AS DATETIME)               AS event_time,
  DATE(SAFE_CAST(event_time AS DATETIME))         AS event_date,
  id                                              AS event_id,
  device_id,
  NULLIF(CAST(order_id AS STRING), '')            AS order_id,
  device_type,
  product_type,
  event_name,
  screen_name,
  from_search_name,
  to_search_name,
  trip_search_date,
  trip_search_type,
  route_way,
  IFNULL(SAFE_CAST(adult_quantity AS INT64), 0)
    + IFNULL(SAFE_CAST(children_quantity AS INT64), 0)
    + IFNULL(SAFE_CAST(senior_quantity AS INT64), 0)
    + IFNULL(SAFE_CAST(student_quantity AS INT64), 0)
    + IFNULL(SAFE_CAST(union_member_quantity AS INT64), 0) AS total_quantity,
  SAFE_CAST(adult_quantity AS INT64)              AS adult_quantity,
  SAFE_CAST(children_quantity AS INT64)           AS children_quantity,
  SAFE_CAST(senior_quantity AS INT64)             AS senior_quantity,
  SAFE_CAST(student_quantity AS INT64)            AS student_quantity,
  SAFE_CAST(union_member_quantity AS INT64)       AS union_member_quantity,
  trip_departure_time,
  trip_arrival_time,
  SAFE_CAST(duration AS INT64)                    AS duration,
  CASE
    WHEN SAFE_CAST(duration AS INT64) IS NULL     THEN NULL
    WHEN SAFE_CAST(duration AS INT64) < 240       THEN 'Gần (dưới 4h)'
    WHEN SAFE_CAST(duration AS INT64) <= 720      THEN 'Vừa (4–12h)'
    ELSE 'Xa (trên 12h)'
  END                                             AS distance_group,
  trip_from_station_code,
  trip_from_station_name,
  trip_from_district,
  trip_from_state,
  trip_to_station_code,
  trip_to_station_name,
  trip_to_district,
  trip_to_state,
  product_trip,
  sort,
  filter,
  route_page_result,
  transaction_status,
  coupon_code,
  coupon_status
FROM `test-data-analyst-514016.vexere.vexere_tracking`;
