#!/bin/bash

# TimerApp Unsigned Release Build Script
# Creates a distributable app without requiring Apple Developer Account

set -e  # Exit on any error

# =============================================================================
# CONFIGURATION
# =============================================================================

APP_NAME="TimerApp"
BUNDLE_ID="com.github.yourname.TimerApp"  # Use your GitHub username
VERSION="1.0.0"
BUILD_DIR=".build"
RELEASE_DIR="${BUILD_DIR}/release"
APP_PATH="${RELEASE_DIR}/${APP_NAME}.app"
ZIP_PATH="${RELEASE_DIR}/${APP_NAME}-v${VERSION}.zip"

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

clean_build() {
    log "Cleaning previous builds..."
    rm -rf "${BUILD_DIR}"
    mkdir -p "${RELEASE_DIR}"
    success "Build directory cleaned"
}

build_universal_app() {
    log "Building ${APP_NAME}..."
    
    # Build for release (will build for current architecture)
    swift build -c release
    
    success "App built successfully"
}

create_app_bundle() {
    log "Creating app bundle..."
    
    # Create app bundle structure
    mkdir -p "${APP_PATH}/Contents/MacOS"
    mkdir -p "${APP_PATH}/Contents/Resources"
    
    # Copy executable
    cp ".build/release/${APP_NAME}" "${APP_PATH}/Contents/MacOS/"
    
    # Make executable
    chmod +x "${APP_PATH}/Contents/MacOS/${APP_NAME}"
    
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
    <key>NSHumanReadableCopyright</key>
    <string>© $(date +%Y) Timer App. Open Source.</string>
</dict>
</plist>
EOF
    
    success "App bundle created"
}

create_zip() {
    log "Creating ZIP archive for distribution..."
    
    cd "${RELEASE_DIR}"
    zip -r "$(basename "${ZIP_PATH}")" "$(basename "${APP_PATH}")"
    cd - > /dev/null
    
    success "ZIP archive created: ${ZIP_PATH}"
}

create_installation_guide() {
    log "Creating installation guide..."
    
    cat > "${RELEASE_DIR}/INSTALL.txt" << EOF
TimerApp v${VERSION} - Installation Instructions
=============================================

🎉 Thanks for downloading TimerApp!

📋 INSTALLATION:
1. Unzip the downloaded file
2. Drag TimerApp.app to your Applications folder
3. Right-click on TimerApp.app and select "Open"
4. Click "Open" when macOS warns about the unsigned app
5. Grant accessibility permissions when prompted

⚠️  SECURITY NOTICE:
This app is not signed with an Apple Developer certificate, so macOS will show a security warning on first launch. This is normal for free/open-source apps.

🔐 TO BYPASS THE WARNING:
- Method 1: Right-click → "Open" (recommended)
- Method 2: System Settings → Privacy & Security → Click "Open Anyway"

✨ FEATURES:
- Multiple floating timers
- Auto-compact mode when running
- Global hotkeys (Cmd+Shift+T for new timer)
- Editable timer names
- Click to pause/resume
- Menu bar integration

🐛 ISSUES?
Report bugs at: https://github.com/yourusername/TimerApp/issues

💝 ENJOY YOUR TIMER APP!
EOF

    success "Installation guide created"
}

verify_app() {
    log "Verifying app bundle..."
    
    # Check if app can be launched
    if [[ ! -x "${APP_PATH}/Contents/MacOS/${APP_NAME}" ]]; then
        error "App executable is not executable"
    fi
    
    # Check bundle structure
    if [[ ! -f "${APP_PATH}/Contents/Info.plist" ]]; then
        error "Info.plist missing"
    fi
    
    success "App bundle verification passed"
}

print_summary() {
    echo ""
    echo "🎉 UNSIGNED BUILD COMPLETE!"
    echo "=========================="
    echo "App: ${APP_PATH}"
    echo "ZIP: ${ZIP_PATH}"
    echo "Size: $(du -h "${ZIP_PATH}" | cut -f1)"
    echo ""
    echo "📦 READY FOR DISTRIBUTION:"
    echo "- Upload ${ZIP_PATH} to GitHub Releases"
    echo "- Include INSTALL.txt instructions"
    echo "- Users will need to right-click → 'Open' on first launch"
    echo ""
    echo "🚀 Next steps:"
    echo "1. Test the app: open '${APP_PATH}'"
    echo "2. Create GitHub release with the ZIP file"
    echo "3. Add clear installation instructions"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log "Starting unsigned build for ${APP_NAME}..."
    
    clean_build
    build_universal_app
    create_app_bundle
    verify_app
    create_zip
    create_installation_guide
    print_summary
}

# Show usage
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << EOF
TimerApp Unsigned Build Script

This script creates a distributable macOS app without requiring
an Apple Developer account. The app will show security warnings
on first launch, but users can bypass them.

Usage: $0

Output: 
- .build/release/TimerApp.app (unsigned app)
- .build/release/TimerApp-v${VERSION}.zip (distribution archive)
- .build/release/INSTALL.txt (user instructions)

EOF
    exit 0
fi

main "$@"
