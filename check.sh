# All functions operate on container $checkContainer

check_containerFinishedStart=
check_su=su
check_grep=grep

function containerExec() {
    leader=$(machinectl show "$checkContainer" -p Leader | cut -d= -f2)
    if [[ $leader ]]; then
        nsenter -t "$leader" -m -u -i -n -p -- $check_su root -l -c "exec $(printf "%q " "$@")"
    fi
}

getFailedUnits() {
    extraArg=$1
    if output=$(containerExec journalctl -b $extraArg --output=cat --grep="Failed with result" 2>&1); then
        if [[ $output ]]; then
            echo "$output"
            return 0
        fi
    fi
    return 1
}

getInvalidUnitFiles() {
    # `systemd-analyze verify unit-files` always outputs error
    # "Failed to prepare filename unit-files", but it correctly shows
    # invalid unit files
    containerExec systemd-analyze verify unit-files \
        |& $check_grep -v "Failed to prepare filename unit-files" || true
}

# Start container and immediately return if failed units are found
check_startContainer() {
    # Run in a subprocess
    if (check_doStart); then
        check_containerFinishedStart=1
    fi
}

check_doStart() {
    mainPID=$BASHPID
    bootWatcherPID=
    startPID=
    success=

    atExit() {
        set +e
        kill $bootWatcherPID 2>/dev/null
        kill $startPID 2>/dev/null
        errEcho
        errEcho
        if [[ ! $success ]]; then
            exit 1
        fi
    }
    trap atExit EXIT
    trap exit SIGUSR1

    # Don't always scan the whole log for failures
    lastCheckTime=$(date +%s.%6N)

    # Start a subprocess which signals this process when a unit failure
    # appears
    (
        machineStarted=
        >&2 printf .
        sleep 0.3
        for ((i=1;; i++)); do
            if [[ ! $machineStarted ]] && machinectl show $checkContainer -p Leader &>/dev/null; then
                machineStarted=1
            fi

            if [[ $machineStarted ]]; then
                now=$(date +%s.%6N)
                if getFailedUnits --since=@$lastCheckTime >/dev/null; then
                    kill -SIGUSR1 $mainPID || true
                    exit
                fi
                lastCheckTime=$now
            fi

            # Print every second loop iteration
            if [[ $i == 1 ]]; then
                >&2 printf .
            else
                i=0
            fi
            sleep 0.2
        done
    )& bootWatcherPID=$!
    disown

    systemctl start container@$checkContainer& startPID=$!
    # Wait and handle signals
    wait $startPID
    success=1
}

check_runCheckAndPrintResults() {
    containerStartTime=$1
    check_foundInvalidUnits=
    check_foundFailedUnits=

    invalidFiles=$(getInvalidUnitFiles)
    if [[ $invalidFiles ]]; then
        check_foundInvalidUnits=1
        echo "The following unit files are invalid:"
        echo "$invalidFiles"
        echo
    fi

    if failed=$(getFailedUnits --since=@$containerStartTime); then
        check_foundFailedUnits=1
        echo "Some units failed while starting:"
        echo "$failed"
        echo
        units=$(echo "$failed" | $check_grep -ohP "^\S+(?=:)")
        containerExec env PAGER=cat systemctl -l status $units || true
        echo
    fi
}
