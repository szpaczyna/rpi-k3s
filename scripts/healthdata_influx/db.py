"""Loads a configuration and imports data points into InfluxDB"""
from datetime import datetime, timezone
import yaml
from influxdb import InfluxDBClient

class InfluxDBUploader:
    """Uploads data points to an InfluxDB instance"""
    def __init__(self, config_path):
        self.config = self._load_config(config_path)

    def upload(self, data_points=None):
        """Uploads data points to InfluxDB"""
        if data_points is not None and len(data_points):
            client = InfluxDBClient(**self.config['influxdb']['client'])
            # only creates a DB if none exists
            client.create_database(self.config['influxdb']['client']['database'])
            client.write_points(points=data_points, **self.config['influxdb']['write_points'])

    def create_point(self, measurement, time, fields, tags=None):
        """Helps enforce proper InfluxDB point creation"""
        # tags can be an empty dict
        if tags is None:
            tags = {}

        if not isinstance(measurement, str):
            raise TypeError('Measurement must be a string.')

        if not isinstance(time, datetime):
            raise TypeError('Time must be a datetime object.')

        if not isinstance(fields, dict):
            raise TypeError('Fields must be a dictionary.')
        elif len(fields) < 1:
            # there must be at least one field
            raise ValueError('Fields must contain at least one field.')

        if not isinstance(tags, dict):
            raise TypeError('Tags must be a dictionary.')

        # convert datetime object to string
        time = self._create_influx_time(time)

        point = {
            'tags': tags,
            'time': time,
            'fields': fields,
            'measurement': measurement
        }

        return point

    def _load_config(self, config_path):
        """Loads config for this script"""
        with open(config_path) as file:
            config = yaml.safe_load(file)
        return config

    def _create_influx_time(self, time):
        """
        Takes in a datetime object
        Returns a datetime string InfluxDB expects, in UTC
        """
        # save as correct format in UTC timezone
        converted_time = time.astimezone(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
        return converted_time
