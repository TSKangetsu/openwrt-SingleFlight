#!/bin/sh

#======= WiFi 5GHz Channel Quality Analyzer for OpenWrt (v2) =======
# Now with automatic mode-switching for accurate scanning.

# --- Configuration ---
# List of standard 20MHz 5GHz channels to check. This list is comprehensive
# and suitable for most regions, including Japan (W52, W53, W56).
# UNII-1: 36, 40, 44, 48
# UNII-2 (DFS): 52, 56, 60, 64
# UNII-2e (DFS): 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144
# UNII-3/W58: 149, 153, 157, 161, 165
CHANNELS_5GHZ="36 40 44 48 52 56 60 64 100 104 108 112 116 132 136 140 144 149 153 157 161 165"

# --- Script Logic ---

# Check for dependencies
for cmd in iw ip; do
    if ! command -v "$cmd" >/dev/null; then
        echo "Error: Command '$cmd' not found. Please install it." >&2
        echo "Try: 'opkg update && opkg install iw-full ip-full'" >&2
        exit 1
    fi
done

# Check for interface argument
if [ -z "$1" ]; then
    echo "Usage: $0 <5ghz-wifi-interface>" >&2
    echo "Example: $0 wlan1" >&2
    echo "" >&2
    echo "Detected 5GHz capable interfaces:" >&2
    iwinfo | grep -E "802.11a|802.11ac|802.11ax" | awk '{print $1}' | xargs -n 1 iwinfo | grep "Hardware:" -B 2 | grep ESSID | sed 's/.*ESSID: unknown //g'
    exit 1
fi

WIFI_IF=$1

# Verify the interface exists
if ! iw dev "$WIFI_IF" info >/dev/null 2>&1; then
    echo "Error: Interface '$WIFI_IF' does not exist or is not a wireless device." >&2
    exit 1
fi

# --- Cleanup function to restore original interface state ---
# This function is called on script exit to ensure we don't leave Wi-Fi broken.
cleanup() {
    echo ""
    echo "--- Restoring interface '$WIFI_IF' to original state... ---"
    ip link set "$WIFI_IF" down >/dev/null 2>&1
    if [ -n "$ORIGINAL_MODE" ]; then
        iw dev "$WIFI_IF" set type "$ORIGINAL_MODE" >/dev/null 2>&1
        echo "Mode restored to '$ORIGINAL_MODE'."
    fi
    if [ "$ORIGINAL_STATE" = "UP" ]; then
        ip link set "$WIFI_IF" up >/dev/null 2>&1
        echo "State restored to 'UP'."
    else
        echo "State left 'DOWN' as it was originally."
    fi
    echo "Cleanup complete."
}

# Trap script exit/interrupt signals to run the cleanup function
trap cleanup EXIT INT TERM

# --- Main analysis ---
echo "--- Starting 5GHz WiFi Analysis for interface '$WIFI_IF' ---"

# Save original state before changing anything
echo "Saving original state of '$WIFI_IF'..."
ORIGINAL_MODE=$(iw dev "$WIFI_IF" info | grep 'type' | awk '{print $2}')
ORIGINAL_STATE=$(ip link show "$WIFI_IF" | grep -o 'state [A-Z]*' | awk '{print $2}')
echo "Original state: Mode=$ORIGINAL_MODE, State=$ORIGINAL_STATE"

# Set interface to managed mode for scanning
echo "Temporarily setting interface to 'managed' mode for accurate scanning..."
ip link set "$WIFI_IF" down
iw dev "$WIFI_IF" set type managed
ip link set "$WIFI_IF" up
sleep 2 # Give the interface a moment to initialize

echo "Scanning all 5GHz channels... This may take 30-60 seconds..."
SCAN_RESULT=$(iw dev "$WIFI_IF" scan)
SURVEY_RESULT=$(iw dev "$WIFI_IF" survey dump)

# Initialize variables to find the best channel
BEST_CHANNEL=""
MIN_NETWORKS=999
MIN_UTILIZATION=101

# Print table header
printf "\n%-10s | %-10s | %-12s | %-12s | %-15s\n" "Channel" "Networks" "Avg Signal" "Noise" "Utilization %"
echo "------------------------------------------------------------------------"

# Loop through each channel and analyze it
for channel in $CHANNELS_5GHZ; do
    FREQ=$((5000 + channel * 5))

    # Parse scan data for networks and signal
    SCAN_STATS=$(echo "$SCAN_RESULT" | awk -v freq="$FREQ" '
        BEGIN { in_target_bss=0; count=0; total_signal=0 }
        /BSS / { in_target_bss=0 }
        /freq:/ { if ($2 == freq) in_target_bss=1 }
        /signal:/ { if (in_target_bss) { count++; total_signal+=$2 } }
        END { if (count > 0) printf "%d %.2f", count, (total_signal/count); else printf "0 -100.00"; }
    ')
    NUM_NETWORKS=$(echo $SCAN_STATS | awk '{print $1}')
    AVG_SIGNAL=$(echo $SCAN_STATS | awk '{print $2}')

    # Parse survey data for noise and utilization
    SURVEY_STATS=$(echo "$SURVEY_RESULT" | awk -v freq="$FREQ" '
        BEGIN { noise="-??"; util="??"; found=0 }
        /frequency:/ && $2 == freq {
            found=1; noise_val="-??"; active_ms=0; busy_ms=0;
            while ((getline > 0) && ($0 !~ /Survey data/)) {
                if ($1 == "noise:") noise_val=$2;
                if ($1 == "channel" && $2 == "active") active_ms=$4;
                if ($1 == "channel" && $2 == "busy") busy_ms=$4;
                if (busy_ms > 0) break;
            }
            util = (active_ms > 0) ? (100 * busy_ms) / active_ms : 0;
            printf "%s %.1f", noise_val, util;
            exit;
        }
        END { if(found==0) printf "-?? 0.0"; }
    ')
    NOISE_FLOOR=$(echo $SURVEY_STATS | awk '{print $1}')
    UTILIZATION=$(echo $SURVEY_STATS | awk '{print $2}')
    UTIL_INT=$(printf "%.0f" $UTILIZATION)

    # Print results for the current channel
    printf "%-10s | %-10s | %-12s | %-12s | %-15s\n" "$channel" "$NUM_NETWORKS" "$AVG_SIGNAL dBm" "$NOISE_FLOOR dBm" "$UTILIZATION %"

    # Determine the best channel
    if [ "$NOISE_FLOOR" != "-??" ]; then
        if [ "$NUM_NETWORKS" -lt "$MIN_NETWORKS" ]; then
            MIN_NETWORKS=$NUM_NETWORKS; MIN_UTILIZATION=$UTIL_INT; BEST_CHANNEL=$channel
        elif [ "$NUM_NETWORKS" -eq "$MIN_NETWORKS" ] && [ "$UTIL_INT" -lt "$MIN_UTILIZATION" ]; then
            MIN_UTILIZATION=$UTIL_INT; BEST_CHANNEL=$channel
        fi
    fi
done

echo "------------------------------------------------------------------------"

# --- Final Recommendation ---
if [ -n "$BEST_CHANNEL" ]; then
    echo "\n🏆 Recommendation:"
    echo "Based on the scan, channel '$BEST_CHANNEL' appears to be the best choice."
    echo "It has the lowest number of competing networks ($MIN_NETWORKS) and low utilization (~$MIN_UTILIZATION%)."
else
    echo "\nCould not determine a best channel. All channels may be occupied or have no survey data."
fi

echo "\nNotes:"
echo "  - Lower is better for 'Networks', 'Avg Signal' (more negative), 'Noise' (more negative), and 'Utilization'."
echo "  - Channels 52-144 are often DFS channels. Using them may involve a brief radar detection delay."
echo "  - For best results, run this script a few times at different times of the day."

# The trap will handle cleanup automatically when the script exits here
exit 0