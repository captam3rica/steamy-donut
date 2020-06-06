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
#       - Verify that the length of the version numbers are equal and find the
#         differnce and append that number of zeros to the shorter version number.
#       - Compare the current installed version to the packaged app version. The
#         packaged version will only be installed if it is newer than the currently
#         installed version.
#
########################################################################################
#
#   TODO:
#
#       - [✅] Turn this tool into a command line Utility
#           - Flags: --app-name, --app-version, --package-name, --verson, -h, --help
#       - handle .dmg installs
#       - Add builtin downloads for common apps
#
########################################################################################


VERSION="1.1.0"

# Define the current working directory
HERE=$(/usr/bin/dirname "$0")

# Script name
SCRIPT_NAME="$(/usr/bin/basename $0)"

declare -a ARG_ARRAY

# Contains all arguments passed
ARG_ARRAY=("${@}")


usage(){
    # Print this tools usage
    echo "usage: $SCRIPT_NAME [-h] --app-name --app-version --package-name [--version]"
}


help_message() {
    # Print this tools help information

    echo "usage: $SCRIPT_NAME [-h] --app-name --app-version --package-name [--version]"
    echo ""
    echo "Install packaged apps without accidently overwriting a newer version that may already be installed."
    echo ""
    echo "arguments:"
    echo "    --app-name        Application name. This should be how the app name appears in the /Applications folder or"
    echo "                      wherever the app is installed."
    echo "                      Examples: \"Microsoft Teams.app\", \"Atom.app\", or \"Google Chrome.app\""
    echo ""
    echo "    --app-version     Version of app being installed. The version number should be of the format X.X.X.X."
    echo "                      Examples: 1 or 1.1 or 1.1.1.1"
    echo ""
    echo "    --pkg-name        Name of package installer (your-installer.pkg)."
    echo ""
    echo "    --version         Print current version of $SCRIPT_NAME"
    echo ""
    echo "    -h, --help        Print this help message."
    echo ""
    exit
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

main() {
    # Run the main logic

    # Validate Arguments
    if [[ "${#ARG_ARRAY}" == 0 ]] || [[ "${ARG_ARRAY}" == "-h" ]] || \
        [[ "${ARG_ARRAY}" == "--help" ]]; then
        # Print this tool's help message
        help_message
    fi

    # Validate the rest of the arguments
    for (( i = 1; i <= ${#ARG_ARRAY[@]}; i++ )); do

        if [[ "${ARG_ARRAY[$i]}" == "--app-name" ]]; then
            APP_NAME="${ARG_ARRAY[$i+1]}"

            # Make sure that an app name was passed.
            if [[ "$APP_NAME" == "" ]]; then printf "Error: Please enter app name!\n"; usage; exit 1; fi
        fi

        if [[ "${ARG_ARRAY[$i]}" == "--app-version" ]]; then
            APP_VERSION="${ARG_ARRAY[$i+1]}"
            if [[ "$APP_VERSION" == "" ]]; then printf "Error: Please enter app version!\n"; usage; exit 1; fi
        fi

        if [[ "${ARG_ARRAY[$i]}" == "--pkg-name" ]]; then
            PKG_NAME="${ARG_ARRAY[$i+1]}"
            if [[ "$PKG_NAME" == "" ]]; then printf "Error: Please enter package name!\n"; usage; exit 1; fi
        fi

        if [[ "${ARG_ARRAY[$i]}" == "--version" ]]; then
            echo "$VERSION"
        fi

    done

    # Make sure that the required args are given
    if [[ -z "$APP_NAME" ]] || [[ -z "$APP_VERSION" ]] || [[ -z "$PKG_NAME" ]] ; then
        usage
        printf "$SCRIPT_NAME: Error: The following arguments are required: --app-name, --app-version, --pkg-name\n"
        exit 1
    fi

    echo "App name: $APP_NAME"
    echo "App version: $APP_VERSION"
    echo "Package name: $PKG_NAME"


    exit

    # Declare arrays that will hold version numbers.
    declare -a pkg_vers_array
    declare -a inst_vers_array

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
            printf "Package version numbers is longer ...\n"
            printf "Appending zeros to version ...\n"
            for (( i = ${#inst_vers_array[@]}; i < ${#pkg_vers_array[@]}; i++ )); do
                inst_vers_array+=(0)
            done
        fi

        if [[ "$vers_num_len_result" -eq 2 ]]; then
            #statements
            printf "Package version numbers is shorter ...\n"
            printf "Appending zeros to version ...\n"
            for (( i = ${#pkg_vers_array[@]}; i < ${#inst_vers_array[@]}; i++ )); do
                pkg_vers_array+=(0)
            done
        fi

        # Compare the packaged version to the current installed version
        comparison_result="$(compare_versions ${#pkg_vers_array[@]} ${#inst_vers_array[@]})"


        if [[ "$comparison_result" == "OLDER" ]] || [[ "$comparison_result" == "EQUAL" ]]; then
            # No need to install an older or equal version.
            printf "Packaged version is "%s" ...\n" "$comparison_result"
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

# Call main
main

exit "$RESULT"
