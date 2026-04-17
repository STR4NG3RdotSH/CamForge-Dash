# CamForge Dash

**Plug-and-Play Multi-Camera Dashcam for Raspberry Pi**

CamForge Dash is a self-configuring dashcam system that automatically detects, initializes, and records from every connected USB camera on a Raspberry Pi — no manual setup required.

Built for reliability and long-term use, it handles camera management, storage cleanup, and automatic recovery so you can plug it in and let it run.

---

## 🚀 Features

* **Automatic camera detection** – Finds and configures all connected `/dev/video*` devices
* **Multi-camera support** – Record from as many cameras as your Pi can handle
* **Plug-and-play setup** – One-time script execution builds the entire system
* **Automated detection after-the-fact** – Swap out cameras or USB storage by simply powering down and swapping. Automatically detected and re-configured to use the new devices on boot.
* **Continuous recording** – Saves looped video segments automatically
* **Self-healing** – Restarts recording if `ffmpeg` stops
* **Storage management** – Deletes oldest footage based on disk usage or file count
* **Persistent camera mapping** – Uses hardware serial numbers to keep footage organized

---

## ⚡ Quick Start

```bash
# 1. Install ffmpeg
sudo apt install ffmpeg -y

# 2. Run the script
# Put record_cam.sh in a suitable home (/home/pi for instance)
chmod +x record_cam.sh
sudo ./record_cam.sh
# Once you see ffmpeg recording data in the terminal, cut power and power back up. Install complete.
```

Once initialized, CamForge Dash will:

* Detect all cameras
* Create recording scripts
* Start capturing video
* Automatically resume on reboot

---

## ⚠️ Warning

This script will:

* Modify mount points
* Create cron jobs
* Continuously write video to attached USB storage

**Do not run on your primary system. Use a dedicated Raspberry Pi.**

---

## 🧠 How It Works

* Detects valid video devices using `v4l2`
* Assigns each camera a unique folder using its serial number
* Spawns parallel `ffmpeg` processes for simultaneous recording
* Uses cron jobs for:

  * **Keep-alive monitoring**
  * **Disk cleanup automation**
* Stores all footage on external USB storage to protect the OS

---

## 🔧 Requirements

* Raspberry Pi (Pi 4 recommended, Pi 5 for 3+ cameras)
* USB webcams (unique serial numbers required for multi-cam setups)
* External USB storage (FAT32 recommended)
* `ffmpeg`, `v4l2-ctl`, `arecord`

---

## 📌 Notes

* Designed for offline use (no reliance on system time)
* File naming is incremental rather than timestamp-based
* Optimized for stability over long runtimes

---

## 📦 My Usage (Real-World Setup)

CamForge Dash was developed and tested over several years in a real vehicle environment using a fully DIY setup. It’s very much a hobbyist system, but stable enough that it has been running continuously in daily use.

The goal was simple: turn the Raspberry Pi into a self-contained multi-camera dashcam system with zero maintenance once installed.

## 🔧 Hardware in my Setup
* Power inverter: https://www.amazon.ca/dp/B08YTH66FN
* 3-way power splitter: https://www.amazon.ca/dp/B098CC6W68
* USB hubs: https://www.amazon.ca/dp/B000T9S4CI
* Raspberry Pi 5: https://www.raspberrypi.com/products/raspberry-pi-5/
* Mobile router: https://www.amazon.ca/dp/B01N5RCZQH
* Cameras (Anker PowerConf C200 used in testing): https://www.amazon.ca/dp/B09MFMTMPD

```bash
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
```

## 🧠 Notes From Long-Term Use
* Storage reliability is the main failure point (USB health matters most)
* Powered USB hubs significantly improve multi-camera stability
* Some low-cost webcams may fail multi-device serial identification
* System performs best when left fully automated (no manual intervention after boot)

## ⚙️ Philosophy
This setup is intentionally unpolished but resilient:
* No cloud dependency
* No external time reliance
* No manual camera configuration
* Designed to recover itself after power loss or crash

## 🧭 Why CamForge Dash Exists
Most Raspberry Pi dashcam solutions are either overly simplified single-camera scripts or tightly coupled systems that require significant manual setup, configuration tuning, and ongoing maintenance.

CamForge Dash was created to solve a different problem: building a reliable, multi-camera dashcam system that can be deployed once and left running indefinitely in real-world conditions.

In practice, vehicle-based recording systems face constraints that traditional software projects often ignore:

* Unreliable or absent internet connectivity
* Power interruptions and abrupt shutdowns
* Variable and low-quality USB camera hardware
* Integrated storage that will eventually fail
* The need for automatic recovery without user intervention

CamForge Dash is designed around these realities.

Rather than requiring a carefully curated hardware and software stack, it takes a self-configuring, defensive approach:

* Cameras are discovered dynamically at boot
* Each device is isolated and mapped using hardware identifiers
* Recording processes are continuously monitored and restarted if needed
* Storage is actively managed to prevent system failure
* All critical components are generated automatically on first run and re-generated as needed

The result is a system that behaves less like a traditional script and more like a self-maintaining recording appliance.

This project is not intended to be the most configurable or feature-rich dashcam system—it is designed to be predictable, resilient, and low-maintenance in environments where failure is not convenient to debug.

## 🛣️ Future Ideas
* External display for live status
* Improved power handling for multi-camera setups
* Configurable recording settings via UI or config file

---

## 🤝 Contributing

This project has been developed and tested over several years and is still evolving.
Feel free to fork, improve, and submit pull requests.
