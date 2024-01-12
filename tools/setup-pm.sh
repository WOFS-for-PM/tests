# set kernel
sudo grubby --set-default "/boot/vmlinuz-5.1.0-splitfs-default-config"
sudo reboot

# set pm
sudo ndctl destroy-namespace -f all
# without size
sudo ndctl create-namespace -f -r 0 -m fsdax
sudo ndctl create-namespace -f -r 1 -m devdax

