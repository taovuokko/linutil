#!/bin/sh -e
# Main entrypoint for the Kernel Parameter Tool

# Resolve absolute path
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Ensure working directory is valid (prevents getcwd errors when temp dirs disappear)
cd "$SCRIPT_DIR"

# Load shared functions
. "$SCRIPT_DIR/../common-script.sh"

# Elevate privileges if needed (with full path)
checkEscalationTool
if [ "$ESCALATION_TOOL" != "eval" ]; then
    exec "$ESCALATION_TOOL" sh "$SCRIPT_PATH" "$@"
fi

# Load bootloader modules
. "$SCRIPT_DIR/helpers.sh"
. "$SCRIPT_DIR/logic.sh"
. "$SCRIPT_DIR/grub.sh"
. "$SCRIPT_DIR/systemdboot.sh"
. "$SCRIPT_DIR/bootloader.sh"
. "$SCRIPT_DIR/bootlogic.sh"
. "$SCRIPT_DIR/ui.sh"

# Detect and handle bootloader
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

# Launch main UI
main_menu