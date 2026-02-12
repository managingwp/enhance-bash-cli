# =============================================================================
# -- enhance-bash-cli - Core library
# =============================================================================

# =============================================================================
# -- Variables
# =============================================================================
REQUIRED_APPS=("jq" "column")
typeset -gA ebc_functions

# ==================================
# -- Colors
# ==================================
NC=$(tput sgr0)
CRED='\e[0;31m'
CRED=$(tput setaf 1)
CYELLOW=$(tput setaf 3)
CGREEN=$(tput setaf 2)
CBLUEBG=$(tput setab 4)
CLIGHTBLUE=$(tput setaf 4)
CCYAN=$(tput setaf 6)
CGRAY=$(tput setaf 7)
CDARKGRAY=$(tput setaf 8)

# =============================================================================
# -- Core Functions
# =============================================================================

# =====================================
# -- messages
# =====================================

_error () { [[ $QUIET == "0" ]] && echo -e "${CRED}** ERROR ** - ${*} ${NC}" >&2; [[ $QUIET == "1" ]] && _debug "ERROR: ${*}"; } 
_warning () { [[ $QUIET == "0" ]] && echo -e "${CYELLOW}** WARNING ** - ${*} ${NC}"; [[ $QUIET == "1" ]] && _debug "WARNING: ${*}"; }
_success () { [[ $QUIET == "0" ]] && echo -e "${CGREEN}** SUCCESS ** - ${*} ${NC}"; [[ $QUIET == "1" ]] && _debug "SUCCESS: ${*}"; }
_running () { [[ $QUIET == "0" ]] && echo -e "${CBLUEBG}${*}${NC}"; [[ $QUIET == "1" ]] && _debug "${*}"; }
_running2 () { [[ $QUIET == "0" ]] && echo -e " * ${CLIGHTBLUE}${*}${NC}"; [[ $QUIET == "1" ]] && _debug "${*}"; }
_running3 () { [[ $QUIET == "0" ]] && echo -e " ** ${CDARKGRAY}${*}${NC}"; [[ $QUIET == "1" ]] && _debug "${*}"; }
_creating () { [[ $QUIET == "0" ]] && echo -e "${CGRAY}${*}${NC}"; [[ $QUIET == "1" ]] && _debug "${*}"; }
_separator () { [[ $QUIET == "0" ]] && echo -e "${CYELLOWBG}****************${NC}"; [[ $QUIET == "1" ]] && _debug "${*}"; }
_dryrun () { [[ $QUIET == "0" ]] && echo -e "${CCYAN}** DRYRUN: ${*$}${NC}"; [[ $QUIET == "1" ]] && _debug "${*}"; }
_usage () { [[ $QUIET == "0" ]] && echo -e "${*}"; [[ $QUIET == "1" ]] && _debug "${*}"; }
_quiet () { [[ $QUIET == "1" ]] && echo -e "${*}"; }

# =====================================
# -- _debug $*
# -- Debug messaging
# =====================================
ebc_functions[_debug]="Debug messaging"
_debug () {
    if [[ $DEBUG == "1" ]]; then
        # Print ti stderr
        echo -e "${CCYAN}** DEBUG ** - ${*}${NC}" >&2
    fi
}

# =====================================
# -- _debug_json_file $*
# -- Debug messaging for json
# =====================================
ebc_functions[_debug_json_file]="Debug messaging for json"
_debug_json_file () {
    if [[ $DEBUG_JSON == "1" ]]; then
        echo -e "${*}" >> /tmp/debug.json
    fi
}

# =====================================
# -- _list_core_functions
# -- List all core functions
# =====================================
ebc_functions[_list_core_functions]="List all core functions"
function _list_core_functions () {
    _running "Listing all core functions with descriptions"
    # Print header
    printf "%-40s | %-60s | %s\n" "Function" "Description" "Count"
    printf "%s-+-%s-+-%s\n" "$(printf '%0.s-' {1..40})" "$(printf '%0.s-' {1..60})" "$(printf '%0.s-' {1..10})"
    
    # Loop through array, printing key and value
    for FUNC_NAME in "${!ebc_functions[@]}"; do
        # -- Count how many times the function is used in the script
        FUNC_COUNT=$(grep "$FUNC_NAME" $SCRIPT_DIR/*.sh | wc -l)
        DESCRIPTION="${ebc_functions[$FUNC_NAME]}"
        printf "%-40s | %-60s | %s\n" "$FUNC_NAME" "$DESCRIPTION" "$FUNC_COUNT"
    done
}

# =====================================
# -- _pre_flight_check
# -- Check to make sure apps and api credentials are available
# =====================================
ebc_functions[_pre_flight_check]="Check to make sure apps and api credentials are available"
function _pre_flight_check () {
    # -- Check enhance creds
    _debug "Checking for enhance credentials"
    _check_api_creds

    # -- Check required
    _debug "Checking for required apps"
    _check_required_apps

    # -- Check bash
    _debug "Checking for bash version"
    _check_bash

    # -- Check debug
    _debug "Checking for debug"
    _check_debug
}

# =====================================
# -- _parse_profiles
# -- Parse INI-style profiles from .enhance file
# -- Populates AVAILABLE_PROFILES array and
# -- PROFILE_DATA_<name>_<KEY> variables
# =====================================
ebc_functions[_parse_profiles]="Parse profiles from .enhance config"
function _parse_profiles () {
    local config_file="$HOME/.enhance"
    AVAILABLE_PROFILES=()

    if [[ ! -f "$config_file" ]]; then
        _error "Config file not found: $config_file"
        _error "Create $config_file with at least one profile section. Example:"
        _error ""
        _error "  [default]"
        _error "  API_TOKEN=your_token"
        _error "  API_URL=https://api.example.com"
        _error "  ORG_ID=your_org_id"
        _error "  CLUSTER_ORG_ID=your_cluster_org_id"
        exit 1
    fi

    local current_profile=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        # Trim leading/trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Check for section header [profile_name]
        if [[ "$line" =~ ^\[([a-zA-Z0-9_-]+)\]$ ]]; then
            current_profile="${BASH_REMATCH[1]}"
            AVAILABLE_PROFILES+=("$current_profile")
            _debug "Found profile: $current_profile"
            continue
        fi

        # Parse key=value lines under a section
        if [[ -n "$current_profile" ]] && [[ "$line" =~ ^([A-Z_]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            # Store as PROFILE_DATA_<profile>_<key>
            local var_name="PROFILE_DATA_${current_profile//-/_}_${key}"
            printf -v "$var_name" '%s' "$value"
            _debug "Profile $current_profile: $key set"
        fi
    done < "$config_file"

    if [[ ${#AVAILABLE_PROFILES[@]} -eq 0 ]]; then
        _error "No profile sections found in $config_file."
        _error "Wrap your credentials in a named section. Example:"
        _error ""
        _error "  [default]"
        _error "  API_TOKEN=your_token"
        _error "  API_URL=https://api.example.com"
        _error "  ORG_ID=your_org_id"
        _error "  CLUSTER_ORG_ID=your_cluster_org_id"
        exit 1
    fi

    _debug "Available profiles: ${AVAILABLE_PROFILES[*]}"
}

# =====================================
# -- _load_profile <profile_name>
# -- Load a specific profile's variables into globals
# =====================================
ebc_functions[_load_profile]="Load a profile's credentials into environment"
function _load_profile () {
    local profile_name="$1"
    local safe_name="${profile_name//-/_}"

    local token_var="PROFILE_DATA_${safe_name}_API_TOKEN"
    local url_var="PROFILE_DATA_${safe_name}_API_URL"
    local org_var="PROFILE_DATA_${safe_name}_ORG_ID"
    local cluster_var="PROFILE_DATA_${safe_name}_CLUSTER_ORG_ID"

    API_TOKEN="${!token_var}"
    API_URL="${!url_var}"

    # Only set ORG_ID from profile if not already set via CLI (-o/--org-id)
    if [[ -z "$CLI_ORG_ID" ]]; then
        ORG_ID="${!org_var}"
    fi
    CLUSTER_ORG_ID="${!cluster_var}"

    _debug "Loaded profile: $profile_name"
}

# =====================================
# -- _select_profile
# -- Select and load a profile
# -- Uses $PROFILE if set, else prompts if multiple exist
# =====================================
ebc_functions[_select_profile]="Select and load a profile from .enhance"
function _select_profile () {
    _parse_profiles

    # If --profile was specified, validate and load it
    if [[ -n "$PROFILE" ]]; then
        local found=0
        for p in "${AVAILABLE_PROFILES[@]}"; do
            if [[ "$p" == "$PROFILE" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            _error "Profile '$PROFILE' not found in \$HOME/.enhance"
            _error "Available profiles: ${AVAILABLE_PROFILES[*]}"
            exit 1
        fi
        _load_profile "$PROFILE"
        _running2 "Using profile: $PROFILE"
        return
    fi

    # If only one profile, auto-select
    if [[ ${#AVAILABLE_PROFILES[@]} -eq 1 ]]; then
        PROFILE="${AVAILABLE_PROFILES[0]}"
        _load_profile "$PROFILE"
        _running2 "Using profile: $PROFILE"
        return
    fi

    # Multiple profiles — prompt user
    echo ""
    _running "Select a profile:"
    echo ""
    local i=1
    for p in "${AVAILABLE_PROFILES[@]}"; do
        printf "  %d) %s\n" "$i" "$p"
        ((i++))
    done
    echo ""

    local selection
    while true; do
        read -rp "Enter profile number [1]: " selection
        selection="${selection:-1}"

        if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#AVAILABLE_PROFILES[@]} )); then
            PROFILE="${AVAILABLE_PROFILES[$((selection-1))]}"
            _load_profile "$PROFILE"
            _running2 "Using profile: $PROFILE"
            return
        else
            _error "Invalid selection. Enter a number between 1 and ${#AVAILABLE_PROFILES[@]}."
        fi
    done
}

# =====================================
# -- _check_api_creds
# -- Check for API credentials
# =====================================
function _check_api_creds () {
    # Save CLI-provided ORG_ID before profile loading can overwrite it
    if [[ -n "$ORG_ID" ]]; then
        CLI_ORG_ID="$ORG_ID"
    fi

    if [[ -n $API_TOKEN ]]; then
        _running "Found \$API_TOKEN via environment, using for authentication."
    else
        # Load from profile
        _select_profile
    fi

    # Validate required credentials
    if [[ -z $API_TOKEN ]]; then
        _error "API_TOKEN not set. Check your profile in \$HOME/.enhance."
        exit 1
    fi

    if [[ -z $API_URL ]]; then
        _error "API_URL not set. Check your profile in \$HOME/.enhance."
        exit 1
    fi

    # Restore CLI ORG_ID if it was set
    if [[ -n "$CLI_ORG_ID" ]]; then
        ORG_ID="$CLI_ORG_ID"
    fi
}

# =====================================
# -- _check_required_apps $REQUIRED_APPS
# -- Check for required apps
# =====================================
function _check_required_apps () {
    for app in "${REQUIRED_APPS[@]}"; do
        if ! command -v $app &> /dev/null; then
            _error "$app could not be found, please install it."
            exit 1
        fi
    done

    _debug "All required apps found."
}

# ===============================================
# -- _check_bash - check version of bash
# ===============================================
function _check_bash () {
	# - Check bash version and _die if not at least 4.0
	if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
		_die "Sorry, you need at least bash 4.0 to run this script." 1
	fi
}

# ===============================================
# -- _check_debug
# ===============================================
function _check_debug () {
	if [[ $DEBUG == "1" ]]; then
		echo -e "${CYAN}** DEBUG: Debugging is on${ECOL}" >&2
	elif [[ $DEBUG_CURL_OUTPUT == "2" ]]; then
		echo -e "${CYAN}** DEBUG: Debugging is on + CURL OUTPUT${ECOL}"	
	fi
}

# =====================================
# -- _json_from_kv
# -- Create JSON from key=value pairs
# =====================================
ebc_functions[_json_from_kv]="Create JSON from key=value pairs"
function _json_from_kv() {
    local json=""
    local first=1
    local key
    local value

    for pair in "$@"; do
        # Split the pair into key and value
        key="${pair%%=*}"
        value="${pair#*=}"

        # Add comma if not the first pair
        if [[ $first -eq 1 ]]; then
            first=0
        else
            json="$json,"
        fi

        # Check if value is numeric or boolean
        if [[ $value =~ ^[0-9]+$ ]] || [[ $value == "true" ]] || [[ $value == "false" ]] || [[ $value == "null" ]]; then
            # Numeric or boolean values don't need quotes
            json="$json\"$key\":$value"
        else
            # String values need quotes
            json="$json\"$key\":\"$value\""
        fi
    done

    json="{$json}"
    echo "$json"
}

# =====================================
# -- _generate_password
# -- Generate a random password
# =====================================
ebc_functions[_generate_password]="Generate a random password"
function _generate_password() {
    local length="${1:-16}"
    local password
    password=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$length")
    echo "$password"
}