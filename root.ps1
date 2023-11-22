# Download and install ADB if not already installed
try {
    # Check if ADB is installed
    if (!(Test-Path 'C:\Program Files (x86)\Android\android-sdk\platform-tools\adb.exe')) {
        # Download ADB installer
        $downloadUrl = 'https://dl.google.com/android/repository/platform-tools_latest-windows.zip'
        $downloadPath = Join-Path $env:TEMP 'platform-tools_latest-windows.zip'

        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath

        # Extract ADB files
        Expand-Archive -Path $downloadPath -DestinationPath $env:LOCALAPPDATA\Android\Sdk\platform-tools

        # Add ADB to PATH environment variable
        $adbPath = 'C:\Program Files (x86)\Android\android-sdk\platform-tools'
        $env:PATH = "$env:PATH;$adbPath"
    }
} catch {
    Write-Error "Error installing ADB: $($_.Exception)"
    exit
}

# Check if device is connected via USB
try {
    $deviceConnected = Test-Path 'C:\Program Files (x86)\Android\android-sdk\platform-tools\adb.exe devices'

    if (!$deviceConnected) {
        Write-Error "Device not connected via USB"
        exit
    }
} catch {
    Write-Error "Error checking device connection: $($_.Exception)"
    exit
}

# Check if developer mode is enabled
try {
    $adbOutput = adb shell pm list packages com.android.settings

    if ($adbOutput -notmatch 'com.android.settings') {
        Write-Error "Developer mode is not enabled"
        exit
    }
} catch {
    Write-Error "Error checking developer mode status: $($_.Exception)"
    exit
}

# Enable OEM unlocking
try {
    adb shell oem unlock
} catch {
    Write-Error "Error enabling OEM unlocking: $($_.Exception)"
    exit
}

# Unlock bootloader
try {
    fastboot oem unlock
} catch {
    Write-Error "Error unlocking bootloader: $($_.Exception)"
    exit
}

# Reboot device into fastboot mode
try {
    fastboot reboot bootloader
} catch {
    Write-Error "Error rebooting device into fastboot mode: $($_.Exception)"
    exit
}

# Root device using Magisk
try {
    adb push magisk.zip /sdcard/magisk.zip
    adb reboot bootloader
    fastboot flash boot magisk.img
    fastboot reboot
} catch {
    Write-Error "Error rooting device using Magisk: $($_.Exception)"
    exit
}

# Verify root access
try {
    $suResult = adb shell su -c 'echo $PATH'

    if ($suResult -notmatch '$PATH') {
        Write-Error "Root access not verified"
        exit
    }
} catch {
    Write-Error "Error verifying root access: $($_.Exception)"
    exit
}

Write-Output "OnePlus Pro 7 bootloader unlocked, rooted, OEM unlocked, and in fastboot mode"
