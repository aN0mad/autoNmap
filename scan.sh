#!/bin/bash

# Function to join array into a string
function join_by { local IFS="$1"; shift; echo "$*"; }


# Check passed in arguments
if [ $# != 2 ]; then
        echo 'Usage ./scan.sh [IP address] [output folder]'
        exit 1
fi


# Set variables
IP="$1"
output="$2"
log="status.log"
initial='allPorts'
target='targeted'
ports='targetedPorts.txt'


# Start initial nmap scan
echo -e "[#] Starting inital scan\n" | tee "$output/$log"
echo "nmap -p- -n -vv \"$IP\" -oA \"$output/$initial\"" | tee "$output/$log"
nmap -p- -n -vv "$IP" -oA "$output/$initial" | tee "$output/$log"
echo -e "\n[#] Grepping ports..." | tee "$output/$log"


# Parse ports out of gnmap file
PORTS_LINE=()
portsData=$(egrep -v "^#|Status: Up" "$output/$initial".gnmap | cut -d" " -f2,4- | sed -n -e 's/Ignored.*//p')

IFS=', ' read -r -a portsDataArray <<< "$portsData"

LOOP=0
for portData in "${portsDataArray[@]}"
do
	# $LOOP[0] is the IP address
	if [ "$LOOP" -eq 0 ]
	then
		((LOOP++))
		continue
	fi
	port=$(echo -n "$portData" | cut -d "/" -f1 | tr -d '\r\n' | tr -d '\n' )
	PORTS_LINE=("${PORTS_LINE[@]}" "$port")
	((LOOP++))

done

PORTS=$(join_by , "${PORTS_LINE[@]}")

echo "$PORTS" >> "$output/$ports"


# Start targeted nmap scan
echo -e "\n[#] Starting final scan\n" | tee "$output/$log"
targetPorts=$(cat "$output/$ports")
echo "nmap -vv -Pn -n -sC -sV --version-all -p$targetPorts -oA \"$output/$target\" \"$IP\" >> \"$output/$log\"" | tee "$output/$log"
nmap -vv -Pn -n -sC -sV --version-all -p"$targetPorts" -oA "$output/$target" "$IP" | tee "$output/$log"
echo -e "\n[!] Scanning complete" | tee "$output/$log"
