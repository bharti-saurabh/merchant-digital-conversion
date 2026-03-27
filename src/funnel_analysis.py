"""
Checkout Funnel Analysis — Payment Conversion
Straive Strategic Analytics | Merchant Practice
"""
import pandas as pd
import numpy as np
import logging

log = logging.getLogger(__name__)

FUNNEL_STEPS = ["session_start","cart_add","checkout_start","payment_method_selected","auth_attempted","auth_approved"]

def compute_funnel(df: pd.DataFrame, group_by: list = None) -> pd.DataFrame:
    """Compute step-by-step funnel conversion rates."""
    if group_by:
        results = []
        for keys, grp in df.groupby(group_by):
            funneled = _compute_single_funnel(grp)
            for k, v in zip(group_by, [keys] if not isinstance(keys, tuple) else keys):
                funneled[k] = v
            results.append(funneled)
        return pd.concat(results, ignore_index=True)
    return _compute_single_funnel(df)

def _compute_single_funnel(df: pd.DataFrame) -> pd.DataFrame:
    rows = []
    prev_count = None
    for step in FUNNEL_STEPS:
        col = f"{step}_flag"
        if col not in df.columns: continue
        count = df[col].sum()
        rows.append({
            "step": step,
            "count": count,
            "step_conversion": count / prev_count if prev_count else 1.0,
            "overall_conversion": count / df[FUNNEL_STEPS[0]+"_flag"].sum(),
        })
        prev_count = count
    return pd.DataFrame(rows)

def segment_funnel_drops(df: pd.DataFrame) -> pd.DataFrame:
    """Identify biggest drop-off by payment method and device."""
    return compute_funnel(df, group_by=["payment_method","device_type"]).sort_values("step_conversion")

def quantify_recovery(funnel: pd.DataFrame, target_rate: float = 0.82) -> float:
    """Estimate GMV uplift if checkout conversion reached target."""
    current_rate = funnel[funnel["step"]=="auth_approved"]["overall_conversion"].iloc[0]
    volume = funnel[funnel["step"]=="session_start"]["count"].iloc[0]
    avg_order_value = 84.5  # from merchant profile
    return (target_rate - current_rate) * volume * avg_order_value
