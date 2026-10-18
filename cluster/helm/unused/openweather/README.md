# OpenWeather exporter

Retired and not deployed. This chart lives in `unused/`, and nothing runs it.

It was a Prometheus exporter for OpenWeather data, deployed to the `monitoring`
namespace. It fetched weather for one configured city and served the metrics on
port `9091`.

## What it was

| Item | Value |
|---|---|
| Chart | `openweather-exporter` 0.1.2, in directory `openweather` |
| Image | `billykwooten/openweather-exporter:0.0.14` |
| Namespace | `monitoring` |
| Exposure | No Service. Pod annotations `prometheus.io/scrape` and `prometheus.io/port` |
| Config | City, units, language, and cache TTL in `values-public.yaml`. City and API key in `values.enc.yaml`, SOPS encrypted |
| Resources | 100m CPU and 128Mi memory, requests and limits |

## What replaced it

Nothing in this repo replaces it, and no live workload carries the openweather
name. The speedtest exporter in `monitoring` collects different data.

The chart moved to `unused/` in commit `5d8e42e` (Aug 22, 2026). That commit
is titled "fix: reorganization along with readmes" and records no reason.

## Related

- [speedtest](../../speedtest): the live exporter in `monitoring`.
- [Repository README](../../../../README.md)
