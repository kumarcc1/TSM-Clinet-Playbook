#!/bin/sh
### BEGIN INIT INFO
# Provides: tsmsched
# Required-Start: $syslog $local_fs
# Required-Stop: $syslog $local_fs
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: The TSM scheduler
# Description: The TSM scheduler
### END INIT INFO

# Source function library
. /etc/init.d/functions

DAEMON="/opt/tivoli/tsm/client/ba/bin/dsmc"
OPTIONS="schedule"
prog=tsmsched

is_running() {
    if pgrep -xf "$DAEMON $OPTIONS" >/dev/null; then
        return 0
    fi
    return 1
}

start() {
    if is_running; then
        RETVAL=0
        return 0
    fi
    echo -n $"Starting $prog: "
    nohup $DAEMON $OPTIONS >/dev/null 2>&1 &
    #daemon $DAEMON $OPTIONS
    RETVAL=$?
    [ $RETVAL -eq 0 ] && success || failure
    return 0
}

stop() {
    if ! is_running; then
        RETVAL=0
        return 0
    fi
    echo -n $"Stopping $prog: "
    killproc $DAEMON
    RETVAL=$?
    [ $RETVAL -eq 0 ] && success || failure
    return 0
}

restart() {
    stop
    start
}

# See how we were called.
case $1 in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status $DAEMON
        RETVAL=$?
        ;;
    *)
        echo $"Usage: $prog {start|stop|restart|status}"
        exit 2
esac

exit $RETVAL
