#!/bin/bash

flutter build macos

mv ./build/macos/Build/Products/Release/zimo_web_photo_uploader.app build/macos/Build/Products/Release/Zimoura.app

appdmg ./packager/macos/appdmg-config.json ./build/macos/Build/Products/Release/Zimoura.dmg

rm -rf ./build/macos/Build/Products/Release/Zimoura.app
