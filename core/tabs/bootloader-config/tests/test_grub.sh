#!/bin/sh
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
    export grub_file="$GRUB_MOCK"
    . "$GRUB_MODULE"
}


# === TEST 1: Add parameter ===
print_header "TEST 1: Add kernel parameter"

(
    export grub_file="$GRUB_MOCK"
    load_grub_env
    init_grub_config
    add_kernel_param "mitigations=off"

    if grep -qw 'mitigations=off' "$grub_file"; then
        print_success "PASS: Parameter 'mitigations=off' was correctly added"
    else
        print_error "FAIL: Parameter 'mitigations=off' was not found"
        exit 1
    fi
)

# === TEST 2: Remove kernel parameter ===
print_header "TEST 2: Remove kernel parameter"

(
    export grub_file="$GRUB_MOCK"
    load_grub_env
    init_grub_config
    add_kernel_param "quiet"

    if ! grep -qw "quiet" "$grub_file"; then
        print_error "Setup failed: 'quiet' not added"
        exit 1
    fi

    remove_kernel_param "quiet"

    if grep -qw "quiet" "$grub_file"; then
        print_error "FAIL: 'quiet' still found after removal"
        exit 1
    else
        print_success "PASS: 'quiet' successfully removed"
    fi
)

# === TEST 3: Duplicate parameter is not added ===
print_header "TEST 3: Duplicate parameter should not be added"

(
    export grub_file="$GRUB_MOCK"
        load_grub_env

    init_grub_config
    add_kernel_param "mitigations=off"

    count=$(grep -o 'mitigations=off' "$grub_file" | wc -l)

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
    export grub_file="$GRUB_MOCK"
    load_grub_env
    init_grub_config
    remove_kernel_param "idontexist123"

    if grep -q 'idontexist123' "$grub_file"; then
        print_error "FAIL: Non-existent parameter appeared in config?!"
        exit 1
    else
        print_success "PASS: Nothing was changed when removing non-existent parameter"
    fi
)

# === TEST 5: Add multi-word parameter ===
print_header "TEST 5: Add multi-word parameter (module_blacklist=nouveau,amdgpu)"

(
    export grub_file="$GRUB_MOCK"
        load_grub_env

    init_grub_config
    add_kernel_param "module_blacklist=nouveau,amdgpu"

    if grep -q 'module_blacklist=nouveau,amdgpu' "$grub_file"; then
        print_success "PASS: Multi-word parameter added correctly"
    else
        print_error "FAIL: Multi-word parameter not found in config"
        exit 1
    fi
)

# === TEST 6: Missing GRUB_CMDLINE line ===
print_header "TEST 6: Config without kernel line should fail gracefully"

(
    BROKEN_FILE="$TEST_DIR/no_kernel_line"
    cp "$MOCK_SOURCE/etc_default_grub" "$BROKEN_FILE"
    sed -i '/GRUB_CMDLINE_LINUX/d' "$BROKEN_FILE"

    export grub_file="$BROKEN_FILE"
        load_grub_env

    if init_grub_config 2>/dev/null; then
        print_error "FAIL: init_grub_config should have failed but didn't"
        exit 1
    else
        print_success "PASS: init_grub_config failed as expected on missing kernel line"
    fi
)

# Clean up
print_info "Cleaning up test files..."
rm -rf "$TEST_DIR"

print_success "✅ All GRUB tests completed successfully"
