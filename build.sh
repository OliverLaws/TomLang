mkdir -p build
for F in src/*.asm src/*/*.asm; do
    nasm -f win64 -i src/ -i src/compiler/ "$F" -o "build/$(basename "$F" .asm).obj" || exit 1
done
ICON=""
if command -v windres > /dev/null; then
    windres assets/tomlang.rc -O coff -o build/icon.res && ICON="build/icon.res"
fi
gcc build/*.obj $ICON -o build/tomlang.exe -nostdlib -e Start -lkernel32 -Wl,--stack,8388608
