#! /bin/bash

main() {
    echo "Enter a color number to get a sample and translation,"
    echo "'g' and 0-23 for grey, or 'c' and three numbers 0-5 for color."
    echo -n '> '
    while read line
    do
        case "$line" in
            'g '*)
                handle_grey "${line#'g '}"
                ;;
            'c '*)
                handle_color "${line#'c '}"
                ;;
            *)
                handle_code "$line"
                ;;
        esac
        echo -n '> '
    done
    echo
}

handle_grey() {
    num="$1"
    if test "$num" -gt 23
    then
        echo "'$num' isn't between 0 and 23."
    else
        code=$(( num + 232 ))
        tput setaf $code
        echo "Grey '$num' is $code."
        tput sgr0
    fi
}

handle_color() {
    set -- $1
    r=$1 ; g=$2 ; b=$3
    for c in $r $g $b
    do
        if test "$c" -gt 5
        then
            echo 'Must be between 0 and 5.'
            return
        fi
    done

    code=$(( 16 + 36 * r + 6 * g + b ))
    tput setaf $code
    echo "rgb($r/$g/$b) is $code."
    tput sgr0
}

handle_code() {
    code="$1"
    tput setaf "$code"
    echo -n "Color number $code is"

    if test "$code" -lt 16
    then
        adjust="$code"
        if test "$code" -eq 0
        then
            echo 'grey.'
        else
            if test "$code" -ge 9
            then
                echo -n ' light'
                adjust=$(( code - 8  ))
            fi
            case "$adjust" in
                0) echo ' black.' ;;
                1) echo ' red.' ;;
                2) echo ' green.' ;;
                3) echo ' yellow.' ;;
                4) echo ' blue.' ;;
                5) echo ' turquoise.' ;;
                6) echo ' magenta.' ;;
                7) echo ' white.' ;;
            esac
        fi
    elif test "$code" -lt 232
    then
        adjust=$(( code - 16 ))
        echo " rgb($(( adjust / 36 ))/$(( adjust % 36 / 6 ))/$(( adjust % 6 )))."
    else
        echo " grey shade $(( code - 232 ))."
    fi
    tput sgr0
}

main
