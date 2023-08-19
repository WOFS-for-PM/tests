#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")

TABLE_NAME="$ABS_PATH/performance-comparison-table-breakdown-fileserver"
table_create "$TABLE_NAME" "file_system file_bench threads iops stat open append create delete close read write IO"
mkdir -p "$ABS_PATH"/DATA

FILE_SYSTEMS=( "NOVA" "NOVA-RELAX" "PMFS" "KILLER" "SplitFS-FILEBENCH" "EXT4-DAX" "XFS-DAX" )
FILE_BENCHES=( "fileserver.f" )
THREADS=( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 )

for file_system in "${FILE_SYSTEMS[@]}"; do
    fbench="fileserver.f"
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
                create=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile1")
                delete=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "deletefile1")
                close1=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "closefile1")
                close2=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "closefile2")
                close3=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "closefile3")
                close=$(echo $close1 $close2 $close3 | awk '{print $1 + $2 + $3}')
                read=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile1")
                write=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "wrtfile1")
            ;;
        esac
        IO=$(echo $read $write | awk '{print $1 + $2}')
        table_add_row "$TABLE_NAME" "$file_system $fbench $thread $iops $stat $open $append $create $delete $close $read $write $IO"
    done
done