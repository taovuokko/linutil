#!/bin/sh
# shellcheck disable=SC1091,SC2030,2031
# Automated GRUB tests

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../helpers.sh"

TEST_DIR="$SCRIPT_DIR/test_env"
MOCK_SOURCE="$SCRIPT_DIR/mocks/grub"
GRUB_MOCK="$TEST_DIR/etc_default_grub"
GRUB_MODULE="$SCRIPT_DIR/../grub.sh"

print_info "Initializing test data..."
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
cp "$MOCK_SOURCE"/* "$TEST_DIR/"

load_grub_env() {
    export GRUB_CONFIG="$GRUB_MOCK"
    . "$SCRIPT_DIR/../helpers.sh"
    . "$GRUB_MODULE"
}

# === TEST 1: Add parameter ===
print_header "TEST 1: Add kernel parameter"
(
    load_grub_env
    init_grub_config
    add_kernel_param "mitigations=off"

    if grep -qw 'mitigations=off' "$GRUB_CONFIG"; then
        print_success "PASS: Parameter 'mitigations=off' was correctly added"
    else
        print_error "FAIL: Parameter 'mitigations=off' was not found"
        exit 1
    fi
)

# === TEST 2: Remove kernel parameter ===
print_header "TEST 2: Remove kernel parameter"
(
    load_grub_env
    init_grub_config
    add_kernel_param "quiet"
    remove_kernel_param "quiet"

    if grep -qw "quiet" "$GRUB_CONFIG"; then
        print_error "FAIL: 'quiet' still found after removal"
        exit 1
    else
        print_success "PASS: 'quiet' successfully removed"
    fi
)

# === TEST 3: Duplicate parameter is not added ===
print_header "TEST 3: Duplicate parameter should not be added"
(
    load_grub_env
    init_grub_config
    add_kernel_param "mitigations=off"
    count=$(grep -o 'mitigations=off' "$GRUB_CONFIG" | wc -l)

    if [ "$count" -gt 1 ]; then
        print_error "FAIL: Duplicate 'mitigations=off' added multiple times"
        exit 1
    else
        print_success "PASS: Duplicate parameter was not added again"
    fi
)

# === TEST 4: Removing a parameter that does not exist ===
print_header "TEST 4: Removing a non-existent parameter"
(
    load_grub_env
    init_grub_config
    remove_kernel_param "idontexist123"

    if grep -q 'idontexist123' "$GRUB_CONFIG"; then
        print_error "FAIL: Non-existent parameter appeared in config?!"
        exit 1
    else
        print_success "PASS: Nothing was changed when removing non-existent parameter"
    fi
)

# === TEST 5: Add multi-word parameter ===
print_header "TEST 5: Add multi-word parameter (module_blacklist=nouveau,amdgpu)"
(
    load_grub_env
    init_grub_config
    add_kernel_param "module_blacklist=nouveau,amdgpu"

    if grep -q 'module_blacklist=nouveau,amdgpu' "$GRUB_CONFIG"; then
        print_success "PASS: Multi-word parameter added correctly"
    else
        print_error "FAIL: Multi-word parameter not found in config"
        exit 1
    fi
)

# === TEST 6: Config without kernel line should fail gracefully ===
print_header "TEST 6: Config without kernel line should fail gracefully"
(
    BROKEN_FILE="$TEST_DIR/no_kernel_line"
    cp "$MOCK_SOURCE/etc_default_grub" "$BROKEN_FILE"
    sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT/d' "$BROKEN_FILE"
    sed -i '/^GRUB_CMDLINE_LINUX/d' "$BROKEN_FILE"

    export GRUB_CONFIG="$BROKEN_FILE"
    . "$SCRIPT_DIR/../helpers.sh"
    . "$GRUB_MODULE"

    if init_grub_config 2>/dev/null; then
        print_error "FAIL: init_grub_config should have failed but didn't"
        exit 1
    else
        print_success "PASS: init_grub_config failed as expected on missing kernel line"
    fi
)

# === TEST 7: Parameter with special characters ===
print_header "TEST 7: Parameter with special characters"
(
    load_grub_env
    init_grub_config

    add_kernel_param "module_blacklist=foo,bar"
    add_kernel_param "rd.driver.blacklist=xyz"

    if grep -q 'module_blacklist=foo,bar' "$GRUB_CONFIG" && \
       grep -q 'rd.driver.blacklist=xyz' "$GRUB_CONFIG"; then
        print_success "PASS: Special character parameters added correctly"
    else
        print_error "FAIL: One or more special character parameters not found"
        exit 1
    fi
)

# === TEST 8: Add to empty GRUB_CMDLINE_LINUX_DEFAULT ===
print_header "TEST 8: Add to empty GRUB_CMDLINE_LINUX_DEFAULT"
(
    FILE="$TEST_DIR/empty_cmdline"
    cp "$MOCK_SOURCE/etc_default_grub" "$FILE"
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/' "$FILE"

    export GRUB_CONFIG="$FILE"
    . "$SCRIPT_DIR/../helpers.sh"
    . "$GRUB_MODULE"

    if ! init_grub_config; then
        print_error "init_grub_config failed."
        exit 1
    fi

    add_kernel_param "testparam"

    if grep -q 'testparam' "$GRUB_CONFIG"; then
        print_success "PASS: Parameter added to empty GRUB_CMDLINE_LINUX_DEFAULT"
    else
        print_error "FAIL: Parameter not added correctly"
        exit 1
    fi
)

