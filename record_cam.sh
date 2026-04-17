#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# This project is almost 4 years in the making and is (and very likely always
# will be) a work in progress. Although functional and fairly stable, there is
# tons of room for improvement (I bet my while loops could use work/replacing).
# Don't hesitate to fork, improve, suggest, etc.

######################################################
# Idiotproofing
######################################################

# - This should go without saying, but DO NOT RUN THIS SCRIPT ON YOUR PC... if you
# - accidentally do, you can stop it by deleting the below files and rebooting: 
# - /etc/cron.d/keep_alive
# - /etc/cron.d/cleanup_disk_space
# - If you DO run this on an unintended machine, it WILL modify your USB mount points and
# - write to the first USB storage it finds, with videos from every attached camera...forever.

######################################################
# Setup & Usage
######################################################
# - Ensure ffmpeg is installed before running this script

# - Attach usb storage, FAT32 (Partition Type W95 FAT32 (LBA) 
# - has performed best during testing)

# - Put this script where you expect its permanent home to 
# - be (NOT the attached USB storage! Suggest home folder, for example /home/pi)

# - Execute this script manually for first run. It will:

# - - Create disk space management script (Ensures USB storage never fills up)

# - - Create keep alive script which ensures cameras restart if ffmpeg stops and 
# - - ensures cameras start after a reboot

# - - Creates accompanying cron jobs

# - - And finally it will start all attached cameras, saving repeated 60 second 
# - - clips to the attached USB

# - Once you see ffmpeg writing frames in the terminal, force reboot the Pi (CTRL+C 
# - won't work, you'll need to cut power manually)

# - From now on, the Pi will begin recording repeated 60 second clips for each camera 
# - within 60 seconds of loading its operating system.

# - To swap storage, power off the Pi, swap the USB, power on the Pi

# - To swap cameras, power off the Pi, swap the camera(s), power on the Pi. The system
# - will automatically detect and create supporting scripts for all webcams it finds 
# - at boot time

######################################################
# Tips, limitations and troubleshooting
######################################################

# - For more than 2 cameras, Pi5 is required (Dedicated PCI lane allows 4 simultaneous)

# - Although untested, for single camera setups a Pi Zero2(w) would likely work, 
# - for 2 I would suggest Pi4

# - Developed using 4 Anker PowerConf C200's. Also tested with Logitech Miro 4k and 
# - Logitech C922x. The Ankers performed way better.

# - All of the v4l2 settings you will see in the script are for the Anker cameras I tested 
# - with, if you plan to use another model you will want to comment them out or adjust 
# - to your liking. Some cameras have different variables to play with, use 
# - 'v4l2-ctl --device=/dev/video[X] --all' to check what values you can tweak on yours

# - 99% of issues observed during testing were due to file system corruptions. This is 
# - why storage and the majority of disk writes occur on the USB and not the system 
# - storage itself, and you'll notice that the script automatically runs a repair on it
# - every boot, just in case. During testing (This is 3-4 years in development) I've 
# - ruined one USB drive and have had to reformat USB storage a few times. SO, if having
# - issues, your first check should be the attached USB storage (Swap/reformat it and see if fixed)

# - One issue unresolved at the moment, I suspect is due to drawing way too much power, is
# - that 1 or 2 cameras become inconsistent after prolonged use. When this occurs, the rest
# - of the cameras seem ultra consistent. I'm thinking switching to its own power source
# - instead of relying on the dash lighter and inverter may resolve it. Seems ultra
# - stable when powered at my workbench during development. Untested theory. If you're
# - doing 1 or 2 cameras you likely won't experience this issue.

# - Ensure you use legit cameras, not the cheapest aliexpress junk you can find, as each
# - camera needs to have its own unique serial number for multiple camera setups. Serial 
# - numbers are used to ensure each camera always stores its videos in its own unique
# - folders. In testing I found lots of junk straight-outta-china cameras that all had
# - identical serial numbers or none at all. If you're just using one camera, by all means 
# - use the cheapest sensor you can find!

# - Datestamps in video filenames are not a thing, simply because once the Pi is in the
# - vehicle, it no longer has access to time servers and quickly loses its grasp on
# - date/time, so this was removed in favor of incremental naming.

# - Read through the script, you'll find variables you may want to tweak, such as how 
# - much used space the system should start deleting old videos (Default is 80% disk usage)
# - or how many videos (count) max before it deletes old videos (Default is 5760, 4 full days
# - worth of 60 second clips)

######################################################
# My usage, for reference/example
######################################################
# - I've been using the below arrangement for about 3+ years, while developing, testing
# - tweaking and troubleshooting. Very hobbyist/DIY, all enclosed in 3D printed casing
# - and 3D printed camera mounts. Not perfect by any means, but finally good enough
# - that I'm comfortable enough to share with the Pi community.

# - The mobile wifi router can be skipped, I only use it so that I can bring a laptop
# - out to my truck and connect to wifi if I'd like to SSH the Pi and mess with things
# - as opposed to bringing it into my home, for quick tweaks/tests.

# - The power setup can also be replaced with something more robust if you have the 
# - space for it (I don't). I bet something like a jackery would power this for weeks.

# - Links to the hardware I'm using below, but all of it can be replaced with any off the
# - shelf equivalents, although I suggest keeping the Pi5 (or better) and the Anker
# - cameras (But if you find a better option please let me know!)
# - Power inverter: https://www.amazon.ca/dp/B08YTH66FN
# - 3 way power splitter: https://www.amazon.ca/dp/B098CC6W68
# - USB hubs: https://www.amazon.ca/dp/B000T9S4CI
# - Pi5 15G: https://www.raspberrypi.com/products/raspberry-pi-5/
# - Mobile router: https://www.amazon.ca/dp/B01N5RCZQH
# - Cameras: https://www.amazon.ca/dp/B09MFMTMPD
#
#             Vehicle Lighter Port             
#                       │                      
#          ┌────────────▼────────────┐         
#          │Automotive Power Inverter│         
#          └────────────┬────────────┘
#              ┌────────▼─────────┐            
#           ┌──┼3 way pwr splitter┼─┐          
#           │  └────────┬─────────┘ │
#       ┌───▼───┐  ┌────▼────┐  ┌───▼───┐      
#     ┌─┼USB hub┼──┼ Pi5 16G ┼──┼USB hub┼─┐    
#     │ └┬──┬───┘  └─────┬───┘  └──────┬┘ │
#     │  │ PWR(USB)   ETHERNET         │  │ 
#     │  │  │ ┌──────────┼───────┐     │  │    
#     │  │  └─►Mobile wifi router│     │  │    
#     │  │    └──────────────────┘     │  │ 
#     │  └───────┐            ┌────────┘  │ 
#  ┌──┴───┐   ┌──┴───┐    ┌───┴──┐    ┌───┴──┐ 
#  │Camera│   │Camera│    │Camera│    │Camera│ 
#  └──────┘   └──────┘    └──────┘    └──────┘ 

######################################################
# Thoughts for future
######################################################
# - Replace power system
# - External display to dash to display dashcam logs feed:
# - - 'journalctl -f -t DASHCAM' is a great live status

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

# Get current cam list and set vdid
echo "Clearing $usb_loc/cams.txt" |logger -t DASHCAM
>$usb_loc/cams.txt

# Dump valid /dev/video*'s into cams.txt and force image properties
echo "Collecting valid /dev/video instances, configuring params and adding to $usb_loc/cams.txt" |logger -t DASHCAM
for v in $(ls -d /dev/video*)
do
    if [[ ! -z "$(v4l2-ctl --device=$v --all | grep 'User Controls')" ]]; then
        echo $v >>$usb_loc/cams.txt
        v4l2-ctl -d $v --set-ctrl contrast=40 --set-ctrl brightness=50 --set-ctrl auto_exposure=0
        v4l2-ctl -d $v --set-ctrl saturation=64
        v4l2-ctl -d $v --set-ctrl hue=0
        v4l2-ctl -d $v --set-ctrl white_balance_automatic=1
        v4l2-ctl -d $v --set-ctrl gamma=400
        v4l2-ctl -d $v --set-ctrl power_line_frequency=0
        v4l2-ctl -d $v --set-ctrl white_balance_temperature=168
        v4l2-ctl -d $v --set-ctrl sharpness=80
        v4l2-ctl -d $v --set-ctrl exposure_time_absolute=156
        v4l2-ctl -d $v --set-ctrl focus_automatic_continuous=0
        v4l2-ctl -d $v --set-ctrl focus_absolute=465
        v4l2-ctl -d $v --set-parm=5
    fi
done

#fetch audio devices (webcam microphones) and dump into $usb_loc/mics.txt
echo "Identifying available microphones for audio capture and updating $usb_loc/mics.txt" |logger -t DASHCAM
arecord -l | grep -o 'card [0-9]*' | grep -o '[0-9]*' >$usb_loc/mics.txt

#Create launch script and supporting directories for each camera, using unique SN for naming so that videos from specific cameras go into the same directory every time
echo "For each camera, assigning first identified microphone, collecting serial number and using it to create video scripts and folders" |logger -t DASHCAM
for cam in $(cat $usb_loc/cams.txt)
do
    #Parse audio devices to record
    mic=$(head -n 1 $usb_loc/mics.txt)
    #If no audio device was found, set value to default to avoid errors
    mic=${mic:-default}
    #remove collected audio device from mics.txt
    sed -i '1d' $usb_loc/mics.txt
    #collect webcam serial# for unique folder naming, create folders/scripts
    sn=$(v4l2-ctl --device=$cam --all | grep -oP 'Serial\s*:\s*\K.*')
    vdid="Cam-$sn"
    mkdir $usb_loc/$vdid
    mkdir $usb_loc/camscripts

cat >"$usb_loc/camscripts/$vdid.sh" <<EOF
#!/bin/bash

BASE_DIR="$usb_loc/$vdid"
mkdir -p "\$BASE_DIR"

# --- Find last file inside folder ---
lastfile=\$(ls -1 "\$BASE_DIR/" 2>/dev/null | grep -E '^[0-9]{10}\\.mp4\$' | sed 's/\\.mp4//' | sort | tail -n1)
if [[ -z "\$lastfile" ]]; then
    file_counter=0
else
    file_counter=\$((10#\$lastfile + 1))
fi

while true; do

    filename=\$(printf "%010d.mp4" "\$file_counter")

    #Possible fixes:
    /usr/bin/ffmpeg \
    -thread_queue_size 8192 \
    -f alsa \
    -i hw:$mic \
    -thread_queue_size 8192 \
    -f v4l2 \
    -input_format mjpeg \
    -video_size $res \
    -framerate 5 \
    -i $cam \
    -fflags +genpts \
    -t 60 -c:v copy -c:a aac -b:a 128k \
    -vsync passthrough "\$BASE_DIR/\$filename"
    echo "Video saved: \$BASE_DIR/\$filename" |logger -t DASHCAM
    file_counter=\$((file_counter + 1))
done
EOF

    chmod +x $usb_loc/camscripts/$vdid.sh
    echo "Camera script built: $usb_loc/camscripts/$vdid.sh" |logger -t DASHCAM
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

