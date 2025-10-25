#!/bin/bash

message () {
  local color
  local OPTIND
  local opt
  while getopts "crgymn" opt; do
    case $opt in
      c)  color=$(tput setaf 6) ;;
      r)  color=$(tput setaf 1) ;;
      g)  color=$(tput setaf 2) ;;
      y)  color=$(tput setaf 3) ;;
      m)  color=$(tput setaf 5) ;;
      *)  color=$(tput sgr0)    ;;
    esac
  done
  shift $(($OPTIND -1))
  printf "${color}%-10s %-50s %-50s %-50s\n" "$1" "$2" "$3" "$4"
  tput sgr0
}

inform () {
  message -m "INFO:" "$1" "$2" "$3"
}

die () {
  message -r "ERROR at $BASH_LINENO:" "$1" "$2" "$3"
  exit -1
}

warning () {
  message -y "WARNING:" "$1" "$2" "$3"
}

pretty_print () {
  if [[ "${VERBOSE}"x != x ]] ; then
    printf "$(tput setaf 2)%-100s\n" "$@" |  tr -s ' '
    tput sgr0
  fi
}

get_func_opts () {
  OPTIND=1
  while getopts "a:A:c:C:D:e:E:h:l:m:p:P:s:S:x:v:V:" opt ; do
    case "${opt}" in
      a) _ldmsd_auth_plugin="${OPTARG}"			;;
      A) _ldmsd_auth_plugin_conf="${OPTARG}"    	;;
      c) _ldmsd_sampler_config_file="${OPTARG}"		;;
      C) _comp_id="${OPTARG}"				;;
      D) _port_metrics_conf_file="${OPTARG}"		;;
      e) _ldmsd_sampler_env_file="${OPTARG}"		;;
      E) _ldmsd_systemd_env_file="${OPTARG}"    	;;
      h) _switch="${OPTARG}"				;;
      l) _ldmsd_log_option="${OPTARG}"  		;;
      m) _ldmsd_mem="${OPTARG}"				;;
      p) _ldmsd_port="${OPTARG}"			;;
      P) _top="${OPTARG}"				;;
      s) _start_file="${OPTARG}"			;;
      S) _ldmsd_systemd_service_file="${OPTARG}"        ;;
      x) _ldmsd_xprt="${OPTARG}"			;;
      v) _ldmsd_verbose="${OPTARG}"			;;
      V) _ldmsd_systemd_service_file_dir="${OPTARG}"	;;
      *)						;;
    esac
  done
  if [[ "${_ldmsd_auth_plugin_conf}" =~ none ]] ; then
    unset _ldmsd_auth_plugin_conf
  fi
  if [[ "${_ldmsd_log_option}" =~ none ]] ; then
    unset _ldmsd_log_option
  fi
}

get_hostname () {
  local _switch=""
  _switch=$(hostname -s)
  echo "$_switch"
}

get_comp_id () {
  local _comp_id=""
  _comp_id=$(hostname -s | sed 's/[a-zA-Z]//g')
  echo "$_comp_id"
}

find_script_dir_top () {
  local _this_script=$1
  local _script_path=$(dirname $(readlink -f ${_this_script}))
  local _top_dir=$(echo ${_script_path} | awk -F'/' '{print $2}')
  echo "${_top_dir}"
}

find_script_dir_bottom () {
  local _this_script=$1
  local _script_path=$(dirname $(readlink -f ${_this_script}))
  local _bottom_dir=$(echo ${_script_path} | awk -F'/' '{print $NF}')
  echo "${_bottom_dir}"
}

gen_port_metrics_conf () {
  get_func_opts "$@"
  command -v dgrportinfo &>/dev/null ||\
    die "dgrportinfo not in \$PATH"
  # Query for unconfigured ports and links using dgrportinfo
  local _conf_ports=$(dgrportinfo | \
                      awk -F':' '/port=running/ { gsub(/p/,""); print $1}' | \
					  awk 'BEGIN {RS=""} {gsub(/\n/,",",$0); print $0}'|sed 's/ //g')
  local _unconf_ports=$(dgrportinfo | \
                        awk -F':' '/port=unconfigured/ { gsub(/p/,""); print $1}' | \
						awk 'BEGIN {RS=""} {gsub(/\n/,",",$0); print $0}'|sed 's/ //g')
  [ -d $(dirname ${_port_metrics_conf_file}) ] || \
	  mkdir -p $(dirname ${_port_metrics_conf_file}) || \
	  die "cannot mkdir at $(dirname ${_port_metrics_conf_file})"
  echo "# Configuration for switch: ${_switch}" > ${_port_metrics_conf_file}
  echo "p=${_conf_ports}" > ${_port_metrics_conf_file}
  echo "#" >> ${_port_metrics_conf_file}
  echo "rfc_3635" >> ${_port_metrics_conf_file}
  inform "Unconfigured Ports are p:${_unconf_ports}"
  inform "Configured Ports are p:${_conf_ports}"
  inform "Port Configuration File Generated at $(readlink -f ${_port_metrics_conf_file})"
  pretty_print "$(cat ${_port_metrics_conf_file})"
}

gen_ldmsd_sampler_conf () {
  get_func_opts "$@"
  local _port_conf_file=""
  cat <<-SAMPCONF >${_ldmsd_sampler_config_file}
load name=slingshot_switch
config name=slingshot_switch producer=${_switch} component_id=${_comp_id} instance=${_switch}/port_metrics conffile=${_port_metrics_conf_file}
start name=slingshot_switch interval=1000000
SAMPCONF
  inform "INFO: Sampler Configuration File Generated at $(readlink -f ${_ldmsd_sampler_config_file})"
  pretty_print "
  $(cat ${_ldmsd_sampler_config_file})"
}

find_lib_dir () {
  _top=$1
  local _libdir=$(find -L ${_top} -name "libldms.so" -exec dirname {} \;)
  [ -d "${_libdir}" ] || die "find_lib_dir failed"
  echo "${_libdir}"
}

find_python_path () {
  _top=$1
  local _python_path=$(find -L ${_top} -type d -name "python*" -exec readlink -f {} \;)
  [ -d "${_python_path}" ] || die "find_python_path failed"
  echo "${_python_path}"
}

find_plugin_path () {
  _top=$1
  local _plugin_path=$(find -L ${_top} -type d -name "ovis-ldms*" -exec readlink -f {} \; | grep -v doc)
  [ -d "${_plugin_path}" ] || die "find_plugin_path failed"
  echo "${_plugin_path}"
}

gen_ldmsd_systemd_env_file () {
  get_func_opts "$@"
  local _libdir=$(find_lib_dir ${_top})
  local _python_path=$(find_python_path ${_top})
  local _plugin_path=$(find_plugin_path ${_top})
  cat <<-LDMSENV>${_ldmsd_systemd_env_file}
LD_LIBRARY_PATH=${_libdir}
PATH=${_top}/sbin:/usr/bin:/usr/sbin:\$PATH
PYTHONPATH=${_python_path}
LDMSD_PLUGIN_LIBPATH=${_plugin_path}
ZAP_LIBPATH=${_plugin_path}

# ldmsd env vars
LDMSD_MAX_CONFIG_STR_LEN=500000
MMALLOC_DISABLE_MM_FREE=0

# Define LDMS transport
LDMSD_XPRT=${_ldmsd_xprt}

# Define LDMS Daemon service port
LDMSD_PORT=${_ldmsd_port}

# Define LDMS maximum memory allocation
LDMSD_MEM=${_ldmsd_mem}

# Define LDMS Daemon verbosity
LDMSD_VERBOSITY=${_ldmsd_verbose}
LDMSENV
  inform "LDMSD Env File Generated at $(readlink -f ${_ldmsd_systemd_env_file})"
  pretty_print "
  $(cat ${_ldmsd_systemd_env_file})"
}

gen_ldmsd_env_file () {
  get_func_opts "$@"
  local _libdir=$(find_lib_dir ${_top})
  local _python_path=$(find_python_path ${_top})
  local _plugin_path=$(find ${_top} -type d -name "ovis-ldms*" -exec readlink -f {} \; | grep -v doc)
  cat <<-ENV>${_ldmsd_sampler_env_file}
export LD_LIBRARY_PATH=${_libdir}:$LD_LIBRARY_PATH
export PATH=${_top}/sbin:${_top}/bin:$PATH
export PYTHONPATH=${_python_path}:$PYTHONPATH
export LDMSD_PLUGIN_LIBPATH=${_plugin_path}
export ZAP_LIBPATH=${_plugin_path}

# ldmsd env vars
export LDMSD_MAX_CONFIG_STR_LEN=500000
export MMALLOC_DISABLE_MM_FREE=0

# Define LDMS transport
export LDMSD_XPRT=${_ldmsd_xprt}

# Define LDMS Daemon service port
export LDMSD_PORT=${_ldmsd_port}

# Define LDMS maximum memory allocation
export LDMSD_MEM=${_ldmsd_mem}

# Define LDMS Daemon verbosity
export LDMSD_VERBOSITY=${_ldmsd_verbose}

# Define log file location (no need if verbosity of QUIET
# Log file control. The default is to log to syslog.
# export LDMSD_LOG_OPTION="${_ldmsd_log_option}"

# Define LDMS Daemon Authentication method
export LDMSD_AUTH_OPTION="${_ldmsd_auth_plugin}"
#if [[ "${_ldmsd_auth_plugin}" =~ ovis ]] && [[ ! -f /etc/ldmsauth.conf ]] && [[ "${_ldmsd_auth_plugin_conf}"x != x ]] ; then export LDMSD_AUTH_OPTION+="${_ldmsd_auth_plugin_conf}" ; else "echo "You need to define the shared secret file location, ensure it is restricted access" ; exit -1"; fi

# LDMS plugin configuration file, see ${_top}/etc/ldms/sampler.conf for an example
export LDMSD_PLUGIN_CONFIG_FILE=${_ldmsd_sampler_config_file}
ENV
  inform "Generated systemd environment file."
  pretty_print "
  $(cat ${_ldmsd_sampler_env_file})"
}

gen_start_file () {
  get_func_opts "$@"
  if [[ "${_ldmsd_log_option}"x != x ]] ; then _ldmsd_log_option=( "-l " ${_ldmsd_log_option} ) ; fi
  if [[ "${_ldmsd_auth_plugin_conf}"x != x ]] ; then _ldmsd_auth_plugin_conf=( "-A" "conf=${_ldmsd_auth_plugin_conf}" ) ; fi
  cat <<-STARTFILE >${_start_file}
#!/bin/bash
source ${top}/etc/ldms/ldmsd.sampler.env
echo "RUNNING: ${_top}/sbin/ldmsd -x ${_ldmsd_xprt}:${_ldmsd_port} -c ${_ldmsd_sampler_config_file} -a ${_ldmsd_auth_plugin} ${_ldmsd_auth_plugin_conf[@]} -v ${_ldmsd_verbose} -m ${_ldmsd_mem} ${_ldmsd_log_option[@]}"
${_top}/sbin/ldmsd -x ${_ldmsd_xprt}:${_ldmsd_port} -c ${_ldmsd_sampler_config_file} -a ${_ldmsd_auth_plugin} ${_ldmsd_auth_plugin_conf[@]}" -v ${_ldmsd_verbose} -m ${_ldmsd_mem} ${_ldmsd_log_option[@]}"
STARTFILE
  chmod +x ${_start_file}
  inform "Generated start script: ${_start_file}"
  pretty_print "
  $(cat ${_start_file})"
}

gen_systemd_service_file () {
  get_func_opts "$@"
  if [[ "${_ldmsd_log_option}"x != x ]] ; then _ldmsd_log_option=( "-l " ${_ldmsd_log_option} ) ; fi
  if [[ "${_ldmsd_auth_plugin_conf}"x != x ]] ; then _ldmsd_auth_plugin_conf=( "-A" "conf=${_ldmsd_auth_plugin_conf}" ) ; fi
  mkdir -p ${_top}/etc/systemd/system
  cat <<-SYSTEMD>${_ldmsd_systemd_service_file}
[Unit]
Description = LDMS Sampler Daemon
Documentation = https://ovis-hpc.readthedocs.io/en/latest/

[Service]
Type = forking
EnvironmentFile = ${_ldmsd_systemd_env_file}
Environment = HOSTNAME=%H
ExecStartPre = /bin/mkdir -p ${_top}/var/run/ldmsd
ExecStart = ${_top}/sbin/ldmsd -x ${_ldmsd_xprt}:${_ldmsd_port} -c ${_ldmsd_sampler_config_file} -a ${_ldmsd_auth_plugin} -v ${_ldmsd_verbose} -m ${_ldmsd_mem} -r ${_top}/var/run/ldmsd/sampler.pid ${_ldmsd_log_option[@]} ${_ldmsd_auth_plugin_conf[@]}
[Install]
WantedBy = default.target
SYSTEMD

  # Create symbolic link to new service file if link doesn't exist
  if [[ -h ${_ldmsd_systemd_service_file_dir}/${_ldmsd_systemd_service_file//*\/} ]] ; then
    inform "${_ldmsd_systemd_service_file_dir}/${_ldmsd_systemd_service_file//*\/} exists and points to $(readlink -f ${_ldmsd_systemd_service_file_dir})"
    unlink "${_ldmsd_systemd_service_file_dir}/${_ldmsd_systemd_service_file//*\/}" || die "cannot remove link at ${_ldmsd_systemd_service_file_dir}/${_ldmsd_systemd_service_File//*\/}"
  elif [[ -f ${_ldmsd_systemd_service_file_dir}/${_ldmsd_systemd_service_file//*\/} ]] ; then
    inform "${_ldmsd_systemd_service_file_dir}/${_ldmsd_systemd_service_file//*\/} is a file"
    rm "${_ldmsd_systemd_service_file_dir}/${_ldmsd_systemd_service_file//*\/}" || die "cannot remove file at ${_ldmsd_systemd_service_file_dir}/${_ldmsd_systemd_service_file//*\/}"
  fi
  inform "Removing ${_ldmsd_systemd_service_file_dir}/${_ldmsd_systemd_service_file//*\/} and placing a symlink to ${_ldmsd_systemd_service_file}"
  pushd ${_ldmsd_systemd_service_file_dir} &>/dev/null
  ln -s ${_ldmsd_systemd_service_file} || die "cannot link to ${_ldmsd_systemd_service_file}"
  popd &>/dev/null
  inform "Generated ${_ldmsd_systemd_service_file}:"
  pretty_print "
  $(cat ${_ldmsd_systemd_service_file})"
  inform "Running \`/usr/bin/systemctl daemon-reload\`"
  /usr/bin/systemctl daemon-reload || die "error running daemon-reload"
}

usage() {
  echo "${0//*\/} Configures LDMS for Slingshot Switches
  usage: ${0//*\/} [options]
    [-a|--auth-plugin]		-- ldmsd authentication plugin; default \"none\".  Chose from: \"none\", \"munge\", \"ovis\". (default: \"none\")
    [-A|--auth-conf]		-- ldmsd authentication file for shared secret when using \"-a ovis\" auth mode;  (default: \"\"; ldmsd defaults to /etc/ldmsauth.conf)
    [-d|--ldmsd-verbose]	-- Set Verbosity of LDMSD Logs chose from: \"DEBUG\", \"INFO\", \"ERROR\", \"CRITICAL\", and \"QUIET\" (default: \"ERROR\")
    [-P|--prefix]		-- Prefix path for OVIS installation (defaults /rwfs/usr)
    [-v|--verbose]		-- enable xtrace output for ${0//*\/}in shell
    [-h|--help]			-- dumps usage and exits
    [-x|--xprt]			-- LDMSD transport (default: sock)
    [-p|--port]			-- LDMSD port (default: 411)
    [-m|--mem]			-- LDMSD mem setting (default: 5M)
    [-l|--log]			-- LDMSD log location (default: none)
    [-S|--systemd-dir]		-- Where to install systemd service files (default: /etc/systemd/system)

  For support email <ldms@sandia.gov>
  Git Repo: https://github.com/jennfshr/docker_ovis_slingshot_switch_build
"
}

for arg in "$@" ; do
  shift
  case "$arg" in
    *-auth-plug**)	set -- "$@" "-a" ;;
    *-auth*conf*)	set -- "$@" "-A" ;;
    *-ldms*ver*)	set -- "$@" "-d" ;;
    *-help*)		set -- "$@" "-h" ;;
    *-ldms*log*)	set -- "$@" "-l" ;;
    *-ldms*mem*)	set -- "$@" "-m" ;;
    *-*port*)		set -- "$@" "-p" ;;
    *-pre*)		set -- "$@" "-P" ;;
    *-systemd*)		set -- "$@" "-S" ;;
    *-verb*)		set -- "$@" "-v" ;;
    *-*xprt*)		set -- "$@" "-x" ;;
    *)			set -- "$@" "$arg" ;;
  esac
done
OPTIND=1
while getopts "a:A:d:hl:m:p:P:S:vx:-" opt ; do
  case "${opt}" in
    a) LDMSD_AUTH_PLUGIN=${OPTARG}		;;
    A) LDMSD_AUTH_PLUGIN_CONF=${OPTARG}		;;
    d) case "${OPTARG}" in
         *ERROR*|*error*) LDMSD_VERBOSE="ERROR" ;;
         *DEBUG*|*debug*) LDMSD_VERBOSE="DEBUG" ;;
         *INFO*|*info*) LDMSD_VERBOSE="INFO"    ;;
         *CRITICAL*|*critical*) LDMSD_VERBOSE="CRITICAL" ;;
         *QUIET*|*quiet*) LDMSD_VERBOSE="QUIET" ;;
         *) usage && die "LDMSD_VERBOSE=$LDMSD_VERBOSE is not supported"
         ;;
       esac
       ;;
    h) usage && exit 0				;;
    l) LDMSD_LOG_OPTION="${OPTARG}"		;;
    m) LDMSD_MEM="${OPTARG}"			;;
    p) LDMSD_PORT="${OPTARG}"			;;
    P) TOP="${OPTARG}"				;;
    S) SYSTEMD_SERVICE_FILE_DIR="${OPTARG}"	;;
    v) set -x; set VERBOSE="true"		;;
    x) LDMSD_XPRT="${OPTARG}"			;;
  esac
done

SWITCH=$(get_hostname)
inform "SWITCH: $SWITCH"
COMPONENT_ID=$(get_comp_id)
inform "COMPONENT_ID: ${COMPONENT_ID}"
first_dir=$(find_script_dir_top $0)
inform "first_dir: ${first_dir}"
last_dir=$(find_script_dir_bottom $0)
inform "last_dir: ${last_dir}"
TOP=${TOP:=/rwfs/OVIS-slingshot}
inform "TOP: $TOP"
PORT_METRICS_CONF_FILE="${TOP}/etc/ldms/${SWITCH}_port_metrics.conf"
inform "PORT_METRICS_CONF_FILE: ${PORT_METRICS_CONF_FILE}"
LDMSD_SAMPLER_CONFIG_FILE="${TOP}/etc/ldms/sampler_slingshot_switch.conf"
inform "LDMSD_SAMPLER_CONFIG_FILE: $LDMSD_SAMPLER_CONFIG_FILE"
LDMSD_SYSTEMD_ENV_FILE="${TOP}/etc/ldms/ldmsd.sampler.systemd.env"
inform "LDMSD_SYSTEMD_ENV_FILE: ${LDMSD_SYSTEMD_ENV_FILE}"
LDMSD_SAMPLER_ENV_FILE="${TOP}/etc/ldms/ldmsd.sampler.env"
inform "LDMSD_SAMPLER_ENV_FILE: ${LDMSD_SAMPLER_ENV_FILE}"
START_FILE="${TOP}/etc/ldms/start_slingshot_ldms_sampler.sh"
inform "START_FILE: ${START_FILE}"
LDMSD_SYSTEMD_SERVICE_FILE="${TOP}/etc/systemd/system/ldmsd.sampler.service"
inform "LDMSD_SYSTEMD_SERVICE_FILE: ${LDMSD_SYSTEMD_SERVICE_FILE}"
LDMSD_SYSTEMD_SERVICE_FILE_DIR=${LDMSD_SYSTEMD_SERVICE_FILE_DIR:=/etc/systemd/system}
inform "LDMSD_SYSTEMD_SERVICE_FILE_DIR=${LDMSD_SYSTEMD_SERVICE_FILE_DIR}"
LDMSD_PORT=${LDMSD_PORT:=411}
inform "LDMSD_PORT: $LDMSD_PORT"
LDMSD_XPRT=${LDMSD_XPRT:=sock}
inform "LDMSD_XPRT: $LDMSD_XPRT"
LDMSD_MEM=${LDMSD_MEM:=5M}
inform "LDMSD_MEM: $LDMSD_MEM"
LDMSD_LOG_OPTION=${LDMSD_LOG_OPTION:=none}
inform "LDMSD_LOG_OPTION: ${LDMSD_LOG_OPTION}"
LDMSD_VERBOSE=${LDMSD_VERBOSE:=QUIET}
inform "LDMSD_VERBOSE: $LDMSD_VERBOSE"
LDMSD_AUTH_PLUGIN=${LDMSD_AUTH_PLUGIN:=none}
inform "LDMSD_AUTH_PLUGIN: $LDMSD_AUTH_PLUGIN"
LDMSD_AUTH_PLUGIN_CONF=${LDMSD_AUTH_PLUGIN_CONF:=none}
inform "LDMSD_AUTH_PLUGIN_CONF: $LDMSD_AUTH_PLUGIN_CONF"

func_opts=(
"-A" "${LDMSD_AUTH_PLUGIN_CONF}"
"-a" "${LDMSD_AUTH_PLUGIN}"
"-C" "${COMPONENT_ID}"
"-c" "${LDMSD_SAMPLER_CONFIG_FILE}"
"-D" "${PORT_METRICS_CONF_FILE}"
"-e" "${LDMSD_SAMPLER_ENV_FILE}"
"-E" "${LDMSD_SYSTEMD_ENV_FILE}"
"-h" "${SWITCH}"
"-l" "${LDMSD_LOG_OPTION}"
"-m" "${LDMSD_MEM}"
"-p" "${LDMSD_PORT}"
"-P" "${TOP}"
"-S" "${LDMSD_SYSTEMD_SERVICE_FILE}"
"-s" "${START_FILE}"
"-V" "${LDMSD_SYSTEMD_SERVICE_FILE_DIR}"
"-v" "${LDMSD_VERBOSE}"
"-x" "${LDMSD_XPRT}"
)

# Run gen_port_metrics_conf
pretty_print "
gen_port_metrics_conf "${func_opts[@]}"
"
gen_port_metrics_conf "${func_opts[@]}"

# Generate LDMSD Sampler Configuration File
inform "Generating ldmsd_sampler_config at ${LDMSD_SAMPLER_CONFIG_FILE}"
pretty_print "
gen_ldmsd_sampler_conf "${func_opts[@]}"
"
gen_ldmsd_sampler_conf "${func_opts[@]}"

# Generate the environment file sourced by the systemd service file
inform "Generating ldmsd systemd environment file at ${LDMSD_SYSTEMD_ENV_FILE}"
pretty_print "
gen_ldmsd_systemd_env_file "${func_opts[@]}"
"
gen_ldmsd_systemd_env_file "${func_opts[@]}"

# Generate the LDMS Sampler Environment file
# used to start ldmsd sampler manually
inform "Generating LDMSD Sampler environment file at ${LDMSD_SAMPLER_ENV_FILE}"
pretty_print "
gen_ldmsd_env_file "${func_opts[@]}"
"
gen_ldmsd_env_file "${func_opts[@]}"

# Generate the LDMS Sampler startup script
# that can be used to manually start the daemon
inform "Generating start script at ${START_FILE}"
pretty_print "
gen_start_file "${func_opts[@]}"
"
gen_start_file "${func_opts[@]}"

# Generate a systemd service file to run
# LDMSD as a service daemon
inform "Generating a systemd service file at ${LDMSD_SYSTEMD_SERVICE_FILE}."
pretty_print "
gen_systemd_service_file "${func_opts[@]}"
"
gen_systemd_service_file "${func_opts[@]}"

# Print out a final statement on how to start via systemd
# and how to interact with it via ldms_ls command
inform "LDMS is now configured to run on ${SWITCH}."
inform "LDMS is installed at ${TOP}."
inform "Start/Stop/Status service: \"systemctl {start,stop,status} ldmsd.sampler\""
inform "To verify that the sampler is collecting:"
inform "\`source ${LDMSD_SAMPLER_ENV_FILE}\`"
inform "\`ldms_ls -h localhost -x ${LDMSD_XPRT} -p ${LDMSD_PORT} -l\`"
