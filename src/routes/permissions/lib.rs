use crate::errors::internal_error;
use crate::db::DatabaseConnection;
use axum::http::StatusCode;

pub async fn add_permission(
    DatabaseConnection(conn): DatabaseConnection,
    permission_name: &String
) -> Result<String, (StatusCode, String)> {
    let row = conn
        .query_one("INSERT INTO permissions (name) VALUES ()", &[permission_name])
        .await
        .map_err(internal_error)?;

    let two: i32 = row.try_get(0).map_err(internal_error)?;

    Ok(two.to_string())
}
