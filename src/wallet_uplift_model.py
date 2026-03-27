"""
Digital Wallet Adoption Uplift Model
Straive Strategic Analytics | Merchant Practice
"""
import pandas as pd
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score
import logging

log = logging.getLogger(__name__)

FEATURES = ["age_band","digital_savviness_score","mobile_device_flag",
            "prior_wallet_txn_flag","avg_txn_value","txn_frequency_30d",
            "card_type","loyalty_tier"]

def compute_ab_lift(control: pd.DataFrame, treatment: pd.DataFrame) -> dict:
    """Measure incremental wallet adoption from A/B promotion test."""
    ctrl_rate = control["adopted_wallet"].mean()
    trt_rate  = treatment["adopted_wallet"].mean()
    ctrl_aov  = control["avg_order_value"].mean()
    trt_aov   = treatment["avg_order_value"].mean()
    ctrl_auth = control["auth_approved"].mean()
    trt_auth  = treatment["auth_approved"].mean()
    return {
        "adoption_lift_ppt":  round((trt_rate - ctrl_rate) * 100, 2),
        "aov_lift_pct":       round((trt_aov - ctrl_aov) / ctrl_aov * 100, 2),
        "auth_rate_lift_ppt": round((trt_auth - ctrl_auth) * 100, 2),
        "control_n": len(control), "treatment_n": len(treatment),
    }

def train_propensity(df: pd.DataFrame) -> LogisticRegression:
    """Propensity model to identify customers likely to adopt wallets."""
    X = pd.get_dummies(df[FEATURES], drop_first=True).fillna(0)
    y = df["adopted_wallet"]
    model = LogisticRegression(max_iter=300, random_state=42)
    model.fit(X, y)
    log.info(f"Wallet propensity AUC: {roc_auc_score(y, model.predict_proba(X)[:,1]):.4f}")
    return model
