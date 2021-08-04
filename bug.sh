TOOLCHAIN=/Library/Developer/Toolchains/swift-wasm-DEVELOPMENT-SNAPSHOT-2021-03-10-a.xctoolchain
rm -f TokamakCore.o
$TOOLCHAIN/usr/bin/swift-frontend -frontend -c -filelist ./filelist -target wasm32-unknown-wasi \
  -disable-objc-interop -sdk $TOOLCHAIN/usr/share/wasi-sysroot \
  -color-diagnostics -g  -swift-version 5 -O -D SWIFT_PACKAGE -parse-as-library \
  -module-name TokamakCore -num-threads 8 -use-static-resource-dir
