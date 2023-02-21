#!/usr/bin/bash

set -e

apt-get update

apt-get install -y \
    curl \
    ca-certificates \
    unzip \
    weston \
    openjdk-11-jdk-headless

# install android command line tools
curl -L https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -o /tmp/commandlinetools-linux-9477386_latest.zip
unzip /tmp/commandlinetools-linux-9477386_latest.zip -d /tmp
mkdir -p $ANDROID_HOME/cmdline-tools
mv /tmp/cmdline-tools /opt/android-sdk/cmdline-tools/latest
rm /tmp/commandlinetools-linux-9477386_latest.zip

# set android sdk env
echo "" >>/root/.profile
echo "# android sdk" >>/root/.profile
echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >>/root/.profile
echo "export ANDROID_HOME=/opt/android-sdk" >>/root/.profile
echo "export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools" >>/root/.profile

source /root/.profile

# install android sdk
yes | sdkmanager --sdk_root=$ANDROID_HOME --licenses
sdkmanager --sdk_root=$ANDROID_HOME --update
sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "platforms;android-30" "build-tools;30.0.3"

# install nodejs
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs

# install waydroid
curl https://repo.waydro.id | sudo bash
apt-get install -y waydroid

# install appium
npm install -g appium

# download waydroid android image
mkdir -p /usr/share/waydroid-extra/images/

curl -L https://oos-cn.ctyunapi.cn/nan-files/lineage-18.1-20230212-MAINLINE-waydroid_x86_64-vendor.zip -o vendor.zip
curl -L https://oos-cn.ctyunapi.cn/nan-files/lineage-18.1-20230212-VANILLA-waydroid_x86_64-system.zip -o system.zip

# unzip waydroid android image
unzip vendor.zip -d /usr/share/waydroid-extra/images/
unzip system.zip -d /usr/share/waydroid-extra/images/

# remove waydroid android image zip
rm vendor.zip
rm system.zip

# init waydroid
waydroid init

# get Waydroid to work through a VM
echo "ro.hardware.gralloc=default" >>/var/lib/waydroid/waydroid.cfg
echo "ro.hardware.egl=swiftshader" >>/var/lib/waydroid/waydroid.cfg
waydroid upgrade -o

# create weston config
mkdir /root/.config
cat <<EOF >/root/.config/weston.ini
[libinput]
enable-tap=true

[shell]
panel-position=none
EOF

# create app.sh
cat <<EOF >/usr/bin/app.sh
#!/usr/bin/bash
set -e

if [ -e /var/run/app.pid ]; then
    echo "App already running"
    exit 0
fi

echo $$ > /var/run/app.pid

trap " rm -f /var/run/app.pid" EXIT SIGQUIT SIGINT SIGSTOP SIGTERM ERR

# start weston
weston --tty 1 2>&1 | tee /var/log/weston.log &

sleep 3

# start waydroid session
waydroid session start 2>&1 | tee /var/log/waydroid.log &

sleep 3

# adb connect to waydroid
ipAddress=\$(waydroid shell ip addr show eth0 | grep "inet " | awk '{print \$2}' | cut -d/ -f1)

while [ -z "\$ipAddress" ]; do
    echo "Waiting for waydroid to start"
    sleep 1
    ipAddress=\$(waydroid shell ip addr show eth0 | grep "inet " | awk '{print \$2}' | cut -d/ -f1)
done

echo "Waydroid started with ip address: \$ipAddress"

adb connect \$ipAddress:5555

# start appium
/usr/bin/appium --allow-cors 2>&1 | tee /var/log/appium.log &

# combine weston, waydroid and appium logs
tail -n 0 -f /var/log/weston.log /var/log/waydroid.log /var/log/appium.log
EOF

chmod +x /usr/bin/app.sh

# create app.service
cat <<EOF >/etc/systemd/system/app.service
[Unit]
Description=App
After=waydroid-container.service

[Service]
Type=simple
Environment="XDG_RUNTIME_DIR=/run/user/0"
Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
Environment=ANDROID_HOME=/opt/android-sdk
Environment=PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/usr/bin/app.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# enable app.service
systemctl enable app.service
systemctl start app.service

# run this script from gist
# curl -sSL https://gist.githubusercontent.com/hydrz/c46dad3a7fa683e47d413bfaf1107ec6/raw/setup.sh | bash -
