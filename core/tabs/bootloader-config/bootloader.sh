#!/bin/sh -e

## Logic for detecting system bootloader

detect_bootloader() {
    if [ -f /etc/systemd/bootctl.json ] || bootctl is-installed 2>/dev/null; then
        BOOTLOADER_TYPE="systemd-boot"
    elif [ -f /etc/default/grub ]; then
        BOOTLOADER_TYPE="grub"
    else
        BOOTLOADER_TYPE="unknown"
    fi
}

print_bootloader_info() {
    case "$BOOTLOADER_TYPE" in
        grub)
            print_info "Detected bootloader: GRUB"
            ;;
        systemd-boot)
            print_info "Detected bootloader: systemd-boot"
            ;;
        *)
            print_error "No supported bootloader found (GRUB or systemd-boot)"
            exit 1
            ;;
    esac
}

update_boot_config_and_exit() {
    case "$BOOTLOADER_TYPE" in
        grub)
            print_info "Updating GRUB configuration..."
            if command -v update-grub >/dev/null 2>&1; then
                grub_command="update-grub"
                print_info "Using command: update-grub"
            elif command -v grub2-mkconfig >/dev/null 2>&1; then
                grub_command="grub2-mkconfig -o /boot/grub2/grub.cfg"
                print_info "Using command: grub2-mkconfig -o /boot/grub2/grub.cfg"
            elif command -v grub-mkconfig >/dev/null 2>&1; then
                grub_command="grub-mkconfig -o /boot/grub/grub.cfg"
                print_info "Using command: grub-mkconfig -o /boot/grub/grub.cfg"
            else
                print_error "No GRUB update command found. Is GRUB installed?"
                return 1
            fi

            if ! $grub_command; then
                print_error "GRUB update failed. Please check for errors."
                return 1
            fi

            print_success "GRUB updated successfully! Please reboot for changes to take effect. 🎉"
            exit 0
            ;;
        systemd-boot)
            print_info "🎉 Systemd-boot updates automatically. Please reboot for changes to take effect. 🎉"
            exit 0
            ;;
        *)
            print_error "Unsupported bootloader: $BOOTLOADER_TYPE"
            return 1
            ;;
    esac
}

