#!/usr/bin/env bash

# Make a folder called "Geniusnt" in your music directory, and place this script in that folder please

# Please read the whole README file before running, there's important information in there
# Set music directory, YT playlist link, and a playlist name for all your songs here
PLAYLIST_URL="<Your YouTube playlist's link (make sure the playlist is set to public)>"
PLAYLIST_FILE="<What you want your playlist to be called on your device>.m3u"
MUSIC_DIR="</path/to/your/music/folder/ (make sure that last / is there)>"
# You'r all set to use the script now :D

#makes the script run in the folder it's saved in rather than your terminals active directory
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCRIPT_DIR"

# support for nix tools & dependency checking - @ripples1253/Ripley White <3
# ripley: theo, if you need extra dependencies in the future, update this line with package.
# theo: Yeah, I know that, I also use NixOS on my laptop (This can stay for anyone else reading the code ig)
# ripley: waah waah waah that's the sound of someone who doesn't own an air fryer
# Theo: stfu, you don't own like 12 sets of D&D dice. I think I win
# ripley: yeah well my huawei 2018 y6 runs a custom alpine linux distro deployed via leaked firehose files, AND my computer doesn't look like a bomb unlike your "pi"
#Theo: Yeah well my "pi" is able to get through security without them questioning me, so clearly it doesn't look that much line a bomb
# names from https://search.nixos.org/packages
# DEPS="yt-dlp ffmpeg python313Packages.mutagen"
REQUIRED_TOOLS=("yt-dlp" "ffmpeg" "mid3v2") # if these commands don't exist, error and die
#
# if [[ -z "${IN_NIX_SHELL-}" ]] && type -p nix-shell > /dev/null 2>&1; then
#     echo "found nix-shell, relaunching!"
#     exec nix-shell -p $DEPS --run "$(printf "%q " "$0" "$@")"
#     exit 0
# fi
#
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! type -p "$tool" > /dev/null 2>&1; then
        echo "$tool wasn't found in your path. Please install it and run again. Or don't. I'm not your father."
        exit 1
    fi
done
echo "dependency check successful!"

## If you run this script and it closes its self imediatly, restarting your device should sort that. It doesn't happen much, but on my raspberry pi 3B+ I had that issue a couple of times and restating it worked both times

# --- Makes the script run in a terminal if you don't launch it via the terminal ---
if [ ! -t 0 ]; then
    lxterminal -t "Music Sync" -e "$0"
    exit
fi
# -----------------------------------------------------------------------------------


# Prevent multiple instances of the script running at once
LOCKFILE="${TMPDIR:-/data/local/tmp}/music_sync.lock"
if [ -e "$LOCKFILE" ]; then
    echo "Sync already in progress. Exiting."
    exit 1
fi
touch "$LOCKFILE"
trap "rm -f '$LOCKFILE' *.tmp $SCRIPT_DIR/online_ids.txt local_history_ids.txt; exit" INT TERM EXIT


# Force UTF-8 for special characters
export LC_ALL=C.UTF-8
export LANG=C.UTF-8


cd "$MUSIC_DIR"

echo "Music sync: Welcome"
echo "Do not distrobute anything you have obtained via this script!"
echo ""


# Storage space check
AVAILABLE_KB=$(df . | tail -1 | awk '{print $4}')
AVAILABLE_MB=$((AVAILABLE_KB / 1024))
echo "Storage Check: $AVAILABLE_MB MB remaining."
if [ "$AVAILABLE_MB" -lt 256 ]; then
    echo "Music sync: LOW DISK SPACE ($AVAILABLE_MB MB). Sync cancelled."
    exit 1
fi

echo ""

# Check for WiFi connection by pinging Google, cos uhh, Google is basicaly always up
CONNECTED=false
for i in {1..5}; do
    if ping -q -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
       CONNECTED=true
       break
   fi
   echo "Music sync: Waiting for WiFi... (Attempt $i)"
   sleep 5
done

echo ""

if [ "$CONNECTED" = false ]; then
    echo "Music sync: No WiFi. Music sync will not procede."
    exit 1
fi

if [ -d "$MUSIC_DIR" ]; then
    echo "Music sync: WiFi connected and checking for new music..."
    echo ""


    # The start of the actuall point of the script lol

    # Generate a yt-dlp archive from id_filename_map.txt that safe to get corrupted if something goes wrong
    if [ -f "$SCRIPT_DIR/id_filename_map.txt" ]; then
        awk -F'|' '{print "youtube " $1}' $SCRIPT_DIR/id_filename_map.txt > $SCRIPT_DIR/id_filename_map_but_so_its_not_corrupted_during_download.tmp
    else
        touch $SCRIPT_DIR/id_filename_map.txt
        touch $SCRIPT_DIR/id_filename_map_but_so_its_not_corrupted_during_download.tmp
    fi

    # The actuall download command
    # Feel free to change the metadata related taggs so that its suited for you (If it breaks shit you can always just look at the original command on GitHub again) :D
    yt-dlp \
    --cookies $SCRIPT_DIR/cookies.txt \
    --extractor-args "youtube:player_client=tv_downgraded,default" \
    -f "ba/b" \
    -x --audio-format mp3 \
    --audio-quality 0 \
    --embed-thumbnail \
    --ppa "EmbedThumbnail+ffmpeg_o:-c:v mjpeg -vf crop='ih:ih'" \
    --embed-metadata \
    --postprocessor-args "ffmpeg:-id3v2_version 3" \
    --parse-metadata "track_number:%(meta_track)s" \
    --parse-metadata "::(?P<uploader>)" \
    --parse-metadata "::(?P<creator>)" \
    --no-part \
    --no-warnings -i \
    --ignore-errors \
    --no-cache-dir \
    --download-archive $SCRIPT_DIR/id_filename_map_but_so_its_not_corrupted_during_download.tmp -o "%(title)s.%(ext)s" \
    --print-to-file "%(id)s|%(title)s.mp3" $SCRIPT_DIR/new_songs.tmp \
    --progress \
    "$PLAYLIST_URL"

    rm -f $SCRIPT_DIR/id_filename_map_but_so_its_not_corrupted_during_download.tmp
    REMOVED_COUNT=0


    # This checks for any new songs so that you get asked if you want to change the title of your newly downloaded songs
    # I found the YouTube song names anoying because alot of them had a bunch of random junk in the names
    if [ -f "$SCRIPT_DIR/new_songs.tmp" ]; then
        ADDED = 0
        echo -e "\nMusic sync: Tagging new songs..."
        # Heres the part where we make sure it asks you for each song because I forgot to do that in some earlier versions of the script
        while IFS='|' read -r id filename <&3; do
            if [ -f "$filename" ]; then
                echo -e "\n-----------------------------------------------------------------"
                echo "NEW FILE: $filename"
                read -p "DISPLAY NAME (Leave blank to use filename): " user_input
                if [ -z "$user_input" ]; then
                    CLEAN_TITLE="${filename%.*}"
                else
                    CLEAN_TITLE="$user_input"
                fi
                mid3v2 -t "$CLEAN_TITLE" "$filename"
                echo " -> Saved title tag as: $CLEAN_TITLE"
                echo "$id|$filename" >> $SCRIPT_DIR/id_filename_map.txt
            fi
            ADDED=$(($ADDED+1))
        done 3< $SCRIPT_DIR/new_songs.tmp
    else
        echo "Music sync: No new songs downloaded, skipping tagging."
        echo ""
    fi



    # Deleting songs that aren't on the YouTube playlist anymore
    echo -e "\nMusic sync: Checking for removed songs..."

    if yt-dlp --get-id --flat-playlist --no-warnings "$PLAYLIST_URL" > $SCRIPT_DIR/online_ids.txt; then

        ONLINE_COUNT=$(wc -l < $SCRIPT_DIR/online_ids.txt)
        LOCAL_COUNT=$(wc -l < $SCRIPT_DIR/id_filename_map.txt 2>/dev/null || echo 0)

        # FAIL-SAFE: If online count drops by more than 25% compared to local, abort deletion cos this prroobballyy means that it didn't pick up on your playlist properly
        if [ "$LOCAL_COUNT" -gt 0 ]; then
            MIN_EXPECTED=$((LOCAL_COUNT * 3 / 4))
            if [ "$ONLINE_COUNT" -lt "$MIN_EXPECTED" ]; then
                echo "CRITICAL WARNING: YouTube only returned $ONLINE_COUNT IDs, but you have $LOCAL_COUNT local songs."
                echo "This usually means YouTube paginated the list or yt-dlp needs an update."
                echo "Aborting deletion step to protect your files."
                SKIP_DELETION=true
            fi
        fi

        # Make the deleted files go kapuf when they arent in id_filename_map.txt
        if [ "${SKIP_DELETION:-false}" = false ] && [ -f "$SCRIPT_DIR/id_filename_map.txt" ]; then
            cp $SCRIPT_DIR/id_filename_map.txt $SCRIPT_DIR/id_filename_map_read.tmp
            while IFS='|' read -r id filename; do
                [ -z "$id" ] && continue
                if ! grep -qFx -- "$id" $SCRIPT_DIR/online_ids.txt; then
                    if [ -f "$filename" ]; then
                        echo ""
                        echo " -> Deleting removed song: $filename"
                        rm "$filename"
                        grep -v "^$id|" $SCRIPT_DIR/id_filename_map.txt > id_map.tmp && mv id_map.tmp $SCRIPT_DIR/id_filename_map.txt
                        echo " -> Removed ID $id and filename from map."
                        echo "$filename" >> Deleted_files.tmp
                        REMOVED_COUNT=$((REMOVED_COUNT + 1))
                    fi
                fi
            done < $SCRIPT_DIR/id_filename_map_read.tmp

            rm -f $SCRIPT_DIR/id_filename_map_read.tmp

        elif [ "${SKIP_DELETION:-false}" = false ]; then
            echo "Music sync: id_filename_map.txt not found, skipping file deletion."
        fi

    else
        echo "Music sync: Could not reach YouTube to verify playlist."
    fi

    # Playlist update if songs were added or removed
    if [[ $ADDED -gt 0 || $REMOVED_COUNT -gt 0 ]]; then
        echo ""
        echo "Music sync: Songs were added or removed, updating playlist"
        ls -1 *.mp3 | grep -v "^\." > "$PLAYLIST_FILE"
    fi


    # Time to make the log!!

        echo "-----------------------------------------------------------------"
        echo "Added: $ADDED songs | Deleted: $REMOVED_COUNT songs"
        echo "Check $SCRIPT_DIR/sync_log.txt in your music directory for more info"
else
    echo "Music sync: $MUSIC_DIR does not exist or could not be found"
fi

# If your reading this comment it is to say that this script was orginaly made by GrenguyAkaTheo with a little help from ripples1253 on GitHub. I am putting this here so that less people are able to succsessfully sell this script and get away with it. I know its petty, but them kind of people really piss me off

# Adding to the sync log
LOG_FILE="$SCRIPT_DIR/sync_log.txt"
{
  echo "Sync Session: $(date)"
  echo "Added: $ADDED | Deleted: $REMOVED_COUNT"
  echo ""
  echo "Songs added (YouTube ID|File name);"
  cat $SCRIPT_DIR/new_songs.tmp 2>/dev/null
  echo ""
  echo "Songs deleted (File name);"
  cat Deleted_files.tmp 2>/dev/null
  echo "-----------------------------------------------------------------"
} >> "$LOG_FILE"


rm Deleted_files.tmp 2>/dev/null
rm $SCRIPT_DIR/new_songs.tmp 2>/dev/null

echo ""
read -p "Music sync complete. Press [Enter] to exit..."



# Thanks for reading this. It was heavily vibe coded as this is the first bash script I've ever made, so I used gemini and claud to help me learn. Ok to be fair I've been maintaning this for a while now, and I don't need anywhere near as much help with bash scripting now, so it's as long as the part of code has been updated atleast once then it's made without AI
# I do use this scrip on my raspberry pi 3B+ wth pi OS, and my Nobara PC. So uhh, it does work lol (It also worked on Bazzite when I used to use that)


# Also shoutout to all the IT lab admins at CBC college, there's no way I would have ended up making script if you guys didn't exist (even though you played no roll in actually making the script (Other than ripley who made the dependacy check for this)), also your all just great friends and co-workers in general!!
