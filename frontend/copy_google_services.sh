#!/bin/sh

# Script to copy the correct GoogleService-Info.plist based on the Flavor/Bundle ID
# This should be added as a "Run Script" Build Phase in Xcode.

# Destination path inside the built app bundle
PLIST_DEST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

echo "Copying GoogleService-Info.plist for ${PRODUCT_BUNDLE_IDENTIFIER}"

case "${PRODUCT_BUNDLE_IDENTIFIER}" in
  "com.example.myapp.dev")
    # Path relative to PROJECT_DIR (normally ios/)
    if [ -f "${PROJECT_DIR}/flavors/dev/GoogleService-Info.plist" ]; then
        cp "${PROJECT_DIR}/flavors/dev/GoogleService-Info.plist" "${PLIST_DEST}"
        echo "Successfully copied dev plist."
    else
        echo "Error: File not found at ${PROJECT_DIR}/flavors/dev/GoogleService-Info.plist"
        exit 1
    fi
    ;;
  "com.example.myapp.staging")
    if [ -f "${PROJECT_DIR}/flavors/staging/GoogleService-Info.plist" ]; then
        cp "${PROJECT_DIR}/flavors/staging/GoogleService-Info.plist" "${PLIST_DEST}"
        echo "Successfully copied staging plist."
    else
        echo "Error: File not found at ${PROJECT_DIR}/flavors/staging/GoogleService-Info.plist"
        exit 1
    fi
    ;;
  "com.example.myapp")
    if [ -f "${PROJECT_DIR}/flavors/prod/GoogleService-Info.plist" ]; then
        cp "${PROJECT_DIR}/flavors/prod/GoogleService-Info.plist" "${PLIST_DEST}"
        echo "Successfully copied prod plist."
    else
        echo "Error: File not found at ${PROJECT_DIR}/flavors/prod/GoogleService-Info.plist"
        exit 1
    fi
    ;;
  *)
    echo "No matching GoogleService-Info.plist for bundle id: ${PRODUCT_BUNDLE_IDENTIFIER}"
    exit 1
    ;;
esac

