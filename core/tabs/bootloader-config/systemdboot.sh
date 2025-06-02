#!/bin/sh -e
# systemd-boot specific logic for kernel parameters and boot entries

get_systemdboot_entry_dir() {
    [ -d /boot/loader/entries ] && echo /boot/loader/entries && return
    [ -d /efi/loader/entries ] && echo /efi/loader/entries && return
    print_error "No systemd-boot entries directory found!"
    exit 1
}

init_systemdboot_config() {
    ENTRY_DIR=$(get_systemdboot_entry_dir)
    BACKUP_DIR="$ENTRY_DIR/backup"
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
    ENTRY_DIR=$(get_systemdboot_entry_dir)
    entries=$(find "$ENTRY_DIR" -maxdepth 1 -type f -name "*.conf")
    [ -z "$entries" ] && {
        print_error "No systemd-boot entries found in $ENTRY_DIR!"
        exit 1
    }

    echo "Select an entry to modify:"
    i=1
    for entry in $entries; do
        echo "$i) $entry"
        eval "entry_$i=\"$entry\""
        i=$((i + 1))
    done

    total=$((i - 1))
    printf "Enter the number of the entry [1-%s]: " "$total"
    read -r selection

    i=1
    for entry in $entries; do
        if [ "$i" -eq "$selection" ]; then
            SYSTEMDBOOT_ENTRY="$entry"
            export SYSTEMDBOOT_ENTRY
            print_info "Selected entry: $(basename "$SYSTEMDBOOT_ENTRY")"
            return 0
        fi
        i=$((i + 1))
    done

    print_error "Invalid selection."
    return 1
}

backup_systemdboot_entry() {
    [ -z "$SYSTEMDBOOT_ENTRY" ] && {
        print_error "No entry selected for backup"
        return 1
    }

    ENTRY_NAME=$(basename "$SYSTEMDBOOT_ENTRY")
    BACKUP_DIR="${SYSTEMDBOOT_ENTRY%/*}/backup"
    BACKUP_PATH="$BACKUP_DIR/${ENTRY_NAME}.bak"
    mkdir -p "$BACKUP_DIR"

    if cp "$SYSTEMDBOOT_ENTRY" "$BACKUP_PATH"; then
        print_success "Backup created at $BACKUP_PATH"
    else
        print_error "Failed to create backup at $BACKUP_PATH"
        return 1
    fi
}

restore_systemdboot_entry() {
    [ -z "$SYSTEMDBOOT_ENTRY" ] && {
        print_error "No entry selected for restore"
        return 1
    }

    BACKUP_DIR="${SYSTEMDBOOT_ENTRY%/*}/backup"
    backup_path="$BACKUP_DIR/$(basename "$SYSTEMDBOOT_ENTRY").bak"

    [ -f "$backup_path" ] || {
        print_warning "No backup file found: $backup_path"
        return 1
    }

    if cp "$backup_path" "$SYSTEMDBOOT_ENTRY"; then
        print_success "Restored $(basename "$SYSTEMDBOOT_ENTRY") from backup"
        return 0
    else
        print_error "Failed to restore from backup"
        return 1
    fi
}

add_systemdboot_param() {
    param="$1"

    # Allow override from tests
    if [ -n "$SYSTEMDBOOT_ENTRY_OVERRIDE" ]; then
        SYSTEMDBOOT_ENTRY="$SYSTEMDBOOT_ENTRY_OVERRIDE"
    fi

    [ -z "$SYSTEMDBOOT_ENTRY" ] && {
        print_error "No systemd-boot entry selected."
        return 1
    }

    # Require an existing 'options' line
    if ! grep -q "^options" "$SYSTEMDBOOT_ENTRY"; then
        print_error "Missing 'options' line in $SYSTEMDBOOT_ENTRY"
        return 1
    fi

    # Extract what follows, if the line is exactly "options", this leaves empty
    current_options=$(grep "^options" "$SYSTEMDBOOT_ENTRY" | sed 's/^options[[:space:]]*//')

    # If parameter is already in the list, do nothing
    if printf "%s\n" "$current_options" | grep -qw "$param"; then
        print_info "Parameter '$param' already exists."
        return 0
    fi

    # Build new options line
    if [ -n "$current_options" ]; then
        new_options="options $current_options $param"
    else
        new_options="options $param"
    fi

    # Collapse multiple spaces, trim leading/trailing whitespace
    new_options=$(printf "%s\n" "$new_options" | sed -E 's/[[:space:]]+/ /g; s/^ *//; s/ *$//')

    # Escape characters that sed might misinterpret
    escaped_opts=$(printf "%s\n" "$new_options" | sed 's/[\/&]/\\&/g')

    # Replace the first options line with the updated version
    if ! sed -i "s|^options.*|$escaped_opts|" "$SYSTEMDBOOT_ENTRY"; then
        print_error "Failed to update options in $SYSTEMDBOOT_ENTRY"
        return 1
    fi

    print_success "Parameter '$param' added."
    return 0
}


show_systemdboot_params() {
    [ -z "$SYSTEMDBOOT_ENTRY" ] && {
        print_error "No systemd-boot entry selected."
        return 1
    }

    clear
    current_options=$(grep "^options" "$SYSTEMDBOOT_ENTRY" | cut -d' ' -f2-)
    echo "Current kernel parameters in $(basename "$SYSTEMDBOOT_ENTRY"):"
    [ -z "$current_options" ] && print_warning "None found." || echo "$current_options"
    printf "\nPress Enter to return to the main menu..."
    read -r _
}

remove_systemdboot_param() {
    param="$1"
    [ -z "$SYSTEMDBOOT_ENTRY" ] && {
        print_error "No selected systemd-boot entry to modify"
        return 1
    }
    [ ! -f "$SYSTEMDBOOT_ENTRY" ] && {
        print_error "Selected entry file does not exist: $SYSTEMDBOOT_ENTRY"
        return 1
    }

    BACKUP_DIR="${SYSTEMDBOOT_ENTRY%/*}/backup"
    mkdir -p "$BACKUP_DIR"
    backup_path="$BACKUP_DIR/$(basename "$SYSTEMDBOOT_ENTRY").bak"

    if ! cp "$SYSTEMDBOOT_ENTRY" "$backup_path"; then
        print_error "Failed to backup entry before removal"
        return 1
    fi

    options_line=$(grep "^options" "$SYSTEMDBOOT_ENTRY")
    [ -z "$options_line" ] && {
        print_warning "No options line found in $SYSTEMDBOOT_ENTRY"
        return 1
    }

    current_options=$(echo "$options_line" | cut -d' ' -f2-)
    new_options=$(echo "$current_options" | tr ' ' '\n' | grep -vxF "$param" | tr '\n' ' ')
    new_options=$(echo "$new_options" | sed 's/  */ /g; s/^ *//; s/ *$//')

    if [ "$current_options" = "$new_options" ]; then
        print_warning "Parameter '$param' not found in entry"
        return 1
    fi

    if [ -z "$new_options" ]; then
        if sed -i "/^options/d" "$SYSTEMDBOOT_ENTRY"; then
            print_success "Parameter '$param' removed; options line deleted."
            return 0
        else
            print_error "Failed to remove options line"
            return 1
        fi
    fi

    new_line="options $new_options"
    escaped_line=$(printf '%s\n' "$new_line" | sed 's/[&/\]/\\&/g')

    if sed -i "s|^options.*|$escaped_line|" "$SYSTEMDBOOT_ENTRY"; then
        print_success "Parameter '$param' removed from entry"
        return 0
    else
        print_error "Failed to update entry file"
        return 1
    fi
}
