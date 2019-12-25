#!/usr/bin/env bash
# This script will auto-detect the OS and Version
# It will update system packages and install Ansible and git
# Then it will clone the goshimmer-playbook and run it.

# Goshimmer playbook: https://github.com/nuriel77/goshimmer-playbook
# By Nuriel Shem-Tov (https://github.com/nuriel77), December 2019
# Copyright (c) 2019 Nuriel Shem-Tov

set -o pipefail
set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as user root"
    echo "Please change to root using: 'sudo su -' and re-run the script"
    exit 1
fi

# Default value for goshimmer-playbook repository URL
: "${GIT_REPO_URL:=https://github.com/nuriel77/goshimmer-playbook.git}"

export NEWT_COLORS='
window=,
'

declare -g GOSHIMMER_PLAYBOOK_DIR="/opt/hornet-playbook"
declare -g INSTALLER_OVERRIDE_FILE="${GOSHIMMER_PLAYBOOK_DIR}/group_vars/all/z-installer-override.yml"

# Configurable install options passed to ansible-playbook command
: "${INSTALL_OPTIONS:=}"

# Set minimum ram, used to set profile.
: "${MIN_RAM_KB:=1572864}"

if test -e /etc/motd && grep -q 'GoShimmer PLAYBOOK' /etc/motd; then
    :>/etc/motd
else
    if [ -f "$INSTALLER_OVERRIDE_FILE" ] && [ "$1" != "rerun" ]
    then
        if ! (whiptail --title "Confirmation" \
                 --yesno "It looks like a previous installation already exists.\n\nRunning the installaer on an already working node is not recommended.\n\nIf you want to re-run only the playbook check the documentation or ask for assistance on Discord #goshimmer-discussion channel.\n\nPlease confirm you want to proceed with the installation?" \
                 --defaultno \
                 16 78); then
            exit 1
        fi
    fi
fi

cat <<'EOF'

go
  _____ _   _ ________  ______  ___ ___________
 /  ___| | | |_   _|  \/  ||  \/  ||  ___| ___ \
 \ `--.| |_| | | | | .  . || .  . || |__ | |_/ /
  `--. \  _  | | | | |\/| || |\/| ||  __||    /
 /\__/ / | | |_| |_| |  | || |  | || |___| |\ \
 \____/\_| |_/\___/\_|  |_/\_|  |_/\____/\_| \_| node installer

EOF

cat <<EOF
Welcome to IOTA's goShimmer (unofficial) installer!
1. By pressing 'y' you agree to install goShimmer node on your system.
2. By pressing 'y' you aknowledge that this installer requires a CLEAN operating system
   and may otherwise !!!BREAK!!! existing software on your server.
3. You read and agree to http://iri-playbook.readthedocs.io/en/master/disclaimer.html
4. This installation ensures firewall is enabled.
5. If you already have a configured server, re-running this script might overwrite previous configuration.
EOF

read -p "Do you wish to proceed? [y/N] " yn
if echo "$yn" | grep -v -iq "^y"; then
    echo Cancelled
    exit 1
fi

#################
### Functions ###
#################
function set_dist() {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        echo "Unsupported OS."
        exit 1
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        echo "Old OS version. Minimum required is 7."
        exit 1
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        VER=$(uname -r)
    fi
}

# Installation selection menu
function set_selections()
{
    local RC RESULTS RESULTS_ARRAY CHOICE SKIP_TAGS
    SKIP_TAGS="--skip-tags=_"

    RESULTS=$(whiptail --title "Installation Options" --checklist \
        --cancel-button "Exit" \
        "\nInstallation options.\nNote that it is perfectly okay, and even recommended, to leave this as is!\n\
Select/unselect options using space and click Enter to proceed.\n" 12 78 2 \
        "SKIP_INSTALL_NGINX"       "Skip installation of nginx webserver" OFF \
        "SKIP_FIREWALL_CONFIG"     "Skip configuring firewall" OFF \
        3>&1 1>&2 2>&3)

    RC=$?
    if [[ $RC -ne 0 ]]; then
        echo "Installation cancelled"
        exit 1
    fi

    if [[ -n "$RESULTS" ]]; then
        RESULTS_MSG=$(echo "$RESULTS"|sed 's/ /\n/g')
        if ! (whiptail --title "Confirmation" \
                 --yesno "You chose:\n\n$RESULTS_MSG\n\nPlease confirm you want to proceed with the installation?" \
                 --defaultno \
                 12 78); then
            exit 1
        fi
    fi

    read -a RESULTS_ARRAY <<< "$RESULTS"
    for CHOICE in "${RESULTS_ARRAY[@]}"
    do
        case $CHOICE in
            '"SKIP_INSTALL_NGINX"')
                echo "install_nginx: false" >>"$INSTALLER_OVERRIDE_FILE"
                ;;
            '"SKIP_FIREWALL_CONFIG"')
                echo "configure_firewall: false" >>"$INSTALLER_OVERRIDE_FILE"
                ;;
            *)
                ;;
        esac
    done

    INSTALL_OPTIONS+=" $SKIP_TAGS"
}

function init_centos_7(){
    echo "Updating system packages..."
    yum update -y

    echo "Install epel-release..."
    yum install epel-release -y

    echo "Update epel packages..."
    yum update -y

    echo "Install yum utils..."
    yum install -y yum-utils

    set +e
    set +o pipefail
    if $(needs-restarting -r 2>&1 | grep -q "Reboot is required"); then
        [ -z "$SKIP_REBOOT" ] && { inform_reboot; exit 0; }
    fi
    set -o pipefail
    set -e

    echo "Installing Ansible and git..."
    yum install ansible git expect-devel cracklib newt -y
}

function init_centos_8(){
    echo "Updating system packages..."
    dnf update -y --nobest

    echo "Install epel-release..."
    dnf install epel-release -y

    echo "Update epel packages..."
    dnf update -y --nobest

    echo "Install yum utils..."
    dnf install -y yum-utils

    local OUTPUT=$(needs-restarting)
    if [[ "$OUTPUT" != "" ]]; then
        [ -z "$SKIP_REBOOT" ] && { inform_reboot; exit 0; }
    fi

    echo "Installing Ansible, git and other requirements..."
    dnf install git expect newt python3-pip cracklib newt -y
    pip3 --disable-pip-version-check install ansible
}

function init_ubuntu(){
    echo "Updating system packages..."
    apt update -qqy --fix-missing
    apt-get upgrade -y
    apt-get clean
    apt-get autoremove -y --purge

    echo "Check reboot required..."
    if [ -f /var/run/reboot-required ]; then
        [ -z "$SKIP_REBOOT" ] && { inform_reboot; exit 0; }
    fi

    echo "Installing Ansible and git..."
    apt-get install software-properties-common -y
    apt-add-repository ppa:ansible/ansible -y
    add-apt-repository universe -y
    apt-get update -y
    apt-get install ansible\
                    git\
                    expect-dev\
                    tcl\
                    libcrack2\
                    cracklib-runtime\
                    whiptail\
                    lsb-release -y
}

function init_debian(){
    echo "Updating system packages..."
    apt update -qqy --fix-missing
    apt-get upgrade -y
    apt-get clean
    apt-get autoremove -y --purge

    echo "Check reboot required..."
    if [ -f /var/run/reboot-required ]; then
        [ -z "$SKIP_REBOOT" ] && { inform_reboot; exit 0; }
    fi

    echo "Installing Ansible and git..."
    local ANSIBLE_SOURCE="deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main"
    grep -q "$ANSIBLE_SOURCE" /etc/apt/sources.list || echo "$ANSIBLE_SOURCE" >> /etc/apt/sources.list
    apt-get install dirmngr --install-recommends -y
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
    apt-get update -y
    apt-get install ansible\
                    git\
                    expect-dev\
                    tcl\
                    libcrack2\
                    cracklib-runtime\
                    whiptail\
                    lsb-release -y
}

function inform_reboot() {
    cat <<EOF >/etc/motd
======================== GoShimmer PLAYBOOK ========================
To proceed with the installation, please re-run:
bash <(curl -s https://raw.githubusercontent.com/nuriel77/goshimmer-playbook/master/goshimmer_install.sh)
(make sure to run it as user root)
EOF

    cat <<EOF
======================== PLEASE REBOOT AND RE-RUN THIS SCRIPT =========================
Some system packages have been updated which require a reboot
and allow the node installer to proceed with the installation.
*** Please reboot this machine and re-run this script ***
>>> To reboot run: 'reboot', and when back online:
bash <(curl -s https://raw.githubusercontent.com/nuriel77/goshimmer-playbook/master/goshimmer_install.sh)
!! Remember to re-run this script as root !!
EOF
}

function set_admin_password_a() {
    whiptail --title "Admin Password" \
             --passwordbox "Please enter the password with which you will connect to services (e.g. Web, etc). Use a stong password!!! Not 'hello123' or 'iota8181', you get the point ;). Only valid ASCII characters are allowed." \
             10 78 3>&1 1>&2 2>&3

    if [[ $? -ne 0 ]]; then
        echo "Installation cancelled"
    fi
}

function set_admin_password_b() {
    whiptail --passwordbox "please repeat" 8 78 --title "Admin Password" 3>&1 1>&2 2>&3
    if [[ $? -ne 0 ]]; then
        echo "Installation cancelled"
    fi
}

function get_admin_password() {

    # Get first password and validate ascii characters only
    local PASSWORD_A=$(set_admin_password_a)
    if [[ "$PASSWORD_A" == "Installation cancelled" ]]; then
        echo "$PASSWORD_A"
        exit 1
    fi

    local LC_CTYPE=C
    case "${PASSWORD_A}" in
        *[![:cntrl:][:print:]]*)
            whiptail --title "Invalid characters!!" \
                     --msgbox "Only ASCII characters are allowed:\n\n!\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_\`abcdefghijklmnopqrstuvwxyz{|}~" \
                     12 78
            get_admin_password
            return
            ;;
    esac

    # Get password again and check passwords match
    local PASSWORD_B=$(set_admin_password_b)
    if [[ "$PASSWORD_B" == "Installation cancelled" ]]; then
        echo "$PASSWORD_B"
        exit 1
    fi
    if [ "$PASSWORD_A" != "$PASSWORD_B" ]; then
        whiptail --title "Passwords Mismatch!" \
                 --msgbox "Passwords do not match, please try again." \
                 8 78
        get_admin_password
        return
    fi

    PASSWD_CHECK=$(echo -n "$PASSWORD_A" | cracklib-check)
    if [[ $(echo "$PASSWD_CHECK" | awk {'print $2'}) != "OK" ]]; then
        whiptail --title "Weak Password!" \
                 --msgbox "Please choose a better password:$(echo ${PASSWD_CHECK}|cut -d: -f2-)" \
                 8 78
        get_admin_password
        return
    fi

    # Ensure we escape single quotes (using single quotes) because we need to
    # encapsulate the password with single quotes for the Ansible variable file
    PASSWORD_A=$(echo "${PASSWORD_A}" | sed "s/'/''/g")
    echo "admin_user_password: '${PASSWORD_A}'" >> group_vars/all/z-installer-override.yml
    chmod 400 group_vars/all/z-installer-override.yml
}

function set_admin_username() {
    ADMIN_USER=$(whiptail --inputbox "Choose an administrator's username.\nOnly valid ASCII characters are allowed:" 10 $WIDTH "$ADMIN_USER" --title "Choose Admin Username" 3>&1 1>&2 2>&3)
    if [[ $? -ne 0 ]]; then
        echo "Installation cancelled"
    fi

    local LC_CTYPE=C
    case "${ADMIN_USER}" in
        *[![:cntrl:][:print:]]*)
            whiptail --title "Invalid characters!!" \
                     --msgbox "Only ASCII characters are allowed:\n\n!\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_\`abcdefghijklmnopqrstuvwxyz{|}~" \
                     12 78
            set_admin_username
            return
            ;;
    esac

    echo "admin_user: '${ADMIN_USER}'" > /opt/goshimmer-playbook/group_vars/all/z-installer-override.yml

}

# Get primary IP from ICanHazIP, if it does not validate, fallback to local hostname
function set_primary_ip()
{
    echo "Getting external IP address..."
    local ip=$(curl -s -f --max-time 10 --retry 2 -4 'https://icanhazip.com')
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "Got IP $ip"
        PRIMARY_IP=$ip
    else
        PRIMARY_IP=$(hostname -I|tr ' ' '\n'|head -1)
        echo "Failed to get external IP... using local IP $PRIMARY_IP instead"
  fi
}

function display_requirements_url() {
    echo "Only Debian, Ubuntu 18.04LTS, Raspbian, CentOS 7 and 8 are supported."
}

function check_arch() {
    # Check architecture
    ARCH=$(uname -m)
    local REGEXP="x86_64|armv7l|armv8l|aarch64|aarch32|armhf"
    if [[ ! "$ARCH" =~ $REGEXP ]]; then
        echo "ERROR: $ARCH architecture not supported"
        display_requirements_url
        exit 1
    fi
}

function set_ssh_port() {
    SSH_PORT=$(whiptail --inputbox "Please verify this is your active SSH port:" 8 78 "$SSH_PORT" --title "Verify SSH Port" 3>&1 1>&2 2>&3)
    if [[ $? -ne 0 ]] || [[ "$SSH_PORT" == "" ]]; then
        set_ssh_port
    elif [[ "$SSH_PORT" =~ [^0-9] ]] || [[ $SSH_PORT -gt 65535 ]] || [[ $SSH_PORT -lt 1 ]]; then
        whiptail --title "Invalid Input" \
                 --msgbox "Invalid input provided. Only numbers are allowed (1-65535)." \
                  8 78
        set_ssh_port
    fi
}

function copy_old_config(){
    if [ ! -d "/opt/goshimmer-playbook/group_vars/all" ]; then
        return
    fi
    CONFIG_FILES=($(find "$GOSHIMMER_PLAYBOOK_DIR/group_vars/all" -name 'z-*'))
    if [ "${#CONFIG_FILES[@]}" -eq 0 ]; then
        return
    fi

    if ! (whiptail --title "Confirmation" \
             --yesno "This looks like a re-installation.\n\nDo you want to keep the previous configuration options? (e.g. user/password etc.)\n" \
             --defaultno \
             10 78); then
        return
    fi

    SKIP_SET_SELECTIONS="true"
    mkdir -p /tmp/goshimmer-tmp
    for FILE in "${CONFIG_FILES[@]}"; do
        cp "$FILE" /tmp/goshimmer-tmp/.
    done
}

function run_playbook(){
    # Ansible output log file
    LOGFILE=/var/log/goshimmer-playbook-$(date +%Y%m%d%H%M).log

    # Override ssh_port
    [[ $SSH_PORT -ne 22 ]] && echo "ssh_port: \"${SSH_PORT}\"" > group_vars/all/z-ssh-port.yml

    # Run the playbook
    echo "*** Running playbook command: ansible-playbook -i inventory -v site.yml $INSTALL_OPTIONS" | tee -a "$LOGFILE"
    set +e
    unbuffer ansible-playbook -i inventory -v site.yml $INSTALL_OPTIONS | tee -a "$LOGFILE"
    RC=$?
    if [ $RC -ne 0 ]; then
        echo "ERROR! The playbook exited with failure(s). A log has been save here '$LOGFILE'"
        exit $RC
    fi
    set -e

    # Check playbook needs reboot
    if [ -f "/var/run/playbook_reboot" ]; then
        cat <<EOF >/etc/motd
-------------------- GoShimmer PLAYBOOK --------------------
It seems you have rebooted the node. You can proceed with
the installation by running the command:
${GOSHIMMER_PLAYBOOK_DIR}/rerun.sh
(make sure you are user root before you run it)
-------------------- GoShimmer PLAYBOOK --------------------
EOF

        cat <<EOF
-------------------- NOTE --------------------
The installer detected that the server requires a reboot,
most probably to enable a functionality required by the playbook.
You can reboot the server using the command 'reboot'.
Once the server is back online you can use the following command
to proceed with the installation (become user root first):
${GOSHIMMER_PLAYBOOK_DIR}/rerun.sh
-------------------- NOTE --------------------
EOF

        rm -f "/var/run/playbook_reboot"
        exit
    fi

    # Calling set_primary_ip
    set_primary_ip

    # Get configured username if missing.
    # This could happen on script re-run
    # due to reboot, therefore the variable is empty
    if [ -z "$ADMIN_USER" ]; then
        ADMIN_USER=$(grep ^admin_user "$INSTALLER_OVERRIDE_FILE" | awk {'print $2'})
    fi

    OUTPUT=$(cat <<EOF

* A log of this installation has been saved to: $LOGFILE

* You should be able to connect to the dashboard on (and skip the warning in the browser):

https://${PRIMARY_IP}:18081/dashboard

* Note that your IP might be different as this one has been auto-detected in best-effort.

* Log in with username ${ADMIN_USER} and the password you have entered during the installation.

* For easy node management you can use gosc, just type gosc (as root)

Thank you for installing a goshimmer node with the goshimmer-playbook!

EOF
)

HEIGHT=$(expr $(echo "$OUTPUT"|wc -l) + 10)
whiptail --title "Installation Done" \
         --msgbox "$OUTPUT" \
         $HEIGHT 78
}
#####################
### End Functions ###
#####################

# Incase we call a re-run
if [[ -n "$1" ]] && [[ "$1" == "rerun" ]]; then
    run_playbook
    exit
fi

# Get OS and version
set_dist

# Check OS version compatibility
if [[ "$OS" =~ ^(CentOS|Red) ]]; then
    if [[ ! "$VER" =~ ^(7|8) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_centos_7
elif [[ "$OS" =~ ^Ubuntu ]]; then
    if [[ ! "$VER" =~ ^(16|17|18) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_ubuntu
elif [[ "$OS" =~ ^Debian ]]; then
    if [[ ! "$VER" =~ ^(9|10) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_debian
elif [[ "$OS" =~ ^Raspbian ]]; then
    if [[ ! "$VER" =~ ^(9|10) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    # Same setup for respbian as debian
    init_debian
else
    echo "$OS not supported"
    exit 1
fi

set +o pipefail
# Get default SSH port
SSH_PORT=$(grep ^Port /etc/ssh/sshd_config | awk {'print $2'})
set -o pipefail
if [[ "$SSH_PORT" != "" ]] && [[ "$SSH_PORT" != "22" ]]; then
    set_ssh_port
else
    SSH_PORT=22
fi
echo "SSH port to use: $SSH_PORT"

echo "Verifying Ansible version..."
ANSIBLE_VERSION=$(ansible --version|head -1|awk {'print $2'}|cut -d. -f1-2)
if (( $(awk 'BEGIN {print ("'2.6'" > "'$ANSIBLE_VERSION'")}') )); then
    echo "Error: Ansible minimum version 2.6 required."
    echo "Please remove Ansible: (yum remove ansible -y for CentOS, or apt-get remove -y ansible for Ubuntu)."
    echo
    echo "Then refer to the documentation on how to get latest Ansible installed:"
    echo "http://docs.ansible.com/ansible/latest/intro_installation.html#latest-release-via-yum"
    echo "Note that for CentOS you may need to install Ansible from Epel to get version 2.6 or higher."
    exit 1
fi

cd /opt

# Backup any existing goshimmer-playbook directory
if [ -d "/opt/goshimmer-playbook" ]; then
    copy_old_config
    echo "Backing up older goshimmer-playbook directory..."
    rm -rf goshimmer-playbook.backup
    mv -- goshimmer-playbook goshimmer-playbook.backup
fi

# Clone the repository (optional branch)
echo "Git cloning goshimmer-playbook repository..."
git clone $GIT_OPTIONS "$GIT_REPO_URL"
cd "$GOSHIMMER_PLAYBOOK_DIR"

if [ "$SKIP_SET_SELECTIONS" = true ]; then
    # Copy old configuration
    cp /tmp/goshimmer-tmp/* /opt/goshimmer-playbook/group_vars/all/.
    rm -fr /tmp/goshimmer-tmp/
else
    # Let user choose installation add-ons
    set_selections

    # Get the administrators username
    set_admin_username

    # web access (ipm, haproxy and grafana)
    get_admin_password
fi

echo -e "\nRunning playbook..."
run_playbook
