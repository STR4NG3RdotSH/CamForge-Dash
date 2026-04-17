# CamForge Dash

**Plug-and-Play Multi-Camera Dashcam for Raspberry Pi**

CamForge Dash is a self-configuring dashcam system that automatically detects, initializes, and records from every connected USB camera on a Raspberry Pi — no manual setup required.

Built for reliability and long-term use, it handles camera management, storage cleanup, and automatic recovery so you can plug it in and let it run.

---

## 🚀 Features

* **Automatic camera detection** – Finds and configures all connected `/dev/video*` devices
* **Multi-camera support** – Record from as many cameras as your Pi can handle
* **Plug-and-play setup** – One-time script execution builds the entire system
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

## 🛣️ Future Ideas

* External display for live status
* Improved power handling for multi-camera setups
* Configurable recording settings via UI or config file

---

## 🤝 Contributing

This project has been developed and tested over several years and is still evolving.
Feel free to fork, improve, and submit pull requests.
