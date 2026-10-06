#!/bin/bash
# Standalone install-on-connect: scans for paired iPhones over USB or Wi-Fi, then builds +
# installs WorkoutTimer to one of them once and exits.
#
# In a terminal it shows a live list of reachable phones (name + UDID) while the scan keeps
# running; press the phone's number to install to it, or q to quit. Without a terminal (or
# with -d) there is no menu: it installs to the first matching phone as soon as one shows up.
# Either way it gives up after the timeout.
#
# Wi-Fi needs the phone paired and "Connect via network" enabled in Xcode (Window >
# Devices and Simulators), on the same network as this Mac. Wi-Fi tunnels are brought
# up on demand, so each scan briefly probes paired phones whose tunnel isn't already up.
#
# Usage:
#   scripts/install-on-connect.sh [-d UDID] [-c Debug|Release] [-t SECONDS] [-i SECONDS] [-w]
#
#   -d UDID     Only consider this device and install without a menu (or $DEVICE_UDID)
#   -c CONFIG   Build configuration (default: Debug; or $CONFIGURATION)
#   -t SECONDS  Give up after this long without an install (default: 120; 0 = scan once)
#   -i SECONDS  Scan interval while waiting (default: 5; or $POLL_INTERVAL)
#   -w          Wired (USB) only; skip Wi-Fi probing
#
# Exits 0 on a successful install, 1 on timeout, build or install failure.
# Progress is logged to ~/Library/Logs/WorkoutTimer-InstallOnConnect.log.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_FILE="$PROJECT_DIR/WorkoutTimer.xcodeproj"
SCHEME="WorkoutTimer"
DERIVED_DATA="$PROJECT_DIR/Build/InstallOnConnect"
LOG_FILE="$HOME/Library/Logs/WorkoutTimer-InstallOnConnect.log"

DEVICE_UDID="${DEVICE_UDID:-}"
CONFIGURATION="${CONFIGURATION:-Debug}"
POLL_INTERVAL="${POLL_INTERVAL:-5}"
WAIT_TIMEOUT=120
WIRED_ONLY=0

while getopts "d:c:i:t:wh" opt; do
    case "$opt" in
        d) DEVICE_UDID="$OPTARG" ;;
        c) CONFIGURATION="$OPTARG" ;;
        i) POLL_INTERVAL="$OPTARG" ;;
        t) WAIT_TIMEOUT="$OPTARG" ;;
        w) WIRED_ONLY=1 ;;
        *) sed -n '2,/^set -uo/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'; exit 2 ;;
    esac
done

# xcodebuild needs full Xcode; fall back to it when xcode-select points at the command line tools.
if [[ "$(xcode-select -p 2>/dev/null)" == */CommandLineTools && -z "${DEVELOPER_DIR:-}" \
    && -d /Applications/Xcode.app ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

for tool in xcrun xcodebuild jq; do
    command -v "$tool" >/dev/null 2>&1 || { echo "error: '$tool' not found in PATH" >&2; exit 1; }
done
[ -d "$PROJECT_FILE" ] || { echo "error: $PROJECT_FILE not found" >&2; exit 1; }

WORK_DIR="$(mktemp -d)"
LOCK_DIR="$HOME/Library/Caches/WorkoutTimer-InstallOnConnect.lock"
mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$LOCK_DIR")"

# Single instance: the lock directory holds the owner's PID; steal it if that process is gone.
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    if kill -0 "$(cat "$LOCK_DIR/pid" 2>/dev/null)" 2>/dev/null; then
        echo "error: already running (pid $(cat "$LOCK_DIR/pid"))" >&2
        exit 1
    fi
fi
echo $$ >"$LOCK_DIR/pid"
trap 'kill "${SCAN_PID:-}" 2>/dev/null; rm -rf "$WORK_DIR" "$LOCK_DIR"' EXIT
trap 'exit 130' INT TERM

DEVICES_JSON="$WORK_DIR/devices.json"

log() {
    local line="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$line" >>"$LOG_FILE"
    echo "$line"
}
notify() { osascript -e "display notification \"$1\" with title \"WorkoutTimer Install-on-Connect\"" >/dev/null 2>&1; }

# Scans paired physical iPhones with Developer Mode on (restricted to $DEVICE_UDID if set) and prints a
# "udid<TAB>name" line for each one reachable right now. A wired phone is reported by the
# device list; Wi-Fi phones with a down tunnel are probed in parallel, which brings the
# tunnel up if reachable.
scan_devices() {
    xcrun devicectl list devices --json-output "$DEVICES_JSON" >/dev/null 2>&1 || return 1
    rm -f "$WORK_DIR"/probe.*
    local udid name transport tunnel
    while IFS=$'\t' read -r udid name transport tunnel; do
        if [ "$tunnel" = "connected" ]; then
            printf '%s\t%s\n' "$udid" "$name"
        elif [ "$transport" = "localNetwork" ] && [ "$WIRED_ONLY" -eq 0 ]; then
            { xcrun devicectl device info details --device "$udid" --timeout 5 >/dev/null 2>&1 \
                && printf '%s\t%s\n' "$udid" "$name" >"$WORK_DIR/probe.$udid"; } &
        fi
    done < <(jq -r --arg udid "$DEVICE_UDID" '
        .result.devices[]
        | select(.hardwareProperties.reality == "physical"
                 and .connectionProperties.pairingState == "paired"
                 and .deviceProperties.developerModeStatus == "enabled"
                 and (.connectionProperties.transportType == "wired"
                      or .connectionProperties.transportType == "localNetwork"))
        | select($udid == "" or .hardwareProperties.udid == $udid)
        | [.hardwareProperties.udid, .deviceProperties.name,
           .connectionProperties.transportType, .connectionProperties.tunnelState] | @tsv' "$DEVICES_JSON")
    wait
    cat "$WORK_DIR"/probe.* 2>/dev/null
    return 0
}

# Runs scans back to back in the background, publishing each result to $FOUND_FILE.
scan_loop() {
    while true; do
        scan_devices >"$FOUND_FILE.tmp" && mv "$FOUND_FILE.tmp" "$FOUND_FILE"
        sleep "$POLL_INTERVAL"
    done
}

# Shows the live device list and sets TARGET_UDID to the phone the user picks. Returns 1 on
# quit or timeout.
pick_device() {
    local -a udids=() names=()
    local lines=0 snapshot="" found key udid name i
    scan_loop &
    SCAN_PID=$!
    local deadline=$((SECONDS + WAIT_TIMEOUT))
    while true; do
        found="$(cat "$FOUND_FILE" 2>/dev/null)"
        if [ "$found" != "$snapshot" ] || [ "$lines" -eq 0 ]; then
            snapshot="$found"
            udids=(); names=()
            while IFS=$'\t' read -r udid name; do
                [ -n "$udid" ] && { udids+=("$udid"); names+=("$name"); }
            done <<<"$found"
            [ "$lines" -gt 0 ] && printf '\033[%dA\033[J' "$lines"
            lines=0
            echo "Reachable iPhones (scanning over $([ "$WIRED_ONLY" -eq 1 ] && echo USB || echo 'USB/Wi-Fi')):"; lines=$((lines + 1))
            if [ "${#udids[@]}" -eq 0 ]; then
                echo "  (none yet)"; lines=$((lines + 1))
            else
                for i in "${!udids[@]}"; do
                    printf '  %d) %s  [%s]\n' $((i + 1)) "${names[i]}" "${udids[i]}"; lines=$((lines + 1))
                done
            fi
            echo "Press a number to install, q to quit."; lines=$((lines + 1))
        fi
        if [ "$SECONDS" -ge "$deadline" ]; then
            echo "Timed out waiting for a selection."
            return 1
        fi
        key=""
        read -r -s -n 1 -t 1 key
        case "$key" in
            q|Q) echo "Cancelled."; return 1 ;;
            [1-9])
                if [ "$key" -le "${#udids[@]}" ]; then
                    TARGET_UDID="${udids[key-1]}"
                    kill "$SCAN_PID" 2>/dev/null
                    return 0
                fi
                ;;
        esac
    done
}

build_and_install() {
    local udid="$1"
    log "iPhone $udid connected -- building $SCHEME ($CONFIGURATION)..."
    if ! xcodebuild -project "$PROJECT_FILE" -scheme "$SCHEME" -configuration "$CONFIGURATION" \
        -destination "id=$udid" -derivedDataPath "$DERIVED_DATA" build >>"$LOG_FILE" 2>&1; then
        log "Build failed."
        notify "Build failed -- check $LOG_FILE"
        return 1
    fi

    # The project may override the products location, so ask xcodebuild where the app landed.
    local settings app_path
    settings="$(xcodebuild -project "$PROJECT_FILE" -scheme "$SCHEME" -configuration "$CONFIGURATION" \
        -destination "id=$udid" -derivedDataPath "$DERIVED_DATA" -showBuildSettings 2>/dev/null)"
    app_path="$(awk -F' = ' '$1 ~ /^ *TARGET_BUILD_DIR$/ {d=$2} $1 ~ /^ *FULL_PRODUCT_NAME$/ {n=$2} END {print d "/" n}' <<<"$settings")"
    log "Build succeeded, installing to device..."
    if xcrun devicectl device install app --device "$udid" "$app_path" >>"$LOG_FILE" 2>&1; then
        log "Install succeeded."
        notify "Installed the latest build to your iPhone."
    else
        log "Install failed. Make sure Developer Mode is enabled on the iPhone (Settings > Privacy & Security > Developer Mode)."
        notify "Install failed -- check $LOG_FILE"
        return 1
    fi
}

FOUND_FILE="$WORK_DIR/found"
TARGET_UDID=""

if [ -t 0 ] && [ -t 1 ] && [ -z "$DEVICE_UDID" ]; then
    pick_device || exit 1
else
    log "Scanning for ${DEVICE_UDID:-paired iPhones} over $([ "$WIRED_ONLY" -eq 1 ] && echo USB || echo 'USB/Wi-Fi') (up to ${WAIT_TIMEOUT}s)..."
    deadline=$((SECONDS + WAIT_TIMEOUT))
    while true; do
        found="$(scan_devices)"
        [ -n "$found" ] && break
        if [ "$SECONDS" -ge "$deadline" ]; then
            log "Timed out: no reachable iPhone found."
            notify "No iPhone reachable -- gave up after ${WAIT_TIMEOUT}s"
            exit 1
        fi
        sleep "$POLL_INTERVAL"
    done
    TARGET_UDID="${found%%$'\t'*}"
    [ "$(wc -l <<<"$found")" -gt 1 ] && log "Multiple devices reachable; using the first."
fi

build_and_install "$TARGET_UDID"
