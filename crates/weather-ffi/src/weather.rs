//! Swift-facing `WeatherService`. Domain types cross the boundary as-is via weather's `uniffi` feature.

use std::sync::Arc;

use ::weather::{Forecast, Location, WeatherError};

/// Unified-logging subsystem for Rust logs (visible in Xcode's console and Console.app).
const LOG_SUBSYSTEM: &str = "org.example.weather";

#[derive(uniffi::Object)]
pub struct WeatherService(::weather::WeatherService);

#[uniffi::export(async_runtime = "tokio")]
impl WeatherService {
    #[uniffi::constructor]
    pub fn new(data_dir: String) -> Result<Arc<Self>, WeatherError> {
        use tracing_subscriber::layer::SubscriberExt as _;
        use tracing_subscriber::util::SubscriberInitExt as _;
        // Info and above; dependencies like hyper log every connection at debug.
        let _ = tracing_subscriber::registry()
            .with(tracing_oslog::OsLogger::new(LOG_SUBSYSTEM, "rust"))
            .with(tracing_subscriber::filter::LevelFilter::INFO)
            .try_init();
        Ok(Arc::new(Self(::weather::WeatherService::new(data_dir)?)))
    }

    pub async fn forecast(&self, location: Location, force_refresh: bool) -> Result<Forecast, WeatherError> {
        self.0.forecast(&location, force_refresh).await
    }

    pub fn cached_forecast(&self, location_id: String) -> Option<Forecast> {
        self.0.cached_forecast(&location_id)
    }

    pub async fn search(&self, query: String, language: String) -> Result<Vec<Location>, WeatherError> {
        self.0.search(&query, &language).await
    }

    pub fn saved_locations(&self) -> Result<Vec<Location>, WeatherError> {
        self.0.saved_locations()
    }

    pub fn add_location(&self, location: Location) -> Result<Vec<Location>, WeatherError> {
        self.0.add_location(location)
    }

    pub fn remove_location(&self, id: String) -> Result<Vec<Location>, WeatherError> {
        self.0.remove_location(&id)
    }
}
