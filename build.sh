mkdir -p build
for F in src/*.asm; do
    nasm -f win64 -i src/ "$F" -o "build/$(basename "$F" .asm).obj" || exit 1
done
gcc build/*.obj -o build/tomlang.exe -nostdlib -e Start -lkernel32