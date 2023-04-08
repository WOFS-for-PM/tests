function attr_meta_stats () {
    if grep -q "$1" "$2"; then
         grep -oP "(?<=$1:[[:space:]]{1})[0-9]+" "$2"
    else
        echo "Error: string: $1 not found in file"
    fi
}

function where_is_script() {
    local script=$1
    cd "$( dirname "$script" )" && pwd
}

#SECTION: TABLE
function table_create () {
    local TABLE_NAME
    local COLUMNS
    TABLE_NAME=$1
    COLUMNS=$2
    echo "$COLUMNS" >"$TABLE_NAME"
}

function table_add_row () {
    local TABLE_NAME
    local ROW
    TABLE_NAME=$1
    ROW=$2
    echo "$ROW" >> "$TABLE_NAME"
}
#!SECTION