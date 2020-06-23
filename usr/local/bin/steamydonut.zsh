#!/usr/bin/env zsh

# GitHub: @captam3rica

########################################################################################
#
#   A script to install a packaged app and optionally set
#   default preferences if the set_default_preferences.sh script is present.
#
#   This script has the following capabilities
#
#       - Determine if the app is already installed. If not installed then the script
#         will run a fresh installation of the app.
#       - Determine the verion of the currently installed app.
#       - Verify that the length of the version numbers are equal, find the
#         differnce and append that number of zeros to the shorter version number.
#       - Compare the current installed version to the packaged app version. The
#         packaged version will only be installed if it is newer than the currently
#         installed version.
#
########################################################################################


VERSION="0.3.0"


# Define this scripts current working directory
SCRIPT_DIR=$(/usr/bin/dirname "$0")

# The present working directory
HERE="$(pwd)"

# Script name
SCRIPT_NAME="$(/usr/bin/basename $0)"

declare -a ARGS_ARRAY

# Contains all arguments passed
ARGS_ARRAY=("${@}")


main() {
    # Run the main logic

    # Declare arrays that will hold version numbers.
    declare -a pkg_vers_array
    declare -a inst_vers_array

    # Validate Args
    # Don't forget that zsh array index start at 1 and not zero
    for (( i = 0; i <= ${#ARGS_ARRAY[@]}; i++ )); do

        # Validate if no agrs given, -h, or --help are passed.
        if [[ ${#ARGS_ARRAY[@]} -eq 0 ]] || [[ "${ARGS_ARRAY}" == "-h" ]] || \
            [[ "${ARGS_ARRAY}" == "--help" ]]; then
            # Print this tool's help message
            help_message
        fi

        if [[ "${ARGS_ARRAY[$i]}" == "--list-donuts" ]]; then
            available_internet_downlowds
            exit 0
        fi

        if [[ "${ARGS_ARRAY[$i]}" == "--get-donut" ]]; then
            # Return the specified keyword.
            donut="${ARGS_ARRAY[$i+1]}"
            if [[ "$donut" == "" ]]; then printf "Error: Please enter app keyword!\n"; usage; exit 1; fi
        fi

        if [[ "${ARGS_ARRAY[$i]}" == "--version" ]]; then; echo "$VERSION"; exit; fi

    done

    # Initialize some variables
    local os_version="$(return_os_version)"
    local current_user="$(get_current_user)"
    local current_user_uid="$(get_current_user_uid $current_user)"


    # Check to see if we are installing a application from the internet
    if [[ "$donut" ]]; then

        # Return the application information for the specified donut ...
        return_app_download_info "$donut"

        echo "$app_name"
        echo "$type"
        echo "$url"
        echo "$expected_team_id"

        if [[ "$blocking_processes" ]]; then
            echo "$blocking_processes"
        fi

        if [[ "$update_tool" ]]; then
            echo "$update_tool"
        fi
    fi


    printf "Checking to see if $app_name is installed ...\n"
    installed_version="$(return_installed_app_version $app_name)"

    echo "$installed_version"

    exit 0

    # See if the app is not installed.
    if [ $installed_version = "None" ]; then
        printf "The app is currently not installed ...\n"
        printf "Installing the app for the first time ...\n"
        install_package "$pkg_path" "/"

        # If the set_default_preferences.sh script is present in the installer.
        if [[ -f "$HERE/set_default_preferences.sh" ]]; then
            printf "Setting default settings for %s.app ...\n" "$app_name"
            /bin/zsh "$HERE/set_default_preferences.sh"
        fi

    else

        printf "%s is installed ...\n" "$app_name"
        printf "Packaged version: %s\n" "$app_version"
        printf "Installed version: %s\n" "$installed_version"

        # Loop over the packaged version and append version numbers to array.
        # Splits the version number on the "."
        # ${(@s/./)app_version}
        for number in "${(@s/./)app_version}"; do
            pkg_vers_array+=("$number")
        done

        # Loop over the installed version and append version numbers to array.
        # Splits the version number on the "."
        for number in "${(@s/./)installed_version}"; do
            inst_vers_array+=("$number")
        done

        # Care version numbers lengths and return result.
        vers_num_len_result="$(compare_version_number_lengths ${#pkg_vers_array[@]} ${#inst_vers_array[@]})"

        if [[ "$vers_num_len_result" -eq 1 ]]; then
            # Append zeros to installed version array so that it matches the length of
            # the packaged version array length.
            printf "Package version number is longer ...\n"
            printf "Appending zeros to version ...\n"
            for (( i = ${#inst_vers_array[@]}; i < ${#pkg_vers_array[@]}; i++ )); do
                inst_vers_array+=(0)
            done
        fi

        if [[ "$vers_num_len_result" -eq 2 ]]; then
            #statements
            printf "Package version number is shorter ...\n"
            printf "Appending zeros to version ...\n"
            for (( i = ${#pkg_vers_array[@]}; i < ${#inst_vers_array[@]}; i++ )); do
                pkg_vers_array+=(0)
            done
        fi

        # Compare the packaged version to the current installed version
        version_comparison="$(compare_versions ${#pkg_vers_array[@]} ${#inst_vers_array[@]})"

        # See if the packaged version is OLDER than or EQUAL to the installed version.
        if [[ "$version_comparison" == "OLDER" ]] || [[ "$version_comparison" == "EQUAL" ]]; then
            # No need to install an older or equal version.
            printf "Packaged version is "%s" ...\n" "$version_comparison"
            printf "Skipping installation ...\n"
            RESULT=1

        else
            printf "Installing %s ...\n" "$PKG"
            install_package "$pkg_path" "/"

            # If the set_default_preferences.sh script is present in the installer.
            if [[ -f "$HERE/set_default_preferences.sh" ]]; then
                printf "Setting default settings for %s.app ...\n" "$app_name"
                /bin/zsh "$HERE/set_default_preferences.sh"
            fi
        fi
    fi
}


usage(){
    # Print this tools usage
    echo "usage: $SCRIPT_NAME [-h] --app-name <\"app_name\"> --app-version <version> --pkg-name <\"package_name\"> "
    echo         "[--path <full_path>] [--list-donuts] [--get-donut <keyword>] [--version]"
}


help_message() {
    # Print this tools help information

    # Add usage output to help message
    echo "$(usage)"
    echo ""
    echo "Easily install locally packaged apps without installing over a newer version, or download and install publicly "
    echo "avaialble apps directly from the internet."
    echo ""
    echo "arguments:"
    echo "      --list-donuts   See a list of apps available for internet download."
    echo ""
    echo "      --get-donut     Download and install specified app from the internet. For example, to download and "
    echo "                      install the latest version of Google Chrome use the following flag and app keyword: "
    echo ""
    echo "                          $SCRIPT_NAME --get-donut googlechrome"
    echo ""
    echo "      --version       Print current version of $SCRIPT_NAME"
    echo ""
    echo "      -h, --help      Print this help message."
    echo ""
    echo "examples:"
    echo ""
    exit
}


available_internet_downlowds() {
    # Return a list of available internet downloads.
    echo ""
    echo "available internet downloads:"
    echo ""
    echo "      App:                        Keyword:"
    echo "      ----------------------------------------------------------"
    # echo "      Adobe Reader DC             adobereaderdc"
    echo "      Google Chrome               googlechrome"
    echo "      Microsoft AutoUpdate        microsoftautoupdate"
    echo "      Microsoft Company Portal    microsoftcompanyportal"
    echo "      Microsoft Defender ATP      microsoftdefenderatp"
    echo "      Microsoft Edge              microsoftedgeenterprisestable"
    echo "      Microsoft Excel             microsoftexcel"
    echo "      Microsoft OneDrive          microsoftonedrive"
    echo "      Microsoft OneNote           microsoftonenote"
    echo "      Microsoft Outlook           microsoftoutlook"
    echo "      Microsoft PPT               microsoftpowerpoint"
    echo "      Microsoft Remote Desktop    microsoftremotedesktop"
    echo "      Microsoft SharePointPlugin  microsoftsharepointplugin"
    echo "      Microsoft Teams             microsoftteams"
    echo "      Microsoft Word              microsoftword"
    echo "      Visual Studio Code          visualstudiocode"
    echo ""
}


logging() {
    # Pe-pend text and print to standard output
    # Takes in a log level and log string.
    # Example: logging "INFO" "Something describing what happened."

    log_level=$(printf "$1" | /usr/bin/tr '[:lower:]' '[:upper:]')
    log_statement="$2"
    LOG_FILE="$SCRIPT_NAME""_log-$(date +"%Y-%m-%d").log"
    LOG_PATH="$ROOT_LIB/Logs/$LOG_FILE"

    if [ -z "$log_level" ]; then
        # If the first builtin is an empty string set it to log level INFO
        log_level="INFO"
    fi

    if [ -z "$log_statement" ]; then
        # The statement was piped to the log function from another command.
        log_statement=""
    fi

    DATE=$(date +"[%b %d, %Y %Z %T $log_level]:")
    printf "%s %s\n" "$DATE" "$log_statement" >> "$LOG_PATH"
}


return_os_version() {
    # Return the OS Version with "_" instead of "."
    /usr/bin/sw_vers -productVersion | sed 's/[.]/_/g'
}


get_current_user() {
    # Grab current logged in user
    printf '%s' "show State:/Users/ConsoleUser" | \
        /usr/sbin/scutil | \
        /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}'
}


get_current_user_uid() {
    # Check to see if the current console user uid is greater than 501
    # Loop until either the 501 or 502 user is found.

    # Get the current console user again
    current_user="$1"

    CURRENT_USER_UID=$(/usr/bin/dscl . -list /Users UniqueID | \
        /usr/bin/grep "$current_user" | \
        /usr/bin/awk '{print $2}' | \
        /usr/bin/sed -e 's/^[ \t]*//')

    while [ $CURRENT_USER_UID -lt 501 ]; do
        logging "" "Current user is not logged in ... WAITING"
        /bin/sleep 1

        # Get the current console user again
        current_user="$(get_current_user)"
        CURRENT_USER_UID=$(/usr/bin/dscl . -list /Users UniqueID | \
            /usr/bin/grep "$current_user" | \
            /usr/bin/awk '{print $2}' | \
            /usr/bin/sed -e 's/^[ \t]*//')
        if [ $CURRENT_USER_UID -lt 501 ]; then
            logging "" "Current user: $current_user with UID ..."
        fi
    done
    printf "%s\n" "$CURRENT_USER_UID"
}


return_app_download_info() {
    # Return app info based on keyword passed.
    #
    # Args:
    #   $1: app_keyword

    local app_keyword="$1"

    # Alot of these dowload links were pulled from the
    # https://github.com/scriptingosx/Installomator project from scriptingosx :)
    case $app_keyword in
        adobereaderdc)
            app_name="Adobe Reader DC.app"
            type="dmg"
            url="https://get.adobe.com/reader/download/?installer=Reader_DC_2020.009.20063_for_Mac_Intel&stype=7601&standalone=1"
            expected_team_id="EQHXZ8M8AV"
            ;;

        googlechrome)
            app_name="Google Chrome.app"
            type="dmg"
            url="https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"
            expected_team_id="EQHXZ8M8AV"
            ;;

        microsoftautoupdate)
            app_name="Microsoft AutoUpdate.app"
            type="pkg"
            url="https://go.microsoft.com/fwlink/?linkid=830196"
            expected_team_id="UBF8T346G9"
            # commented the update_tool for MSAutoupdate, because when Autoupdate is
            # really old or broken, you want to force a new install
            # update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            # update_toolArguments=( --install --apps MSau04 )
            ;;

        microsoftcompanyportal)
            app_name="Company Portal.app"
            type="pkg"
            url="https://go.microsoft.com/fwlink/?linkid=869655"
            expected_team_id="UBF8T346G9"
            update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            update_toolArguments=( --install --apps IMCP01 )
            ;;

        microsoftdefenderatp)
            app_name="Microsoft Defender ATP.app"
            type="pkg"
            url="https://go.microsoft.com/fwlink/?linkid=2097502"
            expected_team_id="UBF8T346G9"
            update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            update_toolArguments=( --install --apps WDAV00 )
            ;;

        microsoftedgeenterprisestable)
            app_name="Microsoft Edge.app"
            type="pkg"
            url="https://go.microsoft.com/fwlink/?linkid=2093438"
            expected_team_id="UBF8T346G9"
            update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            update_toolArguments=( --install --apps EDGE01 )
            ;;

        microsoftexcel)
            app_name="Microsoft Excel.app"
            type="pkg"
            url="https://go.microsoft.com/fwlink/?linkid=525135"
            expected_team_id="UBF8T346G9"
            update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            update_toolArguments=( --install --apps XCEL2019 )
            ;;

        microsoftonedrive)
            app_name="OneDrive.app"
            type="pkg"
            url="https://go.microsoft.com/fwlink/?linkid=823060"
            expected_team_id="UBF8T346G9"
            update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            update_toolArguments=( --install --apps ONDR18 )
            ;;

        microsoftonenote)
            app_name="Microsoft OneNote.app"
            type="pkg"
            url="https://go.microsoft.com/fwlink/?linkid=820886"
            expected_team_id="UBF8T346G9"
            update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            update_toolArguments=( --install --apps ONMC2019 )
            ;;

        microsoftoutlook)
            app_name="Microsoft Outlook.app"
            type="pkg"
            url="https://go.microsoft.com/fwlink/?linkid=525137"
            expected_team_id="UBF8T346G9"
            update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            update_toolArguments=( --install --apps OPIM2019 )
            ;;

        microsoftpowerpoint)
            app_name="Microsoft PowerPoint.app"
            type="pkg"
            url="https://go.microsoft.com/fwlink/?linkid=525136"
            expected_team_id="UBF8T346G9"
            update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            update_toolArguments=( --install --apps PPT32019 )
            ;;

        microsoftremotedesktop)
            app_name="Microsoft Remote Desktop.app"
            type="pkg"
            url="https://go.microsoft.com/fwlink/?linkid=868963"
            expected_team_id="UBF8T346G9"
            update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            update_toolArguments=( --install --apps MSRD10 )
            ;;

        microsoftsharepointplugin)
            app_name="MicrosoftSharePointPlugin.app"
            type="pkg"
            url="https://go.microsoft.com/fwlink/?linkid=800050"
            expected_team_id="UBF8T346G9"
            # TODO: determine blocking_processes for SharePointPlugin
            ;;

        microsoftteams)
            app_name="Microsoft Teams.app"
            type="pkg"
            url="https://go.microsoft.com/fwlink/?linkid=869428"
            expected_team_id="UBF8T346G9"
            blocking_processes=( Teams "Microsoft Teams Helper" )
            update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            update_toolArguments=( --install --apps TEAM01 )
            ;;

        microsoftword)
            app_name="Microsoft Word.app"
            type="pkg"
            url="https://go.microsoft.com/fwlink/?linkid=525134"
            expected_team_id="UBF8T346G9"
            update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            update_toolArguments=( --install --apps MSWD2019 )
            ;;

        visualstudiocode)
            app_name="Visual Studio Code.app"
            type="zip"
            url="https://go.microsoft.com/fwlink/?LinkID=620882"
            expected_team_id="UBF8T346G9"
            appName="Visual Studio Code.app"
            blocking_processes=( Electron )
            ;;
    esac
}


return_installed_app_version() {
    # Return the current application version
    #
    # $1 - Is the full path to the application.
    local app_name="$1"
    local installed_version=""

    local find_app="$(/usr/bin/find /Applications -maxdepth 3 -name $app_name)"
    local ret="$?"

    # Check to see if the app is installed.
    if [[ "$ret" -eq 0 ]] && [[ -d "$find_app" ]] \
        && [[ "$app_name" == "$(/usr/bin/basename $find_app)" ]]; then
        # If the previous command returns true and the returned object is a directory
        # and the app that we are looking for is exactly equal to the app found by the
        # find command.

        # Gets the installed app version and replaces any "-" with "."
        installed_version=$(/usr/bin/defaults read \
            "$find_app/Contents/Info.plist" CFBundleShortVersionString | \
            /usr/bin/sed "s/-/./g")

    else
        installed_version="None"
    fi

    printf "%s" "$installed_version"
}


get_latest_downloadable_version() {
    # Return the latest app version

    local os_version="$1"

    ## Set the User Agent string for use with curl
	user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X $os_version) AppleWebKit/535.6.2 (KHTML, like Gecko) Version/5.2 Safari/535.6.2"

    lv=$(/usr/bin/curl -s -A "$user_agent" https://www.mozilla.org/$LANG/firefox/new/ | grep 'data-latest-firefox' | sed -e 's/.* data-latest-firefox="\(.*\)".*/\1/' -e 's/\"//' | /usr/bin/awk '{print $1}')

    # Return the latest version
    printf "%s\n" "$lv"
}


compare_version_number_lengths() {
    # Check to see if the array lengths are equal
    #
    # Args:
    #   $1: pkg_vers_nums array
    #   $2: inst_vers_nums array
    local pkg_vers_nums="$1"
    local inst_vers_nums="$2"
    local result=""

    if [[ "$pkg_vers_nums" -gt "$inst_vers_nums" ]]; then
        # Packaged array length is greater than installed array length.
        result=1
        printf "%s" "$result"
    fi

    if [[ "$pkg_vers_nums" -lt "$inst_vers_nums" ]]; then
        # Packaged array length is less than installed array length.
        result=2
        printf "%s" "$result"
    fi
}


compare_versions() {
    # Compare packaged version to installed version.
    #
    #   NOTE: pkg_vers_array and inst_vers_array array variables could not be passed
    #         directly to this function. Instead they are inherited by this function
    #         from the main function where the arrays are declared. This is due to
    #         spaces being counted as additional index pointers when the arrays are
    #         passed to this function as parameters.
    #
    # Args:
    #   $1: package version array length
    #   $2: installed version array length
    local pkg_vers_array_len="$1"
    local inst_vers_array_len="$2"
    local result=""

    # Compare each verson number in the packaged version to the version numbers in the
    # installed version at each level to determine if the packaged version is older,
    # newer, or the same as the installed version.
    for (( i = 1; i <= $pkg_vers_array_len || i <= $inst_vers_array_len; i++ )); do
        # Loop over the version numbers
        # i starts at 1 because zshell array indexes start at 1

        if [[ "${pkg_vers_array[$i]}" -eq "${inst_vers_array[$i]}" ]]; then
            # See if the version numbers are equal

            if [[ "$i" -eq "${#pkg_vers_array[@]}" ]]; then
                # All version numbers are equal.
                # Packaged version is the same as the intalled version
                result="EQUAL"
                printf "%s" "$result"
            fi
        fi

        if [[ "${pkg_vers_array[$i]}" -gt "${inst_vers_array[$i]}" ]]; then
            # See if packaged version number is greater than installed version
            # number.
            result="NEWER"
            printf "%s" "$result"
            break
        fi

        if [[ "${pkg_vers_array[$i]}" -lt "${inst_vers_array[$i]}" ]]; then
            # See if the pacakged version number is less than installed version
            # number.
            result="OLDER"
            printf "%s" "$result"
            break
        fi

    done
}


verify_installer_team_id() {
    # Verify the Team ID associated with the installation media.
    #
    # Args:
    #   $1: The path to the install media.
    installer_path="$1"

    verified=False

    if [[ "$(/usr/bin/basename $installer_path | /usr/bin/awk -F '.' '{print $NF}')" == "pkg" ]]; then
        # Validate a .pkg

        received_team_id="$(/usr/sbin/spctl -a -vv -t install $installer_path 2>&1 | \
            /usr/bin/awk '/origin=/ {print $NF}' | /usr/bin/tr -d '()')"
        ret="$?"

        # Make sure that we didn't receive an error from spctl
        if [[ "$ret" -ne 0 ]]; then
            printf "Error validating $installer_path ...\n"
            printf "Exiting installer ...\n"
            exit "$ret"
        fi

    else
        # Validate a .app
        received_team_id="$(/usr/sbin/spctl -a -vv $installer_path 2>&1 | \
            /usr/bin/awk '/origin=/ {print $NF}' | /usr/bin/tr -d '()')"
        ret="$?"

        # Make sure that we didn't receive an error from spctl
        if [[ "$ret" -ne 0 ]]; then
            printf "Error validating $installer_path ...\n"
            printf "Exiting installer ...\n"
            exit "$ret"
        fi

    fi

    # Check to see if the Team IDs are not equal
    if [[ "$received_team_id" == "$EXPECTED_TEAM_ID" ]]; then
        verified=True
    else
        verified=False
    fi

    # Return verified
    printf "$verified\n"
}


install_package() {
    # Install a .pkg file.
    #
    # $1 - The full path to the package.
    # $2 - The target directory i.e. "/"
    local pkg="$1"
    local target="$2"

    # Install the pacakge
    /usr/sbin/installer -dumplog -verbose -pkg "$pkg" -target "$target"
    RET="$?"

    # Make sure the installer didn't fail.
    if [ "$RET" -ne 0 ]; then
        # Send the installation error to the logger
        /usr/bin/logger "Failed to install $pkg ..."
        RESULT=1
    fi
}


install_dmg() {
    echo "Would install a .dmg file ..."
}


# Call main
main

exit "$RESULT"
