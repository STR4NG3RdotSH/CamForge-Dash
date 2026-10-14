#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

######################################################
# Setting Global Vars
######################################################
#Mount point to use for USB (video files) storage
usb_loc="/media/vids"
#Collect script location for future use
home_loc="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
#Set desired video resolution
res="640x480"

echo "Starting record_cam.sh" |logger -t DASHCAM

#Unmount the USB if its mounted
echo "Un-mounting $usb_loc" |logger -t DASHCAM
umount $usb_loc |logger -t DASHCAM
#Clear any residual files from symlink
echo "Deleting /media/*" |logger -t DASHCAM
rm -rf /media/* |logger -t DASHCAM

#Repair USB filesystem if needed, and re-mount first USB storage found to /media/vids
echo "Repair USB filesystem if needed, and re-mounting first USB storage found to $usb_loc" |logger -t DASHCAM
dev=$(readlink -f /dev/disk/by-id/usb-* | head -n1); \
    part=$(lsblk -rpno NAME,TYPE "$dev" | awk '$2=="part"{print $1; exit}'); \
    findmnt -rn -S "$part" -T $usb_loc >/dev/null 2>&1 || \
    { rm -rf $usb_loc; mkdir -p $usb_loc; fsck -ay "$part" |logger -t DASHCAM; mount "$part" $usb_loc |logger -t DASHCAM; rm -f $usb_loc/camscripts/*; }

#Now that USB is clean and mounted, check if there is an update on the USB, updating if so
if [ -f "$usb_loc/record_cam.sh" ] && ! cmp -s "$usb_loc/record_cam.sh" "$home_loc/record_cam.sh"; then
    cp "$usb_loc/record_cam.sh" "$home_loc/record_cam.sh" && reboot
fi


# Get current cam list and set vdid
echo "Clearing $usb_loc/cams.txt" |logger -t DASHCAM
>$usb_loc/cams.txt

# Clear cam scripts folder in case a camera was swapped (avoids system trying to run cams that no longer exist)
rm -f "$usb_loc/camscripts/*"

# Dump valid /dev/video*'s into cams.txt and force image properties
echo "Collecting valid /dev/video instances, configuring params and adding to $usb_loc/cams.txt" |logger -t DASHCAM
for v in $(ls -d /dev/video*)
do
    if [[ ! -z "$(v4l2-ctl --device=$v --all | grep 'User Controls')" ]]; then
        echo $v >>$usb_loc/cams.txt   
        # v4l2-ctl -d $v --set-ctrl contrast=40 --set-ctrl brightness=50 --set-ctrl auto_exposure=0
        # v4l2-ctl -d $v --set-ctrl saturation=64
        # v4l2-ctl -d $v --set-ctrl hue=0
        # v4l2-ctl -d $v --set-ctrl white_balance_automatic=1
        # v4l2-ctl -d $v --set-ctrl gamma=400
        # v4l2-ctl -d $v --set-ctrl power_line_frequency=0
        # v4l2-ctl -d $v --set-ctrl white_balance_temperature=168
        # v4l2-ctl -d $v --set-ctrl sharpness=80
        # v4l2-ctl -d $v --set-ctrl exposure_time_absolute=156
        # v4l2-ctl -d $v --set-ctrl focus_automatic_continuous=0
        # v4l2-ctl -d $v --set-ctrl focus_absolute=465
        # v4l2-ctl -d $v --set-parm=5
    fi
done

#fetch audio devices (webcam microphones) and dump into $usb_loc/mics.txt
echo "Identifying available microphones for audio capture and updating $usb_loc/mics.txt" |logger -t DASHCAM
arecord -l | grep -o 'card [0-9]*' | grep -o '[0-9]*' | grep . >$usb_loc/mics.txt

#Create launch script and supporting directories for each camera, using unique SN for naming so that videos from specific cameras go into the same directory every time
echo "For each camera, assigning first identified microphone, collecting serial number and using it to create video scripts and folders" |logger -t DASHCAM
for cam in $(cat $usb_loc/cams.txt)
do
    #collect webcam serial# for unique folder naming, create folders/scripts
    sn=$(v4l2-ctl --device=$cam --all | grep -oP 'Serial\s*:\s*\K.*')

    if [[ -n "${sn//[[:space:]]/}" ]]; then
    #Parse audio devices to record
    mic=$(head -n 1 $usb_loc/mics.txt)
    #If no audio device was found, set value to default to avoid errors
    # Initialize empty variables for audio arguments
    audio_input=""
    # If a mic is found (string is not empty), populate the audio arguments
    if [ -n "$mic" ]; then
        audio_input="-f alsa -ac 1 -ar 48000 -i plughw:$mic,0 -thread_queue_size 8192"
            
    fi
    #remove collected audio device from mics.txt
    sed -i '1d' $usb_loc/mics.txt
    vdid="Cam-$sn"
    # Added quotes to prevent errors if $usb_loc has spaces
    mkdir -p "$usb_loc/$vdid"
    mkdir -p "$usb_loc/camscripts"

cat >"$usb_loc/camscripts/$vdid.sh" <<EOF
#!/bin/bash

BASE_DIR="$usb_loc/$vdid"
mkdir -p "\$BASE_DIR"

# --- Find last file inside folder ---
lastfile=\$(ls -1 "\$BASE_DIR/" 2>/dev/null | grep -E '^[0-9]{10}\\.mkv\$' | sed 's/\\.mkv//' | sort | tail -n1)
if [[ -z "\$lastfile" ]]; then
    file_counter=0
else
    file_counter=\$((10#\$lastfile + 1))
fi

while true; do

    filename=\$(printf "%010d.mkv" "\$file_counter")
    /usr/bin/ffmpeg \
    -thread_queue_size 8192 \
    $audio_input \
    -f v4l2 \
    -input_format mjpeg \
    -video_size $res \
    -framerate 5 \
    -i $cam \
    -fflags +genpts \
    -t 60 -c:v copy -c:a aac -b:a 128k \
    -flush_packets 1 \
    -vsync passthrough "\$BASE_DIR/\$filename" >> $usb_loc/log 2>&1
    echo "Video saved: \$BASE_DIR/\$filename" |logger -t DASHCAM
    file_counter=\$((file_counter + 1))
done
EOF

    chmod +x $usb_loc/camscripts/$vdid.sh
    echo "Camera script built: $usb_loc/camscripts/$vdid.sh" |logger -t DASHCAM

    else
       # Added quotes around $v for safety
       echo "$v returned nothing for serial#, skipping device" | logger -t DASHCAM
    fi

done
echo "All identified cameras ready" |logger -t DASHCAM

# Create vars for each created script for the execution command
echo "Generating simultaneous launch script" |logger -t DASHCAM
increment=0
declare -a scripts
for script in $(ls -d $usb_loc/camscripts/*)
do
    scripts[$increment]=$script 
    ((increment++))
done 

# build script execution command so they all fire simultaneously (or only one camera will record)
script_exec_line=""
for ((i=0; i<${#scripts[@]}; i++))
do
    script_exec_line+="${scripts[i]} & "
done

#Create maintenance scripts if they don't already exist
cat >"$home_loc/cleanup_disk_space.sh" <<EOF
#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

loc="$home_loc"

# Navigate to video location
cd "$usb_loc"

echo "Checking current space used and file count..." | logger -t DASHCAM

# Get current space used
space_used=\$(df $usb_loc/ | awk 'NR==2 {print \$5}' | cut -d'%' -f1)

# Get current mp4 count
file_count=\$(find $usb_loc/ -type f -name "*.mp4" | wc -l)

echo "Usage: \$space_used% | Files: \$file_count" | logger -t DASHCAM

# Loop while space > 80 OR file count > 2880
while [ "\$space_used" -gt 80 ] || [ "\$file_count" -gt 5760 ]; do

    # Isolate oldest video
    oldest_video=\$(find $usb_loc/ -type f -name "*.mp4" -printf '%T+ %p\n' | sort | head -n 1 | awk '{print \$2}')

    if [ -n "\$oldest_video" ]; then
        echo "Deleting \$oldest_video" | logger -t DASHCAM
        rm -f "\$oldest_video"

        # Also clear any FSCK dumps
        rm -f $usb_loc/FSCK*REC

        # And finally, clear log
        > $usb_loc/log

        # Recalculate BOTH conditions
        space_used=\$(df $usb_loc/ | awk 'NR==2 {print \$5}' | cut -d'%' -f1)
        file_count=\$(find $usb_loc/ -type f -name "*.mp4" | wc -l)

        echo "Now at: \$space_used% | Files: \$file_count" | logger -t DASHCAM
    else
        break
    fi
done

echo "Cleanup complete: \$space_used% | Files: \$file_count" | logger -t DASHCAM
EOF
chmod +x $home_loc/cleanup_disk_space.sh

cat >"$home_loc/keep_alive.sh" <<EOF
#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

env >> $usb_loc/log
# if ffmpeg process not running then run start_capture script
if ! pgrep -x ffmpeg; then { echo "ffmpeg was down, starting again" |logger -t DASHCAM & $home_loc/record_cam.sh; }; fi
EOF
chmod +x $home_loc/keep_alive.sh

#Create cron jobs if they don't already exist
cat >"/etc/cron.d/cleanup_disk_space" <<EOF
*/5 * * * * root $home_loc/cleanup_disk_space.sh
EOF

cat >"/etc/cron.d/keep_alive" <<EOF
* * * * * root $home_loc/keep_alive.sh
EOF

# Execute the scripts (Start recording all valid cameras)
echo "Launching all cameras" |logger -t DASHCAM
eval $script_exec_line

# Ideal for innomaker cam
        # Model            : Innomaker-U20CAM-1080p-S1: Inno
        # Serial           : SN0001
        # v4l2-ctl -d $v --set-ctrl backlight_compensation=40
        # v4l2-ctl -d $v --set-ctrl gamma=160
        # v4l2-ctl -d $v --set-ctrl contrast=26

# Defaults for innomaker cam
        # Model            : Innomaker-U20CAM-1080p-S1: Inno
        # Serial           : SN0001
#                      brightness 0x00980900 (int)    : min=-64 max=64 step=1 default=0 value=0 flags=has-min-max
#                        contrast 0x00980901 (int)    : min=0 max=64 step=1 default=32 value=32 flags=has-min-max
#                      saturation 0x00980902 (int)    : min=0 max=128 step=1 default=64 value=64 flags=has-min-max
#                             hue 0x00980903 (int)    : min=-40 max=40 step=1 default=0 value=0 flags=has-min-max
#         white_balance_automatic 0x0098090c (bool)   : default=1 value=1
#                           gamma 0x00980910 (int)    : min=72 max=500 step=1 default=100 value=100 flags=has-min-max
#                            gain 0x00980913 (int)    : min=0 max=100 step=1 default=0 value=0 flags=has-min-max
#            power_line_frequency 0x00980918 (menu)   : min=0 max=2 default=1 value=1 (50 Hz)
#                                 0: Disabled
#                                 1: 50 Hz
#                                 2: 60 Hz
#       white_balance_temperature 0x0098091a (int)    : min=2800 max=6500 step=1 default=4600 value=4600 flags=inactive, has-min-max
#                       sharpness 0x0098091b (int)    : min=0 max=6 step=1 default=3 value=3 flags=has-min-max
#          backlight_compensation 0x0098091c (int)    : min=0 max=160 step=1 default=12 value=12 flags=has-min-max

# Camera Controls

#                   auto_exposure 0x009a0901 (menu)   : min=0 max=3 default=3 value=3 (Aperture Priority Mode)
#                                 1: Manual Mode
#                                 3: Aperture Priority Mode
#          exposure_time_absolute 0x009a0902 (int)    : min=1 max=5000 step=1 default=157 value=157 flags=inactive, has-min-max
#      exposure_dynamic_framerate 0x009a0903 (bool)   : default=0 value=1
