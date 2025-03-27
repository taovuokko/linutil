#!/bin/sh 

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../helpers.sh"

#  test environment
TEST_DIR="$SCRIPT_DIR/test_env"
MOCK_SOURCE="mocks/systemd-boot"
SYSTEMDBOOT_ENTRY="$TEST_DIR/entries/arch.conf"

print_info "Initializing test data..."
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/entries"
cp "$MOCK_SOURCE"/entries/* "$TEST_DIR/entries/"
cp "$MOCK_SOURCE"/loader.conf "$TEST_DIR/"

# === TEST 1: Add parameter ===
print_header "TEST 1: Add kernel parameter"

(
    export SYSTEMDBOOT_ENTRY
    . "$SCRIPT_DIR/../systemdboot.sh"


    add_systemdboot_param "mitigations=off"

    if grep -q 'mitigations=off' "$SYSTEMDBOOT_ENTRY"; then
        print_success "PASS: Parameter 'mitigations=off' was correctly added"
    else
        print_error "FAIL: Parameter 'mitigations=off' was not found"
        exit 1
    fi
)

# === TEST 2: Remove parameter ===
print_header "TEST 2: Remove kernel parameter"

(
    export SYSTEMDBOOT_ENTRY
    . "$SCRIPT_DIR/../systemdboot.sh"

    add_systemdboot_param "quiet"

    if ! grep -qw "quiet" "$SYSTEMDBOOT_ENTRY"; then
        print_error "Setup failed: 'quiet' not added"
        exit 1
    fi

    remove_systemdboot_param "quiet"

    if grep -qw "quiet" "$SYSTEMDBOOT_ENTRY"; then
        print_error "FAIL: 'quiet' still found after removal"
        exit 1
    else
        print_success "PASS: 'quiet' successfully removed"
    fi
)

# === TEST 3: Duplicate parameter is not added ===
print_header "TEST 3: Duplicate parameter should not be added"

(
    export SYSTEMDBOOT_ENTRY
    . "$SCRIPT_DIR/../systemdboot.sh"


    add_systemdboot_param "mitigations=off"

    count=$(grep -o 'mitigations=off' "$SYSTEMDBOOT_ENTRY" | wc -l)

    if [ "$count" -gt 1 ]; then
        print_error "FAIL: Duplicate 'mitigations=off' added multiple times"
        exit 1
    else
        print_success "PASS: Duplicate parameter was not added again"
    fi
)

# === TEST 4: Remove non-existent parameter ===
print_header "TEST 4: Removing a non-existent parameter"

(
    export SYSTEMDBOOT_ENTRY
    . "$SCRIPT_DIR/../systemdboot.sh"

    remove_systemdboot_param "idontexist123"

    if grep -q 'idontexist123' "$SYSTEMDBOOT_ENTRY"; then
        print_error "FAIL: Non-existent parameter appeared in config?!"
        exit 1
    else
        print_success "PASS: Nothing changed when removing non-existent parameter"
    fi
)

# === TEST 5: Missing options line ===
print_header "TEST 5: Missing options line should fail gracefully"

(
    BROKEN_FILE="$TEST_DIR/entries/no_options.conf"
    cp "$MOCK_SOURCE/entries/arch.conf" "$BROKEN_FILE"
    sed -i '/^options/d' "$BROKEN_FILE"

    if [ -n "$GRUB_CONFIG" ]; then
        grub_file="$GRUB_CONFIG"
    else
        grub_file="$GRUB_MOCK"
    fi
    . "$SCRIPT_DIR/../systemdboot.sh"

    export SYSTEMDBOOT_ENTRY_OVERRIDE="$BROKEN_FILE"

    if add_systemdboot_param "testparam"; then
        print_error "FAIL: add_systemdboot_param should have failed"
        exit 1
    else
        print_success "PASS: add_systemdboot_param failed as expected on missing options line"
    fi

)


# Clean up
print_info "Cleaning up test files..."
rm -rf "$TEST_DIR"

print_success "✅ All systemd-boot tests completed successfully"
