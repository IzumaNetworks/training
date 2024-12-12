#!/usr/bin/env bash
#intenals
# incus launch images:ubuntu/22.04 mybuild --vm -s <storage-pool> --config devices.root.size=20GB
PROMPT_TEMP=""
__prompt_entry() {
    pushd . >>/dev/null
    PROMPT_TEMP=$(mktemp -d /tmp/XXXXXXXXXXXX)
    cd $PROMPT_TEMP
}

__prompt_exit() {
    tempdirforthis="$1"
    brakettext="$2"
    confirmdestroy="$3"
    echo -en "#!/bin/bash\n    text=\"([$brakettext]: exit when done) \"\n    export PS1=\"\\\[\\\e[31;43m\\\]\\\W\\\\$text[\\\e[m\\\] \"\n    export PS1=\"\\\[\\\e[36m\\\]\$text\\\[\\\e[33m\\\]\\\W >\\\[\\\e[m\\\] \"\n" >/tmp/s.sh
    bash --rcfile <(echo '. /tmp/s.sh')
    popd >>/dev/null
    if [[ $confirmdestroy == "yes" ]]; then
        echo "Do you wish to remove $tempdirforthis?"
        select yn in "Yes" "No"; do
            case $yn in
            Yes)
                rm -rf $tempdirforthis
                break
                ;;
            #
            No) exit ;;
                #
            esac
        done
    else
        rm -rf $tempdirforthis
    fi
}
echo "label  ::1/128       0
label  ::/0          1
label  2002::/16     2
label ::/96          3
label ::ffff:0:0/96  4
precedence  ::1/128       50
precedence  ::/0          40
precedence  2002::/16     30
precedence ::/96          20
precedence ::ffff:0:0/96  100" >/tmp/gai.conf

sudo mv /tmp/gai.conf /etc/gai.conf
sudo apt-get install -y coreutils curl gawk wget git diffstat unzip \
    texinfo g++ gcc-multilib build-essential chrpath socat cpio \
    openjdk-11-jre python3 python3-pip python3-venv python3-pexpect \
    xz-utils debianutils iputils-ping libsdl1.2-dev xterm libssl-dev \
    libelf-dev file lz4 ca-certificates whiptail xxd \
    libtinfo5 zstd libncurses5-dev emacs
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo >~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH
python3 -m venv ~/edge-venv
source ~/edge-venv/bin/activate
python --version
pip install wheel
pip install manifest-tool
if [[ ! -d ~/Edge_Credentials ]]; then
    mkdir ~/Edge_Credentials
fi
if [[ ! -f ~/Edge_Credentials/update_default_resources.c ]]; then
    read -n 1 -p "waiting for you to upload credentials to ~/Edge_Credentials"
fi
mkdir ~/build
cd ~/build
repo init -u https://github.com/PelionIoT/manifest-edge.git -m edge.xml -b refs/tags/v2.6.0
repo sync -j"$(nproc)"
cp ~/Edge_Credentials/update_default_resources.c layers/meta-edge/recipes-edge/edge-core/files/
cp ~/Edge_Credentials/mbed_cloud_dev_credentials.c layers/meta-edge/recipes-edge/edge-core/files/

MACHINE=raspberrypi3-64 source setup-environment
export LOCALCONF=/home/travis/build/build-lmp/conf/local.conf
echo -e "\n" >>"$LOCALCONF"
echo 'MBED_EDGE_CORE_CONFIG_DEVELOPER_MODE = "ON"' >>"$LOCALCONF"
echo 'MBED_EDGE_CORE_CONFIG_FIRMWARE_UPDATE = "ON"' >>"$LOCALCONF"
echo 'MBED_EDGE_CORE_CONFIG_FOTA_ENABLE = "ON"' >>"$LOCALCONF"
bitbake rust-native
bitbake clang-native
#bitbake core-image-minimal
bitbake lmp-base-console-image
