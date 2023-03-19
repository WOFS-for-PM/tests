#!/bin/awk -f

BEGIN {
    print "Filter Range: " start "-" end
    ops="read"
}  

{
    if (index($5, "cpu/mem-stores/P") > 0) {
        ops="write"
    } else {
        ops="read"
    }
    
    target="0x"$6

    if (target >= start && target <= end) {
        print ops ":" target
    }
} 

END {
    print "Finished"
}