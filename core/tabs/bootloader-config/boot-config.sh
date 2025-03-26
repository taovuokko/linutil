#!/bin/sh -e
# Main entrypoint for the tool
# Loads modules, detects bootloader and initializes UI

. "$(dirname "$0")/../common-script.sh"
checkEscalationTool
if [ "$ESCALATION_TOOL" != "eval" ]; then
    exec "$ESCALATION_TOOL" "$0" "$@"
fi

# Modules
. "$(dirname "$0")/helpers.sh"
. "$(dirname "$0")/logic.sh"
. "$(dirname "$0")/grub.sh"
. "$(dirname "$0")/ui.sh"
. "$(dirname "$0")/systemdboot.sh"
. "$(dirname "$0")/bootloader.sh"
. "$(dirname "$0")/bootlogic.sh"

detect_bootloader
print_bootloader_info

case "$BOOTLOADER_TYPE" in
    grub)
        init_grub_config
        ;;
    systemd-boot)
        init_systemdboot_config
        select_systemdboot_entry
        ;;
    *)
        print_error "Unsupported bootloader: $BOOTLOADER_TYPE"
        exit 1
        ;;
esac

main_menu
