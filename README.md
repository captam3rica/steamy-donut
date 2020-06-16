# Steamy Donut

![](https://img.shields.io/badge/release-0.2.1-blue)&nbsp;
![](https://img.shields.io/badge/code-zshell-blue)&nbsp;
![](https://img.shields.io/badge/syntax-bashisms-blue)&nbsp;
![](https://img.shields.io/badge/macOS-10.14%2B-success)&nbsp;

<p align=center>
<b>NOTE</b>: THE CONTENTS OF THIS REPO ARE A WORK IN PROGRESS ... PLEASE TEST IN YOUR ENVIRONMENT BEFORE PUTTING INTO PRODUCTION AND FEEDBACK IS APPRECIATED ☺️
</p>

Easily install packaged apps without installing over a newer version. Download and install software that is available directly from the internet. (Examples: Google Chrome Browser, FireFox, Microsoft Office Suite)

This project will start with installing local `.pkg` installers, but will grow to handle `.dmg` bundled installers, direct internet downloads, and other methods of installing macOS apps.

## Usage

```
usage: steamydonut.zsh [-h] --app-name <"app_name"> --app-version <version> --pkg-name <"package_name"> [--path <full_path>] [--list-donuts] [--get-donut <keyword>] [--version]

Install packaged apps without accidentally overwriting a newer version that may already be installed.

arguments:
      --app-name      Application name. This should be how the app name appears in the /Applications 
                      folder or wherever the app is installed. If the app name contains spaces make 
                      sure to it in double quotes ("").
                      Examples: "Microsoft Teams.app", Atom.app, or "Google Chrome.app"

      --app-version   Version of app being installed. The version number should be of the format X.X.X.X.
                      Examples: 1 or 1.1 or 1.1.1-1

      --pkg-name      Name of package installer (your-installer.pkg).

      --path          Path to installer. If a path is not provided it is assumed that the installer file 
                      is in the current working directory.

      --list-donuts   See a list of apps available for internet download.

      --get-donut     Download and install specified app from the internet. For example, to download and 
                      install the latest version of Google Chrome use the following flag and app keyword: 

                          steamydonut.zsh --get-donut googlechrome

      --version       Print current version of steamydonut.zsh

      -h, --help      Print this help message.
```


## Examples

### Older Package Version

![](images/steamydonut_older_pkg_version_demo.gif)


### List Donuts

![](images/steamydonut_list_donuts.gif)


##   TODO:

✅ - Turn this tool into a command line Utility  
🔲 - handle .dmg installs  
🔲 - Add builtin internet installers for common apps
