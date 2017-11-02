#/bin/bash

if [ -e /etc/friendlyarm-ts-input.conf ] ; then
	. /etc/friendlyarm-ts-input.conf
fi
true	${TSLIB_TSDEVICE:=/dev/touchscreen}

CTP=0

ONE_WIRE_PROC=/proc/driver/one-wire-info
if [ -e $ONE_WIRE_PROC ] ; then
	if read lcd_type fw_ver ts_cnt tail < $ONE_WIRE_PROC ; then
		if [ $ts_cnt -lt 100 ]; then
			CTP=1
		fi
	fi
fi

if grep -Ei "\<ctp=(1|2|3)\>" /proc/cmdline >/dev/null; then
	CTP=1
fi

echo "ctp = $CTP"

if [ $CTP = "1" ]; then
	TSLIB_CONFFILE=/etc/ts-mt.conf
	echo "-27 13757 -2071768 -9105 -32 34531248 65536 800 480" \
		>/etc/pointercal
	sync
else
	TSLIB_CONFFILE=/etc/ts.conf
fi

export TSLIB_TSDEVICE
export TSLIB_CONFFILE

export TSLIB_PLUGINDIR=/usr/lib/ts
export TSLIB_CALIBFILE=/etc/pointercal


if [ -d /usr/local/Trolltech/QtEmbedded-5.9.1-arm ]; then
	export QTDIR=/usr/local/Trolltech/QtEmbedded-5.9.1-arm
elif [ -d /usr/local/Trolltech/QtEmbedded-5.9.1-arch64 ]; then
	export QTDIR=/usr/local/Trolltech/QtEmbedded-5.9.1-arch64
else
	echo "Not found Qt5."
	exit 1
fi

export QT_QPA_FONTDIR=$QTDIR/lib/fonts
export QT_QPA_PLATFORM_PLUGIN_PATH=$QTDIR/plugins/
export LD_LIBRARY_PATH=$QTDIR/lib:$LD_LIBRARY_PATH
export QT_QPA_PLATFORM=linuxfb:fb=/dev/fb0
export QT_QPA_PLATFORM=linuxfb:fb=/dev/fb0
if [ -e /dev/fb-st7789s ]; then
        # for Matrix-2.8 SPI TFT
        export QT_QPA_PLATFORM=linuxfb:fb=/dev/fb-st7789s
fi

if [ -c ${TSLIB_TSDEVICE} ]; then
	if [ ! -s /etc/pointercal ] ; then
		rm -f /etc/pointercal
		/usr/bin/ts_calibrate
	fi
	export QT_QPA_GENERIC_PLUGINS=tslib,evdevkeyboard
else
	export QT_QPA_GENERIC_PLUGINS=evdevmouse,evdevkeyboard
fi

