# Nocturnes - Setup Notes

## Host dependencies

```
sudo apt-get install sshpass socat wakeonlan python3-gi gir1.2-gtk-3.0
```

## Setting a static IP on a target device

Each device needs a unique static IP. After flashing and booting,
SSH in and run:

```
connmanctl services
connmanctl config ethernet_<mac>_cable --ipv4 manual <ip> 255.255.255.0 192.168.10.1
```

For example, for device at 192.168.10.20:

```
connmanctl config ethernet_aabbccddeeff_cable --ipv4 manual 192.168.10.20 255.255.255.0 192.168.10.1
```

The setting persists across reboots.

## Wake-on-LAN

WOL is enabled automatically via the S30wol init script. To verify on a target:

```
ethtool enp1s0 | grep Wake
```

Should show `Supports Wake-on: ...g` and `Wake-on: g`.

WOL must also be enabled in the BIOS/UEFI (look for "Wake on LAN" or
"Wake on PCI-E" under Power Management).

Add MAC addresses to `nocturnes-hosts.conf` (optional 3rd column) for
reliable wake:

```
192.168.10.18 content.mp4 aa:bb:cc:dd:ee:ff
```

Then use `nocturnes-ctl wake` or the "Wake All" button in the GUI.

## Checking hardware decoder

On the target device (via SSH):

```
echo '{"command":["get_property","hwdec-current"]}' | socat -t2 STDIO UNIX-CONNECT:/tmp/mpv.sock
```

Should return `{"data":"vaapi","error":"success"}` if VAAPI is active.

## Encoding video for synchronized playback

Use CBR H.264 High profile at 60fps for frame-accurate sync:

```
ffmpeg -i input.mp4 \
  -c:v libx264 -profile:v high \
  -b:v 12M -minrate 12M -maxrate 12M -bufsize 12M \
  -x264-params "nal-hrd=cbr" \
  -g 60 -keyint_min 60 -sc_threshold 0 \
  -r 60 -vsync cfr \
  -s 1920x1080 \
  -c:a aac -b:a 192k \
  -movflags +faststart \
  output.mp4
```
