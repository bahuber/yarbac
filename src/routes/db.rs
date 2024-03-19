use crate::errors::internal_error;
use axum::{extract::State,http::StatusCode};
use crate::db::{DatabaseConnection, ConnectionPool};

pub async fn using_connection_pool_extractor(
    State(pool): State<ConnectionPool>,
) -> Result<String, (StatusCode, String)> {
    let conn = pool.get().await.map_err(internal_error)?;

    let row = conn
        .query_one("select 1 + 1", &[])
        .await
        .map_err(internal_error)?;
    let two: i32 = row.try_get(0).map_err(internal_error)?;

    Ok(two.to_string())
}



pub async fn using_connection_extractor(
    DatabaseConnection(conn): DatabaseConnection,
) -> Result<String, (StatusCode, String)> {
    let row = conn
        .query_one("select 1 + 1", &[])
        .await
        .map_err(internal_error)?;
    let two: i32 = row.try_get(0).map_err(internal_error)?;

    Ok(two.to_string())
}
