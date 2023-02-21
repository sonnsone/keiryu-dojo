#!/bin/bash

DIRS=($(find . -type d))

START_DIR=$(pwd)

BEFORE=$(du -hs .)

RENAMED=()

for dir in "${DIRS[@]}"; do
    echo "Entering $dir"
    cd $dir

    files=$(ls *.jpg 2> /dev/null | wc -l)
    if [ "$files" != "0" ]; then
        for i in *.jpg; do
            OPAQUE=$(identify -format '%[opaque]' $i)
            if [ "$OPAQUE" == "true" ]; then
                echo "Converting $i to JPG as it has no transparency"
                iJPG=${i/png/jpg}
                convert "$i" "$iJPG"
                git rm -f $i
                git add $iJPG
            else
                echo "Optimizing $i"
                optipng -silent -o7 -zm1-9 -strip all $i
                zopflipng --prefix=toto --lossy_transparent -m $i
            fi
        done
    fi

    files=$(ls *.jpg 2> /dev/null | wc -l)
    if [ "$files" != "0" ]; then
        for i in *.jpg; do
            echo "Optimizing $i"
            guetzli --quality 84 $i toto$i
        done
    fi

    files=$(ls toto* 2> /dev/null | wc -l)
    if [ "$files" != "0" ]; then
        for i in toto*; do
            mv "$i" "${i#toto}"
        done
    fi

    cd $START_DIR
done

AFTER=$(du -hs .)
echo "Results: $BEFORE -> $AFTER"

echo "Those files were renamed:"
printf '%s\n' "${RENAMED[@]}"
