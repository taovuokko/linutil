#!/bin/sh -e

BOOT_DIR="/boot"
ENTRY_DIR="$BOOT_DIR/loader/entries"
BACKUP_DIR="$ENTRY_DIR/backup"
SELECTED_ENTRY=""

init_systemdboot_config() {
    [ -d "$ENTRY_DIR" ] || {
        print_error "Entry directory not found: $ENTRY_DIR"
        exit 1
    }

    mkdir -p "$BACKUP_DIR" || {
        print_error "Failed to create backup directory: $BACKUP_DIR"
        exit 1
    }
}

select_systemdboot_entry() {
    ENTRY_DIR="/boot/loader/entries"

    entries=$(find "$ENTRY_DIR" -maxdepth 1 -type f -name "*.conf")
    if [ -z "$entries" ]; then
        print_error "No systemd-boot entries found in $ENTRY_DIR!"
        exit 1
    fi

    echo "Select an entry to modify:"
    PS3="Enter the number of the entry: "
    select entry_file in $entries; do
        if [ -n "$entry_file" ]; then
            export SYSTEMDBOOT_ENTRY="$entry_file"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    print_info "Selected entry: $SYSTEMDBOOT_ENTRY"
}


backup_systemdboot_entry() {
    if [ -z "$SYSTEMDBOOT_ENTRY" ]; then
        print_error "No entry selected for backup"
        return 1
    fi

    ENTRY_NAME=$(basename "$SYSTEMDBOOT_ENTRY")
    BACKUP_PATH="/boot/loader/entries/backup/${ENTRY_NAME}.bak"

    if cp "$SYSTEMDBOOT_ENTRY" "$BACKUP_PATH"; then
        print_success "Backup created at $BACKUP_PATH"
    else
        print_error "Failed to create backup at $BACKUP_PATH"
        return 1
    fi
}


restore_systemdboot_entry() {
    [ -n "$SYSTEMDBOOT_ENTRY" ] || {
        print_error "No entry selected for restore"
        return 1
    }

    local backup_path="$BACKUP_DIR/$(basename "$SYSTEMDBOOT_ENTRY").bak"

    [ -f "$backup_path" ] || {
        print_warning "No backup file found: $backup_path"
        return 1
    }

    if cp "$backup_path" "$SYSTEMDBOOT_ENTRY"; then
        print_success "Restored $SYSTEMDBOOT_ENTRY from backup"
        return 0
    else
        print_error "Failed to restore from backup"
        return 1
    fi
}

add_systemdboot_param() {
    param="$1"
    if [ -z "$SYSTEMDBOOT_ENTRY" ]; then
        print_error "No systemd-boot entry selected."
        return 1
    fi

    current_options=$(grep "^options" "$SYSTEMDBOOT_ENTRY" | cut -d' ' -f2-)
    if echo "$current_options" | grep -qw "$param"; then
        print_info "Parameter '$param' already exists."
        return 0
    fi

    if [ -n "$current_options" ]; then
        new_options="options $current_options $param"
    else
        new_options="options $param"
    fi

    new_options=$(echo "$new_options" | sed 's/  */ /g')

    if grep -q "^options" "$SYSTEMDBOOT_ENTRY"; then
        if ! sed -i "s/^options.*/$new_options/" "$SYSTEMDBOOT_ENTRY"; then
            print_error "Failed to update options in $SYSTEMDBOOT_ENTRY"
            return 1
        fi
    else
        if ! echo "$new_options" >> "$SYSTEMDBOOT_ENTRY"; then
            print_error "Failed to append options to $SYSTEMDBOOT_ENTRY"
            return 1
        fi
    fi

    print_success "Parameter '$param' added."
    return 0
}


show_systemdboot_params() {
    if [ -z "$SYSTEMDBOOT_ENTRY" ]; then
        print_error "No systemd-boot entry selected."
        return 1
    fi

    clear
    current_options=$(grep "^options" "$SYSTEMDBOOT_ENTRY" | cut -d' ' -f2-)
    echo "Current kernel parameters in $(basename "$SYSTEMDBOOT_ENTRY"):"
    if [ -z "$current_options" ]; then
        print_warning "None found."
    else
        echo "$current_options"
    fi
    printf "\nPress Enter to return to the main menu..."
    read _
    return 0
}

remove_systemdboot_param() {
    param="$1"

    if [ -z "$SYSTEMDBOOT_ENTRY" ]; then
        print_error "No selected systemd-boot entry to modify"
        return 1
    fi

    if [ ! -f "$SYSTEMDBOOT_ENTRY" ]; then
        print_error "Selected entry file does not exist: $SYSTEMDBOOT_ENTRY"
        return 1
    fi

    backup_path="$BACKUP_DIR/$(basename "$SYSTEMDBOOT_ENTRY").bak"
    cp "$SYSTEMDBOOT_ENTRY" "$backup_path" || {
        print_error "Failed to backup entry before removal"
        return 1
    }

    options_line=$(grep "^options" "$SYSTEMDBOOT_ENTRY")
    if [ -z "$options_line" ]; then
        print_warning "No options line found in $SYSTEMDBOOT_ENTRY"
        return 1
    fi

    current_options=$(echo "$options_line" | cut -d' ' -f2-)
    new_options=$(echo "$current_options" | tr ' ' '\n' | grep -vxF "$param" | tr '\n' ' ')
    new_options=$(echo "$new_options" | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

    if [ "$current_options" = "$new_options" ]; then
        print_warning "Parameter '$param' not found in entry"
        return 1
    fi

    if [ -z "$new_options" ]; then
        if ! sed -i "/^options/d" "$SYSTEMDBOOT_ENTRY"; then
            print_error "Failed to remove options line from $SYSTEMDBOOT_ENTRY"
            return 1
        fi
        print_success "Parameter '$param' removed; options line deleted (it became empty)."
        return 0
    fi

    new_line="options $new_options"
    if grep -q "^options" "$SYSTEMDBOOT_ENTRY"; then
        if ! sed -i "s|^options.*|$new_line|" "$SYSTEMDBOOT_ENTRY"; then
            print_error "Failed to update entry file"
            return 1
        fi
    else
        if ! echo "$new_line" >> "$SYSTEMDBOOT_ENTRY"; then
            print_error "Failed to append new options to $SYSTEMDBOOT_ENTRY"
            return 1
        fi
    fi

    print_success "Parameter '$param' removed from entry"
    return 0
}




