#!/bin/bash

# Log file path
log_file="/var/log/network-scanning.log"

# Configuration variables
parallelism=10 # Number of parallel scans, can be overridden
verbose=0 # Verbose mode off by default
location="" # Location string, empty by default

# Function to print messages in verbose mode
verbose_echo() {
    if [ "$verbose" -eq 1 ]; then
        echo "$@"
    fi
}

# Read script arguments
while getopts "r:p:v:l:" opt; do
    case $opt in
        r) network_range=$OPTARG ;;
        p) parallelism=$OPTARG ;;
        v) verbose=1 ;;
        l) location=$OPTARG ;;
        \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
    esac
done

# Check network range input
if [ -z "$network_range" ]; then
    echo "Network range not specified. Use -r to specify."
    exit 1
fi

# Start scanning
verbose_echo "Starting network scan for range: $network_range at location: $location"
start_time=$(date +%s)

# Check if required tools are installed
for tool in fping arp-scan nmap; do
    if ! command -v $tool &> /dev/null; then
        echo "Error: $tool is not installed." >&2
        exit 1
    fi
done

# Perform a ping sweep to find live hosts and store the results
verbose_echo "Performing ping sweep..."
live_hosts=$(fping -a -g $network_range 2>/dev/null)

# Perform an ARP scan on the entire network range and store the results
verbose_echo "Performing ARP scan..."
arp_scan_results=$(sudo arp-scan --localnet 2>/dev/null)

# Function to perform nmap scan and output in JSON format
scan_host() {
    ip=$1
    read mac device_type <<< $(echo "$arp_scan_results" | awk -v ip="$ip" '$1==ip {print $2, $3}')
    mac=${mac:-"Not Detected"}
    device_type=${device_type:-"Not Detected"}
    host_status="down"
    os_info="Not Detected"
    services=""

    if [ "$mac" != "Not Detected" ]; then
        host_status="up"
        nmap_results=$(sudo nmap -sV --version-light 5 $ip 2>/dev/null)
        os_info=$(echo "$nmap_results" | grep 'Service Info:' | awk -F': ' '{print $3}' | cut -d';' -f1)
        os_info=${os_info:-"OS Detection Failed"}
        services=$(echo "$nmap_results" | grep 'open' | awk '{print $3}' | xargs | sed 's/ /, /g')
        services=${services:-"No Services Detected"}
    fi

    timestamp=$(date -Iseconds)
    echo "{\"timestamp\":\"$timestamp\", \"ip\":\"$ip\", \"mac\":\"$mac\", \"device_type\":\"$device_type\", \"status\":\"$host_status\", \"os\":\"$os_info\", \"services\":\"$services\", \"location\":\"$location\"}"
}

export -f scan_host
export arp_scan_results
export location

# Redirect output to log file
verbose_echo "Scanning live hosts..."
printf "%s\n" $live_hosts | xargs -I {} -P $parallelism -n 1 bash -c 'scan_host "$@"' _ {} >> "$log_file"

# Final statements
end_time=$(date +%s)
execution_time=$((end_time - start_time))
verbose_echo "Scan completed. Execution Time: $execution_time seconds"
echo "Output saved to $log_file"
