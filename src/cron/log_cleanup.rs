use crate::state::AppState;
use crate::utils::logging::cleanup_old_logs;
use std::sync::Arc;

pub async fn run(state: Arc<AppState>) {
    tracing::info!("Running daily log cleanup...");

    let log_dir = "app/logs";
    let svc = "bap-webhook";
    let log_retention_days = state.config.logging.log_retention_days;

    let normal_log_dir = format!("{}/{}", log_dir, svc);
    let perf_log_dir = format!("{}/perf", log_dir);
    let cron_log_dir = format!("{}/cron", log_dir);

    cleanup_old_logs(&normal_log_dir, log_retention_days);
    cleanup_old_logs(&perf_log_dir, log_retention_days);
    cleanup_old_logs(&cron_log_dir, log_retention_days);

    tracing::info!("Daily log cleanup finished.");
}
