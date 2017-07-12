Two things have worked.
-----------------------

The first (1) no longer works after a ph-suspend-hybrid.
The second (2) currently works.

1. https://ubuntuforums.org/showthread.php?t=2322413&page=2&p=13578990#post13578990
Copy "50-synaptics.conf" from /usr/share/X11/xorg.conf.d/ into /etc/X11/xorg.conf.d/
Add the below two lines in the first "InputClass" section, under the line that has 'MatchDevicePath "/dev/input/event*"':
    # Enable ClickPad as specified here: https://ubuntuforums.org/showthread.php?t=2322413&page=2&p=13578990#post13578990
    Option "ClickPad" "1"

2. http://askubuntu.com/a/369229 (4)
    echo "options psmouse proto=imps" | sudo tee -a /etc/modprobe.d/touchpad.conf

