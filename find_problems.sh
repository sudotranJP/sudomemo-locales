#!/bin/bash

echo "# Untranslated (or identical) strings"

# you can pass a langcode to filter by language
# We exclude English variations from this
# e.g ./find_untranslated.sh ja_JP

if [ ! -z $1 ]; then
    LANGFILTER=$1
else
    LANGFILTER="."
fi

for lang in $(echo ??_?? | tr ' ' '\n' | grep -v "en_" | grep $LANGFILTER); do
    echo "## $lang"
    echo
    for domain in $(ls en_US/LC_MESSAGES/*.po | xargs -L1 basename); do

        # Missing locale file?
        if [ ! -f $lang/LC_MESSAGES/$domain ]; then
            echo "Error: $lang/LC_MESSAGES/$domain is missing"
            exit 1
        fi

        # Wrong text encoding?

        CHECK_ENCODING=$(file $lang/LC_MESSAGES/$domain | egrep -v "(UTF-8|ASCII|empty)")

        if [ ! -z "$CHECK_ENCODING" ]; then
            echo "$lang/LC_MESSAGES/$domain has wrong encoding: should be detected as UTF-8, ASCII, or empty"
            file $lang/LC_MESSAGES/$domain
            exit 1
        fi

        # Missing/extra strings?

        ENG_MSGID_LIST=$(grep -Po "^msgid..\K.+?(?=\")" en_US/LC_MESSAGES/$domain | sort | uniq)
        NEW_MSGID_LIST=$(grep -Po "^msgid..\K.+?(?=\")" $lang/LC_MESSAGES/$domain | sort | uniq)

        COMPARE_MISSING=$(comm -23 <(echo "$ENG_MSGID_LIST") <(echo "$NEW_MSGID_LIST"))
        COMPARE_EXTRA=$(comm -23 <(echo "$NEW_MSGID_LIST") <(echo "$ENG_MSGID_LIST"))

        if [ ! -z $COMPARE_MISSING ]; then
            echo "$lang/LC_MESSAGES/$domain is missing msgid's present in en_US/LC_MESSAGES/$domain :"
            echo "$COMPARE_MISSING"
            exit 1
        fi

        if [ ! -z $COMPARE_EXTRA ]; then
            echo "$lang/LC_MESSAGES/$domain has extra msgid's compared to en_US/LC_MESSAGES/$domain :"
            echo "$COMPARE_EXTRA"
            exit 1
        fi

        # Untranslated strings?

        RESULTS=$(diff --unchanged-line-format='%L' --old-line-format='' --new-line-format='' en_US/LC_MESSAGES/$domain $lang/LC_MESSAGES/$domain | sed '/^$/d' | grep -B1 msgstr | grep -Po "^msgid..\K.+?(?=\")" | awk '{print "- " $1}')
        if [ ! -z "$RESULTS" ]; then
            echo "$lang/LC_MESSAGES/$domain:"
            echo "$RESULTS"
            echo
        fi
    done
done
