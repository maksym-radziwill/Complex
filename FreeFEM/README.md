Download nix e.g on Debian 

sudo apt install nix-setup-systemd
sudo adduser $USER nix-users

Then in this folder 

nix --extra-experimental-features 'nix-command flakes' develop -L

This will drop you into a new shell with FreeFEM in it, in which you run:

FreeFem++ ./example.edp 


