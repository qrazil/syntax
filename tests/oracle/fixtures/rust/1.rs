// Copyright (c) 2026 [Your Name]. All rights reserved.
// SPDX-License-Identifier: LicenseRef-Proprietary
// Commercial licensing: [your future site]

//! Optional embeddings via any OpenAI-compatible `/embeddings` endpoint.
//! Returns `None` (never errors) when disabled or unreachable — callers degrade
//! gracefully to FTS-only recall.

use crate::config::CONFIG;

/// Request an embedding vector for `text`. `None` means "vector search unavailable
/// for this item" and callers must skip the vec_index write and reweight recall.
pub async fn embed(text: &str) -> Option<Vec<f32>> {
    if !CONFIG.embeddings_enabled {
        return None;
    }
    let url = CONFIG.embeddings_api_url.as_ref()?;
    let model = CONFIG.embeddings_model.as_deref().unwrap_or("");

    let mut req = reqwest::Client::new()
        .post(format!("{}/embeddings", url.trim_end_matches('/')))
        .json(&serde_json::json!({ "model": model, "input": text }));
    if let Some(key) = CONFIG.embeddings_api_key.as_ref() {
        req = req.bearer_auth(key);
    }

    let res = match req.send().await {
        Ok(r) => r,
        Err(e) => {
            tracing::warn!("embeddings request failed: {e}");
            return None;
        }
    };
    if !res.status().is_success() {
        tracing::warn!("embeddings endpoint returned {}", res.status());
        return None;
    }
    let body = res.json::<serde_json::Value>().await.ok()?;
    let arr = body["data"][0]["embedding"].as_array()?;
    Some(
        arr.iter()
            .filter_map(|v| v.as_f64().map(|f| f as f32))
            .collect(),
    )
}

/// Encode a vector as a JSON array string — the text form `vec0` accepts on insert
/// and in `MATCH` queries.
pub fn embedding_to_json(v: &[f32]) -> String {
    let mut s = String::from("[");
    for (i, x) in v.iter().enumerate() {
        if i > 0 {
            s.push(',');
        }
        s.push_str(&x.to_string());
    }
    s.push(']');
    s
}

