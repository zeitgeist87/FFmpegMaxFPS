#!/bin/bash

LOGDIR="/tmp/ffmpeg_maxfps/logs"
TEMPDIR="/tmp/ffmpeg_maxfps/temp"

export LC_NUMERIC="C"

usage() {
	echo -e "Usage: $0 [-L <LOGDIR>] [-T <TEMPDIR>]\n\t[run|stresstest|printfps] COMMAND" 1>&2
	exit 1
}

unbuf() {
	stdbuf -i0 -o0 -e0 "$@"
}

run() {
	unbuf "$@" 2>&1 | unbuf tr '\r' '\n' | unbuf sed -n 's/frame=\s*\([0-9]\+\)\s\+fps=\s*\([0-9\.]\+\)\s\+.*/\1 \2/p'
}

clear_logs() {
	rm -rf "$LOGDIR"/*
}

clear_temp() {
	rm -rf "$TEMPDIR"/*
}

killall_procs() {
	killall -9 $1 2>/dev/null
	ls "$LOGDIR/" 2>/dev/null | xargs -n 1 kill -9 2>/dev/null
}

start_proc() {
	mkdir -p "$LOGDIR"
    mkdir -p "$TEMPDIR/tmp/$BASHPID/"
    
    OLDDIR="$(pwd)"
    cd "$TEMPDIR/tmp/$BASHPID/"
    
	run "$@" | while read result
	do 
		echo "$result" > "$LOGDIR/$BASHPID"
		result=($result)
		frame=${result[0]}
		fps=${result[1]}

		echo -n -e "frame = $frame, fps = $fps\r"
	done

    cd "$OLDDIR"
	rm -f "$LOGDIR/$BASHPID"
	rm -rf "$TEMPDIR/tmp/$BASHPID/"
}

aggregate_fps() {
	cat "$LOGDIR"/* 2>/dev/null | cut -d ' ' -f 2 | awk '{sum += $1} END {print sum;}' | xargs printf "%.0f\n"
}

perform_stress_test() {
	killall_procs $COMMAND
	sleep 2
	clear_logs

	mkdir -p "$TEMPDIR"
	mkdir -p "$LOGDIR"

	echo "Performing stress test"

	fps=0
	prev_fps=0
	count=0
	while [ $prev_fps -le $fps ]; do
		count=$((count + 1))
		echo "Starting process $count"
		( start_proc $COMMAND ) 2>/dev/null 1>/dev/null &
		
		sleep 2
		
		prev_fps=$fps
		fps=$( aggregate_fps )
		echo "Total FPS=$fps"
		clear_logs
	done

	if [ $count -gt 0 ]; then
		count=$((count - 1))
	fi

	echo "The ideal # of processes is: $count"

	sleep 3
	killall_procs $COMMAND
	sleep 2
	clear_logs
	clear_temp
}

while getopts "hL:T:" o; do
	case "${o}" in
		h)
			usage
			;;
		L)
			LOGDIR=${OPTARG}
			;;
		T)
			TEMPDIR=${OPTARG}
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

OPERATION=$1
shift
COMMAND="$@"

if [ -z "$COMMAND" ]; then
	usage
fi

case "$OPERATION" in
	run)
		start_proc $COMMAND
		;;
	stresstest)
		perform_stress_test
		;;
	printfps)
		aggregate_fps
		;;
	*)
		usage
		;;
esac
