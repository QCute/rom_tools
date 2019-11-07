#!/bin/bash

## check brotli, gzip, cpio
type brotli > /dev/null 2>&1 || { echo >&2 "require brotli but it's not installed."; exit 1;}
type unzip > /dev/null 2>&1 || { echo >&2 "require unzip but it's not installed."; exit 1;}
type gzip > /dev/null 2>&1 || { echo >&2 "require gzip but it's not installed."; exit 1;}
type cpio > /dev/null 2>&1 || { echo >&2 "require cpio but it's not installed."; exit 1;}

## file name directory
if [ $# == 0 ];then
    echo "run [all | system | vendor | boot | context] rom.zip"
    exit
elif [ "${2##*.}" != "zip" ];then
    echo "not a zip archive"
    exit
elif [ ! -f "$2" ];then
    echo "file not exists"
    exit
fi

name=${2%.*}
tool=$(dirname ${BASH_SOURCE[0]})


vendor(){
    ## vendor with brotli compress
    if [ ! -f "$name/vendor.img" ] && [ -f "$name/vendor.new.dat.br" ];then
        # oreo 8.0~
        echo "decompress..."
        brotli -d "$name/vendor.new.dat.br" -o "$name/vendor.new.dat"
    fi;
    ## extract vendor if exists
    if [ ! -f "$name/vendor.img" ] && [ -f "$name/vendor.new.dat" ];then
        ## convert to img
        python3 "$tool/sdat2img/sdat2img.py" "$name/vendor.transfer.list" "$name/vendor.new.dat" "$name/vendor.img"
    fi;
    ## extract folder if exists
    if [ -f "$name/vendor.img" ];then
        ## extract to file
        echo "extract to file..."
        rm -rf "$name/vendor"
        python3 "$tool/ext4extract/ext4extract.py" -D "$name/vendor" "$name/vendor.img"
    fi;
}

system(){
    ## system with brotli compress
    if [ ! -f "$name/system.img" ] && [ -f "$name/system.new.dat.br" ];then
        # oreo 8.0~
        echo "decompress..."
        brotli -d "$name/system.new.dat.br" -o "$name/system.new.dat"
    fi;
    ## extract system if exists
    if [ ! -f "$name/system.img" ] && [ -f "$name/system.new.dat" ];then
        ## convert to img
        python3 "$tool/sdat2img/sdat2img.py" "$name/system.transfer.list" "$name/system.new.dat" "$name/system.img"
    fi;
    ## extract folder if exists
    if [ -f "$name/system.img" ];then
        ## extract to file
        echo "extract to file..."
        rm -rf "$name/system"
        python3 "$tool/ext4extract/ext4extract.py" -D "$name/system" "$name/system.img"
    fi;
}

boot(){
    ## extract boot if exists
    if [ -f "$name/boot.img" ];then
        if [ ! -d "$name/boot" ];then
           mkdir "$name/boot"
           mkdir "$name/boot/root"
        else
            rm -rf "$name/boot/*"
            mkdir "$name/boot/root"
        fi;
        echo "unpackbootimg..."
        python3 "$tool/droidtools/droidtools/unpackbootimg.py" -i "$name/boot.img" -o "$name/boot"
        mv "$name/boot/boot.img-ramdisk.gz" "$name/boot/root/boot.img-ramdisk.gz"
        cd "$name/boot/root"
        gzip -dc "boot.img-ramdisk.gz" | cpio -i
        rm "boot.img-ramdisk.gz"
        cd -
    fi
}

context(){
    if [ -f "$name/file_contexts.bin" ];then
        python3 "$tool/sefcontext-parser/sefcontext_parser/sefcontext_parser.py" "$name/file_contexts.bin" -o "$name/file_contexts"
    fi
}

all(){
    system
    vendor
    boot
    context
}

## check function
if [ "$(type -t $1)" != "function" ] ; then
    echo "unknown function"
    exit
fi

## unzip
if [ ! -d "$name" ];then
    unzip $2 -d $name
fi

# 调用函数
_CALL_FUNCTION(){
    $1
}

# 根据参数调用相应命令
_CALL_FUNCTION $@
