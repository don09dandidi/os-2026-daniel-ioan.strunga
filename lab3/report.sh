#!/bin/bash
log=$1
# Corectam conditia stricata Ivert() vert() cu || (SAU) si ! -f
if [ -z "$log" ] || [ ! -f "$log" ]; then
    echo "Fisierul log nu exista sau nu a fost specificat."
    exit 1
fi
echo "Procesare $log..."
