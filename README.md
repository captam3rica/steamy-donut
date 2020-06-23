# Steamy Donut

![](https://img.shields.io/badge/release-0.2.1-blue)&nbsp;
![](https://img.shields.io/badge/code-zshell-blue)&nbsp;
![](https://img.shields.io/badge/syntax-bashisms-blue)&nbsp;
![](https://img.shields.io/badge/macOS-10.14%2B-success)&nbsp;

<p align=center>
<b>NOTE</b>: THE CONTENTS OF THIS REPO ARE A WORK IN PROGRESS ... PLEASE TEST IN YOUR ENVIRONMENT BEFORE PUTTING INTO PRODUCTION AND FEEDBACK IS APPRECIATED ☺️
</p>

Easily download and install software that is available directly from the internet. (Examples: Google Chrome Browser, FireFox, Microsoft Office Suite)


## Usage

```
usage: steamydonut.zsh [-h] --app-name <"app_name"> --app-version <version> --pkg-name <"package_name"> 
[--path <full_path>] [--list-donuts] [--get-donut <keyword>] [--version]

Easily install locally packaged apps without installing over a newer version, or download and install publicly 
avaialble apps directly from the internet.

arguments:
      --list-donuts   See a list of apps available for internet download.

      --get-donut     Download and install specified app from the internet. For example, to download and 
                      install the latest version of Google Chrome use the following flag and app keyword: 

                          steamydonut.zsh --get-donut googlechrome

      --version       Print current version of steamydonut.zsh

      -h, --help      Print this help message.

examples:
```


## Examples


### List Donuts

![](images/steamydonut_list_donuts.gif)


##   TODO:

✅ - Turn this tool into a command line Utility  
🔲 - handle .dmg installs  
🔲 - Add builtin internet installers for common apps
