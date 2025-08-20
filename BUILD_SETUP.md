# TimerApp Release Build Setup

This document explains how to set up and use the release build script for TimerApp.

## Prerequisites

### 1. Apple Developer Account
- You need a paid Apple Developer account ($99/year)
- Download and install your Developer ID certificates in Keychain Access

### 2. Required Tools
```bash
# Install Homebrew if you haven't already
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install create-dmg
brew install create-dmg

# Install jq for JSON parsing
brew install jq
```

### 3. App-Specific Password
1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Go to "App-Specific Passwords"
4. Generate a new password for "TimerApp Notarization"
5. Save this password securely

## Setup Instructions

### 1. Configure Your Build Settings
```bash
# Copy the example config file
cp build-config.example.sh build-config.sh

# Edit the configuration with your details
nano build-config.sh
```

Update these required values:
- `DEVELOPER_TEAM_ID`: Your 10-character Team ID from Apple Developer
- `SIGNING_IDENTITY`: Replace "Your Name" with your certificate name
- `INSTALLER_IDENTITY`: Replace "Your Name" with your certificate name
- `BUNDLE_ID`: Your app's bundle identifier (e.g., com.yourcompany.TimerApp)
- `APPLE_ID`: Your Apple ID email address
- `APP_SPECIFIC_PASSWORD`: The app-specific password you generated

### 2. Find Your Team ID
```bash
# List your signing identities
security find-identity -v -p codesigning

# Or check your certificates in Keychain Access
open "/Applications/Utilities/Keychain Access.app"
```

### 3. Verify Your Certificate Name
Your signing identity should look like:
```
Developer ID Application: John Smith (ABC123DEFG)
```

## Usage

### Basic Build
```bash
# Run the build script
./build-release.sh
```

### Test Build (Skip Notarization)
```bash
# For testing, you can skip notarization
export SKIP_NOTARIZATION=true
./build-release.sh
```

### Build Process Steps

The script will:
1. ✅ **Clean** - Remove previous build artifacts
2. ✅ **Build** - Compile the app in release mode for both Intel and Apple Silicon
3. ✅ **Bundle** - Create proper macOS app bundle structure
4. ✅ **Sign** - Code sign the app with your Developer ID
5. ✅ **Archive** - Create ZIP archive for notarization
6. ✅ **Notarize** - Submit to Apple for notarization (can take 1-5 minutes)
7. ✅ **Staple** - Attach notarization ticket to the app
8. ✅ **Package** - Create signed DMG installer
9. ✅ **Verify** - Final verification of signatures

### Output Files

After successful build:
```
.build/release/
├── TimerApp.app          # Signed and notarized app
├── TimerApp.dmg          # Signed DMG installer
└── TimerApp-notarize.zip # Archive used for notarization
```

## Troubleshooting

### Common Issues

**"signing identity not found"**
```bash
# List available identities
security find-identity -v -p codesigning
```

**"create-dmg command not found"**
```bash
brew install create-dmg
```

**Notarization fails**
- Check your Apple ID and app-specific password
- Ensure your Team ID is correct
- Make sure you have an active Developer Program membership

**"No signing certificate found"**
1. Open Xcode
2. Go to Preferences → Accounts
3. Add your Apple ID
4. Download certificates

### Testing Your Build

```bash
# Test the signed app
open .build/release/TimerApp.app

# Test the DMG
open .build/release/TimerApp.dmg

# Verify signatures
codesign -vvv --deep --strict .build/release/TimerApp.app
spctl -a -t exec -vv .build/release/TimerApp.app
```

## Distribution

Once built successfully:
1. Test the app on a clean macOS system
2. Upload `TimerApp.dmg` to your website or distribution platform
3. Users can download and install without security warnings

## Security Notes

- Keep your app-specific password secure
- Never commit `build-config.sh` to version control
- The script automatically enables Hardened Runtime for security
- All binaries are signed with your Developer ID for trusted distribution
