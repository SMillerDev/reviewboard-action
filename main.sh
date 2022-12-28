#!/usr/bin/env bash
LOCATION=$(dirname $0)
COOKIE_JAR="$LOCATION/cookies.tmp"
if [ -z "$1" ]; then
  REVIEW_ID=$(git show --pretty="format:%b" "HEAD" --no-patch | grep "${REVIEWBOARD_URL}" | sed "s|.*${REVIEWBOARD_URL}/r/\([0-9]*\)/|\1|g")
else
  REVIEW_ID="$1"
fi
echo "::debug::Review ID: ${REVIEW_ID}"

if [ -z "$2" ]; then
  PUBLIC="false"
else
  PUBLIC="$2"
fi
echo "::debug::Public: ${PUBLIC}"

function cleanup()
{
     echo "::debug::cleaning up $1"
     if [[ -f "$1" ]]; then
          rm "$1"
     fi
}

function check_api_call()
{
     echo "::debug::checking API output"
     if [[ $1 -gt 0 ]]; then
          echo "::error title=API issue::API call failed"
          echo "::debug::return=${1} data=${2}"

          return 1
     fi

     state=$(jq -r .stat <<< "$2")
     if [[ "$state" != "ok" ]]; then
          echo "::error title=API issue::API returned not OK"
          echo "::debug::state=${state}"

          return 1
     fi
}

cleanup "${COOKIE_JAR}"
cleanup "review_header.tmp.md"
cleanup "review_footer.tmp.md"

echo "::debug::calling ${REVIEWBOARD_URL}/api/"
response=$(curl --silent --fail "${REVIEWBOARD_URL}/api/" \
                --cookie-jar "${COOKIE_JAR}" \
                --output - \
                -H "Accept: application/json" \
                -H "Authorization: token ${REVIEWBOARD_API_TOKEN}")

status=$?
if ! check_api_call "${status}" "${response}"; then
     echo "::debug::exiting after main API issue"
     exit 1
fi

echo "::debug::calling ${REVIEWBOARD_URL}/api/review-requests/${REVIEW_ID}/reviews/"
response=$(curl --silent --fail "${REVIEWBOARD_URL}/api/review-requests/${REVIEW_ID}/reviews/" \
               --cookie "${COOKIE_JAR}" \
               --output - \
               -H "Accept: application/json" \
               --data 'publish_to_owner_only=true' \
               --data "public=${PUBLIC}" \
               --data-binary "body_top=$(cat $LOCATION/review_header.tmp.md)" \
               --data 'body_top_text_type=markdown' \
               --data-binary "body_bottom=$(cat $LOCATION/review_footer.tmp.md)" \
               --data 'body_bottom_text_type=markdown')

status=$?
if ! check_api_call "${status}" "${response}"; then
     echo "::debug::exiting after post API issue"
     exit 1
fi
