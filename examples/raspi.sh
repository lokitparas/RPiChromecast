#!/bin/bash
# simple YouTube TV for Raspberry Pi
# kills any currently playing video as soon as a new video is queued
# needs youtube-dl and omxplayer
export SCREEN_ID="f0d6h2hnjp2c876sl74538cvue"
export SCREEN_NAME="Raspberry Pi"
export SCREEN_APP="pitubecast-v1"
export OMX_OPTS="-o hdmi -b "
export YTDL_OPTS="-f mp4"
export PLAYER1="org.mpris.MediaPlayer2.omxplayer"
export PLAYER2="org.one.two.omxplayer"
export CURR_PLAYER=$PLAYER1


function omxdbus {
    OMXPLAYER_DBUS_ADDR="/tmp/omxplayerdbus.${USER:-root}"
    OMXPLAYER_DBUS_PID="/tmp/omxplayerdbus.${USER:-root}.pid"
    export DBUS_SESSION_BUS_ADDRESS=`cat $OMXPLAYER_DBUS_ADDR`
    export DBUS_SESSION_BUS_PID=`cat $OMXPLAYER_DBUS_PID`
    dbus-send --print-reply=literal --session --reply-timeout=100 --dest=$CURR_PLAYER /org/mpris/MediaPlayer2 $* >/dev/null 2>/dev/null
}

gotubecast -s "$SCREEN_ID" -n "$SCREEN_NAME" -i "$SCREEN_APP" | while read line
do
    cmd="`cut -d ' ' -f1 <<< "$line"`"
    arg="`cut -d ' ' -f2 <<< "$line"`"
    case "$cmd" in
        pairing_code)
            echo "Your pairing code: $arg"
            ;;
        remote_join)
            cut -d ' ' -f3- <<< "$line connected"
            ;;
        video_id)
			pid="`pgrep omxplayer.bin`"
			if [ "$CURR_PLAYER" == "$PLAYER1" ]; then
				CURR_PLAYER=$PLAYER2
			else
				CURR_PLAYER=$PLAYER1
			fi
			omxplayer --dbus_name $CURR_PLAYER $OMX_OPTS "$arg" </dev/null 2>/dev/null &
			sleep 0.5
			kill -9 $pid >/dev/null 2>/dev/null
            ;;
        play | pause)
            omxdbus org.mpris.MediaPlayer2.Player.PlayPause
            ;;
        stop)
            omxdbus org.mpris.MediaPlayer2.Player.Stop
            ;;
        seek_to)
            omxdbus org.mpris.MediaPlayer2.Player.SetPosition objpath:/not/used int64:${arg}000000
            ;;
        set_volume)
            vol="1.0"
            if [ $arg -lt 100 ]; then
                vol="0.$arg"
            fi
            omxdbus org.freedesktop.DBus.Properties.Set string:"org.mpris.MediaPlayer2.Player" string:"Volume" double:$vol
            ;;
    esac
done
