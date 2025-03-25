#!/bin/sh
# GRUB parameter and config manipulation logic

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

init_grub_config() {
    grub_file="${grub_file:-/etc/default/grub}"
    backup_file="${backup_file:-/etc/default/grub.bak}"

    if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT" "$grub_file"; then
        grub_cmdline="GRUB_CMDLINE_LINUX_DEFAULT"
    elif grep -q "^GRUB_CMDLINE_LINUX" "$grub_file"; then
        grub_cmdline="GRUB_CMDLINE_LINUX"
    else
        print_error "Neither GRUB_CMDLINE_LINUX_DEFAULT nor GRUB_CMDLINE_LINUX was found in $grub_file."
        exit 1
    fi
}

add_kernel_param() {
    param="$1"

    if ! grep -q "^${grub_cmdline}" "$grub_file"; then
        print_error "The line ${grub_cmdline} was not found in the file."
        return 1
    fi

    current_line=$(grep "^${grub_cmdline}" "$grub_file" | cut -d'"' -f2)

    if echo "$current_line" | grep -qw "$param"; then
        print_info "Parameter '$param' is already present."
        return 0
    fi

 
    new_line="${grub_cmdline}=\"${current_line} ${param}\""

    # Escape for sed
    escaped_line=$(printf '%s\n' "$new_line" | sed 's/[&/\]/\\&/g')

    sed -i "s|^${grub_cmdline}=\".*\"|${escaped_line}|" "$grub_file" || {
        print_error "Sed command failed."
        return 1
    }

    print_success "Parameter '$param' added."
}

remove_kernel_param() {
    param="$1"

    current_line="$(
        sed -n "s/^[[:space:]]*${grub_cmdline}[[:space:]]*=\"\\(.*\\)\"/\\1/p" "$grub_file"
    )"

    if [ -z "$current_line" ]; then
        print_error "No line found matching ${grub_cmdline}=\"...\" format."
        return 1
    fi

    if ! echo "$current_line" | grep -qw "$param"; then
        print_warning "The parameter '$param' is not found in $grub_cmdline."
        return 0
    fi

    # Clean up spaces after removing the parameter
    new_line="$(
        echo "$current_line" |
        sed -E "s/(^| )${param}($| )/ /g" |
        sed -E 's/^[[:space:]]*//' |
        sed -E 's/[[:space:]]*$//'
    )"
    # Replace only the first matching line (if multiple GRUB_CMDLINE entrie exist)
    sed -i "0,/^[[:space:]]*${grub_cmdline}[[:space:]]*=\".*\"/s//${grub_cmdline}=\"${new_line}\"/" "$grub_file" || {
        print_error "Sed command failed while removing parameter."
        return 1
    }

    print_success "Parameter '$param' removed from $grub_cmdline in GRUB settings."
}



show_current_params() {
    clear
    current_params=$(grep "^$grub_cmdline" "$grub_file" | cut -d'"' -f2)
    echo "Current kernel parameters in $grub_cmdline:"
    echo "$current_params"
    printf "\nPress Enter to return to the main menu..."
    read -r _
}

