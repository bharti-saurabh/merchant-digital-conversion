-- Payment Method P&L Analysis
-- Straive Strategic Analytics | Merchant Digital Conversion

SELECT
    pm.payment_method,
    pm.funding_source,
    COUNT(t.txn_id)                                           AS txn_count,
    SUM(t.amount)                                             AS gross_volume,
    AVG(t.amount)                                             AS avg_txn_value,
    SUM(t.amount) / SUM(SUM(t.amount)) OVER ()               AS volume_share,
    -- Auth performance
    AVG(CASE WHEN t.auth_result = 'APPROVED' THEN 1.0 ELSE 0 END) AS auth_rate,
    -- Cost components
    SUM(t.amount * pm.interchange_rate)                       AS interchange_cost,
    SUM(pm.per_txn_fee)                                       AS per_txn_fees,
    SUM(t.amount * pm.assessment_rate)                        AS assessment_fees,
    SUM(t.amount * pm.interchange_rate + pm.per_txn_fee + t.amount * pm.assessment_rate) AS total_cost,
    -- Risk
    SUM(CASE WHEN t.is_disputed THEN 1 ELSE 0 END) * 1.0 / COUNT(t.txn_id) AS chargeback_rate,
    -- Net economics
    SUM(t.amount) - SUM(t.amount * pm.interchange_rate + pm.per_txn_fee + t.amount * pm.assessment_rate) AS net_revenue_contribution,
    (SUM(t.amount) - SUM(t.amount * pm.interchange_rate + pm.per_txn_fee + t.amount * pm.assessment_rate))
        / NULLIF(SUM(t.amount), 0) * 100                     AS net_margin_pct
FROM fact_transactions t
JOIN dim_payment_methods pm ON t.payment_method_id = pm.payment_method_id
WHERE t.txn_date BETWEEN :start_date AND :end_date
  AND t.status = 'SETTLED'
GROUP BY 1, 2
ORDER BY net_revenue_contribution DESC
