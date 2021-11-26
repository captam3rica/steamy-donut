#!/usr/bin/env zsh

# GitHub: @captam3rica

###################################################################################################
#
#   A tool to install applications directly from the internet.
#
#   This script has the following capabilities
#
#       - Determine if the app is already installed. If not installed then the script will run a
#         fresh installation of the app.
#       - Determine the verion of the currently installed app.
#       - Verify that the length of the version numbers are equal, find the differnce and append
#         that number of zeros to the shorter version number.
#       - Compare the current installed version to the packaged app version. The packaged version
#         will only be installed if it is newer than the currently installed version.
#
###################################################################################################
#
#   Changelog:
#
###################################################################################################

VERSION="0.4.0"

# zsh has a built-in operator that can actually do float compares; just gotta load it
autoload is-at-least

###################################################################################################
####################################### VARIABLES #################################################
###################################################################################################

LANG="US"

# Define this scripts current working directory
SCRIPT_DIR="$(/usr/bin/dirname $0)"

# The present working directory
HERE="$(pwd)"

# Script name
SCRIPT_NAME="$(/usr/bin/basename $0)"

declare -a ARGS_ARRAY

# Contains all arguments passed
ARGS_ARRAY=("${@}")

###################################################################################################
########################### FUNCTIONS - DO NOT MODIFY BELOW #######################################
###################################################################################################

usage() {
    # Print this tools usage
    echo "usage: $SCRIPT_NAME [-h] [--donut-menu] [--donut-recipe <keyword>] [--order-donut <keyword>] [--version]"
}

help_message() {
    # Print this tools help information

    # Add usage output to help message
    echo "$(usage)"
    echo ""
    echo "Easily install locally packaged apps without installing over a newer version, or download and install publicly "
    echo "avaialble apps directly from the internet."
    echo "arguments:"
    echo "      --donut-menu            See a list of apps available for internet download."
    echo "      --donut-recipe          See more info about a particular app."
    echo "      --order-donut           Download and install specified app from the internet. For example, to download and "
    echo "                              install the latest version of Google Chrome use the following flag and app keyword: "
    echo ""
    echo "                                  $SCRIPT_NAME --order-donut googlechrome"
    echo ""
    echo "      --version               Print current version of $SCRIPT_NAME"
    echo "      -h, --help              Print this help message."
    echo ""
    echo "examples:"
    echo ""
    exit
}

donut_menu() {
    # Return a list of available internet downloads.
    echo ""
    echo "The following applications can be downloaded"
    echo ""
    echo "      App:                        Keyword:"
    echo "      ----------------------------------------------------------"
    echo "      Adobe Reader DC             adobereaderdc"
    echo "      Atom.io                     atom"
    echo "      Chromium                    chromium"
    echo "      DEPNotify                   depnotify"
    echo "      Firefox                     firefox"
    echo "      FirefoxESR                  firefoxesr"
    echo "      Google Chrome               googlechrome"
    # echo "      Hancock                     hancock"
    # echo "      Hyper                       hyper"
    echo "      Low Profile                 lowprofile"
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
    echo "      Packages                    packages"
    # echo "      Platypus                    platypus"
    echo "      SAP icons                   sap-icons"
    echo "      SAP Privileges              sap-privileges"
    echo "      Slack                       slack"
    echo "      Suspicious Packaged         suspicious-package"
    echo "      TechSmith Snagit            snagit-latest"
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
    printf "%s %s\n" "$DATE" "$log_statement" >>"$LOG_PATH"
}

return_os_version() {
    # Return the OS Version with "_" instead of "."
    /usr/bin/sw_vers -productVersion | sed 's/[.]/_/g'
}

get_current_user() {
    # Grab current logged in user
    printf '%s' "show State:/Users/ConsoleUser" |
        /usr/sbin/scutil |
        /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}'
}

get_current_user_uid() {
    # Check to see if the current console user uid is greater than 501
    # Loop until either the 501 or 502 user is found.

    # Get the current console user again
    current_user="$1"

    CURRENT_USER_UID=$(/usr/bin/dscl . -list /Users UniqueID |
        /usr/bin/grep "$current_user" |
        /usr/bin/awk '{print $2}' |
        /usr/bin/sed -e 's/^[ \t]*//')

    while [ $CURRENT_USER_UID -lt 501 ]; do
        logging "" "Current user is not logged in ... WAITING"
        /bin/sleep 1

        # Get the current console user again
        current_user="$(get_current_user)"
        CURRENT_USER_UID=$(/usr/bin/dscl . -list /Users UniqueID |
            /usr/bin/grep "$current_user" |
            /usr/bin/awk '{print $2}' |
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
        file_type="dmg"
        url="https://get.adobe.com/reader/download/?installer=Reader_DC_2020.009.20063_for_Mac_Intel&stype=7601&standalone=1"
        expected_team_id="EQHXZ8M8AV"
        ;;

    atom)
        app_name="Atom.app"
        file_type="zip"
        release_name="atom-mac.zip"
        url="$(get_github_download_url atom atom $release_name)"
        expected_team_id="VEKTX9H2N7"
        ;;

    # NOTE: spctl is not able to find a valid signing certificate
    # NOTE: Install at your own risk
    chromium)
        app_name="Chromium.app"
        file_type="zip"
        url="https://download-chromium.appspot.com/dl/Mac"
        expected_team_id="NOT_FOUND"
        ;;

    depnotify)
        app_name="DEPNotify.app"
        file_type="pkg"
        url="https://files.nomad.menu/DEPNotify.pkg"
        expected_team_id="VRPY9KHGX6"
        target_directory="/Applications/Utilities"
        ;;

    firefox)
        app_name="Firefox.app"
        file_type="pkg"
        url="https://download.mozilla.org/?product=firefox-pkg-latest-ssl&os=osx&lang=en-US"
        expected_team_id="43AQ936H96"
        blockingProcesses=(firefox)
        ;;

    firefoxesr)
        app_name="Firefox.app"
        file_type="pkg"
        url="https://download.mozilla.org/?product=firefox-esr-pkg-latest-ssl&os=osx"
        expected_team_id="43AQ936H96"
        blocking_processes=(firefox)
        ;;

    googlechrome)
        app_name="Google Chrome.app"
        file_type="dmg"
        url="https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"
        expected_team_id="EQHXZ8M8AV"
        ;;

    hancock)
        name="Hancock"
        type="dmg"
        url=$(downloadURLFromGit JeremyAgost Hancock)
        expected_team_id="SWD2B88S58"
        ;;

    hyper)
        app_name="Hyper.app"
        file_type="dmg"
        if [[ $(arch) == i386 ]]; then
            release_name="mac-x64.dmg"
        elif [[ $(arch) == arm64 ]]; then
            release_name="mac-arm64.dmg"
        fi
        url="$(get_github_download_url vercel hyper $release_name)"
        expected_team_id="JW6Y669B67"
        ;;

    lowprofile)
        app_name="Low Profile.app"
        file_type="pkg"
        release_name="Low.Profile.*.pkg" # Use a wild card to match the latest version
        url="$(get_github_download_url ninxsoft LowProfile $release_name)"
        expected_team_id="7K3HVCLV7Z"
        ;;

    microsoftautoupdate)
        app_name="Microsoft AutoUpdate.app"
        file_type="pkg"
        url="https://go.microsoft.com/fwlink/?linkid=830196"
        expected_team_id="UBF8T346G9"
        # commented the update_tool for MSAutoupdate, because when Autoupdate is
        # really old or broken, you want to force a new install
        # update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
        # update_toolArguments=( --install --apps MSau04 )
        ;;

    microsoftcompanyportal)
        app_name="Company Portal.app"
        file_type="pkg"
        url="https://go.microsoft.com/fwlink/?linkid=869655"
        expected_team_id="UBF8T346G9"
        update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
        update_toolArguments=(--install --apps IMCP01)
        ;;

    microsoftdefenderatp)
        app_name="Microsoft Defender ATP.app"
        file_type="pkg"
        url="https://go.microsoft.com/fwlink/?linkid=2097502"
        expected_team_id="UBF8T346G9"
        update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
        update_toolArguments=(--install --apps WDAV00)
        ;;

    microsoftedgeenterprisestable)
        app_name="Microsoft Edge.app"
        file_type="pkg"
        url="https://go.microsoft.com/fwlink/?linkid=2093438"
        expected_team_id="UBF8T346G9"
        update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
        update_toolArguments=(--install --apps EDGE01)
        ;;

    microsoftexcel)
        app_name="Microsoft Excel.app"
        file_type="pkg"
        url="https://go.microsoft.com/fwlink/?linkid=525135"
        expected_team_id="UBF8T346G9"
        update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
        update_toolArguments=(--install --apps XCEL2019)
        ;;

    microsoftonedrive)
        app_name="OneDrive.app"
        file_type="pkg"
        url="https://go.microsoft.com/fwlink/?linkid=823060"
        expected_team_id="UBF8T346G9"
        update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
        update_toolArguments=(--install --apps ONDR18)
        ;;

    microsoftonenote)
        app_name="Microsoft OneNote.app"
        file_type="pkg"
        url="https://go.microsoft.com/fwlink/?linkid=820886"
        expected_team_id="UBF8T346G9"
        update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
        update_toolArguments=(--install --apps ONMC2019)
        ;;

    microsoftoutlook)
        app_name="Microsoft Outlook.app"
        file_type="pkg"
        url="https://go.microsoft.com/fwlink/?linkid=525137"
        expected_team_id="UBF8T346G9"
        update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
        update_toolArguments=(--install --apps OPIM2019)
        ;;

    microsoftpowerpoint)
        app_name="Microsoft PowerPoint.app"
        file_type="pkg"
        url="https://go.microsoft.com/fwlink/?linkid=525136"
        expected_team_id="UBF8T346G9"
        update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
        update_toolArguments=(--install --apps PPT32019)
        ;;

    microsoftremotedesktop)
        app_name="Microsoft Remote Desktop.app"
        file_type="pkg"
        url="https://go.microsoft.com/fwlink/?linkid=868963"
        expected_team_id="UBF8T346G9"
        update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
        update_toolArguments=(--install --apps MSRD10)
        ;;

    microsoftsharepointplugin)
        app_name="MicrosoftSharePointPlugin.app"
        file_type="pkg"
        url="https://go.microsoft.com/fwlink/?linkid=800050"
        expected_team_id="UBF8T346G9"
        # TODO: determine blocking_processes for SharePointPlugin
        ;;

    microsoftteams)
        app_name="Microsoft Teams.app"
        file_type="pkg"
        url="https://go.microsoft.com/fwlink/?linkid=869428"
        expected_team_id="UBF8T346G9"
        blocking_processes=(Teams "Microsoft Teams Helper")
        update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
        update_toolArguments=(--install --apps TEAM01)
        ;;

    microsoftword)
        app_name="Microsoft Word.app"
        file_type="pkg"
        url="https://go.microsoft.com/fwlink/?linkid=525134"
        expected_team_id="UBF8T346G9"
        update_tool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
        update_toolArguments=(--install --apps MSWD2019)
        ;;

    # NOTE: Packages is signed but _not_ notarized, so spctl will reject it
    packages)
        app_name="Packages.app"
        file_type="dmg"
        pkg_name="Install Packages.pkg"
        downloadURL="http://s.sudre.free.fr/Software/files/Packages.dmg"
        expectedTeamID="NL5M9E394P"
        ;;

    platypus)
        app_name="platypus.app"
        file_type="dmg"
        url="https://sveinbjorn.org/files/software/platypus.zip"
        expected_team_id=""
        ;;

    sap-icons)
        app_name="Icons.app"
        file_type="zip"
        release_name="Icons.zip"
        url="$(get_github_download_url SAP macOS-icon-generator $release_name)"
        expected_team_id="7R5ZEU67FQ"
        ;;

    sap-privileges)
        app_name="Privileges.app"
        file_type="zip"
        release_name="Privileges.zip"
        url="$(get_github_download_url SAP macOS-enterprise-privileges $release_name)"
        expected_team_id="7R5ZEU67FQ"
        ;;

    slack)
        app_name="Slack"
        file_type="dmg"
        url="https://slack.com/ssb/download-osx"
        expected_team_id="BQR82RBBHL"
        ;;

    snagit-latest)
        app_name="Snagit.app"
        file_type="dmg"
        url="https://download.techsmith.com/snagitmac/releases/Snagit.dmg"
        expected_team_id=""
        ;;

    suspicious-package)
        app_name="Suspicious Package.app"
        file_type="dmg"
        downloadURL="https://mothersruin.com/software/downloads/SuspiciousPackage.dmg"
        expectedTeamID="936EB786NH"
        ;;

    visualstudiocode)
        app_name="Visual Studio Code.app"
        file_type="zip"
        url="https://go.microsoft.com/fwlink/?LinkID=620882"
        expected_team_id="UBF8T346G9"
        blocking_processes=(Electron)
        ;;

    *)
        usage
        echo ""
        echo "  \"$app_keyword\" is not a valid keyword. Try make sure you have entered the correct keyword. "
        echo "  Used --donut-menu to see available keywords ..."
        echo ""
        exit 0
        ;;
    esac
}

get_github_download_url() {
    # Determine the latest download URL from github.
    account_name="$1"
    repo_name="$2"
    file_name="$3"
    bdu="browser_download_url"

    base_url="https://api.github.com/repos/$account_name/$repo_name/releases/latest"

    git_url=$(/usr/bin/curl --fail --silent "$base_url" |
        /usr/bin/awk '{ if ($1 ~ /'$bdu'/ && $2 ~ /'$file_name'/) print $2 }' |
        /usr/bin/sed -e 's/"//g')

    if [[ -z "$git_url" ]]; then
        echo "Unabled to determine the git download url for $account_name ..."
        exit 1
    fi

    echo "$git_url"
}

donut_recipe() {
    # Return more information about an app download

    donut="$1"
    # Return the application information for the specified donut ...
    return_app_download_info "$donut"

    echo ""
    echo "Donut Recipe Information"
    echo "------------------------"
    echo ""

    echo "  Application Name:         $app_name"
    echo "  Install File Type:        $type"
    if [[ "$release_name" ]]; then
        echo "  GitHub Release Name:      $release_name"
    fi
    echo "  Download URL:             $url"
    echo "  Team ID:                  $expected_team_id"
    if [[ "$blocking_processes" ]]; then
        echo "  Blocking Process:     $blocking_processes"
    fi
    if [[ "$update_tool" ]]; then
        echo "  Update Tool:              $update_tool"
    fi
    echo ""
}

downloader() {
    # Download an app from the internet using curl
    #
    # $1 Name of the application
    # $2 url used to download the app
    # $3 the filetype expected
    tmp_dir="/tmp/steamy-donut"
    download_name=$(/usr/bin/basename "$1" | /usr/bin/awk -F "." '{print $1}')

    # Make sure that the tmp download directory exits
    /bin/mkdir -p "$tmp_dir"

    echo "Should be dl url: $2"

    # Use curl to pulldown the app
    /usr/bin/curl --location --max-redirs 3 "$2" --output "$tmp_dir/$download_name.$3"

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

app_search() {
    # Search for an app. If found return the path to the app otherwise return "None"
    #
    #   The application must exist on the local Mac and the name of the app must match the
    #   application that is passed to the function. If any of these conditions are not met the
    #   function will return of "None"
    #
    # $1 - Is the name of the application.
    local app_name="$1"
    local app_path=""

    # Uses the find binary to look for the app inside of the /Applications and /System/
    # Applications directories up to 2 levels deep.
    app_path="$(/usr/bin/find /Applications /System/Applications -maxdepth 2 -name $app_name)"

    # Check to see if the app is installed.
    if [[ ! -e $app_path ]] || [[ $app_name != "$(/usr/bin/basename $app_path)" ]]; then
        # If the previous command returns true and the returned object exists and the app name
        # that we are looking for is exactly equal to the app name found by the find command.
        app_path="None"
    fi

    # Return the value of app_path
    echo "$app_path"
}

return_installed_app_version() {
    # Return the currently installed application version
    local path="$1"
    local inst_vers=""

    inst_vers=$(/usr/bin/defaults read "$path/Contents/Info.plist" CFBundleShortVersionString)

    if [[ $? -ne 0 ]]; then
        #statements
        inst_vers="None"
    fi

    echo "$inst_vers"
}

sanitize_app_version_number() {
    # Make sure the app version number is in a form that can be used for comparison
    #
    # version_number: $1 is the first parameter passed to the function. It represents an
    #                 Application's version number. The version number can be obtained
    #                 programatically or manually passed to this function.
    local version_number="$1"
    local santized_version

    # rem ( with: s/[`(]//g'
    # rem ) with: s/[`)]//g'
    santized_version="$(echo $version_number | /usr/bin/sed -e 's/[[:space:]]//g' -e 's/[`(]/./g' -e 's/[`)]//g' -e 's/[`-]/./g')"

    echo "$santized_version"
}

vers_check() {
    # is-at-least is a zsh built-in for float math
    # returns exit 0 for true, exit 1 for false, so we can use || OR separators here
    is-at-least "$1" "$2" && echo "greater than or equal to" || echo "less than"
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

        received_team_id="$(/usr/sbin/spctl -a -vv -t install $installer_path 2>&1 |
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
        received_team_id="$(/usr/sbin/spctl -a -vv $installer_path 2>&1 |
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

check_running_processes() {
    # Check for running processes so that we can close them
    continue
}

install_package() {
    # Install a .pkg file.
    #
    # $1 - The full path to the package.
    # $2 - The target directory i.e. "/"
    local pkg="$1"
    local target="$2"

    # If a custom install path is not passed set $target to "/"
    if [[ -z "$target" ]]; then
        target="/"
    fi

    echo "Attempting to install $app_installer_path ..."

    # install the package that was found
    /usr/sbin/installer -dumplog -verbose -pkg "$pkg" -target "$target"
    RET="$?"

    # Make sure the installer didn't fail.
    if [ "$RET" -ne 0 ]; then
        # Send the installation error to the logger
        /usr/bin/logger "Failed to install $pkg ..."
        echo "Check /var/log/installer.log"
        RESULT=1
    fi

}

move_app_to_applications() {
    # Move .app to Applications folder
    # This function will move a .app file to the Applications folder.
    continue
}

mount_dmg() {
    # Mount dmg files
    echo "Mounting dmg ..."
    continue
}

install_dmg() {
    echo "Would install a .dmg file ..."
    continue
}

clean_up() {
    # Cleanup after
}

###################################################################################################
############################ MAIN LOGIC - DO NOT MODIFY BELOW #####################################
###################################################################################################

# Initialize some variables
local os_version="$(return_os_version)"
local current_user="$(get_current_user)"
local current_user_uid="$(get_current_user_uid $current_user)"

# Validate Args
# Don't forget that zsh array index start at 1 and not zero
for ((i = 0; i <= ${#ARGS_ARRAY[@]}; i++)); do

    # Validate if no agrs given, -h, or --help are passed.
    if [[ ${#ARGS_ARRAY[@]} -eq 0 ]] || [[ "${ARGS_ARRAY}" == "-h" ]] ||
        [[ "${ARGS_ARRAY}" == "--help" ]]; then
        # Print this tool's help message
        help_message
    fi

    if [[ "${ARGS_ARRAY[$i]}" == "--donut-menu" ]]; then
        donut_menu
        exit 0
    fi

    if [[ "${ARGS_ARRAY[$i]}" == "--donut-recipe" ]]; then
        donut="${ARGS_ARRAY[$i + 1]}"
        donut_recipe "$donut"
        if [[ "$donut" == "" ]]; then
            printf "Error: Please enter app keyword!\n"
            usage
            exit 1
        fi
        exit 0
    fi

    # Is is possible to accept more that one app at one time???

    if [[ "${ARGS_ARRAY[$i]}" == "--order-donut" ]]; then

        # Declare an array to store a list of apps to download.
        # declare -a donut_download_list

        # Loop over the arguments and append app keywards to a list
        for ((i = 1; i < ${#ARGS_ARRAY[@]} + 1; i++)); do

            # Make sure that we are not capturing a command argument
            # Filters out the command arguments by looking for anything that
            # dosen't contain "--"
            if [[ "${ARGS_ARRAY[$i]}" != *"--"* ]]; then
                # Return the specified keyword.
                donut="${ARGS_ARRAY[$i]}"

                # Append the donut to the list
                # If we eventually support having multiple apps downloaded at one time.
                # Right now just one app can be downloaded at a time.
                # donut_download_list+=("$donut")

            fi

        done

        if [[ "$donut" == "" ]]; then
            printf "Error: Please enter app keyword!\n"
            usage
            exit 1
        fi
    fi

    if [[ "${ARGS_ARRAY[$i]}" == "--version" ]]; then
        echo "$VERSION"
        exit
    fi

done

echo "$donut"

# Return the information needed to download the donut.
# This info is passed to the downloader function
return_app_download_info "$donut"

exit 0

# Download the application
downloader "$app_name" "$url" "$file_type"

echo ""

exit 0

printf "Checking to see if $app_name is installed ...\n"
installed_version="$(return_installed_app_version $app_name)"

# Look for the app
app_install_path="$(app_search $APP_NAME)"

# Check to make sure that the app is installed on the system before doing anything else.
if [[ $app_install_path == "None" ]]; then
    echo "$APP_NAME not installed ..."
    echo "Starting installation process ..."
    exit 1
else
    echo "$APP_NAME is installed at $app_install_path"
fi

# Get the installed version
installed_version="$(return_installed_app_version $app_install_path)"

# Make sure that the installed app version can be found before moving on.
if [[ $installed_version == "None" ]]; then
    echo "App version could not be determined for $APP_NAME"
    echo "Starting installation process ..."
    exit 1
fi

# Make the version number have the same dot format (x.x.x.x.n) for comparisons sake.
installed_app_vers_sanitized="$(sanitize_app_version_number $installed_version)"
min_enforced_app_vers_sanitized="$(sanitize_app_version_number $MINIMUM_ENFORCED_VERSION)"

# Compare minimum enforced version to installed version
echo "Comparing minimum enforced version to installed version ..."
version_check="$(vers_check $min_enforced_app_vers_sanitized $installed_app_vers_sanitized)"

if [[ $version_check == *"less"* ]]; then
    echo "$APP_NAME version \"$installed_version\" is installed and is $version_check min enforced version \"$MINIMUM_ENFORCED_VERSION\" ..."
    echo "Upgrading $APP_NAME ..."
    exit 1
else
    echo "$APP_NAME version \"$installed_version\" is installed and is $version_check min enforced version \"$MINIMUM_ENFORCED_VERSION\" ..."
    echo "Nothing to do ..."
    exit 0
fi

echo "$installed_version"

# Call main
main

exit "$RESULT"
