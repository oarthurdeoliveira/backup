# Simple program to backup your files with rclone and zip!

## Features

## Dependencies
- Rclone
    - Remember to set a remote (with rclone config) before using the script!
- Zip

## Installation

Just clone the repository and put the backup script on your PATH and mark it as executable and run it!

### Examples

```
backup -f folder/file -r RcloneRemote:

backup -f $HOME -r googledrive:

backup -f $HOME/Images -r protondrive:/backup
```

## Flags

```
 -f [path to folder or file] (Required)
 -r [rclone remote path] (Required)
 -e [gpg recipient] (Optional)
 -h helper flag
 -v version of script
```