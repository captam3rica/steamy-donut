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


VERSION="0.2.1"

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
    for (( i = 1; i <= ${#ARGS_ARRAY[@]}; i++ )); do

        # Validate if no agrs given, -h, or --help are passed.
        if [[ "${#ARGS_ARRAY}" == 0 ]] || [[ "${ARGS_ARRAY}" == "-h" ]] || \
            [[ "${ARGS_ARRAY}" == "--help" ]]; then
            # Print this tool's help message
            help_message
        fi

        if [[ "${ARGS_ARRAY[$i]}" == "--app-name" ]]; then
            APP_NAME="${ARGS_ARRAY[$i+1]}"
            # Make sure that an app name was passed.
            if [[ "$APP_NAME" == "" ]]; then printf "Error: Please enter app name!\n"; usage; exit 1; fi
        fi

        if [[ "${ARGS_ARRAY[$i]}" == "--app-version" ]]; then
            APP_VERSION="$(/bin/echo ${ARGS_ARRAY[$i+1]} | /usr/bin/sed 's/-/./g')"
            if [[ "$APP_VERSION" == "" ]]; then printf "Error: Please enter app version!\n"; usage; exit 1; fi
        fi

        if [[ "${ARGS_ARRAY[$i]}" == "--pkg-name" ]]; then
            PKG_NAME="${ARGS_ARRAY[$i+1]}"
            if [[ "$PKG_NAME" == "" ]]; then printf "Error: Please enter package name!\n"; usage; exit 1; fi
        fi

        if [[ "${ARGS_ARRAY[$i]}" == "--path" ]]; then
            PKG_PATH="${ARGS_ARRAY[$i+1]}"
            if [[ "$PKG_PATH" == "" ]]; then printf "Error: Please enter package path!\n"; usage; exit 1; fi
        fi

        if [[ "${ARGS_ARRAY[$i]}" == "--list-donuts" ]]; then
            available_internet_downlowds
            exit 0
        fi

        if [[ "${ARGS_ARRAY[$i]}" == "--get-donut" ]]; then
            # Download the specified app from the internet.
            exit 0
        fi

        if [[ "${ARGS_ARRAY[$i]}" == "--version" ]]; then; echo "$VERSION"; exit; fi

    done

    # Make sure that the required args are given
    if [[ -z "$APP_NAME" ]] || [[ -z "$APP_VERSION" ]] || [[ -z "$PKG_NAME" ]] ; then
        usage
        printf "$SCRIPT_NAME: Error: The following arguments are required: --app-name, --app-version, --pkg-name\n"
        exit 1
    fi

    # Determine the installer path.
    if [[ -e "$HERE/$PKG_NAME" ]] && [[ "$PKG_PATH" == "" ]]; then
        # If the --path flag is not passed assume the package is in the current working
        # directory.
        printf "%s found in %s ...\n" "$PKG_NAME" "$HERE"
        PKG_PATH="$HERE/$PKG_NAME"

    elif [[ "$PKG_PATH" != "" ]] && [[ -e "$PKG_PATH/$PKG_NAME" ]]; then
        printf "%s found at %s\n" "$PKG_NAME" "$PKG_PATH"
        PKG_PATH="$PKG_PATH/$PKG_NAME"

    elif [[ "$PKG_PATH" != "" ]] && [[ ! -e "$PKG_PATH/$PKG_NAME" ]]; then
        printf "Error: %s not found at %s\n" "$PKG_NAME" "$PKG_PATH"
        printf "       Please check the defined path ...\n"
        exit 1

    else
        printf "Error: Unable to locate %s in the current working directory ...\n" "$PKG_NAME"
        printf "       Please define a path to the package useing the --path flag.\n"
        usage
        exit 1
    fi

    printf "Checking to see if $APP_NAME is installed ...\n"
    installed_version="$(return_current_app_version $APP_NAME)"

    # See if the app is not installed.
    if [ $installed_version = "None" ]; then
        printf "The app is currently not installed ...\n"
        printf "Installing the app for the first time ...\n"
        install_package "$PKG_PATH" "/"

        # If the set_default_preferences.sh script is present in the installer.
        if [[ -f "$HERE/set_default_preferences.sh" ]]; then
            printf "Setting default settings for %s.app ...\n" "$APP_NAME"
            /bin/zsh "$HERE/set_default_preferences.sh"
        fi

    else

        printf "%s is installed ...\n" "$APP_NAME"
        printf "Packaged version: %s\n" "$APP_VERSION"
        printf "Installed version: %s\n" "$installed_version"

        # Loop over the packaged version and append version numbers to array.
        # Splits the version number on the "."
        # ${(@s/./)APP_VERSION}
        for number in "${(@s/./)APP_VERSION}"; do
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
            install_package "$PKG_PATH" "/"

            # If the set_default_preferences.sh script is present in the installer.
            if [[ -f "$HERE/set_default_preferences.sh" ]]; then
                printf "Setting default settings for %s.app ...\n" "$APP_NAME"
                /bin/zsh "$HERE/set_default_preferences.sh"
            fi
        fi
    fi
}


usage(){
    # Print this tools usage
    echo "usage: $SCRIPT_NAME [-h] --app-name <\"app_name\"> --app-version <version> --pkg-name <\"package_name\"> [--path <full_path>] [--list-donuts] [--get-donut <keyword>] [--version]"
}


help_message() {
    # Print this tools help information

    # Add usage output to help message
    echo "$(usage)"
    echo ""
    echo "Install packaged apps without accidently overwriting a newer version that may already be installed."
    echo ""
    echo "arguments:"
    echo "      --app-name      Application name. This should be how the app name appears in the /Applications "
    echo "                      folder or wherever the app is installed. If the app name contains spaces make "
    echo "                      sure to it in double quotes (\"\")."
    echo "                      Examples: \"Microsoft Teams.app\", Atom.app, or \"Google Chrome.app\""
    echo ""
    echo "      --app-version   Version of app being installed. The version number should be of the format X.X.X.X."
    echo "                      Examples: 1 or 1.1 or 1.1.1-1"
    echo ""
    echo "      --pkg-name      Name of package installer (your-installer.pkg)."
    echo ""
    echo "      --path          Path to installer. If a path is not provided it is assumed that the installer file "
    echo "                      is in the current working directory."
    echo ""
    echo "      --list-donuts   See a list of apps avaialbe for internet download."
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
    exit
}


available_internet_downlowds() {
    # Return a list of available internet downloads.
    echo ""
    echo "available internet downloads:"
    echo ""
    echo "      App:                        Keyword:"
    echo "      ----------------------------------------------------------"
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


return_app_url() {
    # Return app url based on parameters passed.
    #
    # Args:
    #   $1: app_keyword

    local app_keyword="$1"

    # Alot of these dowload links were pulled from the
    # https://github.com/scriptingosx/Installomator project from scriptingosx :)
    case $app_name in
        googlechrome)
            name="Google Chrome"
            type="dmg"
            url="https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"
            expectedTeamID="EQHXZ8M8AV"
            ;;

        microsoftautoupdate)
            name="Microsoft AutoUpdate"
            type="pkg"
            downloadURL="https://go.microsoft.com/fwlink/?linkid=830196"
            expectedTeamID="UBF8T346G9"
            # commented the updatetool for MSAutoupdate, because when Autoupdate is
            # really old or broken, you want to force a new install
            # updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            # updateToolArguments=( --install --apps MSau04 )
            ;;

        microsoftcompanyportal)
            name="Company Portal"
            type="pkg"
            downloadURL="https://go.microsoft.com/fwlink/?linkid=869655"
            expectedTeamID="UBF8T346G9"
            updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            updateToolArguments=( --install --apps IMCP01 )
            ;;

        microsoftdefenderatp)
            name="Microsoft Defender ATP"
            type="pkg"
            downloadURL="https://go.microsoft.com/fwlink/?linkid=2097502"
            expectedTeamID="UBF8T346G9"
            updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            updateToolArguments=( --install --apps WDAV00 )
            ;;

        microsoftedgeenterprisestable)
            name="Microsoft Edge"
            type="pkg"
            downloadURL="https://go.microsoft.com/fwlink/?linkid=2093438"
            expectedTeamID="UBF8T346G9"
            updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            updateToolArguments=( --install --apps EDGE01 )
            ;;

        microsoftexcel)
            name="Microsoft Excel"
            type="pkg"
            downloadURL="https://go.microsoft.com/fwlink/?linkid=525135"
            expectedTeamID="UBF8T346G9"
            updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            updateToolArguments=( --install --apps XCEL2019 )
            ;;

        microsoftonedrive)
            name="OneDrive"
            type="pkg"
            downloadURL="https://go.microsoft.com/fwlink/?linkid=823060"
            expectedTeamID="UBF8T346G9"
            updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            updateToolArguments=( --install --apps ONDR18 )
            ;;

        microsoftonenote)
            name="Microsoft OneNote"
            type="pkg"
            downloadURL="https://go.microsoft.com/fwlink/?linkid=820886"
            expectedTeamID="UBF8T346G9"
            updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            updateToolArguments=( --install --apps ONMC2019 )
            ;;

        microsoftoutlook)
            name="Microsoft Outlook"
            type="pkg"
            downloadURL="https://go.microsoft.com/fwlink/?linkid=525137"
            expectedTeamID="UBF8T346G9"
            updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            updateToolArguments=( --install --apps OPIM2019 )
            ;;

        microsoftpowerpoint)
            name="Microsoft PowerPoint"
            type="pkg"
            downloadURL="https://go.microsoft.com/fwlink/?linkid=525136"
            expectedTeamID="UBF8T346G9"
            updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            updateToolArguments=( --install --apps PPT32019 )
            ;;

        microsoftremotedesktop)
            name="Microsoft Remote Desktop"
            type="pkg"
            downloadURL="https://go.microsoft.com/fwlink/?linkid=868963"
            expectedTeamID="UBF8T346G9"
            updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            updateToolArguments=( --install --apps MSRD10 )
            ;;

        microsoftsharepointplugin)
            name="MicrosoftSharePointPlugin"
            type="pkg"
            downloadURL="https://go.microsoft.com/fwlink/?linkid=800050"
            expectedTeamID="UBF8T346G9"
            # TODO: determine blockingProcesses for SharePointPlugin
            ;;

        microsoftteams)
            name="Microsoft Teams"
            type="pkg"
            downloadURL="https://go.microsoft.com/fwlink/?linkid=869428"
            expectedTeamID="UBF8T346G9"
            blockingProcesses=( Teams "Microsoft Teams Helper" )
            updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            updateToolArguments=( --install --apps TEAM01 )
            ;;

        microsoftword)
            name="Microsoft Word"
            type="pkg"
            downloadURL="https://go.microsoft.com/fwlink/?linkid=525134"
            expectedTeamID="UBF8T346G9"
            updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
            updateToolArguments=( --install --apps MSWD2019 )
            ;;

        visualstudiocode)
            name="Visual Studio Code"
            type="zip"
            downloadURL="https://go.microsoft.com/fwlink/?LinkID=620882"
            expectedTeamID="UBF8T346G9"
            appName="Visual Studio Code.app"
            blockingProcesses=( Electron )
            ;;
    esac
}


return_current_app_version() {
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

    os_version="$1"

    ## Set the User Agent string for use with curl
	user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X $os_version) AppleWebKit/535.6.2 (KHTML, like Gecko) Version/5.2 Safari/535.6.2"

    lv=$(/usr/bin/curl -s -A "$user_agent" https://www.mozilla.org/$LANG/firefox/new/ | grep 'data-latest-firefox' | sed -e 's/.* data-latest-firefox="\(.*\)".*/\1/' -e 's/\"//' | /usr/bin/awk '{print $1}')

    # Return the latest version
    printf "%s\n" "$lv"
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


# Call main
main

exit "$RESULT"
