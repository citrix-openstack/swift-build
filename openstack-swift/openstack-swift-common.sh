. /etc/rc.d/init.d/functions

lockfile="/var/lock/subsys/openstack-swift-$name"

[ -e "/etc/sysconfig/openstack-swift-$name" ] && \
   . "/etc/sysconfig/openstack-swift-$name"

export PYTHON_EGG_CACHE=/tmp/swift/PYTHON_EGG_CACHE

swift_init() {
  local name="$1"
  local action="$2"

  local actstring
  if [ "$action" = "start" ]
  then
    actstring="Starting"
  else
    actstring="Stopping"
  fi

  echo -n "$actstring $name: "
  swift-init "$name" "$action" >/dev/null
  retval=$?
  [ $retval -eq 0 ] && success || failure
  echo
  return $retval
}

start_() {
    swift_init "$name-server" start
}

start() {
    start_
    retval=$?
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}

stop_() {
    swift_init "$name-server" stop
}

stop() {
    stop_
    retval=$?
    rm -f $lockfile
    return $retval
}

restart() {
    stop
    start
}

rh_status() {
    status -p "/var/run/swift/$name-server.pid" "$name-server" status
}

rh_status_q() {
    rh_status &> /dev/null
}

handle_args() {
    case "$1" in
        start)
            rh_status_q && exit 0
            $1
            ;;
        stop)
            rh_status_q || exit 0
            $1
            ;;
        restart)
            $1
            ;;
        reload)
            ;;
        status)
            rh_status
            ;;
        condrestart|try-restart)
            rh_status_q || exit 0
            restart
            ;;
        *)
            echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart}"
            exit 2
    esac
    exit $?
}
