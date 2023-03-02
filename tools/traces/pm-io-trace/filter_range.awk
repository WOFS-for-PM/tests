#!/bin/awk -f

BEGIN {
    print "Filter Range: " start "-" end
    ops="read"
}  

{
    if ($1 == "#" && index($6, "cpu/mem-stores/P") > 0) {
        ops="write"
    }

    if ($2 >= start && $2 <= end) {
        print ops ":" $0
    }
} 

END {
    print "Finished"
}