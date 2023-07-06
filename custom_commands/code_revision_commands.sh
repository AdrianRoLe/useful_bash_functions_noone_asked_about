function check_for_bs_in_staged_changes() {
    staged_changes_raw=$(git diff --cached --name-only)
    staged_changes=($(echo "$staged_changes_raw" | tr '\n' '\n'))
    
    # check if $1 is set to "-y"
    if [[ "$1" == "-y" ]]; then
        always_yes="y"
    else
        always_yes="n"
    fi
    
    for staged_change in "${staged_changes[@]}"; do
        if [ ! -f "$staged_change" ]; then
            echo "File $staged_change does not exist"
            return 1
        fi
        matches_to_remove=("console.log" "var_dump" "debugger" "error_log")
        
        for staged_change in $staged_changes; do
            for match_to_remove in "${matches_to_remove[@]}"; do
                echo -n "Checking for $match_to_remove in $staged_change"
                grep_and_remove_for_staging $match_to_remove $staged_change $always_yes
            done
        done
    done
    
    return 0
}

function grep_and_remove_for_staging() {
    # check if file exists
    if [ ! -f "$2" ]; then
        echo "File $2 does not exist"
        return 1
    fi
    
    changes=$(git diff --cached $2)
    matches=$(echo "$changes" | grep -n "$1")
    
    # check if there are any matches
    if [ -z "$matches" ]; then
        echo "-->No $1 found in $2"
    else
        echo "-->Found $1:"
        echo "--->$matches<----"
        
        if [[ "$3" == "n" ]]; then
            echo -n "--->Remove $1? (y/n) "
            read remove_matches
            if [[ $remove_matches == "y" ]]; then
                delete_line_in_file_and_stash $1 $2
            fi
        else
            delete_line_in_file_and_stash $1 $2
        fi
    fi
    
    return 0
}

function delete_line_in_file_and_stash() {
    # delete line with match, only if it is from the staged changes
    changes=$(git diff --cached $2)
    matches=$(echo "$changes" | grep -n "$1")
    
    # delete line with match (ex: 17:+    console.log("test"); -> coincidence=console.log("test");)
    for match in $matches; do
        coincidence_string=$(echo "$match" | cut -d ':' -f2)
        coincidence="${coincidence_string:1}"
        echo "--->Deleting $coincidence from $2"
        sed -i "/$coincidence/d" $2
    done
    
    # add file to stash
    git add $2
}