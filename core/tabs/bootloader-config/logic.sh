#!/bin/sh
# Core logic for bootloader agnostic operations


select_params() {
    options="$1"
    params="$2"

    set -- $options
    option_count=$#
    option_args="$@"

    set -- $params
    param_count=$#
    param_args="$@"

    if [ "$option_count" -ne "$param_count" ]; then
        print_error "Mismatch between number of options and parameters."
        return 1
    fi

    echo "Enter the numbers (separated by spaces):"
    read -r selected_options

    for selected in $selected_options; do
        found=false
        for option in $option_args; do
            if [ "$option" = "$selected" ]; then
                found=true
                break
            fi
        done

        if $found; then
            index=1
            for opt in $option_args; do
                if [ "$opt" = "$selected" ]; then
                    break
                fi
                index=$((index + 1))
            done

            i=1
            for param in $param_args; do
                if [ "$i" -eq "$index" ]; then
                    param_to_add=$param
                    break
                fi
                i=$((i + 1))
            done

            print_info "Adding parameter: $param_to_add"
            bootlogic_add_param "$param_to_add"
        else
            print_error "Invalid selection: $selected"
        fi
    done
}
