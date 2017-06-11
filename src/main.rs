#![feature(plugin)]
#![plugin(rocket_codegen)]

#[macro_use]
extern crate serde_derive;

extern crate rocket;
extern crate rocket_contrib;
extern crate oping;
extern crate rusqlite;
extern crate time;
extern crate serde;
extern crate serde_json;

use std::thread;
use std::time::Duration;
use oping::Ping;
use rusqlite::Connection;
use rocket_contrib::JSON;

#[derive(Serialize, Deserialize, Debug)]
struct LastPingData {
    target: String,
    success_count: i64,
    failed_count: i64,
    failed_percent: f64,
    avg_ms: f64,
    min_ms: f64,
    max_ms: f64
}

fn do_ping(ping: Ping) {
    let conn = Connection::open("file::memory:?cache=shared").unwrap();
    let mut stmt = conn.prepare("INSERT INTO pingdata (target,time,success,latency_ms) VALUES (?,?,?,?)").unwrap();
    let ping_time = time::get_time();
    let responses = ping.send().unwrap();
    for resp in responses {
        if resp.dropped > 0 {
            stmt.execute(&[&resp.address, &ping_time, &"0", &"0"]);
        } else {
            stmt.execute(&[&resp.address, &ping_time, &"1", &resp.latency_ms]);
        }
    }
}

fn start_ping(target: &str) {
    println!("Starting ping loop: {}", target);
    loop {
        let mut ping = Ping::new();
        ping.add_host(target);
        ping.set_timeout(2.0);
        do_ping(ping);
        thread::sleep(Duration::from_secs(1));
    }
}

fn db_cleanup() {
    let conn = Connection::open("file::memory:?cache=shared").unwrap();
    match conn.execute("DELETE FROM pingdata WHERE time <= STRFTIME('%Y-%m-%d %H:%M:%S',DATETIME('now', '-' || ? || ' minutes'))", &[&10i32]) {
            Ok(deleted) => println!("DB cleanup finished, {} rows were deleted.", deleted),
            Err(err) => println!("Failed to clean up database: {}", err),
        }
}

fn schedule_db_cleanup() {
    println!("DB cleanup thread started...");
    loop {
        thread::sleep(Duration::from_secs(600));
        db_cleanup();
    }
}

#[get("/last/<min>", format = "application/json")]
fn last_mins(min: &str) -> JSON<Vec<LastPingData>> {
    let minutes = min.parse::<i32>().unwrap();
    let conn = Connection::open("file::memory:?cache=shared").unwrap();
    let mut stmt = conn.prepare("SELECT p1.target, COUNT(*), AVG(p1.latency_ms), MIN(p1.latency_ms), MAX(p1.latency_ms), IFNULL(p2.failed_count, 0)
                                FROM pingdata p1
                                LEFT JOIN
                                (SELECT fq.target, COUNT(*) as failed_count
                                 FROM pingdata fq WHERE fq.success=0 AND
                                 fq.time >= STRFTIME('%Y-%m-%d %H:%M:%S',DATETIME('now', '-' || ? || ' minutes'))
                                 GROUP BY fq.target) p2 ON p1.target=p2.target
                                WHERE
                                p1.time >= STRFTIME('%Y-%m-%d %H:%M:%S',DATETIME('now', '-' || ? || ' minutes')) AND
                                p1.success=1 GROUP BY p1.target").unwrap();
    let lastping_iter = stmt.query_map(&[&minutes, &minutes], |row| {
        let s_count : i64 = row.get(1);
        let f_count : i64 = row.get(5);
        LastPingData {
            target: row.get(0),
            success_count: s_count,
            avg_ms: row.get(2),
            min_ms: row.get(3),
            max_ms: row.get(4),
            failed_count: f_count,
            failed_percent: (f_count as f64/(s_count as f64 + f_count as f64)) * 100.0
        }
    }).unwrap();

    let lastpings: Vec<_> = lastping_iter.map(|res| res.unwrap()).collect();

    JSON(lastpings)
}

fn main() {
    println!("DB init...");
    let db = Connection::open("file::memory:?cache=shared").unwrap();

    db.execute("CREATE TABLE pingdata (
               id              INTEGER PRIMARY KEY,
               target          VARCHAR(255) NOT NULL,
               time            VARCHAR(255) NOT NULL,
               success         INTEGER,
               latency_ms      REAL
               )", &[]).unwrap();

    println!("DB initialized.");

    let mut targets = vec![];
    targets.push("8.8.8.8");

    for x in &targets {
        let ping_target = x.clone();
        thread::spawn(move || {
            start_ping(ping_target);
        });
    }

    thread::spawn(move || {
        schedule_db_cleanup();
    });

    rocket::ignite().mount("/", routes![last_mins]).launch();
}
