CREATE OR REPLACE TABLE `test-data-analyst-514016.vexere.raw_paid_order` AS
WITH p AS (   -- chỉ các dòng thanh toán thành công
  SELECT *
  FROM `test-data-analyst-514016.vexere.raw_overview_daily`
  WHERE event_name = 'view_load' AND screen_name = 'payment_result'
    AND transaction_status = 'successful' AND order_id IS NOT NULL
),
agg AS (      -- số liệu tính trên toàn bộ dòng của order
  SELECT
    order_id,
    MAX(total_quantity)                                         AS n_passengers,
    GREATEST(COUNT(DISTINCT CAST(trip_departure_time AS STRING)), 1) AS n_legs,
    COUNT(*)                                                    AS n_paid_rows,
    MIN(event_time)                                             AS paid_time
  FROM p
  GROUP BY order_id
),
first_row AS ( -- thuộc tính lấy từ dòng thanh toán đầu tiên của order
  SELECT *
  FROM p
  QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY event_time, event_id) = 1
),
cp AS (        -- order có mã coupon ở bất kỳ event nào
  SELECT order_id, TRUE AS has_coupon
  FROM `test-data-analyst-514016.vexere.raw_overview_daily`
  WHERE order_id IS NOT NULL AND coupon_code IS NOT NULL
  GROUP BY order_id
)
SELECT
  f.order_id,
  f.device_id,
  a.paid_time,
  DATE(a.paid_time)                       AS paid_date,
  f.device_type,
  f.product_type,
  f.trip_search_type,
  f.from_search_name,
  f.to_search_name,
  f.trip_from_station_code,
  f.trip_from_station_name,
  f.trip_from_state,
  f.trip_to_station_code,
  f.trip_to_station_name,
  f.trip_to_state,
  f.trip_departure_time,
  f.trip_arrival_time,
  f.duration,
  f.distance_group,
  a.n_passengers,
  f.adult_quantity,
  f.children_quantity,
  f.senior_quantity,
  f.student_quantity,
  f.union_member_quantity,
  a.n_legs,
  a.n_passengers * a.n_legs               AS n_tickets,
  IFNULL(c.has_coupon, FALSE)             AS has_coupon,
  a.n_paid_rows,
  IF(f.device_id IS NULL, NULL,
     COUNT(*) OVER (PARTITION BY f.device_id)) AS device_paid_orders
FROM first_row f
JOIN agg a USING (order_id)
LEFT JOIN cp c USING (order_id);
