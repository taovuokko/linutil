#!/bin/sh

backup_grub() {
    cp "$grub_file" "$backup_file"
    print_success "GRUB file backed up to $backup_file."
}

restore_grub() {
    if [ -f "$backup_file" ]; then
        cp "$backup_file" "$grub_file"
        print_success "GRUB file restored from backup."
    else
        print_warning "No backup file found."
    fi
}

validate_parameter() {
    param="$1"
    max_length=50

    if [ "${#param}" -gt "$max_length" ]; then
        print_error "Parameter exceeds the maximum length of $max_length characters."
        return 1
    fi

    if ! echo "$param" | grep -Eq '^[a-zA-Z0-9=_-]+$'; then
        print_error "Parameter contains invalid characters. Allowed are letters, digits, '=', '-', and '_'."
        return 1
    fi

    return 0
}
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
    read selected_options

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
