#!/usr/bin/env bash

# Run from the project folder (containing the game.project)

set -e

PROJECT=defold-spine

if [ "" == "${BOB}" ]; then
    BOB=${DYNAMO_HOME}/share/java/bob.jar
fi

echo "Using BOB=${BOB}"

if [ "" == "${DEFOLDSDK}" ]; then
    DEFOLDSDK=$(java -jar $BOB --version | awk '{print $5}')
fi

echo "Using DEFOLDSDK=${DEFOLDSDK}"

if [ "" == "${SERVER}" ]; then
    SERVER=https://build-stage.defold.com
fi
#SERVER=http://localhost:9000

echo "Using SERVER=${SERVER}"

if [ "" == "${VARIANT}" ]; then
    VARIANT=headless
fi

echo "Using VARIANT=${VARIANT}"

TARGET_DIR=./$PROJECT/plugins
mkdir -p $TARGET_DIR

function copyfile() {
    local path=$1
    local folder=$2
    if [ -f "$path" ]; then
        if [ ! -d "$folder" ]; then
            mkdir -v -p $folder
        fi
        cp -v $path $folder
    fi
}

function copy_results() {
    local platform=$1
    local platform_ne=$2

    # Copy the .jar files
    for path in ./build/$platform_ne/$PROJECT/*.jar; do
        copyfile $path $TARGET_DIR/share
    done

    # Copy the files to the target folder
    for path in ./build/$platform_ne/$PROJECT/*.dylib; do
        copyfile $path $TARGET_DIR/lib/$platform_ne
    done

    for path in ./build/$platform_ne/$PROJECT/*.so; do
        copyfile $path $TARGET_DIR/lib/$platform_ne
    done

    for path in ./build/$platform_ne/$PROJECT/*.dll; do
        copyfile $path $TARGET_DIR/lib/$platform_ne
    done
}


function build_plugin() {
    local platform=$1
    local platform_ne=$2

    java -jar $BOB --platform=$platform build --build-artifacts=plugins --variant $VARIANT --build-server=$SERVER --defoldsdk=$DEFOLDSDK

    copy_results $platform $platform_ne
}


PLATFORMS=$1
if [ "" == "${PLATFORM}" ]; then
    PLATFORMS="x86_64-macos x86_64-linux x86_64-win32"
fi

if [[ $# -gt 0 ]] ; then
    PLATFORMS="$*"
fi

echo "Building ${PLATFORMS}"

for platform in $PLATFORMS; do

    platform_ne=$platform

    if [ "$platform" == "x86_64-macos" ]; then
        platform_ne="x86_64-osx"
    fi

    build_plugin $platform $platform_ne
done

if command -v tree >/dev/null 2>&1; then
    # The tree command is available. Use it.
    tree $TARGET_DIR
else
    # We don't have tree. Approximate its output using find and sed.
    find $TARGET_DIR -print | sed -e "s;[^/]*/;|-- ;g;s;-- |;   |;g"
fi
