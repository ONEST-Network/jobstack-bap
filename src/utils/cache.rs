use deadpool_redis::Pool;
use redis::AsyncCommands;
use tracing::error;

pub const V3_SEARCH_CACHE_VERSION_KEY: &str = "v3_search_cache_version";
pub const V3_SEARCH_CACHE_KEY_PREFIX: &str = "v3_search_cache";

pub async fn invalidate_v3_search_cache(redis_pool: &Pool) {
    let mut conn = match redis_pool.get().await {
        Ok(c) => c,
        Err(e) => {
            error!(
                "Failed to get Redis connection for cache invalidation: {:?}",
                e
            );
            return;
        }
    };

    let result: redis::RedisResult<i64> = conn.incr(V3_SEARCH_CACHE_VERSION_KEY, 1).await;
    if let Err(e) = result {
        error!("Failed to increment cache version key: {:?}", e);
    }
}
