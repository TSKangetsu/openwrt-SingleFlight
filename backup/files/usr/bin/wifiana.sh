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
CHANNELS_5GHZ="149 153 157 161 165"

# --- Script Logic ---

# Function for logging to dmesg
log_info() {
    logger -t "wifiana" "$@"
}

# Function to restore the original interface state
cleanup() {
    log_info "Restoring original state of '$WIFI_IF'"
    if [ -n "$ORIGINAL_MODE" ] && [ -n "$ORIGINAL_STATE" ]; then
        ip link set "$WIFI_IF" down
        iw dev "$WIFI_IF" set type "$ORIGINAL_MODE"
        if [ "$ORIGINAL_STATE" = "UP" ]; then
            ip link set "$WIFI_IF" up
        fi
        log_info "Restored: Mode=$ORIGINAL_MODE, State=$ORIGINAL_STATE"
    else
        log_info "Original state was not saved, skipping restore."
    fi
}

# Function to update the configuration file
update_config_file() {
    local best_channel=$1
    if [ -z "$best_channel" ]; then
        return
    fi

    local best_freq=$((5000 + best_channel * 5))
    local auto_channel_file="/etc/AUTO_CHANNEL"
    local config_file="/etc/APSconfig.json"

    log_info "Recommended frequency: $best_freq MHz."

    if [ -f "$auto_channel_file" ]; then
        if [ -f "$config_file" ]; then
            sed -i "/\"COM_BroadCastWirelessFreq\":/c\\        \"COM_BroadCastWirelessFreq\": $best_freq," "$config_file"
            log_info "Updated $config_file with COM_BroadCastWirelessFreq: $best_freq"
        else
            log_info "Warning: $config_file not found. Could not update COM_BroadCastWirelessFreq."
        fi
    else
        log_info "Info: $auto_channel_file not found. Skipping update of COM_BroadCastWirelessFreq in $config_file."
    fi
}

# Set trap to ensure cleanup runs on exit
trap cleanup EXIT

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
    echo "Usage: $0 <5ghz-wifi-interface> [mode]" >&2
    echo "Example: $0 wlan1" >&2
    echo "Example: $0 wlan0 mode2" >&2
    echo "" >&2
    echo "Detected 5GHz capable interfaces:" >&2
    iwinfo | grep -E "802.11a|802.11ac|802.11ax" | awk '{print $1}' | xargs -n 1 iwinfo | grep "Hardware:" -B 2 | grep ESSID | sed 's/.*ESSID: unknown //g'
    exit 1
fi

WIFI_IF=$1
MODE=${2:-"default"} # Default mode if not specified

# Verify the interface exists
if ! iw dev "$WIFI_IF" info >/dev/null 2>&1; then
    echo "Error: Interface '$WIFI_IF' does not exist or is not a wireless device." >&2
    exit 1
fi

# --- Main analysis ---
log_info "Starting 5GHz WiFi Analysis for interface '$WIFI_IF' (Mode: $MODE)"

# Save original state before changing anything
log_info "Saving original state of '$WIFI_IF'..."
ORIGINAL_MODE=$(iw dev "$WIFI_IF" info | grep 'type' | awk '{print $2}')
ORIGINAL_STATE=$(ip link show "$WIFI_IF" | grep -o 'state [A-Z]*' | awk '{print $2}')
log_info "Original state: Mode=$ORIGINAL_MODE, State=$ORIGINAL_STATE"

# Set interface to managed mode for scanning
log_info "Temporarily setting interface to 'managed' mode for accurate scanning..."
ip link set "$WIFI_IF" down
iw dev "$WIFI_IF" set type managed
ip link set "$WIFI_IF" up
sleep 1 # Give the interface a moment to initialize

# Get the list of disabled channels
DISABLED_CHANNELS=$(iw list | awk '/Frequencies:/ {f=1} f==1 && /\(disabled\)/ {print $2}' | grep -o '[0-9]\+')

if [ "$MODE" = "default" ]; then
    # Build frequency list for a targeted 5GHz scan
    FREQ_LIST_5GHZ=""
    for channel in $CHANNELS_5GHZ; do
        FREQ=$((5000 + channel * 5))
        FREQ_LIST_5GHZ="$FREQ_LIST_5GHZ $FREQ"
    done

    log_info "Performing targeted scan on 5GHz frequencies..."
    SCAN_RESULT=$(iw dev "$WIFI_IF" scan freq $FREQ_LIST_5GHZ passive)
    SURVEY_RESULT=$(iw dev "$WIFI_IF" survey dump)

    # Initialize variables to find the best channel
    BEST_CHANNEL=""
    MIN_NETWORKS=99999
    MIN_UTILIZATION=99999
    BEST_CHANNEL_NUM=99999

    # Print table header
    printf "\n%-10s | %-10s | %-12s | %-12s | %-15s\n" "Channel" "Networks" "Avg Signal" "Noise" "Utilization %"
    echo "------------------------------------------------------------------------"

    # Loop through each channel and analyze it
    for channel in $CHANNELS_5GHZ; do
        # If channel is disabled, skip it
        if echo "$DISABLED_CHANNELS" | grep -q -w "$channel"; then
            log_info "Channel $channel is disabled, skipping."
            continue
        fi
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
        if [ "$NUM_NETWORKS" -lt "$MIN_NETWORKS" ]; then
            MIN_NETWORKS=$NUM_NETWORKS
            MIN_UTILIZATION=$UTIL_INT
            BEST_CHANNEL=$channel
            BEST_CHANNEL_NUM=$channel
        elif [ "$NUM_NETWORKS" -eq "$MIN_NETWORKS" ]; then
            if [ "$UTIL_INT" -lt "$MIN_UTILIZATION" ]; then
                MIN_UTILIZATION=$UTIL_INT
                BEST_CHANNEL=$channel
                BEST_CHANNEL_NUM=$channel
            elif [ "$UTIL_INT" -eq "$MIN_UTILIZATION" ]; then
                # If network count and utilization are the same, prefer the lower channel number
                if [ "$channel" -lt "$BEST_CHANNEL_NUM" ]; then
                    BEST_CHANNEL=$channel
                    BEST_CHANNEL_NUM=$channel
                fi
            fi
        fi
    done

    echo "------------------------------------------------------------------------"

    # --- Final Recommendation ---
    if [ -n "$BEST_CHANNEL" ]; then
        log_info "🏆 Recommendation:"
        log_info "Based on the scan, channel '$BEST_CHANNEL' appears to be the best choice."
        log_info "It has the lowest number of competing networks ($MIN_NETWORKS) and low utilization (~$MIN_UTILIZATION%)."
        update_config_file "$BEST_CHANNEL"
        echo "$BEST_CHANNEL"
    else
        log_info "Could not determine a best channel. All channels may be occupied or have no survey data."
    fi

elif [ "$MODE" = "mode2" ]; then
    ACS_PROC_FILE="/proc/net/rtl88x2eu/$WIFI_IF/acs"
    log_info "Entering Mode 2: Driver-specific Analysis"

    if [ ! -f "$ACS_PROC_FILE" ]; then
        echo "Error: Driver-specific ACS data file not found at $ACS_PROC_FILE." >&2
        echo "Mode 2 is likely not supported by your WiFi driver/device." >&2
        exit 1
    fi

    # Execute passive scan
    # Build frequency list for a targeted 5GHz scan in mode2
    FREQ_LIST_5GHZ_MODE2=""
    for channel in $CHANNELS_5GHZ; do
        FREQ=$((5000 + channel * 5))
        FREQ_LIST_5GHZ_MODE2="$FREQ_LIST_5GHZ_MODE2 $FREQ"
    done

    log_info "Performing passive scan on $WIFI_IF with specified frequencies..."
    iw dev "$WIFI_IF" scan freq $FREQ_LIST_5GHZ_MODE2 passive >/dev/null 2>&1

    # Get best 5G channel from driver-specific tool
    ACS_OUTPUT=$(cat "$ACS_PROC_FILE" 2>/dev/null)
    if [ -z "$ACS_OUTPUT" ]; then
        echo "Error: Could not read ACS data from $ACS_PROC_FILE" >&2
        exit 1
    fi

    BEST_CHANNEL_MODE2=""

    # First, try to extract "Best 5G Channel" directly
    # In mode2, we always perform detailed analysis based on CHANNELS_5GHZ and ACS_OUTPUT
    log_info "Performing detailed analysis based on CHANNELS_5GHZ range..."
    
    AWK_SCRIPT='
    BEGIN {
        min_itf=99999;
        min_nhm=99999;
        min_clm=99999;
        min_bss=99999;
        best_ch_found=0; # Flag: 0 = no best channel found yet, 1 = best channel found
        best_ch=0;       # Will hold the best channel, default to 0 if none found

        split(disabled_channels, disabled_arr, " ");
        for (i in disabled_arr) {
            disabled_map[disabled_arr[i]]=1;
        }

        split(channels_5ghz, allowed_5g_arr, " ");
        for (i in allowed_5g_arr) {
            allowed_5g_map[allowed_5g_arr[i]]=1;
        }
    }
    /^ *[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ *$/ {
        # Index CH BSS CLM(%) NHM(%) ITF
        ch=$2; bss=$3; clm=$4; nhm=$5; itf=$6;

        if (ch in allowed_5g_map && !(ch in disabled_map)) {
            if (best_ch_found == 0) { # This is the first valid channel encountered
                min_itf=itf;
                min_nhm=nhm;
                min_clm=clm;
                min_bss=bss;
                best_ch=ch;
                best_ch_found=1;
            } else if (itf < min_itf) {
                min_itf=itf;
                min_nhm=nhm;
                min_clm=clm;
                min_bss=bss;
                best_ch=ch;
            } else if (itf == min_itf) {
                if (nhm < min_nhm) {
                    min_nhm=nhm;
                    min_clm=clm;
                    min_bss=bss;
                    best_ch=ch;
                } else if (nhm == min_nhm) {
                    if (clm < min_clm) {
                        min_clm=clm;
                        min_bss=bss;
                        best_ch=ch;
                    } else if (clm == min_clm) {
                        if (bss < min_bss) {
                            min_bss=bss;
                            best_ch=ch;
                        } else if (bss == min_bss) {
                            # Finally, prefer lower channel number as tie-breaker
                            if (ch < best_ch) {
                                best_ch=ch;
                            }
                        }
                    }
                }
            }
        }
    }
    END {
        print best_ch;
    }'

    BEST_CHANNEL_MODE2=$(echo "$ACS_OUTPUT" | awk -v disabled_channels="$DISABLED_CHANNELS" -v channels_5ghz="$CHANNELS_5GHZ" "$AWK_SCRIPT")

    if [ -n "$BEST_CHANNEL_MODE2" ] && [ "$BEST_CHANNEL_MODE2" -ne "0" ]; then
        log_info "Detailed analysis determined Best 5G Channel: $BEST_CHANNEL_MODE2."
    else
        log_info "Could not determine best 5G channel from detailed analysis."
    fi

    if [ -n "$BEST_CHANNEL_MODE2" ] && [ "$BEST_CHANNEL_MODE2" -ne "0" ]; then
        log_info "Final Recommended 5G channel: $BEST_CHANNEL_MODE2."
        update_config_file "$BEST_CHANNEL_MODE2"
        echo "$BEST_CHANNEL_MODE2"
    else
        log_info "Could not determine a best 5G channel in Mode 2."
    fi
else
    echo "Error: Unknown mode '$MODE'. Use 'default' or 'mode2'." >&2
    exit 1
fi

log_info "Notes:"
log_info "  - Lower is better for 'Networks', 'Avg Signal' (more negative), 'Noise' (more negative), and 'Utilization'."
log_info "  - Channels 52-144 are often DFS channels. Using them may involve a brief radar detection delay."
log_info "  - For best results, run this script a few times at different times of the day."

# The trap will handle cleanup automatically when the script exits
exit 0