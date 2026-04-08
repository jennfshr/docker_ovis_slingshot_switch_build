# Slingshot Switch Sampler LDMS DPKG Package Build in a Docker Debian Container

## Docker container build of debian11 ovis-ldms v4.4.6 release with slingshot-switch-sampler-plugin support

## Command line docker build and copy instructions
```bash
docker build -f Dockerfile -t ovis-ldms-slingshot-debian11:latest .
```
```bash
docker run --entrypoint tar ovis-ldms-slingshot-debian11 cfJ - /ovis-ldms-debian-package > ovis-ldms-debian-package.tar.xz
tar jfx ovis-ldms-debian-package.tar.xz -x ovis-ldms-debian-package/ovis-ldms_4.4.6-1_arm64.deb
```

## Get debian package to the Slingshot Switch
```bash
scp ovis-ldms-debian-package/ovis-ldms_4.4.6-1_arm64.deb $USER@ncn-m001:~
ssh $USER@ncn-m001
scp ovis-ldms_4.4.6-1_arm64.deb root@x3001c0r42b0:~
ssh root@x3001c0r42b0
dpkg --instdir /rwfs/ --admindir /rwfs -i ovis-ldms_4.4.6-1_arm64.deb
```

## Get Switch Generation Script to the Switch
```bash
scp  ~jkgreen/myovis-ldms-slingshot/new_gen_switch_configs.sh root@x3001c0r42b0:/rwfs/usr/bin/.
root@x3001c0r42b0's password:
new_gen_switch_configs.sh      100%   17KB   9.2MB/s   00:00
ssh root@
chmod +x new_gen_switch_config.sh
./new_gen_switch_config.sh -h
```
## Usage output for customizations
```bash
root@x3001c0r42b0:/rwfs/usr/bin# ./new_gen_switch_configs.sh -h
new_gen_switch_configs.sh Configures LDMS for Slingshot Switches
  usage: new_gen_switch_configs.sh [options]
    [-a|--auth-plugin]		-- ldmsd authentication plugin; default "none".  Chose from: "none", "munge", "ovis". (default: "none")
    [-A|--auth-conf]		-- ldmsd authentication file for shared secret when using "-a ovis" auth mode;  (default: ""; ldmsd defaults to /etc/ldmsauth.conf)
    [-d|--ldmsd-verbose]	-- Set Verbosity of LDMSD Logs chose from: "DEBUG", "INFO", "ERROR", "CRITICAL", and "QUIET" (default: "ERROR")
    [-P|--prefix]		-- Prefix path for OVIS installation (defaults /rwfs/usr)
    [-v|--verbose]		-- enable xtrace output for new_gen_switch_configs.shin shell
    [-h|--help]			-- dumps usage and exits
    [-x|--xprt]			-- LDMSD transport (default: sock)
    [-p|--port]			-- LDMSD port
    [-m|--mem]			-- LDMSD mem setting (default: 5M)
    [-l|--log]			-- LDMSD log location (default: none)
    [-S|--systemd-dir]		-- Where to install systemd service files (default: /etc/systemd/system)

  For support email <ldms@sandia.gov>
  Git Repo: https://github.com/jennfshr/docker_ovis_slingshot_switch_build
```

## Generate Switch Configurations
- `new_gen_switch_configs.sh` should do what is required to setup LDMS configurations and systemd service unit files for ldms-services enablement
```bash


## Github Action Automations are enabled - but require a self-hosted linux github debian11 runner on ARM64
- WIP
  
## Script `build_debian_package.sh` is outdated, but left here for reference.
- It'll get updated in time.
- The successful execution of the script will output the following execution trace of the docker build steps and a print statement directing the user to the resulting tarball on their desktop.

![image](https://github.com/user-attachments/assets/a8f502a8-4292-496b-835a-b6746fbba110)

