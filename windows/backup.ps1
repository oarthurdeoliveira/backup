
# Remember that the parameters have priority
param (
	[string]$arg1,
	[string]$file_folder = "",
	[string]$rclone_remote = "",
	#TODO: Encryption
	[switch]$help = $false,
	[switch]$version = $false
	
)

$nome = "windows-" + (Get-Date -Format "dd-MM-yyyy")
$log_data = "log-" + (Get-Date -Format "dd-MM-yyyy") + ".log"
$version_value="0.3.0"

# Data Dirs

$main_data="$Env:USERPROFILE\AppData\Roaming\backup"
$log_data_dir="$main_data\logs"
$config_data_dir="$main_data\config"
$zip_data_dir="$main_data\files"

# Other vars

$regex_config="[a-z0-9_]+=(.*)"
$dependencies_commands="rclone" #Remember to add GPG later

# Main checks

if ((Test-Path -Path $main_data) -eq $false) {
	#TODO: Log that files were created on the log file
	# Dirs
	# Should use a loop?
	New-Item -Path "$main_data" -ItemType Directory | Out-Null
	New-Item -Path "$log_data_dir" -ItemType Directory | Out-Null
	New-Item -Path "$config_data_dir" -ItemType Directory | Out-Null
	New-Item -Path "$zip_data_dir" -ItemType Directory | Out-Null
	# Files 
	New-Item -Path "$config_data_dir/backup.conf" -ItemType File | Out-Null
	New-Item -Path "$log_data_dir/latest.log" -ItemType File | Out-Null
	# Don't Forget the Append
	"rclone_default=" | Out-File -FilePath "$config_data_dir/backup.conf" -Append
	"path_default=" | Out-File -FilePath "$config_data_dir/backup.conf" -Append
	
	echo "New user detected, dirs and files created at $main_data"
}

function log_events {
	
	param (
		[Parameter(Mandatory=$true)][string]$text_log,
		[string]$type = "Event"
	)
	
	$hour = Get-Date -DisplayHint Time
	$timer_of_event = "[$hour] ${type}: $text_log"
	
	"$timer_of_event" | Out-File -FilePath "$log_data_dir/latest.log" -Append
}

# Clear the latest.log (The log before the wipe is already saved in a log with the date of the run)
if ((Test-Path -Path "$log_data_dir\latest.log") -eq $true) {
	"Booting" | Out-File -FilePath "$log_data_dir/latest.log"
}

# Remember 
function read_store_value {
	log_events -text_log "Getting Defaults from the config file"
	foreach($line in Get-Content "$config_data_dir/backup.conf") {
		if ($line -match $regex_config) {
			# Because the flag is priority, in case the user put an value in flag it will not override the value
			if (($line -like "*path*") -and ($script:file_folder -eq "") ) {
				log_events -text_log "Path Default Readed!"
				# Remember to search later about the powershell scope
				$script:file_folder = $Matches.1
			}
			elseif (($line -like "*rclone*") -and ($script:rclone_remote -eq "")) {
				log_events -text_log "Rclone remote Default Readed!"
				$script:rclone_remote = $Matches.1
			}
		}	
	}	
}

# Checks

foreach ($command in $dependencies_commands) {
	if (Get-Command $command -ErrorAction SilentlyContinue) {
		#pass
	} else {
		echo "Command $command not found! Please make sure you installed it"
		exit 2
	}
}

# Remember to put it down of the Check Test
read_store_value

if ($arg1 -eq "config") { 
	
	function config_text {
		echo "Rclone default: $rclone_remote"
		echo "Path to backup: $file_folder"
		echo ""

		echo "r) to change the rclone remote"
		echo "p) to change the path"
		echo "e) to exit"
	}


	function read_change_file {
		
		param (
			[Parameter(Mandatory=$true)][string]$text_find,
			[Parameter(Mandatory=$true)][string]$change_part
			
		)
		
		foreach($line in Get-Content "$config_data_dir/backup.conf") {
			if ($line -match $regex_config) {
				if ($line -like "*$text_find*") {
					# I don't think i need to use the Get-content 2 times
					(Get-Content $config_data_dir/backup.conf).Replace("$line", "$change_part") | Set-Content $config_data_dir/backup.conf
				}
				
			}
		}		
	}
	
	config_text
	
	while($true) {
		$option = Read-Host "r/p/e ->"
		$changed = $false
		
		
		if ($option -eq "r") {
			$rclone_default = Read-Host "Write the rclone remote you want to default "
			read_change_file -text_find rclone -change_part rclone_default=$rclone_default
			$changed = $true
		}
		elseif ($option -eq "p") {
			$path_default = Read-Host "Write the path of your system to default "
			read_change_file -text_find path -change_part path_default=$path_default
			$changed = $true
		}
		elseif ($option -eq "e") {
			exit 1
		}
		
		if ($changed -eq $true) {
			clear
			read_store_value
			config_text
		}
	}
}

if ($version) {
	echo $version_value
	exit 1
}

if ($help) {
	echo ""
	echo "-f [path to folder or file] (Required if no default config is set)"
	echo "-r [rclone remote path] (Required if no default config is set)"
	echo "-h helper flag"
	echo "-v version of script"
	echo "config (backup config) to set a configuration of the script"
	echo ""
}

if ($file_folder -eq "") {
	echo "Folder or file path not defined"
	echo "Please use the flag -f [path]"
	echo "Or define a default one using 'backup config'"
	exit 1   
}

if ($rclone_remote -eq "") {
	echo "Default rclone remote not found, please assign a remote using the flag -r [remote]"
	echo "Or define a default one using 'backup config'"
	exit 1
}

# End of checks

# idk if it's funny that good chunk of the code is most of checks or reading the config file
# and only this part is the actual part that do the work of the script...

$compress = @{
	Path = "$file_folder"
	DestinationPath = "$zip_data_dir\$nome.zip"
}

echo "Saving files in a zip"
log_events -text_log "Compressing Files"

Compress-Archive @compress | Out-File -FilePath "$log_data_dir/latest.log" -Append

#TODO: GPG

echo "Moving to $rclone_remote"
log_events -text_log "Moving files using rclone to $rclone_remote"

rclone move "$zip_data_dir\$nome.zip" "$rclone_remote" | Out-File -FilePath "$log_data_dir/latest.log" -Append

log_events -text_log "Copying lastest.log to $log_data"
Copy-Item "$log_data_dir/latest.log" -Destination "$log_data_dir/$log_data"