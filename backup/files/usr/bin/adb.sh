#!/bin/sh

# Infinite loop to continuously check for ADB devices
while true; do
    # Check if an ADB device is connected
    # If the output of `adb devices` contains "device" and does not contain "offline" or "unauthorized",
    # then a device is considered connected.
    if adb devices | grep -q "device" && ! adb devices | grep -q "offline" && ! adb devices | grep -q "unauthorized"; then
        echo "ADB device detected. Waiting for device to be online and performing port forwarding..."
        # Wait for the device to be online to ensure it's ready
        adb wait-for-device
        # Check again if the device is still connected, in case it disconnected during wait-for-device
        if adb devices | grep -q "device" && ! adb devices | grep -q "offline" && ! adb devices | grep -q "unauthorized"; then
            adb reverse tcp:8025 tcp:554
            adb reverse tcp:8022 tcp:22
            echo "Port forwarding complete."
        else
            echo "Device disconnected or abnormal state during wait, skipping port forwarding."
        fi
    else
        echo "No ADB device detected. Waiting..."
    fi
    # Check every 5 seconds
    sleep 5
done