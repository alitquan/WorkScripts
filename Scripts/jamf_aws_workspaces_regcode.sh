#!/bin/bash

# manually increment this for every update -- for troubleshooting
version=16

jamf_logs=/var/tmp/jamfscripts.log
currentUser=$(/bin/ls -la /dev/console | /usr/bin/cut -d " " -f 4) 
registration_path="/Users/$currentUser/Library/Application Support/Amazon Web Services/Amazon WorkSpaces/RegistrationList.json"
usersettings_path="/Users/$currentUser/Library/Application Support/Amazon Web Services/Amazon WorkSpaces/UserSettings.json"


# delete configuration files
# registration path will be added manually, prepopulating registrationcode field
# user settings will be re-created when AWS Workspaces is opened the first time after this script is ran
# the newly-defined RegistrationCode in RegistrationList.json is then cached in UserSettings.json until changed
/bin/rm -f "$registration_path" 2>> "$jamf_logs"
/bin/rm -f "$usersettings_path" 2>> "$jamf_logs"


# Write the JSON content
/bin/cat <<EOF > "$registration_path"
[
  {
    "RegistrationCode": "xxxxx--xxxxx",
    "CustomDescription": null,
    "RegionKey": "SLiad",
    "OrgName": "abc",
    "RememberMeSetting": {
      "AdminSetting": true,
      "LocalSetting": false
    },
    "LogLevelSetting": {
      "AdminSetting": true,
      "LocalSetting": 2
    },
    "DiagnosticUploadSetting": {
      "AutoLogUploadSetting": {
        "AdminSetting": true,
        "LocalSetting": true
      }
    }
  }
]
EOF


# maintaining original permissions
/bin/chmod 644 "$registration_path"

# appending to system logs and temp log
/usr/bin/logger "QVT Jamf --- AWS Workspace Registration Script $version has been run successfully."
/usr/bin/touch $jamf_logs
/bin/echo "$(date) --- AWS Workspace Registration Script $version has been run successfully." >> $jamf_logs
