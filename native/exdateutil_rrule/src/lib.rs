use chrono::{DateTime, Month};
use rrule::{RRule, Unvalidated, Tz};
use rustler::{Encoder, Decoder, Env, Term, NifResult, NifStruct};
use std::fmt;

use std::convert::TryFrom;

mod atoms {
    rustler::atoms! {
        ok
    }
}

#[derive(Debug, Clone)]
enum ExternalNWeekday {
    Tuple(i16, String),
    String(String)
}

#[derive(Debug, Clone, Default)]
enum MaybeCount {
    #[default]
    None,
    Some(u32)
}

#[derive(Debug, Clone, Default)]
enum MaybeDateTime {
    #[default]
    None,
    Some(DateTime<Tz>)
}


/// Encoding and decoding implementations for custom types to allow conversion between
/// Elixir and Rust data structures. These implementations allow Rustler to automatically 
/// convert between Elixir terms and Rust types when NIFs are called, providing
/// interoperability between the two languages.
/// 
/// The Encoder trait defines how to convert Rust types to Elixir terms.
/// The Decoder trait defines how to convert Elixir terms to Rust types.
/// 
/// If it cannot be converted, it returns an argument error on the elixir side

impl Encoder for MaybeDateTime {
    fn encode<'a>(&self, env: Env<'a>) -> Term<'a> {
        match self {
            MaybeDateTime::None => rustler::types::atom::nil().to_term(env),
            MaybeDateTime::Some(dt) => dt.to_rfc3339().encode(env)
        }
    }
}

impl<'a> Decoder<'a> for MaybeDateTime {
    fn decode(term: Term<'a>) -> NifResult<Self> {
        if rustler::types::atom::nil() == term {
            return Ok(MaybeDateTime::None);
        } else if let Ok(dt) = term.decode::<String>() {
            return Ok(MaybeDateTime::Some(DateTime::parse_from_rfc3339(&dt).unwrap().with_timezone(&Tz::UTC)));
        }
        Err(rustler::Error::BadArg)
    }
}

impl Encoder for MaybeCount {
    fn encode<'a>(&self, env: Env<'a>) -> Term<'a> {
        match self {
            MaybeCount::None => rustler::types::atom::nil().to_term(env),
            MaybeCount::Some(n) => n.encode(env)
        }
    }
}

impl<'a> Decoder<'a> for MaybeCount {
    fn decode(term: Term<'a>) -> NifResult<Self> {
        if rustler::types::atom::nil() == term {
            return Ok(MaybeCount::None);
        } else if let Ok(n) = term.decode::<u32>() {
            return Ok(MaybeCount::Some(n));
        }
        Err(rustler::Error::BadArg)
    }
}

impl std::fmt::Display for MaybeCount {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            MaybeCount::None => write!(f, "None"),
            MaybeCount::Some(n) => write!(f, "Some({})", n)
        }
    }
}

impl Encoder for ExternalNWeekday {
    fn encode<'a>(&self, env: Env<'a>) -> Term<'a> {
        match self {
            ExternalNWeekday::Tuple(n, s) => (n, s).encode(env),
            ExternalNWeekday::String(s) => s.encode(env)
        }
    }
}

impl<'a> Decoder<'a> for ExternalNWeekday {
    fn decode(term: Term<'a>) -> NifResult<Self> {
        if let Ok((n, s)) = term.decode::<(i16, String)>() {
            return Ok(ExternalNWeekday::Tuple(n, s));
        } else if let Ok(s) = term.decode::<String>() {
            return Ok(ExternalNWeekday::String(s));
        }
        Err(rustler::Error::BadArg)
    }
}

impl std::fmt::Display for ExternalNWeekday {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ExternalNWeekday::Tuple(n, s) => write!(f, "Tuple({}, {})", n, s),
            ExternalNWeekday::String(s) => write!(f, "String({})", s)
        }
    }
}

/// Properties struct maps directly to an Elixir struct in the ExDateUtil.Rrule module.
/// It represents all the components of an RFC 5545 recurrence rule (RRULE).
///
/// This struct is decorated with #[module = "ExDateUtil.Rrule"] to indicate that it
/// corresponds to the Elixir struct of the same name. Rustler automatically handles
/// conversion between the Elixir struct and this Rust struct when NIFs are called.
///
/// Each field in this struct represents a different component of the RRULE:
/// - freq: The frequency of recurrence (e.g., "Daily", "Weekly")
/// - interval: How often the recurrence repeats (e.g., every 2 days)
/// - count: The number of occurrences (optional)
/// - until: The end date of the recurrence (optional)
/// - week_start: The day of the week that starts the week (e.g., "MO" for Monday)
/// - by_*: Various filters that can be applied to the recurrence
#[derive(Debug, NifStruct, Default)]
#[module = "ExDateUtil.Rrule"]
struct Properties {
    freq: String,
    interval: u16,
    count: MaybeCount,
    until: MaybeDateTime,
    week_start: String,
    by_set_pos: Vec<i32>,
    by_month: Vec<u8>,
    by_month_day: Vec<i8>,
    by_year_day: Vec<i16>,
    by_week_no: Vec<i8>,
    by_weekday: Vec<ExternalNWeekday>,
    by_hour: Vec<u8>,
    by_minute: Vec<u8>,
    by_second: Vec<u8>
}

fn to_external_n_weekday(n_weekday: &rrule::NWeekday) -> ExternalNWeekday {
    match n_weekday {
        rrule::NWeekday::Nth(n, s) => ExternalNWeekday::Tuple(*n, s.to_string()),
        rrule::NWeekday::Every(s) => ExternalNWeekday::String(s.to_string())
    }
}

fn to_maybe_count(count: Option<u32>) -> MaybeCount {
    match count {
        Some(n) => MaybeCount::Some(n),
        None => MaybeCount::None
    }
}

fn to_maybe_datetime(dt: Option<DateTime<Tz>>) -> MaybeDateTime {
    match dt {
        Some(dt) => MaybeDateTime::Some(dt),
        None => MaybeDateTime::None
    }
}

impl std::fmt::Display for Properties {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Properties {{ freq: {}, interval: {}, count: {}, until: {:?}, week_start: {}, by_set_pos: {:?}, by_month: {:?}, by_month_day: {:?}, by_year_day: {:?}, by_week_no: {:?}, by_weekday: {:?}, by_hour: {:?}, by_minute: {:?}, by_second: {:?} }}",
            self.freq, self.interval, self.count, self.until, self.week_start, 
            self.by_set_pos, self.by_month, self.by_month_day,
            self.by_year_day, self.by_week_no, self.by_weekday, self.by_hour,
            self.by_minute, self.by_second)
    }
}

#[rustler::nif]
/// Parses an RFC 5545 RRULE string into a structured Properties object
///
/// This function takes a string representation of a recurrence rule (RRULE) as defined in RFC 5545
/// and converts it into a structured Properties object that can be used by Elixir code.
///
/// Arguments:
///
/// * `rrule_string`: A string containing an RFC 5545 compliant RRULE (e.g., "FREQ=DAILY;INTERVAL=2")
///
/// Returns:
///
/// * `Ok(Properties)`: A structured representation of the RRULE if parsing succeeds
/// * `Err`: An error if the RRULE string is malformed or contains invalid values
///
/// Examples:
///
/// ```
/// let result = string_to_rrule("FREQ=DAILY;INTERVAL=2;COUNT=10".to_string());
/// // Returns Ok(Properties with freq="Daily", interval=2, count=Some(10), etc.)
///
/// let result = string_to_rrule("FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR".to_string());
/// // Returns Ok(Properties with freq="Weekly", interval=1, by_weekday=[String("MO"), String("WE"), String("FR")], etc.)
/// ``` 
fn string_to_rrule(rrule_string: String) -> NifResult<Properties> {
    match rrule_string.parse::<RRule<Unvalidated>>() {
        Ok(rrule) => Ok(Properties {
            freq: format!("{:?}", rrule.get_freq()),
            interval: rrule.get_interval().clone(),
            count: to_maybe_count(rrule.get_count()),
            until: to_maybe_datetime(rrule.get_until().copied()),
            week_start: format!("{:?}", rrule.get_week_start()),
            by_set_pos: rrule.get_by_set_pos().to_vec(),
            by_month: rrule.get_by_month().to_vec(),
            by_month_day: rrule.get_by_month_day().to_vec(),
            by_year_day: rrule.get_by_year_day().to_vec(),
            by_week_no: rrule.get_by_week_no().to_vec(),
            by_weekday: rrule
                .get_by_weekday()
                .to_vec()
                .iter()
                .map(|n_weekday| to_external_n_weekday(n_weekday))
                .collect(),
            by_hour: rrule.get_by_hour().to_vec(),
            by_minute: rrule.get_by_minute().to_vec(),
            by_second: rrule.get_by_second().to_vec()
        }),
        Err(e) => {
            let error_message = format!("Error parsing rrule: {:?}", e);
            Err(rustler::Error::Term(Box::new(error_message)))
        }
    }
}

#[rustler::nif]
/// Converts a Properties object back into an RFC 5545 RRULE string
///
/// This function takes a Properties object that represents a recurrence rule and
/// converts it back into a string representation that follows the RFC 5545 RRULE format.
///
/// Arguments:
///
/// * `p`: A Properties struct containing the RRULE parameters
///
/// Returns:
///
/// * `Ok(String)`: The string representation of the RRULE if conversion succeeds
/// * `Err`: An error if the Properties object contains invalid values
///
/// Examples:
///
/// ```
/// let props = Properties {
///     freq: "Daily".to_string(),
///     interval: 2,
///     count: MaybeCount::Some(10),
///     // ... other fields with default values
/// };
/// let result = rrule_to_string(props);
/// // Returns Ok("FREQ=DAILY;INTERVAL=2;COUNT=10")
///
/// let props = Properties {
///     freq: "Weekly".to_string(),
///     interval: 1,
///     by_weekday: vec![ExternalNWeekday::String("MO".to_string()), 
///                      ExternalNWeekday::String("WE".to_string()),
///                      ExternalNWeekday::String("FR".to_string())],
///     // ... other fields with default values
/// };
/// let result = rrule_to_string(props);
/// // Returns Ok("FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR")
/// ```
fn rrule_to_string(p: Properties) -> NifResult<String>  {
    match properties_to_rrule(p) {
        Ok(rrule) => return Ok(format!("{}", rrule)),
        Err(e) => {
            let error_message = format!("Error converting properties to rrule: {:?}", e);
            return Err(rustler::Error::Term(Box::new(error_message)));
        }
    };    
}

#[rustler::nif]
/// Validates if a recurrence rule is properly formed with respect to a start date
///
/// This function checks if the given Properties object represents a valid recurrence rule
/// when combined with the provided start date. The validation includes checking if all
/// rule components are consistent with each other and with the start date.
///
/// Arguments:
///
/// * `env`: The NIF environment
/// * `p`: A Properties struct containing the RRULE parameters
/// * `dt_start`: A string containing an RFC 3339 formatted date-time for the rule's start date
///
/// Returns:
///
/// * `Ok(atom::ok())`: If the RRULE is valid
/// * `Err`: An error describing why the RRULE is invalid
///
/// Examples:
///
/// ```
/// let props = Properties {
///     freq: "Monthly".to_string(),
///     interval: 1,
///     by_month_day: vec![31],
///     // ... other fields with default values
/// };
/// let result = validate_rrule(env, props, "2023-04-01T00:00:00Z".to_string());
/// // Returns Ok(atom::ok())
///
/// let props = Properties {
///     freq: "Monthly".to_string(),
///     interval: 1,
///     by_month_day: vec![31],
///     // ... other fields with default values
/// };
/// let result = validate_rrule(env, props, "2023-02-01T00:00:00Z".to_string());
/// // Returns Err with message about February not having 31 days
/// ```
fn validate_rrule(env: Env, p: Properties, dt_start: String) -> NifResult<Term> {
    let dt_start = match DateTime::parse_from_rfc3339(&dt_start) {
        Ok(dt) => dt.with_timezone(&Tz::UTC),
        Err(_) => {
            let error_message = format!("Invalid datetime: {}", dt_start);
            return Err(rustler::Error::Term(Box::new(error_message)));
        }
    };

    let rrule = match properties_to_rrule(p) {
        Ok(rrule) => rrule,
        Err(e) => {
            let error_message = format!("Error converting properties to rrule: {:?}", e);
            return Err(rustler::Error::Term(Box::new(error_message)));
        }
    };

    match rrule.validate(dt_start) {
        Ok(_) => Ok(atoms::ok().encode(env)),
        Err(e) => {
            let error_message = format!("Invalid rrule: {:?}", e);
            return Err(rustler::Error::Term(Box::new(error_message)));
        }
    }
}

/// Converts a Properties object to an internal RRule<Unvalidated> representation
///
/// This function is for internal use only and converts the Properties struct that is
/// used for communication with Elixir code to the internal RRule<Unvalidated> type used 
/// by the rrule library.
///
/// Arguments:
///
/// * `p`: A Properties struct containing the RRULE parameters
///
/// Returns:
///
/// * `Ok(RRule<Unvalidated>)`: The internal representation of the recurrence rule
/// * `Err`: An error if conversion fails due to invalid values
///
/// Examples:
///
/// ```
/// let props = Properties {
///     freq: "Daily".to_string(),
///     interval: 2,
///     // ... other fields
/// };
/// let result = properties_to_rrule(props);
/// // Returns Ok(RRule<Unvalidated> instance)
///
/// let props = Properties {
///     freq: "InvalidFreq".to_string(),
///     // ... other fields
/// };
/// let result = properties_to_rrule(props);
/// // Returns Err with message about invalid frequency
/// ```
fn properties_to_rrule(p: Properties) -> Result<RRule<Unvalidated>, rustler::Error> {
    let frequency = match p.freq.as_str() {
        "Secondly" => rrule::Frequency::Secondly,
        "Minutely" => rrule::Frequency::Minutely,
        "Hourly" => rrule::Frequency::Hourly,
        "Daily" => rrule::Frequency::Daily,
        "Weekly" => rrule::Frequency::Weekly,
        "Monthly" => rrule::Frequency::Monthly,
        "Yearly" => rrule::Frequency::Yearly,
        e => {
            let error_message = format!("Invalid frequency: {}", e);
            return Err(rustler::Error::Term(Box::new(error_message)));
        }
    };

    let week_start = match p.week_start.parse::<rrule::Weekday>() {
        Ok(week_start) => week_start,
        Err(_) => {
            let error_message = format!("Invalid week start: {}", p.week_start);
            return Err(rustler::Error::Term(Box::new(error_message)));
        }
    };

    let by_month_result: Result<Vec<chrono::Month>, _>  = p.by_month
        .iter()
        .map(|m| Month::try_from(*m))
        .collect();


    let by_month = match by_month_result {
        Ok(by_month) => by_month,
        Err(_) => {
            let error_message = format!("Invalid month: {:?}", p.by_month);
            return Err(rustler::Error::Term(Box::new(error_message)));
        }
    };

    let by_weekday_result: Result<Vec<rrule::NWeekday>, _> =
        p.by_weekday
        .iter()
        .map(|weekday| {
            match weekday {
                ExternalNWeekday::Tuple(n, s) => {
                    match s.parse::<rrule::Weekday>() {
                        Ok(w) => return Ok(rrule::NWeekday::Nth(*n, w)),
                        Err(_) => {
                            let error_message = format!("Invalid weekday: {}", s);
                            return Err(error_message);
                        }
                    };

                }
                ExternalNWeekday::String(s) => {
                    match s.parse::<rrule::Weekday>() {
                        Ok(w) => return Ok(rrule::NWeekday::Every(w)),
                        Err(_) => {
                            let error_message = format!("Invalid weekday: {}", s);
                            return Err(error_message);
                        }
                    };
                }
            }
        })
        .collect();

    let by_weekday = match by_weekday_result {
        Ok(by_weekday) => by_weekday,
        Err(error_message) => {
            return Err(rustler::Error::Term(Box::new(error_message)));
        }
    };

    let mut rrule: RRule<Unvalidated> =
        RRule::<Unvalidated>::new(frequency)
            .interval(p.interval)
            .week_start(week_start)
            .by_set_pos(p.by_set_pos)
            .by_month(&by_month)
            .by_month_day(p.by_month_day)
            .by_year_day(p.by_year_day)
            .by_week_no(p.by_week_no)
            .by_weekday(by_weekday)
            .by_hour(p.by_hour)
            .by_minute(p.by_minute)
            .by_second(p.by_second);

    if let MaybeCount::Some(c) = p.count {
        rrule = rrule.count(c);
    }

    if let MaybeDateTime::Some(dt) = p.until {
        rrule = rrule.until(dt);
    }

    return Ok(rrule);
}




rustler::init!(
    "Elixir.ExDateUtil.Rrule.Api"
);
