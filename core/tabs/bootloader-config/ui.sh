#!/bin/sh
# spell-checker: disable

# Generic UI module for selecting kernel boot parameters

CYAN=$(tput setaf 6)
RC=$(tput sgr0)

audio_params_menu() {
    echo "Select audio-related parameters to add (separated by spaces):"
    echo "1. snd-intel-dspcfg.dsp_driver=1 - Force legacy HDA audio driver (bypasses modern SOF/SST audio stack)"
    echo "2. snd_hda_intel.power_save=0 - Disable power saving for HDA audio"
    echo "3. snd-hda-intel.model=generic - Use generic model for compatibility"
    select_params "1 2 3" "snd-intel-dspcfg.dsp_driver=1 snd_hda_intel.power_save=0 snd-hda-intel.model=generic"
}

keyboard_params_menu() {
    echo "Select keyboard-related parameters to add (separated by spaces):"
    echo "1. i8042.nomux - Bypass PS/2 multiplexer"
    echo "2. i8042.reset - Force PS/2 controller reset"
    echo "3. i8042.nopnp - Disable PS/2 Plug and Play"
    echo "4. atkbd.reset - Reset PS/2 keyboard"
    select_params "1 2 3 4" "i8042.nomux i8042.reset i8042.nopnp atkbd.reset"
}

cpu_params_menu() {
    echo "Select CPU-related parameters to add (separated by spaces):"
    echo "1. intel_pstate=disable - Disable Intel power management"
    echo "2. acpi=off - Disable ACPI"
    echo "3. nmi_watchdog=0 - Disable NMI watchdog"
    echo "4. processor.max_cstate=1 - Limit CPU idle states"
    echo "5. ibt=off - Disable Indirect Branch Tracking (may affect security!)"
    select_params "1 2 3 4 5" "intel_pstate=disable acpi=off nmi_watchdog=0 processor.max_cstate=1 ibt=off"
}

power_params_menu() {
    echo "Select power management parameters to add (separated by spaces):"
    echo "1. pcie_aspm=force - Force PCIe ASPM power saving"
    echo "2. usbcore.autosuspend=-1 - Disable USB autosuspend"
    echo "3. intel_idle.max_cstate=1 - Limit CPU idle states"
    echo "4. ahci.mobile_lpm_policy=1 - Enable mobile AHCI low power management"
    echo "5. acpi_osi=Linux - Improve ACPI power management for Linux"
    echo "6. mem_sleep_default=deep - Use a deeper sleep state for suspend"
    echo "7. pcie_port_pm=off - Disable PCIe port power management"
    echo "8. intel_pstate=passive - Set Intel power management to passive"
    echo "9. idle=halt - Use a simple CPU idle model"
    echo "10. amd_pstate=passive - Enable AMD power saving model for Zen 3/4"
    echo "11. noresume - Disable resume from suspend/hibernate"
    select_params "1 2 3 4 5 6 7 8 9 10 11" "pcie_aspm=force usbcore.autosuspend=-1 intel_idle.max_cstate=1 ahci.mobile_lpm_policy=1 acpi_osi=Linux mem_sleep_default=deep pcie_port_pm=off intel_pstate=passive idle=halt amd_pstate=passive noresume"
}

display_params_menu() {
    echo "Select display-related parameters to add (separated by spaces):"
    echo "1. nomodeset - Disable Kernel Mode Setting (KMS)"
    echo "2. pci=noaer - Disable PCI Advanced Error Reporting"
    echo "3. iommu=soft - Use alternative IOMMU handling"
    echo "4. acpi_backlight=vendor - Fix backlight control on some devices"
    echo "5. acpi_backlight=native - Fix backlight power management issues"
    echo "6. acpi=noirq - Reduce ACPI's effect on interrupts"
    echo "7. nouveau.modeset=0 - Disable Nouveau driver KMS"
    echo "8. i915.enable_psr=0 - Disable Intel Panel Self Refresh (PSR)"
    echo "9. xe.enable_psr=0 - Disable XE driver Panel Self Refresh"
    echo "10. i915.enable_dc=0 - Disable Intel Display C-states"
    echo "11. radeon.si_support=0 - Force Southern Islands GPUs to use amdgpu"
    echo "12. amdgpu.si_support=1 - Enable amdgpu for Southern Islands GPUs"
    echo "13. radeon.cik_support=0 - Force Sea Islands GPUs to use amdgpu"
    echo "14. amdgpu.cik_support=1 - Enable amdgpu for Sea Islands GPUs"
    select_params "1 2 3 4 5 6 7 8 9 10 11 12 13 14" "nomodeset pci=noaer iommu=soft acpi_backlight=vendor acpi_backlight=native acpi=noirq nouveau.modeset=0 i915.enable_psr=0 xe.enable_psr=0 i915.enable_dc=0 radeon.si_support=0 amdgpu.si_support=1 radeon.cik_support=0 amdgpu.cik_support=1"
}

general_params_menu() {
    echo "Select general boot parameters to add (separated by spaces):"
    echo "1. loglevel=3 - Limit boot log messages"
    echo "2. quiet - Quiet boot messages"
    echo "3. splash - Show a graphical splash screen"
    echo "4. rootfstype=ext4 - Set root filesystem type to ext4"
    echo "5. init=/bin/bash - Boot directly into a bash shell"
    echo "6. ro - Mount root filesystem as read-only"
    echo "7. rootdelay=5 - Wait 5 seconds for the root device to be available"
    select_params "1 2 3 4 5 6 7" "loglevel=3 quiet splash rootfstype=ext4 init=/bin/bash ro rootdelay=5"
}


add_parameters() {
    while true; do
        clear
        print_header "Add Kernel Boot Parameters"
        print_menu_item 1 "Audio"
        print_menu_item 2 "CPU Settings"
        print_menu_item 3 "Display"
        print_menu_item 4 "General Settings"
        print_menu_item 5 "Keyboard & PS/2 Controller"
        print_menu_item 6 "Power Management"
        print_menu_item 7 "Return to Main Menu"
        printf "%sYour choice: %s" "$CYAN" "$RC"
        read -r choice
        if ! echo "1 2 3 4 5 6 7" | grep -qw "$choice"; then
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
            6) power_params_menu ;;
            7)
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
