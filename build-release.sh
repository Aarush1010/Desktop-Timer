#!/bin/bash

# TimerApp Release Build Script
# Builds, signs, notarizes, and packages a SwiftPM macOS app

set -e  # Exit on any error

# =============================================================================
# CONFIGURATION VARIABLES - UPDATE THESE FOR YOUR PROJECT
# =============================================================================

# App configuration
APP_NAME="TimerApp"
BUNDLE_ID="com.yourcompany.TimerApp"  # Update with your bundle ID
VERSION="1.0.0"

# Code signing configuration
DEVELOPER_TEAM_ID="YOUR_TEAM_ID_HERE"  # 10-character Team ID from Apple Developer
SIGNING_IDENTITY="Developer ID Application: Your Name (${DEVELOPER_TEAM_ID})"  # Update with your identity
INSTALLER_IDENTITY="Developer ID Installer: Your Name (${DEVELOPER_TEAM_ID})"  # For installer signing

# Notarization configuration
APPLE_ID="your-apple-id@example.com"  # Update with your Apple ID
APP_SPECIFIC_PASSWORD="your-app-specific-password"  # Create at appleid.apple.com
TEAM_ID="${DEVELOPER_TEAM_ID}"  # Same as above

# Build configuration
BUILD_DIR=".build"
RELEASE_DIR="${BUILD_DIR}/release"
ARCHIVE_PATH="${RELEASE_DIR}/${APP_NAME}.xcarchive"
APP_PATH="${RELEASE_DIR}/${APP_NAME}.app"
DMG_PATH="${RELEASE_DIR}/${APP_NAME}.dmg"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log() {
    echo "🔵 [$(date '+%H:%M:%S')] $1"
}

error() {
    echo "🔴 [$(date '+%H:%M:%S')] ERROR: $1" >&2
    exit 1
}

success() {
    echo "✅ [$(date '+%H:%M:%S')] $1"
}

check_requirements() {
    log "Checking requirements..."
    
    # Check if we're on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This script must be run on macOS"
    fi
    
    # Check for required tools
    command -v swift >/dev/null 2>&1 || error "Swift not found. Install Xcode."
    command -v codesign >/dev/null 2>&1 || error "codesign not found. Install Xcode."
    command -v xcrun >/dev/null 2>&1 || error "xcrun not found. Install Xcode."
    command -v create-dmg >/dev/null 2>&1 || error "create-dmg not found. Install with: brew install create-dmg"
    
    # Check signing identity
    if ! security find-identity -v -p codesigning | grep -q "${SIGNING_IDENTITY}"; then
        error "Signing identity not found: ${SIGNING_IDENTITY}"
    fi
    
    success "All requirements met"
}

clean_build() {
    log "Cleaning previous builds..."
    rm -rf "${BUILD_DIR}"
    mkdir -p "${RELEASE_DIR}"
    success "Build directory cleaned"
}

build_app() {
    log "Building ${APP_NAME} in release mode..."
    
    # Build with SwiftPM
    swift build -c release --arch arm64 --arch x86_64
    
    # Create app bundle structure
    mkdir -p "${APP_PATH}/Contents/MacOS"
    mkdir -p "${APP_PATH}/Contents/Resources"
    
    # Copy executable
    cp ".build/release/${APP_NAME}" "${APP_PATH}/Contents/MacOS/"
    
    # Create Info.plist
    cat > "${APP_PATH}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>Timer App</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Timer App uses Apple Events for global hotkey functionality.</string>
    <key>NSSystemAdministrationUsageDescription</key>
    <string>Timer App needs system administration access for global hotkeys.</string>
</dict>
</plist>
EOF
    
    success "App built successfully"
}

sign_app() {
    log "Signing ${APP_NAME}..."
    
    # Sign all binaries and frameworks recursively
    find "${APP_PATH}" -name "*.dylib" -o -name "*.framework" -o -name "*.app" | while read file; do
        if [[ -f "$file" ]]; then
            log "Signing: $file"
            codesign --force --verify --verbose --sign "${SIGNING_IDENTITY}" --options runtime "$file"
        fi
    done
    
    # Sign the main app
    codesign --force --verify --verbose --sign "${SIGNING_IDENTITY}" --options runtime "${APP_PATH}"
    
    # Verify signature
    codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
    spctl -a -t exec -vv "${APP_PATH}"
    
    success "App signed successfully"
}

create_archive() {
    log "Creating archive for notarization..."
    
    # Create a zip archive for notarization
    NOTARIZE_ZIP="${RELEASE_DIR}/${APP_NAME}-notarize.zip"
    cd "${RELEASE_DIR}"
    zip -r "$(basename "${NOTARIZE_ZIP}")" "$(basename "${APP_PATH}")"
    cd - > /dev/null
    
    success "Archive created: ${NOTARIZE_ZIP}"
}

submit_for_notarization() {
    log "Submitting to Apple for notarization..."
    
    NOTARIZE_ZIP="${RELEASE_DIR}/${APP_NAME}-notarize.zip"
    
    # Submit for notarization
    SUBMISSION_ID=$(xcrun notarytool submit "${NOTARIZE_ZIP}" \
        --apple-id "${APPLE_ID}" \
        --password "${APP_SPECIFIC_PASSWORD}" \
        --team-id "${TEAM_ID}" \
        --wait \
        --output-format json | jq -r '.id')
    
    if [[ -z "${SUBMISSION_ID}" || "${SUBMISSION_ID}" == "null" ]]; then
        error "Failed to get submission ID from notarization"
    fi
    
    log "Submission ID: ${SUBMISSION_ID}"
    
    # Wait for notarization to complete
    log "Waiting for notarization to complete..."
    xcrun notarytool wait "${SUBMISSION_ID}" \
        --apple-id "${APPLE_ID}" \
        --password "${APP_SPECIFIC_PASSWORD}" \
        --team-id "${TEAM_ID}"
    
    # Check status
    STATUS=$(xcrun notarytool info "${SUBMISSION_ID}" \
        --apple-id "${APPLE_ID}" \
        --password "${APP_SPECIFIC_PASSWORD}" \
        --team-id "${TEAM_ID}" \
        --output-format json | jq -r '.status')
    
    if [[ "${STATUS}" != "Accepted" ]]; then
        error "Notarization failed with status: ${STATUS}"
    fi
    
    success "Notarization completed successfully"
}

staple_app() {
    log "Stapling notarization to app..."
    
    xcrun stapler staple "${APP_PATH}"
    xcrun stapler validate "${APP_PATH}"
    
    success "App stapled successfully"
}

create_dmg() {
    log "Creating DMG installer..."
    
    # Remove existing DMG
    rm -f "${DMG_PATH}"
    
    # Create DMG with create-dmg
    create-dmg \
        --volname "${APP_NAME}" \
        --volicon "${APP_PATH}/Contents/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 800 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 200 190 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 600 185 \
        --disk-image-size 100 \
        "${DMG_PATH}" \
        "${RELEASE_DIR}"
    
    success "DMG created: ${DMG_PATH}"
}

sign_dmg() {
    log "Signing DMG..."
    
    codesign --force --verify --verbose --sign "${SIGNING_IDENTITY}" "${DMG_PATH}"
    
    success "DMG signed successfully"
}

verify_final_product() {
    log "Verifying final product..."
    
    # Verify app
    codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
    spctl -a -t exec -vv "${APP_PATH}"
    
    # Verify DMG
    codesign --verify --deep --strict --verbose=2 "${DMG_PATH}"
    spctl -a -t open --context context:primary-signature -v "${DMG_PATH}"
    
    success "All verifications passed"
}

print_summary() {
    echo ""
    echo "🎉 BUILD COMPLETE!"
    echo "=================="
    echo "App: ${APP_PATH}"
    echo "DMG: ${DMG_PATH}"
    echo "Size: $(du -h "${DMG_PATH}" | cut -f1)"
    echo ""
    echo "The app is now ready for distribution!"
}

# =============================================================================
# MAIN SCRIPT EXECUTION
# =============================================================================

main() {
    log "Starting ${APP_NAME} release build process..."
    
    check_requirements
    clean_build
    build_app
    sign_app
    create_archive
    submit_for_notarization
    staple_app
    create_dmg
    sign_dmg
    verify_final_product
    print_summary
}

# Show usage if no arguments or help requested
if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
    cat << EOF
${APP_NAME} Release Build Script

Usage: $0 [options]

This script will:
1. Build the app in release mode
2. Code sign the app
3. Submit for notarization
4. Staple the notarization
5. Create a signed DMG

Before running, update these variables in the script:
- DEVELOPER_TEAM_ID
- SIGNING_IDENTITY
- INSTALLER_IDENTITY  
- APPLE_ID
- APP_SPECIFIC_PASSWORD
- BUNDLE_ID

Requirements:
- Xcode and command line tools
- Valid Developer ID certificates
- App-specific password for Apple ID
- create-dmg (brew install create-dmg)

Options:
  --help, -h    Show this help message

EOF
    exit 0
fi

# Run main function
main "$@"
