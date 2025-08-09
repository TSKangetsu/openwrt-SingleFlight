#!/bin/ash

# --- CPU Temperature and Frequency Monitor with Alert ---
#
# This script monitors the temperature and frequency for a 4-core CPU.
# If the temperature reaches or exceeds the defined threshold (85°C),
# it creates a warning file at /root/temp_warning.

# --- Configuration ---
# The temperature at which to trigger the warning.
TEMP_THRESHOLD=85

# File paths for sensor and CPU frequencies.
# NOTE: thermal_zone0 is common for the CPU, but may differ on your system.
TEMP_FILE="/sys/class/thermal/thermal_zone0/temp"
CPU0_FREQ_FILE="/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
CPU1_FREQ_FILE="/sys/devices/system/cpu/cpu1/cpufreq/scaling_cur_freq"
CPU2_FREQ_FILE="/sys/devices/system/cpu/cpu2/cpufreq/scaling_cur_freq"
CPU3_FREQ_FILE="/sys/devices/system/cpu/cpu3/cpufreq/scaling_cur_freq"
WARNING_LOG_FILE="/root/temp_warning"

# --- Sanity Check ---
# Verify that the necessary files exist before starting.
if [ ! -f "$TEMP_FILE" ]; then
  echo "Error: Temperature sensor file not found at $TEMP_FILE"
  exit 1
fi
if [ ! -f "$CPU0_FREQ_FILE" ]; then
  echo "Error: CPU0 frequency file not found at $CPU0_FREQ_FILE"
  exit 1
fi

# --- Main Program ---
echo "Starting monitor... Press Ctrl+C to stop."
sleep 1

# A flag to ensure the warning file is only created once per event.
warning_triggered=0

# Loop forever until the user presses Ctrl+C.
while true; do
  # --- Data Collection ---
  # Read the raw value from the temperature file (in millidegrees Celsius).
  temp_raw=$(cat "$TEMP_FILE")

  # Read the raw frequency values for each core (in kHz).
  freq0_raw=$(cat "$CPU0_FREQ_FILE")
  freq1_raw=$(cat "$CPU1_FREQ_FILE")
  freq2_raw=$(cat "$CPU2_FREQ_FILE")
  freq3_raw=$(cat "$CPU3_FREQ_FILE")

  # --- Calculations ---
  # Convert temperature to whole degrees Celsius.
  temp_c=$((temp_raw / 1000))

  # Convert frequencies to MHz for easier reading.
  freq0_mhz=$((freq0_raw / 1000))
  freq1_mhz=$((freq1_raw / 1000))
  freq2_mhz=$((freq2_raw / 1000))
  freq3_mhz=$((freq3_raw / 1000))

  # --- Display ---
  # Clear the screen for a clean, non-scrolling output.
  clear
  echo "--- ⚙️ CPU Monitor (Press Ctrl+C to Exit) ---"
  echo
  echo "🌡️  CPU Temperature: ${temp_c}°C"
  echo
  echo "⚡ Core Frequencies:"
  echo "   CPU 0: ${freq0_mhz} MHz"
  echo "   CPU 1: ${freq1_mhz} MHz"
  echo "   CPU 2: ${freq2_mhz} MHz"
  echo "   CPU 3: ${freq3_mhz} MHz"
  echo
  echo "----------------------------------------------"

  # --- Alerting Logic ---
  # Check if the temperature has crossed the threshold.
  if [ "$temp_c" -ge "$TEMP_THRESHOLD" ] && [ "$warning_triggered" -eq 0 ]; then
    # If it's too hot and we haven't warned yet, create the log file.
    echo "WARNING: CPU temperature reached ${temp_c}°C at $(date)" > "$WARNING_LOG_FILE"
    echo "!!! TEMPERATURE WARNING: Log created at $WARNING_LOG_FILE !!!"
    warning_triggered=1
  elif [ "$temp_c" -lt "$TEMP_THRESHOLD" ] && [ "$warning_triggered" -eq 1 ]; then
    # If the temperature has cooled down, reset the trigger and remove the file.
    echo "Temperature is back to normal."
    rm -f "$WARNING_LOG_FILE"
    warning_triggered=0
  fi

  # Wait for 2 seconds before the next update.
  sleep 2
done
