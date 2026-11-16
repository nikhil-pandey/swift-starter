//! Minimal async client for the [Open-Meteo](https://open-meteo.com) forecast, air-quality, and geocoding APIs.
//!
//! Mirrors the API's JSON shape; turning it into app concepts is the `weather` crate's job.
//! Requests use metric units and Unix timestamps; `timezone=auto` makes daily values follow the location's days.

use std::time::Duration;

use serde::Deserialize;

pub use reqwest::Error;

const FORECAST_URL: &str = "https://api.open-meteo.com/v1/forecast";
const AIR_QUALITY_URL: &str = "https://air-quality-api.open-meteo.com/v1/air-quality";
const GEOCODING_URL: &str = "https://geocoding-api.open-meteo.com/v1/search";

const CURRENT: &str = "temperature_2m,apparent_temperature,relative_humidity_2m,dew_point_2m,is_day,weather_code,\
    precipitation,pressure_msl,wind_speed_10m,wind_direction_10m,wind_gusts_10m,visibility,uv_index";
const HOURLY: &str = "temperature_2m,weather_code,precipitation_probability,is_day";
const DAILY: &str = "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,\
    precipitation_probability_max,precipitation_sum";
const FORECAST_DAYS: &str = "10";
/// Without a timeout, reqwest waits forever on a stalled connection.
const TIMEOUT: Duration = Duration::from_secs(15);

#[derive(Debug, Clone)]
pub struct Client {
    http: reqwest::Client,
}

impl Default for Client {
    fn default() -> Self {
        Self::new()
    }
}

impl Client {
    pub fn new() -> Self {
        let http =
            reqwest::Client::builder().timeout(TIMEOUT).build().expect("the HTTP client's TLS backend initializes");
        Self { http }
    }

    pub async fn forecast(&self, latitude: f64, longitude: f64) -> Result<Forecast, Error> {
        let query = [
            ("latitude", latitude.to_string()),
            ("longitude", longitude.to_string()),
            ("current", CURRENT.into()),
            ("hourly", HOURLY.into()),
            ("daily", DAILY.into()),
            ("forecast_days", FORECAST_DAYS.into()),
            ("timezone", "auto".into()),
            ("timeformat", "unixtime".into()),
        ];
        self.get(FORECAST_URL, &query).await
    }

    pub async fn air_quality(&self, latitude: f64, longitude: f64) -> Result<AirQuality, Error> {
        let query =
            [("latitude", latitude.to_string()), ("longitude", longitude.to_string()), ("current", "us_aqi".into())];
        self.get(AIR_QUALITY_URL, &query).await
    }

    /// Searches places by name. `language` is an ISO 639-1 code used for the returned names.
    pub async fn search(&self, name: &str, language: &str) -> Result<Vec<Place>, Error> {
        let query = [("name", name), ("language", language), ("count", "10")];
        let response: SearchResponse = self.get(GEOCODING_URL, &query).await?;
        Ok(response.results)
    }

    async fn get<T: serde::de::DeserializeOwned>(
        &self,
        url: &str,
        query: &(impl serde::Serialize + ?Sized),
    ) -> Result<T, Error> {
        self.http.get(url).query(query).send().await?.error_for_status()?.json().await
    }
}

#[derive(Debug, Deserialize)]
pub struct Forecast {
    /// IANA identifier, e.g. `Europe/Paris`.
    pub timezone: String,
    pub current: Current,
    pub hourly: Hourly,
    pub daily: Daily,
}

#[derive(Debug, Deserialize)]
pub struct Current {
    pub time: i64,
    pub temperature_2m: f64,
    pub apparent_temperature: f64,
    pub relative_humidity_2m: f64,
    pub dew_point_2m: f64,
    pub is_day: u8,
    pub weather_code: u8,
    pub precipitation: f64,
    pub pressure_msl: f64,
    pub wind_speed_10m: f64,
    pub wind_direction_10m: f64,
    pub wind_gusts_10m: f64,
    pub visibility: f64,
    pub uv_index: f64,
}

/// Column-oriented: index `i` of every vector describes hour `time[i]`.
#[derive(Debug, Deserialize)]
pub struct Hourly {
    pub time: Vec<i64>,
    pub temperature_2m: Vec<f64>,
    pub weather_code: Vec<u8>,
    pub precipitation_probability: Vec<Option<u8>>,
    pub is_day: Vec<u8>,
}

/// Column-oriented: index `i` of every vector describes the day starting at `time[i]`.
#[derive(Debug, Deserialize)]
pub struct Daily {
    pub time: Vec<i64>,
    pub weather_code: Vec<u8>,
    pub temperature_2m_max: Vec<f64>,
    pub temperature_2m_min: Vec<f64>,
    pub sunrise: Vec<i64>,
    pub sunset: Vec<i64>,
    pub uv_index_max: Vec<Option<f64>>,
    pub precipitation_probability_max: Vec<Option<u8>>,
    pub precipitation_sum: Vec<Option<f64>>,
}

#[derive(Debug, Deserialize)]
pub struct AirQuality {
    pub current: AirQualityCurrent,
}

#[derive(Debug, Deserialize)]
pub struct AirQualityCurrent {
    pub us_aqi: Option<u16>,
}

#[derive(Debug, Deserialize)]
struct SearchResponse {
    #[serde(default)]
    results: Vec<Place>,
}

#[derive(Debug, Deserialize)]
pub struct Place {
    pub id: i64,
    pub name: String,
    pub latitude: f64,
    pub longitude: f64,
    pub country: Option<String>,
    pub admin1: Option<String>,
}
