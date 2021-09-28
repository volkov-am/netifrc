# Copyright (c) 2016 Joakim Sindholt (zhasha)
# Copyright (c) 2018 Jason A. Donenfeld,
# Released under the 2-clause BSD license.
# shellcheck shell=sh disable=SC1008

wireguard_depend()
{
	program ip /usr/bin/wg
	after interface
}

_is_wireguard() {
	is_interface_type wireguard
}

wireguard_pre_start()
{
	local wireguard=
	eval wireguard=\$type_${IFVAR}
	[ "${wireguard}" = "wireguard" -o "${IFACE#wg}" != "$IFACE" ] || return 0

	ip link delete dev "$IFACE" type wireguard 2>/dev/null
	ebegin "Creating WireGuard interface $IFACE"
	if ! ip link add dev "$IFACE" type wireguard; then
		e=$?
		eend $e
		return $e
	fi
	eend 0

	ebegin "Configuring WireGuard interface $IFACE"
	set -- $(_get_array "wireguard_$IFVAR")
	if [ $# -eq 1 ]; then
		/usr/bin/wg setconf "$IFACE" "$1"
	else
		eval /usr/bin/wg set "$IFACE" "$@"
	fi
	e=$?
	if [ $e -eq 0 ]; then
		_up
		e=$?
		if [ $e -eq 0 ]; then
			eend $e
			set_interface_type wireguard
			return $e
		fi
	fi
	ip link delete dev "$IFACE" type wireguard 2>/dev/null
	eend $e
	return $e
}

wireguard_post_stop()
{
	_is_wireguard || [ "${IFACE#wg}" != "$IFACE" ] || return 0

	ebegin "Removing WireGuard interface $IFACE"
	ip link delete dev "$IFACE" type wireguard
	e=$?
	eend $e
	return $e
}
