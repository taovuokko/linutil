#!/bin/sh

# Helper functions for colored output, validation and parameter safety checks

print_header() {
    width=$(tput cols 2>/dev/null || echo 60)
    line=$(printf '%*s' "$width" '' | tr ' ' '=')
    
    tput setaf 2
    
    printf "%s\n" "$line"
    
    title="$1"
    title_length=$(printf "%s" "$title" | wc -c | tr -d ' ')
    left_padding=$(( (width - title_length) / 2 ))
    right_padding=$(( width - title_length - left_padding ))
    printf "%*s%s%*s\n" "$left_padding" '' "$title" "$right_padding" ''
    
    printf "%s\n" "$line"
    
    tput sgr0
}



print_menu_item() {
    printf "%b\n" "${CYAN}$1. ${2}${RC}"
}

print_error() {
    printf "%b\n" "${RED}Error:${NC} $1"
}

print_success() {
    printf "%b\n" "${GREEN}Success:${NC} $1"
}

print_info() {
    printf "%b\n" "${CYAN}Info:${RC} $1"
}


print_warning() {
    printf "%b\n" "${YELLOW}Warning:${NC} $1"
}


# Parameters that must never be removed
is_protected_param() {
    case "$1" in
        root=*|rw|ro|rootfstype=*|init=*|boot=*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}


# Parameters that are boot-sensitive (warn before remove)
is_risky_param() {
    case "$1" in
        resume=*|cryptdevice=*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

select_params_to_remove() {
    i=1
    shown=0
    echo "Current kernel parameters:"
    for param in "$@"; do
        if is_protected_param "$param"; then
            continue
        fi
        echo "  $i. $param"
        eval "params_$i=\$param"
        i=$((i + 1))
        shown=1
    done

    if [ "$shown" -eq 0 ]; then
        print_info "No removable parameters found."
        return
    fi

    echo
    printf "Enter numbers of parameters to remove (e.g. 1 3): "
    read -r selected

    for n in $selected; do
        eval "param=\$params_$n"
        if [ -z "$param" ]; then
            print_warning "Invalid selection: $n"
            continue
        fi

        if is_risky_param "$param"; then
            printf "⚠️  '%s' may affect boot behavior. Are you sure you want to remove it? (y/N): " "$param"
            read -r confirm
            [ "$confirm" = "y" ] || {
                print_info "Skipped '$param'"
                continue
            }
        fi

        bootlogic_remove_param "$param"
    done
}



remove_parameters() {
    clear
    print_header "Remove Kernel Parameters"
    current_params=$(bootlogic_show_params_raw)
    if [ -z "$current_params" ]; then
        print_warning "No kernel parameters found."
        printf "\nPress Enter to return to the main menu..."
        read -r _
        return
    fi
    select_params_to_remove $current_params
    printf "\nPress Enter to return to the main menu..."
    read -r _
}





