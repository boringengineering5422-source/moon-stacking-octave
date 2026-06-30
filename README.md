# moon-stacking-octave
Lunar image stacking with lucky imaging for GNU Octave
Here is the complete, step-by-step setup guide in English. You can use this directly for your GitHub `README.md` or as a separate `SETUP.md` file in your repository.

***

#  Moon Stacking with Octave – Complete Setup Guide

## 🛠️ Required Software

You only need **two free programs** to get started:

| Software | Purpose | Download Link |
|----------|---------|---------------|
| **GNU Octave** | Runs the stacking script | [https://www.gnu.org/software/octave/download](https://www.gnu.org/software/octave/download) |
| **FFmpeg** | Extracts frames from the moon video | [https://ffmpeg.org/download.html](https://ffmpeg.org/download.html) |

---

## 📥 Step 1: Install GNU Octave

1. Download the latest version from the official website.
2. Install Octave normally (Next → Next → Finish).
3. Launch Octave after installation.

---

## 📦 Step 2: Install the Image Package in Octave

The script requires the **Image Processing Package** for functions like `stdfilt`, `conv2`, etc.

**How to install it:**

1. Open Octave.
2. Type the following command in the Command Window and press Enter:

```octave
pkg install -forge image
```

3. Wait for the installation to finish (it may take 1-2 minutes).
4. The package is loaded automatically by the script, but you can also load it manually with:

```octave
pkg load image
```

---

## 🎬 Step 3: Install FFmpeg

### On Windows:
1. Download a **Windows build** from [https://ffmpeg.org/download.html#build-windows](https://ffmpeg.org/download.html#build-windows) (e.g., from gyan.dev).
2. Extract the ZIP file to a folder (e.g., `C:\ffmpeg`).
3. Add the `bin` folder to your **System PATH variable**:
   - Right-click "This PC" → Properties → Advanced system settings → Environment Variables.
   - Under "System variables", select `Path` → Edit → New → Add `C:\ffmpeg\bin`.
4. Open a **new** Command Prompt (CMD) and test it by typing:
   ```cmd
   ffmpeg -version
   ```

### On macOS:
```bash
brew install ffmpeg
```

### On Linux (Ubuntu/Debian):
```bash
sudo apt install ffmpeg
```

---

## 🖼️ Step 4: Extract Frames from the Moon Video

1. Place your moon video (e.g., `moon_video.mp4`) into a new folder, e.g., `C:\MoonStacking\`.
2. Open a Command Prompt (CMD) or Terminal in this folder.
3. Run the following FFmpeg command:

```bash
ffmpeg -i moon_video.mp4 -vf fps=30 frame_%04d.png
```

**Explanation of parameters:**
- `-i moon_video.mp4` → Input file.
- `-vf fps=30` → Extracts 30 frames per second (adjust to match your video's frame rate).
- `frame_%04d.png` → Names the frames as `frame_0001.png`, `frame_0002.png`, etc.

*Tip: If you only need a specific part of the video, use `-ss` (start time) and `-t` (duration):*
```bash
ffmpeg -i moon_video.mp4 -ss 00:00:05 -t 00:00:20 -vf fps=30 frame_%04d.png
```

---

## 🚀 Step 5: Prepare and Run the Script

1. Download the fixed `moon_stacking.m` script from this GitHub repository. *(Note: Make sure to use the fixed version from this repo, as the original file contained a few syntax typos that have been corrected here).*
2. Place the script in the same folder as your extracted frames:
   ```text
   C:\MoonStacking\
   ├── moon_stacking.m
   ├── frame_0001.png
   ├── frame_0002.png
   └── ...
   ```
3. Open **GNU Octave**.
4. Navigate to your folder:
   ```octave
   cd 'C:\MoonStacking'
   ```
5. Run the script:
   ```octave
   moon_stacking
   ```

---

## ⏳ Step 6: Wait and View the Result

- For 764 frames (1080p), the process takes approximately **2 to 5 minutes**, depending on your CPU.
- Octave will show the progress: `Frame 40 / 764 (used: 35)`.
- Once finished, you will find two new images in your folder:
  - `Moon_Stack_Final_88_Fixed2.png` → The stacked result.
  - `Moon_Stack_Final_4x_88_Fixed2.png` → The 4x upscaled version.

---

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| `error: 'pkg' undefined` | Restart Octave. |
| `error: 'imread' undefined` | Type `pkg load image` in the Command Window. |
| `error: 'histcounts' undefined` | The code already uses `histc` as a fallback for Octave. |
| `error: 'shif t_x' undefined` | You are using the old, buggy version. Download the fixed script from this GitHub repo. |
| Only a few frames are used | Lower the threshold in the script from `conf > 0.3` to `conf > 0.2`. |
| FFmpeg is not found | Check your PATH variable and make sure you opened a **new** CMD window. |

---

## 📋 Summary of Commands

```bash
# 1. Extract frames
ffmpeg -i moon_video.mp4 -vf fps=30 frame_%04d.png

# 2. Start Octave and install/load the image package
octave
pkg install -forge image
pkg load image

# 3. Run the script
cd 'C:\MoonStacking'
moon_stacking
```

---

##  System Requirements

- **RAM:** At least 4 GB (8 GB recommended for 4K videos).
- **Storage:** ~500 MB for 764 frames (1080p).
- **CPU:** Any modern processor (Intel i3 / AMD Ryzen 3 or better).
- **OS:** Windows 10/11, macOS, or Linux.

***

**Happy Stacking! 🌕** If you run into any issues, feel free to open an Issue on this GitHub repository.
