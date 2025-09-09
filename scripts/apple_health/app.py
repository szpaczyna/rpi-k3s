"""
Ingester module that converts Apple Health export zip file
into influx db datapoints
"""
import os
import re
import time
from lxml import etree
from shutil import unpack_archive
from typing import Any, Generator

from formatters import parse_date_as_timestamp, parse_float_with_try, AppleStandHourFormatter, SleepAnalysisFormatter

import gpxpy
from gpxpy.gpx import GPXTrackPoint
from influxdb import InfluxDBClient
from influxdb.exceptions import InfluxDBClientError
from requests.exceptions import ConnectionError, ReadTimeout

# --- Configuration ---
INFLUX_HOST = os.getenv("INFLUX_HOST", "some_ip")
INFLUX_PORT = int(os.getenv("INFLUX_PORT", 8086))
INFLUX_USER = os.getenv("INFLUX_USER", "admin")
INFLUX_PASS = os.getenv("INFLUX_PASS", "some_password")
INFLUX_DB = os.getenv("INFLUX_DB", "health")
INFLUX_TIMEOUT = int(os.getenv("INFLUX_TIMEOUT", 240))
INFLUX_BATCH_SIZE = int(os.getenv("INFLUX_BATCH_SIZE", 120000))
DB_RETRY_COOLDOWN = int(os.getenv("DB_RETRY_COOLDOWN", 60))
DB_MAX_RETRIES = int(os.getenv("DB_MAX_RETRIES", 5))

ZIP_PATH = "./export.zip"
UNPACK_PATH = "./export"
EXPORT_PATH = os.path.join(UNPACK_PATH, "apple_health_export")
ROUTES_PATH = os.path.join(EXPORT_PATH, "workout-routes")
EXPORT_XML_REGEX = re.compile(r"(export|导出)\.xml", re.IGNORECASE)

# --- Logger ---
class _Colors:
    """ANSI color codes"""
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    RESET = '\033[0m'

class Logger:
    """Simple logger for colorized console output."""
    def info(self, message):
        print(f"{_Colors.BLUE}{message}{_Colors.RESET}")
    def success(self, message):
        print(f"{_Colors.GREEN}{message}{_Colors.RESET}")
    def warn(self, message):
        print(f"{_Colors.YELLOW}{message}{_Colors.RESET}")
    def error(self, message):
        print(f"{_Colors.RED}{message}{_Colors.RESET}")

logger = Logger()

def write_points_with_retry(client: InfluxDBClient, points: list[dict], time_precision: str):
    """Writes points to InfluxDB with a retry mechanism."""
    for attempt in range(DB_MAX_RETRIES):
        try:
            client.write_points(points, time_precision=time_precision)
            return True
        except (ConnectionError, ReadTimeout, InfluxDBClientError) as e:
            logger.warn(f"DB write failed (Attempt {attempt + 1}/{DB_MAX_RETRIES}): {e}")
            if attempt + 1 < DB_MAX_RETRIES:
                logger.warn(f"Retrying in {DB_RETRY_COOLDOWN} seconds...")
                time.sleep(DB_RETRY_COOLDOWN)
            else:
                logger.error("Max retries reached. Failed to write points to the database.")
                return False
    return False


def format_route_point(
    name: str, point: GPXTrackPoint, next_point=None
) -> dict[str, Any]:
    """for a given `point`, creates an influxdb point
    and computes speed and distance if `next_point` exists"""
    slug_name = name.replace(" ", "-").replace(":", "-").lower()
    datapoint = {
        "measurement": "workout-routes",
        "tags": {"workout": slug_name},
        "time": point.time,
        "fields": {
            "latitude": point.latitude,
            "longitude": point.longitude,
            "elevation": point.elevation,
        },
    }
    if next_point:
        datapoint["fields"]["speed"] = (
            point.speed_between(next_point) if next_point else 0
        )
        datapoint["fields"]["distance"] = point.distance_3d(next_point)
    return datapoint


def format_record(record: dict[str, Any]) -> list[dict[str, Any]]:
    """format a export health xml record for influx"""
    measurement = (
        record.get("type", "Record")
        .removeprefix("HKQuantityTypeIdentifier")
        .removeprefix("HKCategoryTypeIdentifier")
        .removeprefix("HKDataType")
    )

    if measurement == "AppleStandHour":
        return AppleStandHourFormatter(record)
    if measurement == "SleepAnalysis":
        return SleepAnalysisFormatter(record)

    date = parse_date_as_timestamp(record.get("startDate", "2024-01-01T01:01:01"))
    value = parse_float_with_try(record.get("value", 1))
    unit = record.get("unit", "unit")
    device = record.get("sourceName", "unknown")

    return [{
        "measurement": measurement,
        "time": date,
        "fields": {"value": value},
        "tags": {"unit": unit, "device": device},
    }]


def format_workout(record: dict[str, Any]) -> dict[str, Any]:
    """format a export health xml workout record for influx"""
    measurement = record.get("workoutActivityType", "Workout").removeprefix(
        "HKWorkoutActivityType"
    )
    date = parse_date_as_timestamp(record.get("startDate", "2024-01-01T01:01:01"))
    value = parse_float_with_try(record.get("duration", 0))
    unit = record.get("durationUnit", "unit")
    device = record.get("sourceName", "unknown")

    return {
        "measurement": measurement,
        "time": date,
        "fields": {"value": value},
        "tags": {"unit": unit, "device": device},
    }


def parse_workout_route(client: InfluxDBClient, route_xml_file: str) -> None:
    with open(route_xml_file, "r") as gpx_file:
        gpx = gpxpy.parse(gpx_file)
        for track in gpx.tracks:
            track_points = []
            logger.info(f"Opening {track.name}")
            for segment in track.segments:
                num_points = len(segment.points)
                for i in range(num_points):
                    track_points.append(
                        format_route_point(
                            track.name,
                            segment.points[i],
                            segment.points[i + 1] if i + 1 < num_points else None,
                        )
                    )
            write_points_with_retry(client, track_points, time_precision="s")


def process_workout_routes(client: InfluxDBClient) -> None:
    if not (os.path.exists(ROUTES_PATH) and os.path.isdir(ROUTES_PATH)):
        logger.warn("No workout routes found, skipping ...")
        return

    logger.info("Loading workout routes ...")
    for file in os.listdir(ROUTES_PATH):
        if file.endswith(".gpx"):
            route_file = os.path.join(ROUTES_PATH, file)
            try:
                parse_workout_route(client, route_file)
            except Exception as e:
                logger.error(f"Failed to process route {route_file}: {e}")


def find_xml_file() -> str | None:
    """Finds the health export XML file."""
    if not os.path.exists(EXPORT_PATH):
        return None
    for f in os.listdir(EXPORT_PATH):
        if EXPORT_XML_REGEX.match(f):
            return os.path.join(EXPORT_PATH, f)
    return None


def health_data_generator(xml_file: str) -> Generator[tuple[list[dict] | dict, str], None, None]:
    """
    A generator that yields formatted InfluxDB points and the source from the health data XML.
    """
    with open(xml_file, 'rb') as f:
        # The XML might have leading non-XML data. Find the start of the real XML.
        for line in f:
            if b'<HealthData' in line:
                break
        # Reset stream to the start of the found line
        f.seek(f.tell() - len(line))

        context = etree.iterparse(f, events=('end',), tag=('Record', 'Workout'), recover=True)

        for _, elem in context:
            try:
                source = elem.get("sourceName", "unknown")
                if elem.tag == "Record":
                    for point in format_record(elem):
                        yield point, source
                elif elem.tag == "Workout":
                    yield format_workout(elem), source
            except Exception as e:
                logger.error(f"Error processing element: {e}")
            finally:
                # Clean up to free memory
                elem.clear()
                while elem.getprevious() is not None:
                    del elem.getparent()[0]


def process_health_data(client: InfluxDBClient) -> set[str]:
    """
    Processes the main health data XML file and pushes data to InfluxDB.
    Returns a set of all data sources found.
    """
    export_file = find_xml_file()
    if not export_file:
        logger.warn("No export XML file found, skipping...")
        return set()

    logger.info(f"Processing health data from {os.path.basename(export_file)}...")

    records = []
    sources = set()
    total_count = 0
    for point, source in health_data_generator(export_file):
        records.append(point)
        sources.add(source)
        if len(records) >= INFLUX_BATCH_SIZE:
            if write_points_with_retry(client, records, time_precision="s"):
                total_count += len(records)
                logger.success(f"Inserted {total_count} records...")
                records = []
            else:
                logger.error("Aborting health data processing due to DB write failure.")
                return

    # Push the remaining records
    if records:
        if write_points_with_retry(client, records, time_precision="s"):
            total_count += len(records)

    logger.success(f"Total number of records inserted: {total_count}")
    return sources


def push_sources(client: InfluxDBClient, sources: set[str]):
    if not sources:
        logger.warn("No data sources to push.")
        return

    sources_points = [{
        "measurement": "data-sources",
        "tags": {"device": s},
        "fields": {"value": 1}
    } for s in sources if s]
    logger.info(f"Pushing {len(sources_points)} data sources...")
    write_points_with_retry(client, sources_points, time_precision="s")


def main():
    """Main execution function."""
    logger.info("Unzipping the export file...")
    try:
        unpack_archive(ZIP_PATH, UNPACK_PATH)
        logger.success("Export file unzipped!")
    except FileNotFoundError:
        logger.error(f"Export zip file not found at {ZIP_PATH}")
        exit(1)
    except Exception as unzip_err:
        logger.error(f"Unable to open export zip: {unzip_err}")
        exit(1)

    client = InfluxDBClient(
        host=INFLUX_HOST,
        port=INFLUX_PORT,
        username=INFLUX_USER,
        password=INFLUX_PASS,
        database=INFLUX_DB,
        timeout=INFLUX_TIMEOUT,
    )

    # Wait for InfluxDB to be ready
    while True:
        try:
            client.ping()
            logger.success("InfluxDB is ready.")
            break
        except Exception:
            logger.warn("Waiting for InfluxDB to be ready...")
            time.sleep(2)

    try:
        logger.warn(f"Dropping database '{INFLUX_DB}'...")
        client.drop_database(INFLUX_DB)
        logger.success(f"Creating database '{INFLUX_DB}'...")
        client.create_database(INFLUX_DB)
    except InfluxDBClientError as e:
        logger.error(f"Database setup failed: {e}")
        exit(1)

    found_sources = process_health_data(client)
    push_sources(client, found_sources)
    process_workout_routes(client)
    #push_sources(client, found_sources)

    logger.success("\nAll done! You can now check Grafana.")


if __name__ == "__main__":
    main()
