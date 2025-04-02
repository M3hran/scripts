#!/bin/bash

TIMESTAMP=$(date +"[%m/%d/%Y] [%I:%M:%S %p]")
GOTIFY_URL="https://gotify.parallaxsystem.com"
GOTIFY_APP_TOKEN="ALq4MczJus1Vaw5"
NPM_PROXY_HOST_DIR="/z/docker/nginx-proxy-manager/data/nginx/proxy_host"
NPM_CERTS_DIR="/z/docker/nginx-proxy-manager/letsencrypt/live"
DESTINATION_DIR="/z/mehran-backups/letsencrypt"



# Function to send Gotify notification
send_gotify_notification() {
  local title="$1"
  local message="$2"
  # Escape newlines in the message for JSON
  message=$(echo "$message" | sed ':a;N;$!ba;s/\n/\\n/g')

  # Send notification and capture HTTP response
  response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${GOTIFY_URL}/message?token=${GOTIFY_APP_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
          "title": "'"${title}"'",
          "message": "'"${message}"'",
          "priority": 5
        }')

  # Check HTTP response code
  if [[ "$response" == "200" ]]; then
    print_message "✅ Gotify notification sent successfully."
  else
    print_message "❌ Failed to send Gotify notification. HTTP Status: $response"
  fi
}


# Function to log output
print_message() {

        local message="$1"
        printf "${TIMESTAMP} ${message}\n"
}

# Function to rsync matched npm-crts to domain names
rsync_if_matched() {


        ORIGINAL_LETSENCRYPT=$1
        REMOTE_LETSENCRYPT=$2
        domain_name=$3

        #print_message "-- Starting -- LetsEncrypt [cloud-proxy -> S3][$domain_name]"
        rsync_output=$(rsync -Lazx ${ORIGINAL_LETSENCRYPT} ${REMOTE_LETSENCRYPT} --out-format='changed file: %i %n%L')
        rsync_returncode=$?
        changed_files_n=$(echo ${rsync_output} | grep 'changed file:')
        changed_files=$( echo "${changed_files_n}" | sed 's/ changed file:/\nchanged file:/g')

        if [ "$rsync_returncode" -eq "0" ]; then

        if [ -n "${changed_files}" ]; then
                print_message "[$domain_name -> S3] ⏵ i     info      OK: Syncing file changes"
                print_message "[$domain_name]\n ${changed_files}"
                send_gotify_notification "OK - ${TIMESTAMP} [$domain_name -> S3]" "[$domain_name]\n ${changed_files}"
        else
                print_message "[$domain_name -> S3] ⏵ i     info      NOOP: No file changes."
        fi

        else
                print_message "[$domain_name -> S3] ⏵ ❗     error     ERR: Sync failed with error."
                send_gotify_notification "!! FAIL !! - [cloud-proxy -> S3][$domain_name]" "Backed up letsencrypt to S3 failed with error."
        fi
}


#### MAIN


#find all npm-certs and match them to domain names
for dir in "$NPM_CERTS_DIR"/*/; do
    # Check if it's a directory
    if [ -d "$dir" ]; then
        # Print the directory name without the full path
        SSL_NAME="$(basename "$dir")"
        DOMAIN_NAME=$(find "${NPM_PROXY_HOST_DIR}" -type f -exec grep -wl "${SSL_NAME}" {} \; | xargs grep -wh "server_name" | head -n1 | sed -E 's/server_name [^.]+\.(.*);/\1/' | sed -E 's/^[ \t]+//'| awk '{print $1}' )
        #echo "${SSL_NAME} -> ${DOMAIN_NAME}"
    fi

    #start creating folder struction
    if [ ! -d "${DESTINATION_DIR}/${DOMAIN_NAME}" ]; then
        mkdir -p ${DESTINATION_DIR}/${DOMAIN_NAME}
    fi

    #finally rsync to correct domain names
    if [[ -n ${DOMAIN_NAME} ]]; then
            rsync_if_matched "${dir}" "${DESTINATION_DIR}/${DOMAIN_NAME}/" "${DOMAIN_NAME}"
    fi


done






