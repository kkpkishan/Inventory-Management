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
docker run --net=host  \
           -e ELASTICSEARCH_HOST='https://<IP>:9200' \
           -e ELASTICSEARCH_USERNAME='<USERNAME>' \
           -e ELASTICSEARCH_PASSWORD='<PASSWORD>' \
           -e NETWORK_RANGE='<NETWORK_RANGE_SCAN>' \
           -e PARALLELISM=<NUMBER_OF_PARALLEL_SCANS> \
           -e VERBOSE=0 \
           -e LOCATION=<inventory-location> \
           -e FILEBEAT_MAX_RUNTIME=<MAX_RUNTIME_IN_SECONDS> \
           inventory:v1
```
- `PARALLELISM`: Set this variable based on your network size and machine capacity. Higher values increase the number of simultaneous nmap scans but require more system resources. For large networks, adjust this value to balance between scan speed and system load.
- `FILEBEAT_MAX_RUNTIME`: This variable sets the maximum runtime for Filebeat in seconds. After this time, Filebeat will be stopped. This can be used to control resource usage and scan duration.

Example run command:
```bash
docker run --net=host \
           -e ELASTICSEARCH_HOST='https://192.168.1.100:9200' \
           -e ELASTICSEARCH_USERNAME='admin' \
           -e ELASTICSEARCH_PASSWORD='admin123' \
           -e NETWORK_RANGE='192.168.1.0/24' \
           -e PARALLELISM=5 \
           -e VERBOSE=1 \
           -e LOCATION='main_office' \
           -e FILEBEAT_MAX_RUNTIME=300 \
           inventory:v1
```

In this example:
- `ELASTICSEARCH_HOST` is set to `https://192.168.1.100:9200`, which is the IP and port where OpenSearch is running.
- `ELASTICSEARCH_USERNAME` and `ELASTICSEARCH_PASSWORD` are set to `admin` and `admin123` respectively, which are the credentials for OpenSearch.
- `NETWORK_RANGE` is set to `192.168.1.0/24`, which is the target network range for scanning.
- `PARALLELISM` is set to `5`, indicating the number of parallel network scans.
- `FILEBEAT_MAX_RUNTIME` is set to `300`, meaning Filebeat will run for a maximum of 300 seconds (5 minutes).
- `LOCATION` is set to `main_office`, representing the physical or logical location of the inventory scan.

Remember to replace `<IP>`, `<USERNAME>`, `<PASSWORD>`, `<NETWORK_RANGE_SCAN>`, `<NUMBER_OF_PARALLEL_SCANS>`, `<inventory-location>`, and `<MAX_RUNTIME_IN_SECONDS>` with the actual values suited to your environment. This setup is designed to be flexible and scalable according to the size of the network and the resources available on the host machine.

## Description
This setup scans a specified network range to identify live hosts, their details (IP, MAC, device type, OS, etc.), and logs the information in JSON format. It uses Filebeat to forward these logs to OpenSearch for indexing and analysis.
