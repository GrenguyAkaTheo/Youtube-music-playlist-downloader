# YouTube-music-playlist-downloader
This is a relitivly simple bash scrip that uses yt-dlp to download a youtube music playlist and automatically add the thumbnail, lyrics, album, and artists to the metadata of all the songs on the playlist. It will also automaticaly delete songs from your music directory if you remove them from your youtube music playlist

## Disclaimer
This script is for personal and educational use only. This is to be used for personal archives, or for educational demonstrations. Users are solely responsible for ensuring their compliance with local copyright laws and YouTube's Terms of Service.

# Setup instructions
MAKE SURE THE PLAYLIST YOUR DOWNLOADING IS SET TO PUBLIC ON YOUTUBE!!

For this script to work you must have yt-dlp, ffmpeg, and mid3v2 installed. When installing yt-dlp the other two packages should be installed along with it automatically.

You MUST edit the .sh file (The actual script) and follow the short and simple instructions from line 4 to line 8 or it will crap the bed when you try to run it.

You do also need to export your browser cookies for this to work (because Google are rude, and want to make sure your a person before letting you have the audio stream). To do so, you can get them by installing a browser extention that extracts the cookies for the page your on, opening a private/incognito tab (so that your using a different cookie jar that wont renew when opening yt on a normal tab), going onto YouTube music, and then export the cookies via the browser extention you used. Once you've done that, rename the exported text file to "cookies.txt" and place it in the same folder as the YT_playlist_dl.sh file. Oh yeah, I also think these cookies can expire after a few months, so you might have to do this again if the script gives errors like "could not receive requested format".

Make sure the file is exicutable on your linux distro with `sudo chmod -x <path to file>/YT_playlist_dl.sh` in the terminal, or whatever command you use to make .sh files exicutable.

To run the scrip you can type `bash <path to file>/YT_playlist_dl.sh` in your terminal, or just run it via your file explorer.

# Important information
PLEASE DO NOT USE THIS SCRIPT TO DISTROBUTE ANY MEDIA YOU DOWNLOAD!!!

DO NOT CHANGE THE ACTUAL FILE NAMES OF THE SONGS! This will cause the song to be deleted when you next run the script. This is because the script checks the file name against youtubes songs names to see if the song should be removed or not. If the actual file name is diferent to the one on youtube, the script will think you took the song off your youtube playlist.

On that note, MAKE SURE THAT ANY SONGS YOU ALREADY HAVE DOWNLOADED THAT WERENT DOWNLOADED FROM THIS SCRIPT ARE IN A DIFFERENT FILE OR THEY WILL GET DELETED FOR THE SAME REASON!!

DO NOT REMOVE "id_filename_map.txt" ONCE YOU RUN THE SCRIPT. This is effectively a memory for this script, and it keeps the ID's of all the songs in your file. If you delete this file the whole playlist will be downloaded again rather than just the songs that need to be downloaded.

All the mp3 files in your music folder will be added to the playlist of all songs. If a song doesn't get added (which is highly unlikely) simply add the file name to a new line in your m3u file.

# Useful info and help
If you have nix installed but don't want to use a nix shell for this, remove or comment out lines 18 to 32

If your on Windows, this may not work as you need bash suppourt. If you get bash suppourt on Windows then feel free to try it out. I do know that Visual Studio Code has a Shell extention called "Code runner". This should allow the script to run, but you will need to find a way to install the dependancys and get the /bin/bash path to exist

If a song fails to download due to something along the lines of "video unavalale" but you can get the song in some other way, simply rename the song file to the exact title of the song on youtube music. To stop the script from erroring enter add `<The songs youtube ID (will look something like this "otS3u8227kY")>|<The songs filename with the file type>` as a new line anywhere in "id_filename_map.txt". This ID can be found in the songs link (like this, at the quoted location after "watch?v=" https://music.youtube.com/watch?v=`vbMh38KGZMM`&si=_H1xcMw3Cezj9QWS).

This script tags songs with ID3v2.3 rather than ID3v2.4. This is for better compatibility with older media players like VLC and audatious. You can change this in the yt-dlp download command within the script by changing line 125 to say  `"ffmpeg:-id3v2_version 4"` rather than `"ffmpeg:-id3v2_version 3"`.

If you downloaded a song with charictors like /, you will likely have to remove these from "id_filename_map.txt" and your music folder manualy if you remove it from your YouTube music playlist. This is because your device will think that its looking for a diferent folder all together, fail to find the song to delete, and then give up with removing it from "id_filename_map.txt". Because of this, if your downloading a songs with a / in the name you may been to ad this ID and filename to "id_filename_map.txt" manually (In the format <YouTube ID>|<Filename>.mp3).

If a song fails to download, try running this command in your terminal `yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --embed-metadata --sub-langs "en.*,ja.*,.*-orig,all" --convert-subs lrc --postprocessor-args "ffmpeg:-id3v2_version 3" --parse-metadata "track_number:%(meta_track)s" --no-part --no-warnings -i --ignore-errors --no-cache-dir "<Just the failed songs YouTube URL>"`. Next you NEED to change the ID thats saved in "id_filename_map.txt" for the song to what yt-dlp thinks it should be (This is easily found in what the script outputs when its trying to download the song). You will have to set the title metadata tag manually with this, but it did get that problem sorted with the one song that faled for me. It will also automatically append the song to the "id_filename_map.txt" file, so you wont have to manually add it, which is nice in my opinion :D. You can also remove the ` [YouTube ID]` part of the file name as the ID doesn't have to be in the file name, and then run this in your music directory to add it to the m3u playlist file of all your songs `ls -1 *.mp3 | grep -v "^\." > "<The file name of your playlist file>.m3u"` (Or just manually add the file name to a new line of the playlist).

The album tag is what youtube gives the script to use. If the album gets set to something like the song name (Or nothing at all) this is because of youtube, not the script its self :D. One way to solve this is to add the version of the song you want from the album rather than its music video as the music videos often dont contain the album there from. You can also use apps like EasyTag to change the metadata saved to the mp3 files.

I recomend you format your drives partition to something like BTRFS as this is caps sensitive. Any type of FAT formatting and NTFS are not caps sensitive, which can rarely cause issues.

# Information for running the script on mobile
If you are running this on your phone you do need terminal access. I recommend you use Termix (avalable for free on Fdroid) for this (but any bash terminal should do). I do not know if this works on Apple devices, but it theoretically should if you can get a linux terminal emulator, but you will need some other way to get a terminal as Termix is only avalable on android.

The same dependacies apply if your using it on your phone. The script is EXACTLY the same, there is no version of the script specifically for mobile. The one script should run on pretty much all desktop linux distros, Andoid, and iOS (I am unable to test iOS, but theroretically it should work).

If you are using Termix, sudo won't work, however you don't need sudo. simply run the same commands to install the dependencies but without 'sudo'

You will likely have an issue or two while installing these. One of them will likely be a permission issue, but it will show up as a missing directory error, and has a one comand fix (I can't remember the command though). I won't know exactly what other issues you may have, so I won't list the fixes here (If you read what I said for the rest of the mobile, it should work regardless). They are very easy to find fixes for on Google if you just take a screenshot of Termix, and send it to Gemini (Shut up about AI, this is one of the moments where it's actually useful) and say with the image "I have had this error on Termix. How can I fix it" (or something similar, this is just a prompt I'm providing that should give you a decent answer). If you run AI's fix and you get a different error, simply go through the same prosses again with the same prompt.

The set up is exactly the same as on PC. Please read through the part of the README for PC to set it up, as once again, it's exactly the same script.


- GrenguyAkaTheo, GitHub
