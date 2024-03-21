use crate::{
    db::{DatabaseConnection, ConnectionPool},
    errors::internal_error
};
use axum::{
    routing::{get, post},
    Router,
    http::StatusCode
};

pub async fn router() -> Router<ConnectionPool> {
    let router = Router::new().route("/", post(insert));
    router
}

async fn insert(
    DatabaseConnection(conn): DatabaseConnection
) -> Result<String, (StatusCode, String)> {

    let _result = conn
        .query(include_str!("sql/insert.sql"), &[])
        .await
        .map_err(internal_error)?;

    Ok("ok".to_string())
}

async fn update(
    DatabaseConnection(conn): DatabaseConnection
) -> Result<String, (StatusCode, String)> {

    let _result = conn
        .query(include_str!("sql/update.sql"), &[])
        .await
        .map_err(internal_error)?;

    Ok("ok".to_string())
}

async fn delete(
    DatabaseConnection(conn): DatabaseConnection
) -> Result<String, (StatusCode, String)> {

    let _result = conn
        .query(include_str!("sql/delete.sql"), &[])
        .await
        .map_err(internal_error)?;

    Ok("ok".to_string())
}
