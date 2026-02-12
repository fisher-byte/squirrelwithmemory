#!/bin/bash
echo "1. Killing Squirrel..."
killall Squirrel 2>/dev/null
echo "2. Cleaning build..."
xcodebuild -project Squirrel.xcodeproj -configuration Release -scheme Squirrel clean
echo "3. Re-installing dependencies..."
bash action-install.sh
echo "4. Installing Squirrel to ~/Library/Input Methods..."
make install-debug
echo "Done! Please restart your computer or log out/log in if it does not appear."
