use rrule::{DateFilter, RRule};
use chrono::{DateTime, SecondsFormat};
use chrono_tz::UTC;


#[rustler::nif]
fn properties(rrule_string: String) -> String {
    let rrule: RRule = rrule_string.parse().unwrap();
    let p = rrule.get_properties();
    println!("{:?}", p);
    return "p".parse().unwrap();
}

#[rustler::nif]
/// `next` takes a string that represents a recurrence rule and a limit, and returns a vector of strings
/// that represent the next `limit` number of recurrences
/// 
/// Arguments:
/// 
/// * `rrule_string`: The RRULE string to parse.
/// * `limit`: The number of recurrences to return.
/// 
/// Returns:
/// 
/// A vector of strings.
fn next(rrule_string: String, limit: u16) -> Vec<String> {
    let rrule: RRule = rrule_string.parse().unwrap();
    let recurrences = rrule.all(limit).unwrap();
    let iter = recurrences.iter();
    let mut return_vec: Vec<String> = Vec::new();
    for val in iter {
        return_vec.push(val.to_rfc3339_opts(SecondsFormat::Millis, true))
    }

    return return_vec;
}

/// It takes a rrule string, a start date, an end date, and a boolean indicating whether to include the
/// start date in the results, and returns a vector of strings representing the dates that fall between
/// the start and end dates
/// 
/// Arguments:
/// 
/// * `rrule_string`: The RRule string to parse.
/// * `start_date`: The start date of the range to check for recurrences.
/// * `end_date`: The end date of the recurrence.
/// * `inc`: Whether to include the start date in the results.
/// 
/// Returns:
/// 
/// A vector of strings
#[rustler::nif]
fn between(rrule_string: String, start_date: String, end_date: String, inc: bool) -> Vec<String> {
    let start = DateTime::parse_from_rfc3339(&start_date).unwrap().with_timezone(&UTC);
    let end = DateTime::parse_from_rfc3339(&end_date).unwrap().with_timezone(&UTC);
    let rrule: RRule = rrule_string.parse().unwrap();
    let recurrences = rrule.all_between(start, end, inc).unwrap();
    let iter = recurrences.iter();
    let mut return_vec: Vec<String> = Vec::new();
    for val in iter {
        return_vec.push(val.to_rfc3339_opts(SecondsFormat::Millis, true))
    }

    return return_vec;
}


/// It takes a RRule string, a date string, and a boolean, and returns a vector of date strings
/// 
/// Arguments:
/// 
/// * `rrule_string`: The RRule string to parse.
/// * `before`: The date to find the recurrence before.
/// * `inc`: If true, the before date will be included in the results.
/// 
/// Returns:
/// 
/// A vector of strings.
#[rustler::nif]
fn just_before(rrule_string: String, before: String, inc: bool) -> Vec<String> {
    let start = DateTime::parse_from_rfc3339(&before).unwrap().with_timezone(&UTC);
    let rrule: RRule = rrule_string.parse().unwrap();
    let recurrences = rrule.just_before(start, inc).unwrap();
    let iter = recurrences.iter();
    let mut return_vec: Vec<String> = Vec::new();
    for val in iter {
        return_vec.push(val.to_rfc3339_opts(SecondsFormat::Millis, true))
    }

    return return_vec;
}

/// `just_after` takes a `String` containing an RRule, a `String` containing a date, and a boolean, and
/// returns a `Vec<String>` containing the dates that match the RRule after the given date
/// 
/// Arguments:
/// 
/// * `rrule_string`: The string representation of the RRule.
/// * `after_date`: The date to start looking for recurrences after.
/// * `inc`: If true, include the start date in the results.
/// 
/// Returns:
/// 
/// A vector of strings.
#[rustler::nif]
fn just_after(rrule_string: String, after_date: String, inc: bool) -> Vec<String> {
    let start = DateTime::parse_from_rfc3339(&after_date).unwrap().with_timezone(&UTC);
    let rrule: RRule = rrule_string.parse().unwrap();
    let recurrences = rrule.just_after(start, inc).unwrap();
    let iter = recurrences.iter();
    let mut return_vec: Vec<String> = Vec::new();
    for val in iter {
        return_vec.push(val.to_rfc3339_opts(SecondsFormat::Millis, true))
    }

    return return_vec;
}

rustler::init!("Elixir.ExDateUtil.Rrule", [next, between, just_after, just_before, properties]);
