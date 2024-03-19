use yarbac::routes;
use yarbac::configuration::get_configuration;

use axum::{
    routing::get,
    Router,
};
use bb8::Pool;
use bb8_postgres::PostgresConnectionManager;
use tokio_postgres::NoTls;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() {
    let config = get_configuration().expect("Failed to read configuration.");
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "example_tokio_postgres=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // set up connection pool
    let manager =
        PostgresConnectionManager::new(config.database.with_db(), NoTls);
    let pool = Pool::builder().build(manager).await.unwrap();

    // build our application with some routes
    let app = Router::new()
        .route(
            "/",
            get(routes::using_connection_pool_extractor).post(routes::using_connection_extractor),
        )
        .route(
            "/health_check", get(routes::health_check)
        )
        .with_state(pool);

    // run it
    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .unwrap();
    tracing::debug!("listening on {}", listener.local_addr().unwrap());
    axum::serve(listener, app).await.unwrap();
}
