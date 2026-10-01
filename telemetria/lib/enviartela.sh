cd /home/arariboia/display
flutter build linux --debug
cp build/linux/arm64/debug/bundle/data/flutter_assets/kernel_blob.bin build/linux/arm64/debug/bundle/
flutter-pi build/linux/arm64/debug/bundle/