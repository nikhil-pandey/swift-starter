//! Weather domain types. Values are metric (°C, km/h, hPa, mm, m); times are `SystemTime` (Swift `Date`).
//! Formatting for the user's locale and unit preferences is the UI's job.

use std::time::SystemTime;

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct Location {
    pub id: String,
    pub name: String,
    /// Region and country, e.g. "Île-de-France, France".
    pub region: Option<String>,
    pub latitude: f64,
    pub longitude: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct Forecast {
    /// IANA time zone of the location, for formatting local times.
    pub timezone: String,
    pub fetched_at: SystemTime,
    pub current: Current,
    pub outlook: Outlook,
    /// The next 24 hours, with sunrise and sunset interleaved.
    pub hourly: Vec<HourlyItem>,
    pub daily: Vec<Day>,
    /// Lowest and highest temperature across `daily`, for drawing comparable range bars.
    pub daily_low: f64,
    pub daily_high: f64,
    pub air_quality: Option<AirQuality>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct Current {
    pub time: SystemTime,
    pub condition: Condition,
    pub is_day: bool,
    pub temperature: f64,
    pub feels_like: f64,
    pub feels_like_reason: FeelsLikeReason,
    pub humidity_percent: f64,
    pub dew_point: f64,
    pub precipitation_mm: f64,
    pub pressure_hpa: f64,
    pub visibility_m: f64,
    pub uv_index: f64,
    pub uv_level: UvLevel,
    pub wind: Wind,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct Wind {
    pub speed_kmh: f64,
    pub gusts_kmh: f64,
    /// Direction the wind blows from, in degrees clockwise from north.
    pub direction_degrees: f64,
    pub compass: CompassPoint,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct Hour {
    pub time: SystemTime,
    pub condition: Condition,
    pub is_day: bool,
    pub temperature: f64,
    pub precipitation_probability: Option<u8>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Enum))]
pub enum HourlyItem {
    Hour { hour: Hour },
    Sunrise { time: SystemTime },
    Sunset { time: SystemTime },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct Day {
    /// Local midnight at the location.
    pub date: SystemTime,
    pub condition: Condition,
    pub low: f64,
    pub high: f64,
    pub precipitation_probability: Option<u8>,
    pub precipitation_mm: Option<f64>,
    pub uv_index_max: Option<f64>,
    pub sunrise: SystemTime,
    pub sunset: SystemTime,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Record))]
pub struct AirQuality {
    pub us_aqi: u16,
    pub level: AirQualityLevel,
}

/// Headline for the hourly forecast.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Enum))]
pub enum Outlook {
    /// Current conditions persist for the next 24 hours.
    Continuing { condition: Condition },
    /// Precipitation starts within 24 hours.
    PrecipitationStarting { condition: Condition, at: SystemTime },
    /// Current precipitation stops within 24 hours.
    PrecipitationEnding { at: SystemTime },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Enum))]
pub enum Condition {
    Clear,
    MostlyClear,
    PartlyCloudy,
    Cloudy,
    Fog,
    Drizzle,
    Rain,
    HeavyRain,
    FreezingRain,
    Snow,
    HeavySnow,
    Thunderstorms,
    Hail,
}

impl Condition {
    /// Maps a [WMO weather interpretation code](https://open-meteo.com/en/docs#weather_variable_documentation).
    pub fn from_wmo(code: u8) -> Self {
        match code {
            0 => Self::Clear,
            1 => Self::MostlyClear,
            2 => Self::PartlyCloudy,
            45 | 48 => Self::Fog,
            51 | 53 | 55 => Self::Drizzle,
            56 | 57 | 66 | 67 => Self::FreezingRain,
            61 | 63 | 80 | 81 => Self::Rain,
            65 | 82 => Self::HeavyRain,
            71 | 73 | 77 | 85 => Self::Snow,
            75 | 86 => Self::HeavySnow,
            95 => Self::Thunderstorms,
            96 | 99 => Self::Hail,
            _ => Self::Cloudy,
        }
    }

    pub fn is_precipitation(self) -> bool {
        !matches!(self, Self::Clear | Self::MostlyClear | Self::PartlyCloudy | Self::Cloudy | Self::Fog)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Enum))]
pub enum FeelsLikeReason {
    Similar,
    Humidity,
    Wind,
    Warmer,
    Colder,
}

impl FeelsLikeReason {
    pub fn new(temperature: f64, feels_like: f64, humidity_percent: f64, wind_kmh: f64) -> Self {
        let difference = feels_like - temperature;
        match difference {
            d if d.abs() < 1.5 => Self::Similar,
            d if d > 0.0 && humidity_percent >= 60.0 => Self::Humidity,
            d if d > 0.0 => Self::Warmer,
            _ if wind_kmh >= 15.0 => Self::Wind,
            _ => Self::Colder,
        }
    }
}

/// [WHO UV index](https://www.who.int/news-room/questions-and-answers/item/radiation-the-ultraviolet-(uv)-index) bands.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Enum))]
pub enum UvLevel {
    Low,
    Moderate,
    High,
    VeryHigh,
    Extreme,
}

impl UvLevel {
    pub fn new(index: f64) -> Self {
        match index {
            i if i < 3.0 => Self::Low,
            i if i < 6.0 => Self::Moderate,
            i if i < 8.0 => Self::High,
            i if i < 11.0 => Self::VeryHigh,
            _ => Self::Extreme,
        }
    }
}

/// [US EPA AQI](https://www.airnow.gov/aqi/aqi-basics/) bands.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Enum))]
pub enum AirQualityLevel {
    Good,
    Moderate,
    UnhealthyForSensitiveGroups,
    Unhealthy,
    VeryUnhealthy,
    Hazardous,
}

impl AirQualityLevel {
    pub fn new(us_aqi: u16) -> Self {
        match us_aqi {
            0..=50 => Self::Good,
            51..=100 => Self::Moderate,
            101..=150 => Self::UnhealthyForSensitiveGroups,
            151..=200 => Self::Unhealthy,
            201..=300 => Self::VeryUnhealthy,
            _ => Self::Hazardous,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[cfg_attr(feature = "uniffi", derive(uniffi::Enum))]
pub enum CompassPoint {
    N,
    Nne,
    Ne,
    Ene,
    E,
    Ese,
    Se,
    Sse,
    S,
    Ssw,
    Sw,
    Wsw,
    W,
    Wnw,
    Nw,
    Nnw,
}

impl CompassPoint {
    pub fn new(degrees: f64) -> Self {
        const POINTS: [CompassPoint; 16] = [
            CompassPoint::N,
            CompassPoint::Nne,
            CompassPoint::Ne,
            CompassPoint::Ene,
            CompassPoint::E,
            CompassPoint::Ese,
            CompassPoint::Se,
            CompassPoint::Sse,
            CompassPoint::S,
            CompassPoint::Ssw,
            CompassPoint::Sw,
            CompassPoint::Wsw,
            CompassPoint::W,
            CompassPoint::Wnw,
            CompassPoint::Nw,
            CompassPoint::Nnw,
        ];
        let index = (degrees.rem_euclid(360.0) / 22.5).round() as usize % POINTS.len();
        POINTS[index]
    }
}
