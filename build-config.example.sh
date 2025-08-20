# TimerApp Build Configuration
# Copy this file to build-config.sh and update with your values

# App Information
export APP_NAME="TimerApp"
export BUNDLE_ID="com.yourcompany.TimerApp"  # Update with your bundle ID
export VERSION="1.0.0"

# Developer Information
export DEVELOPER_TEAM_ID="YOUR_TEAM_ID_HERE"  # 10-character Team ID from Apple Developer
export SIGNING_IDENTITY="Developer ID Application: Your Name (YOUR_TEAM_ID_HERE)"
export INSTALLER_IDENTITY="Developer ID Installer: Your Name (YOUR_TEAM_ID_HERE)"

# Notarization Information  
export APPLE_ID="your-apple-id@example.com"  # Your Apple ID email
export APP_SPECIFIC_PASSWORD="your-app-specific-password"  # Generate at appleid.apple.com
export TEAM_ID="YOUR_TEAM_ID_HERE"  # Same as DEVELOPER_TEAM_ID

# Build Settings
export BUILD_UNIVERSAL=true  # Build for both Intel and Apple Silicon
export CREATE_INSTALLER=true  # Create PKG installer in addition to DMG
export SKIP_NOTARIZATION=false  # Set to true for testing builds
