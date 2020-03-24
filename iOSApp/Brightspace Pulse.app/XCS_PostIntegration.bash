#!/bin/bash
# Post-Integration Script to push new Build Number to repo and copy Application Archive to a 'latest build' path for distribution...
# but ONLY IF THE BUILD WAS SUCCESSFUL!


# Trust me
YES_SIR=0


# Copy Relevant Products to Latest Builds Directory
D2L_LATEST_BUILDS_DIR="/Users/bot/Latest_XCS_CI_Builds"
D2L_PROJECT_SRCROOT="${XCS_SOURCE_DIR}/ios-notifications"

# IPA
D2L_LATEST_BUILD_IPA="${D2L_LATEST_BUILDS_DIR}/${XCS_BOT_NAME}-Latest_Build.ipa"
#permissions#echo "Copying this integration's product (${XCS_PRODUCT}) to '${D2L_LATEST_BUILD_IPA}'"
#permissions#cp "${XCS_OUTPUT_DIR}/${XCS_PRODUCT}" "${D2L_LATEST_BUILD_IPA}"

#permissions…
# Having permissions errors, so some stuff has been commented out.
#  Restore (by removing all cases of '#permissions#' from this file) if the following ever starts giving success…
if `stat ${D2L_LATEST_BUILDS_DIR} &> /dev/null`
then
    echo 'XCSBuildDæmon can read the LatestBuilds Directory again!  Some code should be restored in the Post-Integration script.'
else
    echo 'XCSBuildDæmon still can not read the LatestBuilds Directory; some steps will be skipped.'
fi
#…permissions#

# dSYM
# ASSUMPTION:  There is only one item in the dSYMs directory, and it is the dSYM of interest.
OWD=$PWD
cd "${XCS_ARCHIVE}/dSYMs/"
D2L_DSYM_NAME="Brightspace Pulse.app.dSYM"  #$(ls .)
D2L_DSYM_ZIP="/var/_xcsbuildd/${D2L_DSYM_NAME}.zip"    #permissions#D2L_DSYM_ZIP="${D2L_LATEST_BUILDS_DIR}/${D2L_DSYM_NAME}.zip"
echo "Archiving and copying this integration's symbols directory (${D2L_DSYM_NAME}) to '${D2L_DSYM_ZIP}'"
zip -rq "$D2L_DSYM_ZIP" "$D2L_DSYM_NAME"
cd $OWD


# Push to HockeyApp
D2L_GIT_DIR="${D2L_PROJECT_SRCROOT}/"
D2L_TIMESTAMP_FILE="${D2L_LATEST_BUILDS_DIR}/.latest_commit_timestamp-used_by_XCS_CI"
D2L_BUILDSETTINGS_EXPORT_SCRIPT="${D2L_PROJECT_SRCROOT}/D2L_BuildSettingsExport_for_XCS_CI_Triggers.sh"

# Get Exported Build Settings
chmod u+x "$D2L_BUILDSETTINGS_EXPORT_SCRIPT"
source "$D2L_BUILDSETTINGS_EXPORT_SCRIPT"  # currently just sets BSPULSE_HOCKEYAPP_APP_ID

# Get info from Git
latestCommitHash=$(git -C $D2L_GIT_DIR rev-parse --short HEAD)
latestCommitTimestamp_thisIntegration=$(git -C $D2L_GIT_DIR log --pretty=format:"%ct" -1)
#permissions#latestCommitTimestamp_prevIntegration=$(tail -n 1 "$D2L_TIMESTAMP_FILE")

#permissions#[ $latestCommitTimestamp_thisIntegration == $latestCommitTimestamp_prevIntegration ]
#permissions#usingLastIntegrationCommitLog=$?
#permissions#if [ $usingLastIntegrationCommitLog == $YES_SIR ]
#permissions#then
#permissions#    latestCommitTimestamp_prevIntegration=$(tail -n 2 "$D2L_TIMESTAMP_FILE" | head -n 1)  # go back one, and we won't append another this time
#permissions#    echo "Note:  There have not been any new commits since the last integration.  Using the older timestamp '${latestCommitTimestamp_prevIntegration}' rather than the most recent timestamp '${latestCommitTimestamp_thisIntegration}' for retrieving the change log."
#permissions#fi

#permissions#let latestCommitTimestamp_prevIntegration+=1  # get everything since (inclusive) one second after that commit
#permissions#commitLogsSincePreviousNonTrivialIntegration=$(git -C $D2L_GIT_DIR log --pretty=format:"%h - %an, %ar : %s" --since="$latestCommitTimestamp_prevIntegration")

hockeyAppMessage="*LATEST COMMIT HASH:*_#${latestCommitHash}_<br />"
#permissions#if [ $usingLastIntegrationCommitLog == $YES_SIR ]
#permissions#then
#permissions#    hockeyAppMessage="${hockeyAppMessage}*No commits since last integration.*<br />"
#permissions#    hockeyAppMessage="${hockeyAppMessage}*CHANGE LOG FROM PREVIOUS NON-TRIVIAL INTEGRATION:*<br />"
#permissions#else
#permissions#    hockeyAppMessage="${hockeyAppMessage}*CHANGE LOG SINCE LAST INTEGRATION:*<br />"
#permissions#fi
#permissions#hockeyAppMessage="${hockeyAppMessage}${commitLogsSincePreviousNonTrivialIntegration}"

# Push
echo "Pushing latest build to HockeyApp via cURL (https://rink.hockeyapp.net/api/2/apps/${BSPULSE_HOCKEYAPP_APP_ID}/app_versions/upload)"
echo "    with message:"
echo "'${hockeyAppMessage}'"
curl -s \
-F "status=2" \
-F "notify=1" \
-F "teams=27787" \
-F "notes=${hockeyAppMessage}" \
-F "notes_type=0" \
-F "ipa=@${XCS_OUTPUT_DIR}/${XCS_PRODUCT}" \
-F "dsym=@${D2L_DSYM_ZIP}" \
-H "X-HockeyAppToken: 03daf67853324176b1336a27126874ea" \
https://rink.hockeyapp.net/api/2/apps/${BSPULSE_HOCKEYAPP_APP_ID}/app_versions/upload > /dev/null

# Remember for next time
#permissions#if [ $usingLastIntegrationCommitLog != $YES_SIR ]
#permissions#then
#permissions#    echo $latestCommitTimestamp_thisIntegration >> "${D2L_TIMESTAMP_FILE}"
#permissions#fi


#End of Script
