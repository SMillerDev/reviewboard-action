#!/usr/bin/env bash
COOKIE_JAR="cookies.tmp"

review_request_id=$(git show --pretty="format:%b" "HEAD" --no-patch | grep "${REVIEWBOARD_URL}" | sed "s|.*${REVIEWBOARD_URL}/r/\([0-9]*\)/|\1|g")
REVIEW_ID=${1:-"$review_request_id"}
PUBLIC=${2:-"false"}

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
          echo "::notice::${2}"

          return 1
     fi

     state=$(jq -r .stat <<< "$2")
     if [[ "$state" != "ok" ]]; then
          echo "::error title=API issue::API returned not OK"
          echo "::notice::${state}"

          return 1
     fi
}

cleanup "${COOKIE_JAR}"
cleanup "review_header.tmp.md"
cleanup "review_footer.tmp.md"

echo "::debug::calling ${REVIEWBOARD_URL}/api/"
response=$(curl --silent --fail "${REVIEWBOARD_URL}/api/" \
                --cookie-jar "${COOKIE_JAR}" \
                -H "Accept: application/json" \
                -H "Authorization: token ${REVIEWBOARD_API_TOKEN}")

status=$?
if ! check_api_call "${status}" "${response}"; then
     exit 1
fi

echo "::debug::calling ${REVIEWBOARD_URL}/api/review-requests/${review_request_id}/reviews/"
response=$(curl --silent --fail "${REVIEWBOARD_URL}/api/review-requests/${review_request_id}/reviews/" \
               --cookie "${COOKIE_JAR}" \
               -H "Accept: application/json" \
               --data 'publish_to_owner_only=true' \
               --data "public=${PUBLIC}" \
               --data-binary "body_top=$(cat review_header.tmp.md)" \
               --data 'body_top_text_type=markdown' \
               --data-binary "body_bottom=$(cat review_footer.tmp.md)" \
               --data 'body_bottom_text_type=markdown')

status=$?
if ! check_api_call "${status}" "${response}"; then
     exit 1
fi
