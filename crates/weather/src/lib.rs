//! Weather business logic: fetching and interpreting forecasts, searching places, and persisting
//! saved locations and the last forecast for each, so the app can show something offline.

mod forecast;
mod model;

use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime};

pub use model::*;

/// Forecasts younger than this are served from the cache unless a refresh is forced.
const FRESH_FOR: Duration = Duration::from_secs(10 * 60);

#[cfg(feature = "uniffi")]
uniffi::setup_scaffolding!();

#[derive(Debug, thiserror::Error)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Error), uniffi(flat_error))]
pub enum WeatherError {
    #[error("couldn't reach the weather service: {0}")]
    Network(#[from] open_meteo::Error),
    #[error("couldn't read or write saved data: {0}")]
    Storage(#[from] std::io::Error),
    #[error("saved data is corrupted: {0}")]
    Corrupted(#[from] serde_json::Error),
}

pub struct WeatherService {
    client: open_meteo::Client,
    data_dir: PathBuf,
}

impl WeatherService {
    /// `data_dir` holds saved locations and cached forecasts; it is created if missing.
    pub fn new(data_dir: impl Into<PathBuf>) -> Result<Self, WeatherError> {
        let data_dir = data_dir.into();
        std::fs::create_dir_all(&data_dir)?;
        Ok(Self { client: open_meteo::Client::new(), data_dir })
    }

    /// Returns the cached forecast while it is fresh, otherwise fetches (and caches) a new one.
    pub async fn forecast(&self, location: &Location, force_refresh: bool) -> Result<Forecast, WeatherError> {
        if !force_refresh
            && let Some(cached) = self.cached_forecast(&location.id)
            && cached.fetched_at.elapsed().is_ok_and(|age| age < FRESH_FOR)
        {
            return Ok(cached);
        }
        let (raw, air_quality) = tokio::join!(
            self.client.forecast(location.latitude, location.longitude),
            self.client.air_quality(location.latitude, location.longitude),
        );
        // Air quality is optional garnish; don't fail the forecast over it.
        let us_aqi = air_quality
            .inspect_err(|error| tracing::warn!(%error, "air quality unavailable"))
            .ok()
            .and_then(|air_quality| air_quality.current.us_aqi);
        let forecast = forecast::build(raw?, us_aqi, SystemTime::now());
        self.write(&self.forecast_path(&location.id), &forecast)?;
        Ok(forecast)
    }

    /// The last successfully fetched forecast for a location, if any.
    pub fn cached_forecast(&self, location_id: &str) -> Option<Forecast> {
        self.read(&self.forecast_path(location_id))
            .inspect_err(|error| tracing::warn!(%error, location_id, "ignoring unreadable cached forecast"))
            .ok()
            .flatten()
    }

    pub async fn search(&self, query: &str, language: &str) -> Result<Vec<Location>, WeatherError> {
        let query = query.trim();
        if query.len() < 2 {
            return Ok(Vec::new());
        }
        let places = self.client.search(query, language).await?;
        Ok(places.into_iter().map(location_from_place).collect())
    }

    pub fn saved_locations(&self) -> Result<Vec<Location>, WeatherError> {
        Ok(self.read(&self.locations_path())?.unwrap_or_default())
    }

    /// Appends a location unless one with the same id is already saved.
    pub fn add_location(&self, location: Location) -> Result<Vec<Location>, WeatherError> {
        let mut locations = self.saved_locations()?;
        if !locations.iter().any(|saved| saved.id == location.id) {
            locations.push(location);
            self.write(&self.locations_path(), &locations)?;
        }
        Ok(locations)
    }

    pub fn remove_location(&self, id: &str) -> Result<Vec<Location>, WeatherError> {
        let mut locations = self.saved_locations()?;
        locations.retain(|location| location.id != id);
        self.write(&self.locations_path(), &locations)?;
        let _ = std::fs::remove_file(self.forecast_path(id));
        Ok(locations)
    }

    fn locations_path(&self) -> PathBuf {
        self.data_dir.join("locations.json")
    }

    fn forecast_path(&self, location_id: &str) -> PathBuf {
        self.data_dir.join(format!("forecast-{location_id}.json"))
    }

    fn read<T: serde::de::DeserializeOwned>(&self, path: &Path) -> Result<Option<T>, WeatherError> {
        match std::fs::read(path) {
            Ok(bytes) => Ok(Some(serde_json::from_slice(&bytes)?)),
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(None),
            Err(error) => Err(error.into()),
        }
    }

    /// Writes to a temporary file and renames it over `path`, so a crash never leaves a half-written file.
    fn write(&self, path: &Path, value: &impl serde::Serialize) -> Result<(), WeatherError> {
        let temporary = path.with_extension("tmp");
        std::fs::write(&temporary, serde_json::to_vec(value)?)?;
        Ok(std::fs::rename(temporary, path)?)
    }
}

fn location_from_place(place: open_meteo::Place) -> Location {
    let region = [place.admin1, place.country].into_iter().flatten().collect::<Vec<_>>().join(", ");
    Location {
        id: place.id.to_string(),
        name: place.name,
        region: (!region.is_empty()).then_some(region),
        latitude: place.latitude,
        longitude: place.longitude,
    }
}
