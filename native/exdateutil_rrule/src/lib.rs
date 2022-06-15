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
