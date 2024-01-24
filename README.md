# Network Inventory with Filebeat and OpenSearch

## Prerequisites
- Docker installed.
- OpenSearch running on port 9200 (Ensure port 9200 is open for OpenSearch).
- `fping`, `arp-scan`, and `nmap` tools installed for network scanning.

## Build the Docker Image
Build the Docker image from the provided Dockerfile:
```bash
docker build -t inventory:v1 .
```

## Running the Docker Container
Run the Docker container on the host machine network with the necessary environment variables:
```bash
docker run --net=host --privileged \
           -e ELASTICSEARCH_HOST='https://<IP>:9200' \
           -e ELASTICSEARCH_USERNAME='<USERNAME>' \
           -e ELASTICSEARCH_PASSWORD='<PASSWORD>' \
           -e NETWORK_RANGE='<NETWORK_RANGE_SCAN>' \
           -e PARALLELISM=<NUMBER_OF_PARALLEL_SCANS> \
           -e VERBOSE=1 \
           -e LOCATION=<inventory-location> \
           inventory:v1
```
- `PARALLELISM`: Set this variable based on your network size and machine capacity. Higher values increase the number of simultaneous nmap scans but require more system resources. For large networks, adjust this value to balance between scan speed and system load.

---

Remember to replace `<IP>`, `<USERNAME>`, `<PASSWORD>`, `<NETWORK_RANGE_SCAN>`, `<NUMBER_OF_PARALLEL_SCANS>`, and `<inventory-location>` with the actual values suited to your environment. This setup is designed to be flexible and scalable according to the size of the network and the resources available on the host machine.

## Description
This setup scans a specified network range to identify live hosts, their details (IP, MAC, device type, OS, etc.), and logs the information in JSON format. It uses Filebeat to forward these logs to OpenSearch for indexing and analysis.