<!--
-*- mode: markdown; coding: utf-8; -*-
 vim: ft=markdown:sw=2:ts=2:et

 Time-stamp: "Last Modified 2023-03-13 16:40:42 by Gene De Lisa, genedelisa"

 File: Notes.md

 Gene De Lisa
 gene@rockhoppertech.com
 http://rockhoppertech.com/blog/
 License - http://unlicense.org
###############################################################################
-->

# Notes


## What


## References
Here's the [Apple docs directory][apple-docs] .


[apple-docs]:<https://developer.apple.com/documentation/technologies> "Apple documentation"

## Localization

Add the default to Package.swift
```
let package = Package(
    name: "m3ufrob",
    defaultLocalization: "en",
    platforms: [
```

Add localization comments.
         
Old: 
NSLocalizedString("Interval", comment: "for the polling command")

Current:
String(localized: "Input Directory.", comment: "DirView headline"),

```
sed -i '' 's/NSLocalizedString(/String(localized:/g' ./Sources/m3ufrob/Commands/TimerPublishCommand.swift     ─╯
```


[stack](https://stackoverflow.com/questions/63237395/generating-resource-bundle-accessor-type-bundle-has-no-member-module/66630000#66630000)

print $LANG                                                                                                   ─╯
en_US.UTF-8

Change to italian

locale -a
to list all locales

typeset -gx LANG=it_IT.ISO8859-15

or:

export LC_ALL=it_IT.ISO8859-15                                                                                ─╯

$ locale                                                                                                        ─╯

LANG="it_IT.ISO8859-15"
LC_COLLATE="it_IT.ISO8859-15"
LC_CTYPE="it_IT.ISO8859-15"
LC_MESSAGES="it_IT.ISO8859-15"
LC_MONETARY="it_IT.ISO8859-15"
LC_NUMERIC="it_IT.ISO8859-15"
LC_TIME="it_IT.ISO8859-15"
LC_ALL="it_IT.ISO8859-15"

    <key>CFBundleAllowMixedLocalizations</key>
    <true/>
        <key>CFBundleDevelopmentRegion</key>
    <string>en</string>



https://github.com/apple/swift-evolution/blob/main/proposals/0278-package-manager-localized-resources.md
https://developer.apple.com/documentation/xcode/importing-localizations
https://developer.apple.com/documentation/xcode-release-notes/xcode-14-release-notes



# Security-Scoped Bookmarks
https://onmyway133.com/posts/how-to-access-bookmark-url-in-macos/


https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html

https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html

https://benscheirman.com/2019/10/troubleshooting-appkit-file-permissions.html

https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html#//apple_ref/doc/uid/TP40010672-CH3-SW10

https://blog.krzyzanowskim.com/2019/12/05/url-bookmark-yes-and-no/


# File reading

 <key>NSDocumentsFolderUsageDescription</key>
        <string>To be able to read and write images in your Documents folder</string>

        <key>NSDesktopFolderUsageDescription</key>
        <string>To be able to read and write images from your Desktop</string>

        <key>NSDownloadsFolderUsageDescription</key>
        <string>To be able to read and write images in your Downloads folder</string>

        <key>NSNetworkVolumesUsageDescription</key>
        <string>To be able to read and write images on Network Volumes</string>

        <key>NSRemovableVolumesUsageDescription</key>
        <string>To be able to read and write images on removable media like USB-sticks and memeory cards</string>

<key>NSMicrophoneUsageDescription</key>
    <string>$(PRODUCT_NAME) DOES NOT need microphone permission. Please reject this request.</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>Allow $(PRODUCT_NAME) to save an image to your camera roll</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Allow $(PRODUCT_NAME) to access your camera roll to attach photos or videos to your toot</string>


    <key>NSAppleMusicUsageDescription</key>
    <string>Trinity does not require this permission for any functionality. This permission is solely listed in order to satisfy App Store requirements.</string>
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>Trinity does not require this permission for any functionality. This permission is solely listed in order to satisfy App Store requirements.</string>
    <key>NSCalendarsUsageDescription</key>
    <string>Trinity does not require this permission for any functionality. This permission is solely listed in order to satisfy App Store requirements.</string>
    <key>NSCameraUsageDescription</key>
    <string>Trinity requires access to the camera in order to enable QR scanning.</string>
    <key>NSFaceIDUsageDescription</key>
    <string>Trinity requires access to Face ID in order to enable biometric authentication.</string>
    <key>NSHumanReadableCopyright</key>
    <string>2018 IOTA Foundation. All rights reserved.</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>Trinity does not require this permission for any functionality. This permission is solely listed in order to satisfy App Store requirements.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Trinity does not require this permission for any functionality. This permission is solely listed in order to satisfy App Store requirements.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Trinity requires access to your microphone for camera functionality.</string>
    <key>NSMotionUsageDescription</key>
    <string>Trinity does not require this permission for any functionality. This permission is solely listed in order to satisfy App Store requirements.</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>Trinity requires access to your photo library in order to save QR codes to the camera roll.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Trinity does not require this permission for any functionality. This permission is solely listed in order to satisfy App Store requirements.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Trinity does not require this permission for any functionality. This permission is solely listed in order to satisfy App Store requirements.</string>
    <key>UIAppFonts</key>


https://datatracker.ietf.org/doc/html/rfc8216#section-4.3.2.1
