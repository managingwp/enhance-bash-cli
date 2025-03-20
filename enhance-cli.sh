#!/usr/bin/env bash
# =================================================================================================
# -- enhance-cli - Enhance CLI Library
# --
# -- A simple bash script to interface with the enhance API at https://apidocs.enhance.com/
# =================================================================================================

# ==================================
# -- Variables
# ==================================
SCRIPT_NAME="enhance-cli"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VERSION="$(cat "${SCRIPT_DIR}/VERSION")"
DEBUG="0"
# shellcheck disable=SC2034
DRYRUN="0"
QUIET="0"

# ==================================
# -- Command Help Variables
# ==================================
typeset -gA ebc_commands_type
ebc_commands_type[general]="General Actions"
ebc_commands_type[org]="Organization Actions"
ebc_commands_type[plan]="Plan Actions"
ebc_commands_type[website]="Website Actions"
ebc_commands_type[subscriptions]="Subscription Actions"
ebc_commands_type[servers]="Server Actions"
ebc_commands_type[apps]="Apps Actions"
ebc_commands_type[domains]="Domains Actions"

typeset -gA ebc_commands_general
ebc_commands_general[status]="Get status of the Enhance API"
# shellcheck disable=SC2034
ebc_commands_general[settings]="Get settings of the Enhance API"

typeset -gA ebc_commands_tools
# shellcheck disable=SC2034
ebc_commands_tools[site]="Get site information, either provide domain or domain ID"

typeset -gA ebc_commands_org
ebc_commands_org[org-info]="Get organization information"
# shellcheck disable=SC2034
ebc_commands_org[org-customers]="Get organization customers information"

typeset -gA ebc_commands_plan
# shellcheck disable=SC2034
ebc_commands_plan[plan-info]="Get plan information"

typeset -gA ebc_commands_website
ebc_commands_website[websites]="Get website information"
ebc_commands_website[website-get]="Get website information"
# shellcheck disable=SC2034
ebc_commands_website[website-create]="Create a website"


typeset -gA ebc_commands_subscriptions
# shellcheck disable=SC2034
ebc_commands_subscriptions[subscriptions]="Get subscription information"

typeset -gA ebc_commands_servers
# shellcheck disable=SC2034
ebc_commands_servers[servers]="Get server information"

typeset -gA ebc_commands_apps
ebc_commands_apps[apps-list]="Get installable apps"
# shellcheck disable=SC2034
ebc_commands_apps[app-create]="Create create app on website"

typeset -gA ebc_commands_domains
ebc_commands_domains[domains]="Get domain information"
ebc_commands_domains[domain-id]="Get domain information by ID"
ebc_commands_domains[domain-info]="Get domain information"
ebc_commands_domains[domains-summary]="Get domain summary information"
ebc_commands_domains[ssl]="Get SSL information for a domain"
ebc_commands_domains[ssl-summary]="Get SSL summary information for a domain"
ebc_commands_domains[lets-encrypt-pre-flight]="Pre-flight check for lets encrypt for domain"
# shellcheck disable=SC2034
ebc_commands_domains[lets-encrypt-create]="Create lets encrypt certificate for domain"


# ==================================
# -- Include cf-inc.sh and cf-api-inc.sh
# ==================================
source "${SCRIPT_DIR}/enhance-inc.sh"
source "${SCRIPT_DIR}/enhance-inc-api.sh"

# ==============================================================================================
# -- Functions
# ==============================================================================================
# -- Help
function _help () {
        # -- Array of options with descriptions
    declare -A usage_option
    usage_option[org_id]="Show this help message and exit"
    usage_option[domain]="Domain name to check"

        # -- Array for optional arguments
    declare -A optional_args
    optional_args[help]="Show this help message"
    optional_args[debug]="Enable debug mode"
    optional_args[debug_json]="Output debug information as JSON"
    optional_args[quiet]="Enable quiet mode"
    optional_args[json]="Output as JSON"
    optional_args[core-functions]="List core functions"

    _print_options () {
        # -- Print the options typeset array
        _running "Options:"
        echo
        for option in "${!usage_option[@]}"; do
            printf "  %-25s %s\n" "--${option}" "${usage_option[$option]}"
        done
        
        # -- Print the optional arguments typeset array
        echo ""
        _running "Optional:"
        echo ""
        for arg in "${!optional_args[@]}"; do
            printf "  %-25s %s\n" "--${arg}" "${optional_args[$arg]}"
        done
    }

    echo "Usage: $SCRIPT_NAME [OPTIONS] -c <command> [ARGS]"
    echo
    echo "Enhance API CLI"
    echo
    _running "Commands:"
    _help_print_commands
    echo   
    _print_options
    echo
    echo "Version: $VERSION - $SCRIPT_NAME - Author: https://managingWP.io"
}


# =====================================
# -- _help_print_commands
# -- Print commands
# =====================================
function _help_print_commands () {
    # -- Go through each type
    for TYPE in "${!ebc_commands_type[@]}"; do
        _running "${ebc_commands_type[$TYPE]}"
        # -- Go through each command
        declare -n arr="ebc_commands_$TYPE"
        for COMMAND in "${!arr[@]}"; do
            # -- Don't pass the function to the help
            IFS='|' read -r -a CMD_DESC <<< "${arr[$COMMAND]}"
            printf "  %-25s - %s\n" "$COMMAND" "${CMD_DESC[0]}"        
        done
        echo
    done
}

# ==============================================================================================
# -- Main
# ==============================================================================================
ARG_DEBUG=()
ALL_ARGS="$*"
# -- Parse options
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
    key="$1"

    case $key in
		-c|--command)
		CMD="$2"
        ARG_DEBUG+=(CMD)
		shift # past argument
		shift # past variable
		;;
        -o|--org-id)
        ORG_ID="$2"
        ARG_DEBUG+=(ORG_ID)
        shift # past argument
        shift # past variable
        ;;
        -d|--domain)
        DOMAIN="$2"
        ARG_DEBUG+=(DOMAIN)
        shift # past argument
        shift # past variable
        ;;
        -h|--help)
        _cf_partner_help
        exit 0
        ;;
        --quiet)
        # shellcheck disable=SC2034
        QUIET="1"
        ARG_DEBUG+=(QUIET)
        shift # past argument
        ;;
        --debug)
        # shellcheck disable=SC2034
        DEBUG="1"
        ARG_DEBUG+=(DEBUG)
        shift # past argument
        ;;
        --debug-json)
        # shellcheck disable=SC2034
        DEBUG_JSON="1"
        ARG_DEBUG+=(DEBUG_JSON)
        shift # past argument
        ;;        
        --core-functions)
        _list_core_functions
        exit 0
        ;;
        --json)
        # shellcheck disable=SC2034
        JSON="1"
        ARG_DEBUG+=(JSON)
        shift # past argument
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
    done
set -- "${POSITIONAL[@]}" # restore positional parameters

# -- Commands
_debug "ALL_ARGS: $ALL_ARGS"
_debug "ARG_DEBUG: ${ARG_DEBUG[*]}"
for ARG in "${ARG_DEBUG[@]}"; do
    _debug "$ARG: ${!ARG}"
done
# -- pre-flight check
_debug "Pre-flight_check"
_pre_flight_check

[[ -z $CMD ]] && { _help; _error "No command specified"; exit 1; }
_running "Enhance CLI - $CMD"
[[ -n $ORG_ID ]] && { _debug "ORG_ID: $ORG_ID"; _running2 "\$ORG_ID specified via .enhance"; }


# ==================================
if [[ $CMD == "status" ]]; then
    _enhance_status
elif [[ $CMD == "settings" ]]; then
    _enhance_settings
# -- Tools
elif [[ $CMD == "site" ]]; then
    [[ -z $ORG_ID ]] && ORG_ID="$1"
    _enhance_org_tool_site "$ORG_ID" "$1"
elif [[ $CMD == "org-info" ]]; then
    [[ -z $ORG_ID ]] && ORG_ID="${*}"
    _enhance_org_info "$ORG_ID"
elif [[ $CMD == "org-customers" ]]; then
    _enhance_org_customers "$@"
elif [[ $CMD == "plan-info" ]]; then
    _enhance_plan_info "$@"
elif [[ $CMD == "websites" ]]; then
    _enhance_org_websites "$@"
elif [[ $CMD == "website-get" ]]; then
    _enhance_org_website_get "$@"
elif [[ $CMD == "website-create" ]]; then
    _enhance_org_website_create "$@"
elif [[ $CMD == "subscriptions" ]]; then
    _enhance_org_subscriptions "$@"
elif [[ $CMD == "servers" ]]; then
    _enhance_org_servers "$@"
elif [[ $CMD == "apps" ]]; then
    _enhance_apps "$@"
elif [[ $CMD == "app-create" ]]; then
    _enhance_app_create "$@"
elif [[ $CMD == "domains" ]]; then
    [[ -z $ORG_ID ]] && ORG_ID="${*}"
    _enhance_org_domains "$ORG_ID"
elif [[ $CMD == "domain-id" ]]; then
    [[ -z $ORG_ID ]] && ORG_ID="${*}"
    [[ -z $DOMAIN ]] && { _error "No domain specificed, use --domain"; exit 1; }
elif [[ $CMD == "domain-info" ]]; then
    [[ -z $ORG_ID ]] && ORG_ID="${*}"
    [[ -z $DOMAIN ]] && { _error "No domain specificed, use --domain"; exit 1; }
    _enhance_org_domain_info "$ORG_ID" "$DOMAIN"
elif [[ $CMD == "domains-summary" ]]; then
    [[ -z $ORG_ID ]] && ORG_ID="${*}"
    _enhance_org_domains_summary "$ORG_ID"
    _enhance_org_domain_get_id "$ORG_ID" "$DOMAIN"
elif [[ $CMD == "ssl" ]]; then
    [[ -z $DOMAIN ]] && { _error "No domain specificed, use --domain"; exit 1; }
    _enhance_ssl "$DOMAIN"
elif [[ $CMD == "ssl-summary" ]]; then
    [[ -z $ORG_ID ]] && ORG_ID="${*}"    
    _enhance_ssl_summary "$ORG_ID"
elif [[ $CMD == "lets-encrypt-pre-flight" ]]; then
    _enhance_lets_encrypt_pre_flight "$@"
elif [[ $CMD == "lets-encrypt-create" ]]; then    
    _enhance_lets_encrypt_create "$@"
# -- Help
elif [[ $CMD == "help" ]]; then
    _help
    exit 0
else     
    _help
    _error "Command not found: $CMD"
    exit 1
fi