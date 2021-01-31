FROM python:3-alpine

WORKDIR /app
COPY requirements.txt ./
COPY pihole_exporter/pihole_exporter.py ./
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 9311

ENTRYPOINT python3 /app/pihole_exporter.py --pihole pihole.shpaq.org --auth e17d4f0308f3a75bbc785cb605221d7e7cd116cc3661b2d8fab2b764e38257db --extended-metrics
