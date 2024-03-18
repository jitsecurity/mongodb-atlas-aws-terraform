#!/bin/bash
################################################################################
# Description: Deletes data api from mongo
# NOTE - if the state is dirty (data api / service is deleted) - this will cause recreation of data-api
#        This affects eventually other dependent services which will need to refresh their URLs from SSM.
#        It's recommended that dependent services will read at runtime the URLs (and cache it).
#
#
# Dependencies: curl, jq
################################################################################

# perform login and get access_token
echo "Performing login, url: $ATLAS_ADMIN_BASE_API_PATH/auth/providers/mongodb-cloud/login" >&2

response=$(curl -sSL --show-error --fail -X POST "$ATLAS_ADMIN_BASE_API_PATH/auth/providers/mongodb-cloud/login" \
--header 'content-type: application/json' \
--data-raw "$AUTH")
if [ $? -ne 0 ]; then
  echo "Login failed... $response" >&2
  exit 1
fi

MONGO_TOKEN=$(echo "$response" | jq -r '.access_token')

echo "Login finished successfully."  >&2

function curl_with_auth {
  # ----------------------------------
  # performs curl request with mongo token, 404 errors are considered valid.
  # param1 - the url section (without the base URL) to perform
  # param2 - method
  # param3 - the body of the request
  #
  # returns: None
  # ----------------------------------
  url="$ATLAS_ADMIN_BASE_API_PATH/$1"
  method="$2"
  data="$3"

  http_code=$(curl -sSL --fail --output /dev/null -w "%{http_code}" -X "$method" -H "authorization: Bearer $MONGO_TOKEN" -H "content-type: application/json" -d "$data" "$url")

  if [[ "$?" -ne 0 || ("$http_code" != "404" && ("$http_code" -ge 400 || "$http_code" -lt 200)) ]]; then
      echo "HTTP request failed with error code $http_code" >&2
      exit 1
  fi
}

# Take the state (STDIN), - which mean, take the state.
IN=$(cat)
data_api_id=$(echo "${IN}" | jq -r '.data_api_id')

# perform delete
echo "Trying to delete data api for project id: $PROJECT_ID, api_id: $data_api_id, service_id: $service_id" >&2
del_req=$(curl_with_auth "groups/$PROJECT_ID/apps/$data_api_id" "DELETE")
if [ $? -ne 0 ]; then
  exit 1
fi
exit 0
