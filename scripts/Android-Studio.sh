#!/bin/bash
aurhelper=$1

# Install Android Studio and dependencies required
$aurhelper -S --noconfirm android-studio android-tools android-sdk-cmdline-tools-latest android-sdk-build-tools android-sdk-platform-tools android-emulator
