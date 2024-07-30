#!/bin/bash

#NOTE: This script should sit in the OVIS bin dir

SWITCH=$(hostname)
COMPONENT_ID=$(hostname | sed 's/[a-z]//g') #Probably need something more sophisticated here to uniquely numerically identify switches. Could also put hostname into a meta-data metric
SCRIPT_DIR_FIRST="$(pwd | awk -F "/" '{print $2}')"

SCRIPT_DIR_LAST="$(pwd | awk -F "/" '{print $NF}')"
if [ x${SCRIPT_DIR_LAST} = "xbin" ] && [ x${SCRIPT_DIR_FIRST} = "xrwfs" ]; then
	echo "in /rwfs/.../bin dir"
else
	echo "in other dir"
fi
echo "Script directory: $SCRIPT_DIR_FIRST, $SCRIPT_DIR_LAST"
#exit

#COMPONENT_ID=1 
TOP="/rwfs/OVIS-slingshot"
PORT_METRICS_CONF_FILE="${TOP}/etc/ldms/${SWITCH}_port_metrics.conf"
LDMS_SAMPLER_CONFIG_FILE="${TOP}/etc/ldms/sampler_slingshot_switch.conf"
SYSTEMD_ENV_FILE="${TOP}/etc/ldms/ldmsd.sampler.systemd.env"
ENV_FILE="${TOP}/etc/ldms/ldmsd.sampler.env"
START_FILE="${TOP}/etc/ldms/start_slingshot_ldms_sampler.sh"
SYSTEMCTL_SERVICE_FILE="${TOP}/etc/systemd/system/ldmsd.sampler.service"

mkdir -p ${TOP}/etc/ldms

################################################################################
# Build configuration file to define slingshot switch metrics and ports for which to collect them
echo "# Configuration for switch: ${SWITCH}" > ${PORT_METRICS_CONF_FILE}
for i in {0..63}; do PORT="${i}: "; PORT+=$(portctl -p ${i} -o status 2>&1 | grep "R_TF_CFTX.CFG_LINK_STATE.NEW_TX_LK:"); echo ${PORT} | grep RUNNING_0 | awk '{print $1}' | sed 's/://g' | tr '\n' ','; done | sed 's/^/p=/' | sed 's/.$/\n/' >> ${PORT_METRICS_CONF_FILE}
echo "#" >> ${PORT_METRICS_CONF_FILE}
echo "rfc_3635" >> ${PORT_METRICS_CONF_FILE}

################################################################################
# Build ldmsd sampler configuration file for collecting slingshot switch port metrics
#echo "#" >> ${LDMS_SAMPLER_CONFIG_FILE}
echo "load name=slingshot_switch" > ${LDMS_SAMPLER_CONFIG_FILE}
echo "config name=slingshot_switch producer=${SWITCH} component_id=${COMPONENT_ID} instance=${SWITCH}/port_metrics conffile=${PORT_METRICS_CONF_FILE}" >> ${LDMS_SAMPLER_CONFIG_FILE}
echo "start name=slingshot_switch interval=1000000" >> ${LDMS_SAMPLER_CONFIG_FILE}

################################################################################
# Build file that defines environment for running ldmsd using systemctl

echo "LD_LIBRARY_PATH=${TOP}/lib64/" > ${SYSTEMD_ENV_FILE}
echo "PATH=${TOP}/sbin:$PATH" >> ${SYSTEMD_ENV_FILE}
echo "PYTHONPATH=${TOP}/lib/python3.6/site-packages/" >> ${SYSTEMD_ENV_FILE}
echo "LDMSD_PLUGIN_LIBPATH=${TOP}/lib64/ovis-ldms" >> ${SYSTEMD_ENV_FILE}
echo "ZAP_LIBPATH=${TOP}/lib64/ovis-ldms" >> ${SYSTEMD_ENV_FILE}
echo '' >> ${SYSTEMD_ENV_FILE}

echo '# ldmsd env vars' >> ${SYSTEMD_ENV_FILE}
echo 'LDMSD_MAX_CONFIG_STR_LEN=500000' >> ${SYSTEMD_ENV_FILE}
echo 'MMALLOC_DISABLE_MM_FREE=0' >> ${SYSTEMD_ENV_FILE}
echo '' >> ${SYSTEMD_ENV_FILE}

echo '# Define LDMS transport' >> ${SYSTEMD_ENV_FILE}
echo 'LDMSD_XPRT=sock' >> ${SYSTEMD_ENV_FILE}
echo '' >> ${SYSTEMD_ENV_FILE}

echo '# Define LDMS Daemon service port' >> ${SYSTEMD_ENV_FILE}
echo 'LDMSD_PORT=411' >> ${SYSTEMD_ENV_FILE}
echo '' >> ${SYSTEMD_ENV_FILE}

echo '# Define LDMS maximum memory allocation' >> ${SYSTEMD_ENV_FILE}
echo 'LDMSD_MEM=5M' >> ${SYSTEMD_ENV_FILE}
echo '' >> ${SYSTEMD_ENV_FILE}

echo '# Define LDMS Daemon verbosity' >> ${SYSTEMD_ENV_FILE}
echo '#LDMSD_VERBOSITY=DEBUG' >> ${SYSTEMD_ENV_FILE}
echo 'LDMSD_VERBOSE=QUIET' >> ${SYSTEMD_ENV_FILE}
echo '' >> ${SYSTEMD_ENV_FILE}

echo '# Define log file location (no need if verbosity of QUIET' >> ${SYSTEMD_ENV_FILE}
echo '# Log file control. The default is to log to syslog.' >> ${SYSTEMD_ENV_FILE}
echo '# LDMSD_LOG_OPTION="-l /var/log/ldmsd.log"' >> ${SYSTEMD_ENV_FILE}
echo '' >> ${SYSTEMD_ENV_FILE}

echo '# Define LDMS Daemon Authentication method' >> ${SYSTEMD_ENV_FILE}
echo 'LDMSD_AUTH_PLUGIN=none' >> ${SYSTEMD_ENV_FILE}
echo '' >> ${SYSTEMD_ENV_FILE}

#echo '# Authentication options' >> ${SYSTEMD_ENV_FILE}
#echo "#LDMSD_AUTH_OPTION="-a ${LDMSD_AUTH_PLUGIN}"" >> ${SYSTEMD_ENV_FILE}
#echo "#LDMSD_AUTH_OPTION="-A conf=${TOP}/etc/ldms/ldmsauth.conf"" >> ${SYSTEMD_ENV_FILE}
#echo '' >> ${SYSTEMD_ENV_FILE}

echo '# LDMS plugin configuration file, see ${TOP}/etc/ldms/sampler.conf for an example' >> ${SYSTEMD_ENV_FILE}
#echo "LDMSD_PLUGIN_CONFIG_FILE=${TOP}/etc/ldms/${LDMS_SAMPLER_CONFIG_FILE}" >> ${SYSTEMD_ENV_FILE}
echo "LDMSD_PLUGIN_CONFIG_FILE=${LDMS_SAMPLER_CONFIG_FILE}" >> ${SYSTEMD_ENV_FILE}


################################################################################
# Build file that defines environment for running ldmsd from command line

echo "export LD_LIBRARY_PATH=${TOP}/lib64/:$LD_LIBRARY_PATH" > ${ENV_FILE}
echo "export PATH=${TOP}/sbin:$PATH" >> ${ENV_FILE}
echo "export PYTHONPATH=${TOP}/lib/python3.6/site-packages/:$PYTHONPATH" >> ${ENV_FILE}
echo "export LDMSD_PLUGIN_LIBPATH=${TOP}/lib64/ovis-ldms" >> ${ENV_FILE}
echo "export ZAP_LIBPATH=${TOP}/lib64/ovis-ldms" >> ${ENV_FILE}
echo '' >> ${ENV_FILE}

echo '# ldmsd env vars' >> ${ENV_FILE}
echo 'export LDMSD_MAX_CONFIG_STR_LEN=500000' >> ${ENV_FILE}
echo 'export MMALLOC_DISABLE_MM_FREE=0' >> ${ENV_FILE}
echo '' >> ${ENV_FILE}

echo '# Define LDMS transport' >> ${ENV_FILE}
echo 'export LDMSD_XPRT=sock' >> ${ENV_FILE}
echo '' >> ${ENV_FILE}

echo '# Define LDMS Daemon service port' >> ${ENV_FILE}
echo 'export LDMSD_PORT=411' >> ${ENV_FILE}
echo '' >> ${ENV_FILE}

echo '# Define LDMS maximum memory allocation' >> ${ENV_FILE}
echo 'export LDMSD_MEM=5M' >> ${ENV_FILE}
echo '' >> ${ENV_FILE}

echo '# Define LDMS Daemon verbosity' >> ${ENV_FILE}
echo '#export LDMSD_VERBOSITY=DEBUG' >> ${ENV_FILE}
echo 'export LDMSD_VERBOSE=QUIET' >> ${ENV_FILE}
echo '' >> ${ENV_FILE}

echo '# Define log file location (no need if verbosity of QUIET' >> ${ENV_FILE}
echo '# Log file control. The default is to log to syslog.' >> ${ENV_FILE}
echo '# export LDMSD_LOG_OPTION="-l /var/log/ldmsd.log"' >> ${ENV_FILE}
echo '' >> ${ENV_FILE}

echo '# Define LDMS Daemon Authentication method' >> ${ENV_FILE}
echo 'export LDMSD_AUTH_PLUGIN=none' >> ${ENV_FILE}
echo '' >> ${ENV_FILE}

#echo '# Authentication options' >> ${ENV_FILE}
#echo "export #LDMSD_AUTH_OPTION="-a ${LDMSD_AUTH_PLUGIN}"" >> ${ENV_FILE}
#echo "export #LDMSD_AUTH_OPTION="-A conf=${TOP}/etc/ldms/ldmsauth.conf"" >> ${ENV_FILE}
#echo '' >> ${ENV_FILE}

echo '# LDMS plugin configuration file, see ${TOP}/etc/ldms/sampler.conf for an example' >> ${ENV_FILE}
echo "export LDMSD_PLUGIN_CONFIG_FILE=${LDMS_SAMPLER_CONFIG_FILE}" >> ${ENV_FILE}


################################################################################
# Build a start file that runs ldmsd and slingshot sampler outside of systemctl

echo '#!/bin/bash' > ${START_FILE}
echo '' >> ${START_FILE}

echo "source ${TOP}/etc/ldms/ldmsd.sampler.env" >> ${START_FILE}
echo '' >> ${START_FILE}

echo "echo ${TOP}/sbin/ldmsd -x ${LDMSD_XPRT}:${LDMSD_PORT} -c ${LDMSD_PLUGIN_CONFIG_FILE} -a ${LDMSD_AUTH_PLUGIN} -v ${LDMSD_VERBOSE} -m ${LDMSD_MEM} ${LDMSD_LOG_OPTION}" >> ${START_FILE}
echo "${TOP}/sbin/ldmsd -x ${LDMSD_XPRT}:${LDMSD_PORT} -c ${LDMSD_PLUGIN_CONFIG_FILE} -a ${LDMSD_AUTH_PLUGIN} -v ${LDMSD_VERBOSE} -m ${LDMSD_MEM} ${LDMSD_LOG_OPTION}" >> ${START_FILE}
chmod +x ${START_FILE}

################################################################################
# Create systemd related files and links

# Create directory for service file that will have symlink from /etc/systemd/system/ldmsd.sampler.service
mkdir -p ${TOP}/etc/systemd/system

echo '[Unit]' > ${SYSTEMCTL_SERVICE_FILE}
echo 'Description = LDMS Sampler Daemon' >> ${SYSTEMCTL_SERVICE_FILE}
echo 'Documentation = https://ovis-hpc.readthedocs.io/en/latest/' >> ${SYSTEMCTL_SERVICE_FILE}
echo '' >> ${SYSTEMCTL_SERVICE_FILE}
echo '[Service]' >> ${SYSTEMCTL_SERVICE_FILE}
echo 'Type = forking' >> ${SYSTEMCTL_SERVICE_FILE}
echo "EnvironmentFile = ${TOP}/etc/ldms/ldmsd.sampler.systemd.env" >> ${SYSTEMCTL_SERVICE_FILE}
echo 'Environment = HOSTNAME=%H' >> ${SYSTEMCTL_SERVICE_FILE}
echo "ExecStartPre = /bin/mkdir -p ${TOP}/var/run/ldmsd" >> ${SYSTEMCTL_SERVICE_FILE}
echo "ExecStart = ${TOP}/sbin/ldmsd \\" >> ${SYSTEMCTL_SERVICE_FILE}
echo '                -x ${LDMSD_XPRT}:${LDMSD_PORT} \' >> ${SYSTEMCTL_SERVICE_FILE}
echo '                -c ${LDMSD_PLUGIN_CONFIG_FILE} \' >> ${SYSTEMCTL_SERVICE_FILE}
echo '                -a ${LDMSD_AUTH_PLUGIN} \' >> ${SYSTEMCTL_SERVICE_FILE}
echo '                -v ${LDMSD_VERBOSE} \' >> ${SYSTEMCTL_SERVICE_FILE}
echo '                -m ${LDMSD_MEM} \' >> ${SYSTEMCTL_SERVICE_FILE}
echo '                $LDMSD_LOG_OPTION \' >> ${SYSTEMCTL_SERVICE_FILE}
echo "                -r ${TOP}/var/run/ldmsd/sampler.pid" >> ${SYSTEMCTL_SERVICE_FILE}
echo '' >> ${SYSTEMCTL_SERVICE_FILE}
echo '[Install]' >> ${SYSTEMCTL_SERVICE_FILE}
echo 'WantedBy = default.target' >> ${SYSTEMCTL_SERVICE_FILE}

# Create symbolic link to new service file if link doesn't exist
if [ -f /etc/systemd/system/ldmsd.sampler.service ]; then
	echo "/etc/systemd/system/ldmsd.sampler.service -> ${TOP}/etc/systemd/system/ldmsd.sampler.service exists"
else
	echo "Creating symlink:"
	echo "ln -s ${TOP}/etc/systemd/system/ldmsd.sampler.service /etc/systemd/system/ldmsd.sampler.service"
	ln -s ${TOP}/etc/systemd/system/ldmsd.sampler.service /etc/systemd/system/ldmsd.sampler.service
fi


# Reload systemd service in case there were changes to ldmsd.sampler.service file
echo "systemctl daemon-reload"
systemctl daemon-reload

# Restart ldmsd.sampler.service 
echo "To start/restart the ldmsd slingshot sampler run: \"systemctl restart ldmsd.sampler\""
#systemctl restart ldmsd.sampler

echo ''
# Instructions for testing using ldms_ls utility
echo "Set up your environment by running: \"source ${TOP}/etc/ldms/ldmsd.sampler.env\""

echo ''
echo "Run: \"ldms_ls -h localhost -x sock -p 411 -l\""
