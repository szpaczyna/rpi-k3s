#!/bin/bash

function usage_and_exit {
    cat << EOF >&2

Usage: $0 <host-file>

    Show whether it is possible to ssh into hosts listed in <host-file>.
    Hostnames in <host-file> are separated by newlines and have the format:

        [user@]hostname[:port]

    Sample <host-file>:

        example.vm.host.tld
        me@remote.host.tld
        root@bad.host.tld
        deploy@production.live.example:2222
        deploy@staging.live.example:2224

EOF

    exit 1
}

while getopts :h opt; do
    case $opt in
        h)      usage_and_exit
            ;;
        '?')    echo "$0 Invalid option -$OPTARG" >&2
            usage_and_exit
            ;;
    esac
done

shift $((OPTIND - 1))   # remove options, leave arguments

if [ $# -ne 1 ]; then
    usage_and_exit
fi

# Read hosts into an array so we can iterate safely line by line.
mapfile -t hosts < "$1"

# Calculate the longest hostname, to align columns if we can.
longest_hostname=0
for line in "${hosts[@]}"; do
    [ -z "$line" ] && continue
    length=${#line}
    [ "$length" -gt "$longest_hostname" ] && longest_hostname=$length
done

RED='\033[1;31m'
NC='\033[0m' # No Color

for line in "${hosts[@]}"; do
    [ -z "$line" ] && continue
    host=${line%:*}
    port=${line#*:}
    portarg=()
    if [ -n "${port##*[!0-9]*}" ]; then
        portarg=(-p "$port")
    fi
    printf "%${longest_hostname}s ... " "$line"
    if ssh -q -o BatchMode=yes -o ConnectTimeout=3 "${portarg[@]}" "$host" exit 2>/dev/null; then
        echo "OK"
    else
        printf '%bFAIL%b\n' "$RED" "$NC"
    fi
done
