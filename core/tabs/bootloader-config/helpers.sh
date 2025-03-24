#!/bin/sh

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

handle_error() {
    error_msg="$1"
    print_error "$error_msg"
    printf "%sYour choice: %s" "${CYAN}" "${NC}"
    read _
    return 1
}
