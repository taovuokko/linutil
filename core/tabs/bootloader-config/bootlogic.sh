#!/bin/sh

# Abstracts kernel parameter operations for different bootloaders.
# It directs calls to the appropriate functions based on BOOTLOADER_TYPE.

bootlogic_add_param() {
    param="$1"
    case "$BOOTLOADER_TYPE" in
        grub)
            add_kernel_param "$param"
            ;;
        systemd-boot)
            add_systemdboot_param "$param"
            ;;
        *)
            print_error "Unsupported bootloader: $BOOTLOADER_TYPE"
            return 1
            ;;
    esac
}

bootlogic_remove_param() {
    param="$1"
    case "$BOOTLOADER_TYPE" in
        grub)
            remove_kernel_param "$param"
            ;;
        systemd-boot)
            remove_systemdboot_param "$param"
            ;;
        *)
            print_error "Unsupported bootloader: $BOOTLOADER_TYPE"
            return 1
            ;;
    esac
}

bootlogic_show_params() {
    case "$BOOTLOADER_TYPE" in
        grub)
            show_current_params
            ;;
        systemd-boot)
            show_systemdboot_params
            ;;
        *)
            print_error "Unsupported bootloader: $BOOTLOADER_TYPE"
            return 1
            ;;
    esac
}

bootlogic_show_params_raw() {
    case "$BOOTLOADER_TYPE" in
        grub)
            grep "^$grub_cmdline" "$grub_file" | cut -d'"' -f2
            ;;
        systemd-boot)
            grep "^options" "$SYSTEMDBOOT_ENTRY" | cut -d' ' -f2-
            ;;
        *)
            echo ""
            ;;
    esac
}


bootlogic_backup_config() {
    case "$BOOTLOADER_TYPE" in
        grub)
            backup_grub
            ;;
        systemd-boot)
            backup_systemdboot_entry
            ;;
        *)
            print_error "Unsupported bootloader: $BOOTLOADER_TYPE"
            return 1
            ;;
    esac
}

bootlogic_restore_config() {
    case "$BOOTLOADER_TYPE" in
        grub)
            restore_grub
            ;;
        systemd-boot)
            restore_systemdboot_entry
            ;;
        *)
            print_error "Unsupported bootloader: $BOOTLOADER_TYPE"
            return 1
            ;;
    esac
}
