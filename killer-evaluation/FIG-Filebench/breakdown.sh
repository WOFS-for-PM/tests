#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")

TABLE_NAME_FILESERVER="$ABS_PATH/performance-comparison-table-breakdown-fileserver"
table_create "$TABLE_NAME_FILESERVER" "file_system file_bench threads iops stat open append create delete close read write IO"

TABLE_NAME_VARMAIL="$ABS_PATH/performance-comparison-table-breakdown-varmail"
table_create "$TABLE_NAME_VARMAIL" "file_system file_bench threads iops open append create delete close read IO"

TABLE_NAME_WEBSERVER="$ABS_PATH/performance-comparison-table-breakdown-webserver"
table_create "$TABLE_NAME_WEBSERVER" "file_system file_bench threads iops open append read IO"

TABLE_NAME_WEBPROXY="$ABS_PATH/performance-comparison-table-breakdown-webproxy"
table_create "$TABLE_NAME_WEBPROXY" "file_system file_bench threads iops open append create delete read IO"

mkdir -p "$ABS_PATH"/DATA

FILE_SYSTEMS=( "NOVA" "NOVA-RELAX" "PMFS" "KILLER" "SplitFS-FILEBENCH" "EXT4-DAX" "XFS-DAX" )
FILE_BENCHES=( "fileserver.f" "varmail.f" "webserver.f" "webproxy.f" )
THREADS=( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 )

for file_system in "${FILE_SYSTEMS[@]}"; do
    for fbench in "${FILE_BENCHES[@]}"; do
        for thread in "${THREADS[@]}"; do
            iops=$(filebench_attr_iops "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread")
            # Retreive the breakdown
            case "${fbench}" in
                "fileserver.f")
                    stat=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "statfile1")
                    open1=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile1")
                    open2=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile2")
                    open=$(echo $open1 $open2 | awk '{print $1 + $2}')
                    append=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "appendfilerand1")
                    create=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "createfile1")
                    delete=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "deletefile1")
                    close1=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "closefile1")
                    close2=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "closefile2")
                    close3=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "closefile3")
                    close=$(echo $close1 $close2 $close3 | awk '{print $1 + $2 + $3}')
                    read=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile1")
                    write=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "wrtfile1")
                    IO=$(echo $read $write | awk '{print $1 + $2}')
                    table_add_row "$TABLE_NAME_FILESERVER" "$file_system $fbench $thread $iops $stat $open $append $create $delete $close $read $write $IO"
                ;;
                "varmail.f")
                    open3=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile3")
                    open4=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile4")
                    open=$(echo $open3 $open4 | awk '{print $1 + $2}')
                    append2=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "appendfilerand2")
                    append3=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "appendfilerand3")
                    append=$(echo $append2 $append3 | awk '{print $1 + $2}')
                    create=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "createfile2")
                    delete=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "deletefile1")
                    close2=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "closefile2")
                    close3=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "closefile3")
                    close4=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "closefile4")
                    close=$(echo $close2 $close3 $close4 | awk '{print $1 + $2 + $3}')
                    read3=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile3")
                    read4=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile4")
                    read=$(echo $read3 $read4 | awk '{print $1 + $2}')  
                    IO=$read
                    table_add_row "$TABLE_NAME_VARMAIL" "$file_system $fbench $thread $iops $open $append $create $delete $close $read $IO"
                ;;
                "webserver.f")
                    open1=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile1")
                    open2=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile2")
                    open3=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile3")
                    open4=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile4")
                    open5=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile5")
                    open6=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile6")
                    open7=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile7")
                    open8=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile8")
                    open9=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile9")
                    open10=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile10")
                    open=$(echo $open1 $open2 $open3 $open4 $open5 $open6 $open7 $open8 $open9 $open10 | awk '{print $1 + $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9 + $10}')
                    append=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "appendlog")
                    read1=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile1")
                    read2=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile2")
                    read3=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile3")
                    read4=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile4")
                    read5=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile5")
                    read6=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile6")
                    read7=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile7")
                    read8=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile8")
                    read9=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile9")
                    read10=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile10")
                    read=$(echo $read1 $read2 $read3 $read4 $read5 $read6 $read7 $read8 $read9 $read10 | awk '{print $1 + $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9 + $10}')
                    IO=$read
                    table_add_row "$TABLE_NAME_WEBSERVER" "$file_system $fbench $thread $iops $open $append $read $IO"
                ;;
                "webproxy.f")
                    open2=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile2")
                    open3=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile3")
                    open4=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile4")
                    open5=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile5")
                    open6=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile6")
                    open=$(echo $open2 $open3 $open4 $open5 $open6 | awk '{print $1 + $2 + $3 + $4 + $5}')
                    append=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "appendfilerand1")
                    create=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "createfile1")
                    delete=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "deletefile1")
                    read2=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile2")
                    read3=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile3")
                    read4=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile4")
                    read5=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile5")
                    read6=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile6")
                    read=$(echo $read2 $read3 $read4 $read5 $read6 | awk '{print $1 + $2 + $3 + $4 + $5}')
                    IO=$read
                    table_add_row "$TABLE_NAME_WEBPROXY" "$file_system $fbench $thread $iops $open $append $create $delete $read $IO"
                ;;
            esac
        done
    done
done