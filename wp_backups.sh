### Usage: wp_backups.sh website1 website2 website3
### input: wp_backups.env present in the same directory with following variables 
## MYSQL_USER=""
## MYSQL_PASSWORD="
## MYSQL_HOST=""  # Your MySQL host, could be localhost or an IP
## MYSQL_PORT="3306 # Default MySQL port
## GOTIFY_URL=""
## GOTIFY_APP_TOKEN="""
## WEB_ROOT=""
## BACKUP_DIR=""

#!/bin/bash
MAX_DAILY=7                    # Maximum daily backups to retain
MAX_WEEKLY=3                   # Maximum weekly backups to retain
MAX_MONTHLY=3                  # Maximum monthly backups to retain
MAX_YEARLY=1                   # Maximum yearly backups to retain

# Load environment variables from the .env file
if [ -f "wp_backups.env" ]; then
  source wp_backups.env
else
  echo "wp_backups.env file not found. Exiting."
  exit 1
fi


# Ensure at least one website name is provided
if [ $# -lt 1 ]; then
  echo "Please provide at least one website name as an argument."
  exit 1
fi

# Function to send Gotify notification
send_gotify_notification() {
  local title="$1"
  local message="$2"
  curl -X POST "${GOTIFY_URL}/message?token=${GOTIFY_APP_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
          "title": "'"${title}"'",
          "message": "'"${message}"'",
          "priority": 5
        }'
}

backup_wordpress() {
  # Define backup directories for the website
  WEBSITE_NAME="$1"
  SITE_BACKUP_DIR="${BACKUP_DIR}/${WEBSITE_NAME}"
  #FILES_BACKUP_DIR="${SITE_BACKUP_DIR}/files"
  #DB_BACKUP_DIR="${SITE_BACKUP_DIR}/database"
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  #BACKUP_FILE="${FILES_BACKUP_DIR}/wp_files_${WEBSITE_NAME}_${DATE}.tar.gz"
  #DB_BACKUP_FILE="${DB_BACKUP_DIR}/${WEBSITE_NAME}_db_${DATE}.sql"
  BACKUP_FILE="${SITE_BACKUP_DIR}/${TIMESTAMP}_wp_files_${WEBSITE_NAME}.tar.gz"
  DB_BACKUP_FILE="${SITE_BACKUP_DIR}/${TIMESTAMP}_db_${WEBSITE_NAME}.sql"

  # Define MySQL database name for the website
  DB_NAME="${WEBSITE_NAME}"

  # Create backup directories if they don't exist
  mkdir -p "${SITE_BACKUP_DIR}"
  #mkdir -p "${FILES_BACKUP_DIR}"
  #mkdir -p "${DB_BACKUP_DIR}"

  # Backup WordPress files (excluding unnecessary files)
  echo "Backing up WordPress files for ${WEBSITE_NAME}..."
  tar -czf "${BACKUP_FILE}" -C "${WEB_ROOT}/${WEBSITE_NAME}" . || {   
  echo "Error backing up the files for ${WEBSITE_NAME}. Exiting."; 
  send_gotify_notification "WP Backup Failed: ${WEBSITE_NAME}" "Error occurred while backing up the files for ${WEBSITE_NAME}." >/dev/null 2>&1; 
  exit 1; }

  # Backup WordPress database using mysqldump
  echo "Backing up database for ${WEBSITE_NAME}..."
  mysqldump -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" "${DB_NAME}" > "${DB_BACKUP_FILE}" && \
  gzip "${DB_BACKUP_FILE}" || { 
  echo "Error backing up the database for ${WEBSITE_NAME}. Exiting.";
  send_gotify_notification "WP Backup Failed: ${WEBSITE_NAME}" "Error occurred while backing up the database for ${WEBSITE_NAME}." >/dev/null 2>&1;
  exit 1; }

  # Create a symlink for today's backup (daily)
  ln -sf "$(basename "${BACKUP_FILE}")" "${SITE_BACKUP_DIR}/daily_${TIMESTAMP}_wp_files_${WEBSITE_NAME}.tar.gz"
  ln -sf "$(basename "${DB_BACKUP_FILE}.gz")" "${SITE_BACKUP_DIR}/daily_${TIMESTAMP}_db_${WEBSITE_NAME}.sql.gz"  
 
  #Gotify notification for successful backup
  send_gotify_notification "WP Backup Successfull: ${WEBSITE_NAME}" "${WEBSITE_NAME} backup has been successfully completed and old backups have been cleaned up." >/dev/null 2>&1
}

# Function to promote today's backup if needed
promote_today_if_missing() {
    local current_category="$1"
    local next_category="$2"
    local site_name="$3"
    local site_backup_dir="${BACKUP_DIR}/${site_name}"

    # Check if the next category is missing for both wp_files and db files
    local wp_files_symlink
    local db_symlink
    wp_files_symlink=$(find "${site_backup_dir}" -name "${next_category}_*wp_files_*" -type l)
    db_symlink=$(find "${site_backup_dir}" -name "${next_category}_*db_*" -type l)

    if [ -z "$wp_files_symlink" ] && [ -z "$db_symlink" ]; then
        echo "No ${next_category} backup found. Promoting today's backup to ${next_category}..."
        
        # Find today's backups for wp_files and db
        local TODAY_WP_BACKUP
        local TODAY_DB_BACKUP
        TODAY_WP_BACKUP=$(find "${site_backup_dir}" -name "daily_*_wp_files_*" -type l | grep "$(date '+%Y-%m-%d')" || true)
        TODAY_DB_BACKUP=$(find "${site_backup_dir}" -name "daily_*_db_*" -type l | grep "$(date '+%Y-%m-%d')" || true)

        if [ -n "$TODAY_WP_BACKUP" ] && [ -n "$TODAY_DB_BACKUP" ]; then
            # Promote wp_files backup
            TARGET_WP=$(readlink -f "$TODAY_WP_BACKUP")
            NEW_NAME_WP=$(basename "${TODAY_WP_BACKUP}" | sed "s/daily_/${next_category}_/")
            ln -sf "$(basename "${TARGET_WP}")" "${site_backup_dir}/${NEW_NAME_WP}"
            echo "WordPress files backup promoted to ${next_category}."

            # Promote db backup
            TARGET_DB=$(readlink -f "$TODAY_DB_BACKUP")
            NEW_NAME_DB=$(basename "${TODAY_DB_BACKUP}" | sed "s/daily_/${next_category}_/")
            ln -sf "$(basename "${TARGET_DB}")" "${site_backup_dir}/${NEW_NAME_DB}"
            echo "Database backup promoted to ${next_category}."
        else
            echo "No backup for today found in daily. Cannot promote."
        fi
    fi
}

# Function to clean up old backups
cleanup_backups() {
    local category="$1"
    local max_count="$2"
    local site_name="$3"
    local site_backup_dir="${BACKUP_DIR}/${site_name}"

    echo "Cleaning up old ${category} backups for ${site_name}..."
    ls -t "${site_backup_dir}/${category}_"*"_wp_files_"* 2>/dev/null | tail -n +$((max_count + 1)) | xargs -r rm -f || {
        echo "No ${category} backups to clean up or error during cleanup."
    }
    ls -t "${site_backup_dir}/${category}_"*"_db_"* 2>/dev/null | tail -n +$((max_count + 1)) | xargs -r rm -f || {
        echo "No ${category} backups to clean up or error during cleanup."
    }
}


# Main script
echo "Starting backup and retention script..."

# Loop through each website passed as a command-line argument
for WEBSITE_NAME in "$@"
do
    backup_wordpress "${WEBSITE_NAME}"

    # Ensure backups exist for each time window
    promote_today_if_missing "daily" "weekly" "${WEBSITE_NAME}"       # Ensure at least one weekly backup
    promote_today_if_missing "weekly" "monthly" "${WEBSITE_NAME}"    # Ensure at least one monthly backup
    promote_today_if_missing "monthly" "yearly" "${WEBSITE_NAME}"   # Ensure at least one yearly backup

    # Apply retention policy
    cleanup_backups "daily" "${MAX_DAILY}" "${WEBSITE_NAME}"
    cleanup_backups "weekly" "${MAX_WEEKLY}" "${WEBSITE_NAME}"
    cleanup_backups "monthly" "${MAX_MONTHLY}" "${WEBSITE_NAME}"
    cleanup_backups "yearly" "${MAX_YEARLY}" "${WEBSITE_NAME}"
done




echo "Backup and retention policy applied successfully."
