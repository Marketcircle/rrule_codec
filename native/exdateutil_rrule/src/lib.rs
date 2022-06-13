use rrule::{DateFilter, RRule};
// use chrono::{DateTime, TimeZone};

#[rustler::nif]
fn next(rrule_string: String, limit: u16) -> String {
    let rrule: RRule = rrule_string.parse().unwrap();
    // let rrule: RRule = "DTSTART:20120201T093000Z\nRRULE:FREQ=DAILY;COUNT=3".parse().unwrap();
    let recurrences = rrule.all(limit).unwrap();
    let p = rrule.get_properties();
    println!("{:?}", p);
    println!("{:?}", recurrences);
    return "test".to_string()
}
// # to implement
// # fn between(rrrule_string)


rustler::init!("Elixir.ExDateUtil.Rrule", [next]);
