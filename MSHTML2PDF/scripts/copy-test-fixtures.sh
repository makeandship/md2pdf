echo "Copying files..."
echo "From"
echo "${SRCROOT}"
echo "To"
echo "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

EXCLUDES="--exclude '*.DS_Store --exclude '*.psd' --exclude '*.eps' --exclude '.*'"
OPTIONS="-avz --delete"

rsync ${OPTIONS} ${EXCLUDES} "${SRCROOT}/html2pdfTests/Fixtures/" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Fixtures/"
