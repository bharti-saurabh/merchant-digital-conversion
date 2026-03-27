-- Checkout Funnel — Session to Approval
-- Straive Strategic Analytics | Merchant Digital Conversion

WITH session_events AS (
    SELECT
        s.session_id,
        s.customer_id,
        s.device_type,
        s.session_start_ts,
        MAX(CASE WHEN e.event_type = 'CART_ADD'               THEN 1 ELSE 0 END) AS cart_add_flag,
        MAX(CASE WHEN e.event_type = 'CHECKOUT_START'         THEN 1 ELSE 0 END) AS checkout_start_flag,
        MAX(CASE WHEN e.event_type = 'PAYMENT_METHOD_SELECT'  THEN 1 ELSE 0 END) AS payment_method_selected_flag,
        MIN(CASE WHEN e.event_type = 'PAYMENT_METHOD_SELECT'  THEN e.event_data->>'method' END) AS payment_method,
        MAX(CASE WHEN e.event_type = 'AUTH_ATTEMPTED'         THEN 1 ELSE 0 END) AS auth_attempted_flag,
        MAX(CASE WHEN e.event_type = 'AUTH_APPROVED'          THEN 1 ELSE 0 END) AS auth_approved_flag,
        MAX(CASE WHEN e.event_type = 'ORDER_PLACED'           THEN CAST(e.event_data->>'order_value' AS FLOAT) END) AS order_value
    FROM dim_sessions s
    JOIN fact_session_events e ON s.session_id = e.session_id
    WHERE s.session_start_ts BETWEEN :start_date AND :end_date
    GROUP BY 1, 2, 3, 4
)

SELECT
    device_type,
    payment_method,
    COUNT(*)                                                    AS sessions,
    SUM(cart_add_flag)                                          AS cart_adds,
    SUM(checkout_start_flag)                                    AS checkout_starts,
    SUM(payment_method_selected_flag)                           AS payment_selected,
    SUM(auth_attempted_flag)                                    AS auth_attempts,
    SUM(auth_approved_flag)                                     AS auth_approvals,
    SUM(auth_approved_flag) * 1.0 / NULLIF(COUNT(*), 0)        AS end_to_end_conversion,
    SUM(auth_approved_flag) * 1.0 / NULLIF(SUM(auth_attempted_flag),0) AS auth_conversion,
    AVG(CASE WHEN auth_approved_flag = 1 THEN order_value END)  AS avg_approved_order_value,
    SUM(CASE WHEN auth_approved_flag = 1 THEN order_value END)  AS total_gmv
FROM session_events
GROUP BY 1, 2
ORDER BY total_gmv DESC
