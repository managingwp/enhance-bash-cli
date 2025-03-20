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
# -- _check_api_creds
# -- Check for API credentials
# =====================================
function _check_api_creds () {
    local API_CRED_FILE="$HOME/.enhance"

    if [[ -n $API_TOKEN ]]; then
        _running "Found \$API_TOKEN via CLI using for authentication/."
    elif [[ -f "$API_CRED_FILE" ]]; then
        _debug "Found $API_CRED_FILE file."
        # shellcheck source=$API_CRED_FILE
        source "$API_CRED_FILE"
    
        if [[ ${API_TOKEN} ]]; then            
            _debug "Found \$API_TOKEN in $API_CRED_FILE using for authentication."            
        else
            _error "API_TOKEN not found in $API_CRED_FILE."
            exit 1
        fi
    fi

    if [[ -z $API_URL ]]; then
        _error "API_URL not found in $API_CRED_FILE."
        exit 1
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