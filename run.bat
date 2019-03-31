@echo off

SetLocal

:: file name directory
if "%1" == "" (
    echo run [all ^| system ^| vendor ^| boot ^| context] rom.zip
    goto end
)
if "%~x2" neq ".zip" (
    echo not a zip archive
    exit
)
if not exist "%2" (
    echo file not exists
    goto end
)
set name=%~x2
set pwd=%cd%
set tool=%~dp0
goto %1

:vendor
:: vendor with brotli compress
if not exist "%name%/vendor.img" (
    if exist "%name%/vendor.new.dat.br" (
        :: oreo 8.0~
        echo "decompress..."
        brotli.exe --decompress "%name%/vendor.new.dat.br" --out "%name%/vendor.new.dat"
    )
)
:: extract vendor if exists
if not exist "%name%/vendor.img" (
    if exist "%name%/vendor.new.dat" (
        :: convert to img
        python3 "%tool%/sdat2img/sdat2img.py" "%name%/vendor.transfer.list" "%name%/vendor.new.dat" "%name%/vendor.img"
    )
)
:: extract folder if exists
if exist "%name%/vendor.img" (
    :: extract to file
    echo "extract to file..."
    rmdir /s "%name%/vendor"
    python3 "%tool%/ext4extract/ext4extract.py" -D "%name%/vendor" "%name%/vendor.img"
)
goto end

:system
:: system with brotli compress
if not exist "%name%/system.img" (
    if exist "%name%/system.new.dat.br" (
        :: oreo 8.0~
        echo "decompress..."
        brotli.exe --decompress "%name%/system.new.dat.br" --out "%name%/system.new.dat"
    )
)
:: extract system if exists
if not exist "%name%/system.img" (
    if exist "%name%/system.new.dat" (
        :: convert to img
        python3 "%tool%/sdat2img/sdat2img.py" "%name%/system.transfer.list" "%name%/system.new.dat" "%name%/system.img"
    )
)
:: extract folder if exists
if exist "%name%/system.img" (
    :: extract to file
    echo "extract to file..."
    rmdir /s "%name%/system"
    python3 "%tool%/ext4extract/ext4extract.py" -D "%name%/system" "%name%/system.img"
)
goto end

:boot
:: extract boot if exists
if exist "%name%/boot.img" (
    if not exist "%name%/boot" (
       mkdir "%name%/boot"
       mkdir "%name%/boot/root"
    )
    else (
        rmdir "%name%/boot/*"
        mkdir "%name%/boot/root"
    )
    echo "unpackbootimg..."
    python3 "%tool%/droidtools/droidtools/unpackbootimg.py" -i "%name%/boot.img" -o "%name%/boot"
    move "%name%/boot/boot.img-ramdisk.gz" "%name%/boot/root/boot.img-ramdisk.gz"
    cd "%name%/boot/root"
    busybox64.exe gzip -dc "boot.img-ramdisk.gz" | busybox64.exe cpio -i
    del "boot.img-ramdisk.gz"
	cd %pwd%
)
goto end

:context
if exist "%name%/file_contexts.bin" (
    python3 "%tool%/sefcontext-parser/sefcontext_parser/sefcontext_parser.py" "%name%/file_contexts.bin" -o "%name%/file_contexts"
)
goto end

:end

EndLocal