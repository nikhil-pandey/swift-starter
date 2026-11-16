//! Turns raw Open-Meteo responses into the app's forecast, including derived insights.

use std::time::{Duration, SystemTime, UNIX_EPOCH};

use crate::model::{
    AirQuality, AirQualityLevel, CompassPoint, Condition, Current, Day, FeelsLikeReason, Forecast, Hour, HourlyItem,
    Outlook, UvLevel, Wind,
};

const HOURS_SHOWN: usize = 24;
const HOUR: Duration = Duration::from_secs(3600);

pub(crate) fn build(raw: open_meteo::Forecast, air_quality: Option<u16>, fetched_at: SystemTime) -> Forecast {
    let current = current(&raw.current);
    let hours = upcoming_hours(&raw.hourly, current.time);
    let daily = days(&raw.daily);
    let outlook = outlook(&current, &hours);
    let hourly = with_sun_events(hours, &daily);
    let daily_low = daily.iter().map(|day| day.low).fold(f64::INFINITY, f64::min);
    let daily_high = daily.iter().map(|day| day.high).fold(f64::NEG_INFINITY, f64::max);

    Forecast {
        timezone: raw.timezone,
        fetched_at,
        current,
        outlook,
        hourly,
        daily,
        daily_low,
        daily_high,
        air_quality: air_quality.map(|us_aqi| AirQuality { us_aqi, level: AirQualityLevel::new(us_aqi) }),
    }
}

fn current(raw: &open_meteo::Current) -> Current {
    Current {
        time: instant(raw.time),
        condition: Condition::from_wmo(raw.weather_code),
        is_day: raw.is_day == 1,
        temperature: raw.temperature_2m,
        feels_like: raw.apparent_temperature,
        feels_like_reason: FeelsLikeReason::new(
            raw.temperature_2m,
            raw.apparent_temperature,
            raw.relative_humidity_2m,
            raw.wind_speed_10m,
        ),
        humidity_percent: raw.relative_humidity_2m,
        dew_point: raw.dew_point_2m,
        precipitation_mm: raw.precipitation,
        pressure_hpa: raw.pressure_msl,
        visibility_m: raw.visibility,
        uv_index: raw.uv_index,
        uv_level: UvLevel::new(raw.uv_index),
        wind: Wind {
            speed_kmh: raw.wind_speed_10m,
            gusts_kmh: raw.wind_gusts_10m,
            direction_degrees: raw.wind_direction_10m,
            compass: CompassPoint::new(raw.wind_direction_10m),
        },
    }
}

/// The hour containing `now` and the 23 after it.
fn upcoming_hours(raw: &open_meteo::Hourly, now: SystemTime) -> Vec<Hour> {
    let start = raw.time.iter().position(|&time| instant(time) + HOUR > now).unwrap_or(raw.time.len());
    (start..raw.time.len())
        .take(HOURS_SHOWN)
        .map(|i| Hour {
            time: instant(raw.time[i]),
            condition: Condition::from_wmo(raw.weather_code[i]),
            is_day: raw.is_day[i] == 1,
            temperature: raw.temperature_2m[i],
            precipitation_probability: raw.precipitation_probability[i],
        })
        .collect()
}

fn days(raw: &open_meteo::Daily) -> Vec<Day> {
    (0..raw.time.len())
        .map(|i| Day {
            date: instant(raw.time[i]),
            condition: Condition::from_wmo(raw.weather_code[i]),
            low: raw.temperature_2m_min[i],
            high: raw.temperature_2m_max[i],
            precipitation_probability: raw.precipitation_probability_max[i],
            precipitation_mm: raw.precipitation_sum[i],
            uv_index_max: raw.uv_index_max[i],
            sunrise: instant(raw.sunrise[i]),
            sunset: instant(raw.sunset[i]),
        })
        .collect()
}

/// Compares current conditions with the hours after the current one.
fn outlook(current: &Current, hours: &[Hour]) -> Outlook {
    let raining = current.condition.is_precipitation();
    match hours.iter().skip(1).find(|hour| hour.condition.is_precipitation() != raining) {
        Some(hour) if raining => Outlook::PrecipitationEnding { at: hour.time },
        Some(hour) => Outlook::PrecipitationStarting { condition: hour.condition, at: hour.time },
        None => Outlook::Continuing { condition: current.condition },
    }
}

/// Inserts sunrise and sunset after the hour they fall in.
fn with_sun_events(hours: Vec<Hour>, days: &[Day]) -> Vec<HourlyItem> {
    let (Some(first), Some(last)) = (hours.first(), hours.last()) else {
        return Vec::new();
    };
    let window = first.time..last.time + HOUR;
    let mut events: Vec<HourlyItem> = days
        .iter()
        .flat_map(|day| [HourlyItem::Sunrise { time: day.sunrise }, HourlyItem::Sunset { time: day.sunset }])
        .filter(|event| window.contains(&time(event)))
        .collect();
    events.extend(hours.into_iter().map(|hour| HourlyItem::Hour { hour }));
    // An event at the same second as an hour sorts after it.
    events.sort_by_key(|item| (time(item), !matches!(item, HourlyItem::Hour { .. })));
    events
}

fn time(item: &HourlyItem) -> SystemTime {
    match item {
        HourlyItem::Hour { hour } => hour.time,
        HourlyItem::Sunrise { time } | HourlyItem::Sunset { time } => *time,
    }
}

/// Open-Meteo times are Unix seconds (`timeformat=unixtime`).
fn instant(unix_seconds: i64) -> SystemTime {
    UNIX_EPOCH + Duration::from_secs(unix_seconds.max(0) as u64)
}
