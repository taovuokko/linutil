#!/bin/sh
#  Generic UI module

CYAN=$(tput setaf 6)
RC=$(tput sgr0)

keyboard_params_menu() {
    echo "Select keyboard-related parameters to add (separated by spaces):"
    echo "1. i8042.nomux - Bypass PS/2 multiplexer"
    echo "2. i8042.reset - Force PS/2 controller reset"
    echo "3. i8042.nopnp - Disable PS/2 Plug and Play"
    echo "4. atkbd.reset - Reset PS/2 keyboard"
    select_params "1 2 3 4" "i8042.nomux i8042.reset i8042.nopnp atkbd.reset"
}

touchpad_params_menu() {
    echo "Select touchpad-related parameters to add (separated by spaces):"
    echo "1. psmouse.proto=imps - Switch mouse protocol to IMPS"
    echo "2. psmouse.resetafter=5 - Reset touchpad after detachment"
    echo "3. psmouse.synaptics_intertouch=1 - Enable Synaptics Intertouch"
    select_params "1 2 3" "psmouse.proto=imps psmouse.resetafter=5 psmouse.synaptics_intertouch=1"
}

cpu_params_menu() {
    echo "Select CPU settings to add (separated by spaces):"
    echo "1. intel_pstate=disable - Disable Intel power management"
    echo "2. acpi=off - Disable ACPI (not recommended for modern hardware)"
    echo "3. nmi_watchdog=0 - Disable NMI watchdog"
    echo "4. processor.max_cstate=1 - Limit CPU idle states"
    select_params "1 2 3 4" "intel_pstate=disable acpi=off nmi_watchdog=0 processor.max_cstate=1"
}

power_params_menu() {
    echo "Select power management parameters to add (separated by spaces):"
    echo "1. pcie_aspm=force - Force PCIe ASPM power saving"
    echo "2. usbcore.autosuspend=-1 - Disable USB autosuspend"
    echo "3. intel_idle.max_cstate=1 - Limit CPU idle states"
    echo "4. acpi_osi=Linux - Improve ACPI power management for Linux"
    echo "5. mem_sleep_default=deep - Use deeper sleep state for suspend"
    echo "6. pcie_port_pm=off - Disable PCIe port power management"
    echo "7. intel_pstate=passive - Set Intel power management to passive"
    echo "8. idle=halt - Use a simple CPU idle model"
    echo "9. amd_pstate=passive - Enable AMD power saving model for Zen 3/4"
    select_params "1 2 3 4 5 6 7 8 9" "pcie_aspm=force usbcore.autosuspend=-1 intel_idle.max_cstate=1 acpi_osi=Linux mem_sleep_default=deep pcie_port_pm=off intel_pstate=passive idle=halt amd_pstate=passive"
}

display_params_menu() {
    echo "Select display-related parameters to add (separated by spaces):"
    echo "1. nomodeset - Disable Kernel Mode Setting (KMS)"
    echo "2. radeon.modeset=0 - Disable KMS for Radeon"
    echo "3. nouveau.modeset=0 - Disable KMS for Nouveau"
    echo "4. nvidia-drm.modeset=1 - Enable NVIDIA DRM"
    echo "5. nvidia.blacklist=nouveau - Blacklist the Nouveau driver"
    echo "6. nvidia.NVreg_EnableGpuFirmware=1 - Enable NVIDIA GPU firmware"
    echo "7. pci=noaer - Disable PCI Advanced Error Reporting"
    echo "8. iommu=soft - Use alternative IOMMU handling"
    echo "9. acpi_backlight=vendor - Fix backlight control on some devices"
    echo "10. acpi_backlight=native - Fix backlight power management issues"
    echo "11. acpi=noirq - Reduce ACPI's effect on interrupts"
    select_params "1 2 3 4 5 6 7 8 9 10 11" "nomodeset radeon.modeset=0 nouveau.modeset=0 nvidia-drm.modeset=1 nvidia.blacklist=nouveau nvidia.NVreg_EnableGpuFirmware=1 pci=noaer iommu=soft acpi_backlight=vendor acpi_backlight=native acpi=noirq"
}

network_params_menu() {
    echo "Select network-related parameters to add (separated by spaces):"
    echo "1. acpi_enforce_resources=lax - Relax ACPI resource checking"
    echo "2. pcie_aspm=off - Disable PCIe ASPM power saving"
    echo "3. ipv6.disable=1 - Disable IPv6"
    echo "4. tcp_congestion_control=bbr - Enable BBR TCP congestion control"
    echo "5. mtu=1500 - Set MTU (Maximum Transmission Unit)"
    echo "6. net.ipv4.tcp_timestamps=0 - Disable TCP timestamps"
    select_params "1 2 3 4 5 6" "acpi_enforce_resources=lax pcie_aspm=off ipv6.disable=1 tcp_congestion_control=bbr mtu=1500 net.ipv4.tcp_timestamps=0"
}

audio_params_menu() {
    echo "Select audio-related parameters to add (separated by spaces):"
    echo "1. snd_hda_intel.dmic_detect=0 - Fix issues on certain audio devices"
    echo "2. snd_hda_intel.power_save=0 - Disable audio power saving"
    echo "3. snd-hda-intel.model=generic - Use a generic model for compatibility"
    select_params "1 2 3" "snd_hda_intel.dmic_detect=0 snd_hda_intel.power_save=0 snd-hda-intel.model=generic"
}

general_params_menu() {
    echo "1. loglevel=3 - Limit boot log messages"
    echo "2. quiet       - Quiet boot messages"
    echo "3. splash      - Show a graphical splash screen"
    echo "4. swappiness=10"
    echo "5. vm.dirty_ratio=20"
    echo "6. vm.dirty_background_ratio=10"
    select_params "1 2 3 4 5 6" "loglevel=3 quiet splash swappiness=10 vm.dirty_ratio=20 vm_dirty_background_ratio=10"
}



add_parameters() {
    while true; do
        clear
        print_header "Add Kernel Parameters"
        print_menu_item 1 "Audio"
        print_menu_item 2 "CPU Settings"
        print_menu_item 3 "Display"
        print_menu_item 4 "General Settings"
        print_menu_item 5 "Keyboard & PS/2 Controller"
        print_menu_item 6 "Network"
        print_menu_item 7 "Power Management"
        print_menu_item 8 "Touchpad"
        print_menu_item 9 "Return to Main Menu"
        printf "%sYour choice: %s" "$CYAN" "$RC"
        read -r choice
        if ! echo "1 2 3 4 5 6 7 8 9" | grep -qw "$choice"; then
            print_warning "Invalid choice. Please enter a number between 1 and 9."
            sleep 1
            continue
        fi
        case "$choice" in
            1) audio_params_menu ;;
            2) cpu_params_menu ;;
            3) display_params_menu ;;
            4) general_params_menu ;;
            5) keyboard_params_menu ;;
            6) network_params_menu ;;
            7) power_params_menu ;;
            8) touchpad_params_menu ;;
            9)
                print_info "Returning to main menu..."
                break
                ;;
        esac
    done
}
restore_boot_config() {
    bootlogic_restore_config
    return
}

main_menu() {
    bootlogic_backup_config
    while true; do
        clear
        print_header "Kernel Parameters Management"
        print_menu_item 1 "Add kernel parameters"
        print_menu_item 2 "Remove kernel parameters"
        print_menu_item 3 "Show current kernel parameters"
        print_menu_item 4 "Update Bootloader Configuration and exit"
        print_menu_item 5 "Exit without changes"
        printf "%sYour choice: %s" "${CYAN}" "${NC}"
        read -r main_choice
        case "$main_choice" in
            1) add_parameters ;;
            2) remove_parameters ;;
            3) bootlogic_show_params ;;
            4) update_boot_config_and_exit ;;  
            5) restore_boot_config 

                exit 0
                ;;
            *)
                print_warning "Invalid choice. Please enter a number between 1 and 5."
                sleep 1
                ;;
        esac
    done
}
