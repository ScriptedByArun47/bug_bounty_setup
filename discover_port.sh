#!/bin/bash

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <target-ip>"
    exit 1
fi

echo "==============================="
echo "   NMAP AUTO PORT DISCOVERY    "
echo "==============================="

# -----------------------------
# 1. Fast full-port discovery
# -----------------------------
echo "[+] Discovering open ports on $TARGET ..."
echo "[*] Command: nmap -p- --min-rate 8000 -T4 -Pn --open --max-retries 2 --max-scan-delay 20ms $TARGET"
echo

OPEN_PORTS=$(sudo nmap -p- --min-rate 8000 -T4 -Pn --open --max-retries 2 --max-scan-delay 20ms   -oG - $TARGET | grep -oP '\d+/open/tcp' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')

if [ -z "$OPEN_PORTS" ]; then
    echo "[-] No open ports found."
    exit 0
fi

echo "[+] Open ports discovered: $OPEN_PORTS"
echo

# -----------------------------
# 2. Nmap service enumeration
# -----------------------------
echo "[+] Running detailed Nmap scan on discovered ports..."
echo "[*] Command: nmap -p$OPEN_PORTS -sV -sC -T4 $TARGET"
echo

sudo nmap -p$OPEN_PORTS -sV -sC -T4 $TARGET

echo
echo "[+] DONE!"
