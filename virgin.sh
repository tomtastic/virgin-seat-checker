#!/usr/bin/env bash
# ref: https://travelplus.virginatlantic.com/reward-flight-finder/results/month?origin=SEA&destination=LHR&airline=VS&month=11&year=2023

function main {
    if [[ -z "$1" ]]; then
        cat <<HELP
Get premium seat upgrade availability on Virgin Atlantic flights
Usage: $0 <FROM> <TO> YYYY-MM-DD
eg   : $0 SEA    LHR  2023-11-18
HELP
        exit 1
    else
        # Set some output colours up
        COSMOS="\x1b[38;2;223;42;93m"
        GREEN="\x1b[38;2;0;255;76m"
        RESET="\x1b[0m"
        # Parse the input args
        SRC="$1"
        DST="$2"
        YMD="$3"
        DEBUG="$4"
        YEAR=$(ymd_unpack_year "$YMD")
        MONTH=$(ymd_unpack_month "$YMD")
        echo "[+] Checking Virgin reward-seat-checker-api for $SRC -> $DST on $YMD"
    fi

    # Get an array of 0:session_cookie, 1:session_location_url
    SESSION=($(curl_session_cookie)) || exit $?
    JSON=$(curl_json "${SESSION[0]}" "${SESSION[1]}") || exit $?
    parse_json "$JSON"
}

function curl_session_cookie {
    # Grab the curl output from Burp to determine these
    SESSION_HEADERS=(
        'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.5672.127 Safari/537.36'
        'Host: travelplus.virginatlantic.com'
        'Content-Type: application/json'
    )
    SESSION_DATA=(
        '\x0d\x0a{\"slice\":{\"origin\":\"'"$SRC"'\",\"destination\":\"'"$DST"'\",\"departure\":\"'"$YMD"'\"},\"passengers\":[\"ADULT\"],\"permittedCarriers\":[\"VS\"],\"years\":['"$YEAR"'],\"months\":[\"'"$MONTH"'\"]}'
    )
    SESSION_URL='https://travelplus.virginatlantic.com/travelplus/reward-seat-checker-api/'

    echo "[+] Get session cookie..." >&2
	CURL_CMD="curl -i -s -k -X $'POST'"
	# HEADERS
	for h in "${SESSION_HEADERS[@]}"; do
		CURL_CMD+=" -H $'$h'"
	done
	# BINARY DATA
	for d in "${SESSION_DATA[@]}"; do
		CURL_CMD+=" --data-binary $'$d'"
	done
	# URL
	CURL_CMD+=" $SESSION_URL"

	# Run the generated cURL command string
	CURL_RESPONSE=$(eval "$CURL_CMD")
	SESSION_ID=$(echo "$CURL_RESPONSE" | awk -F= '/com.virginholidays.session/ {gsub(/;.*/,"",$2);print $2}')
    SESSION_LOC=$(echo "$CURL_RESPONSE" | awk '/^location:/ {gsub(/\r$/,"");print $2}')
    if [[ -n "$SESSION_ID" && -n "$SESSION_LOC" ]]; then
        echo "$SESSION_ID"
        echo "$SESSION_LOC"
    else
        # Didn't work, print the command and HTTP response
        echo "[!] $CURL_CMD" >&2
        echo "[!] $(echo "$CURL_RESPONSE" | tail -1)" >&2
        exit 1
    fi
}

function curl_json {
    echo "[+] Get availability..." >&2
    SESSION_ID=$1
    SESSION_URL=$2
	CURL_CMD="curl -s -k -X $'GET'"
	# HEADERS
	for h in "${SESSION_HEADERS[@]}"; do
		CURL_CMD+=" -H $'$h'"
	done
	# SESSION_ID
	CURL_CMD+=" -b $'com.virginholidays.session=$SESSION_ID'"
	# URL
	CURL_CMD+=" $SESSION_URL"

	# Run the generated cURL command string
    CURL_RESPONSE=$(eval "$CURL_CMD")
    if [[ -n "$CURL_RESPONSE" ]]; then
        echo "$CURL_RESPONSE"
    else
        echo "[!] Couldn't get JSON response" >&2
        echo "[!] $CURL_RESPONSE" >&2
        exit 2
    fi
}

function parse_json {
        JSON="$1"
        [[ -n "$DEBUG" ]] && echo "$JSON" | jq .
        RESULT=$(jq '.[].pointsDays[]|select(.date == "'"$YMD"'")|{date:.date,min_price:.minPrice,min_points:.minAwardPointsTotal,economy_seats:.seats.awardEconomy.cabinClassSeatCount,premium_seats:.seats.awardComfortPlusPremiumEconomy.cabinClassSeatCount,business_seats:.seats.awardBusiness.cabinClassSeatCount}' <<<"$JSON")

        if [[ -n "$RESULT" ]]; then
            FOUND=$(jq '.|select(.premium_seats >= 1)|{can_upgrade:true}' <<<"$RESULT")
            if [[ -n "$FOUND" ]]; then
                echo "$RESULT"
                # shellcheck disable=SC2059
                printf "${GREEN}[*] Premium seats available, chat for upgrade : ${RESET}https://www.virginatlantic.com/mytrips/findPnr.action\n"
            else
                echo "$RESULT"
                # shellcheck disable=SC2059
                printf "${COSMOS}[!] No premium seats available${RESET}\n"
                exit 4
            fi
        else
            echo "[!] No data available"
            exit 3
        fi
}

function ymd_unpack_year {
    # Take YYYY-MM-DD, return just YYYY
    ymd=$1
    echo "$ymd" | cut -c-4
}

function ymd_unpack_month {
    # Take YYYY-MM-DD, return uppercase full month name
    ymd=$1
    date -jf %F "$ymd" '+%B' | tr 'a-z' 'A-Z'
}

main "$@"
