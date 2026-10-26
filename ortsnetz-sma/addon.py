#!/usr/bin/env python3
"""
Home Assistant wrapper for ortsnetz-sma-shm2.py: runs the upstream script
unchanged and adds optional API fields to every payload: grid power from the
same EMETER telegrams, static site data from the add-on options and values
from Home Assistant entities.
"""

import importlib.util
import json
import os
import sys
import urllib.request

SCRIPT = "/app/ortsnetz-sma-shm2.py"
OPTIONS = "/data/options.json"
HA_API = os.environ.get("ORTSNETZ_HA_API", "http://supervisor/core/api")
ENERGY_TO_KWH = {"Wh": 0.001, "kWh": 1.0, "MWh": 1000.0}

# OBIS indices of the total active power in the EMETER telegram, in 0.1 W
OBIS_POWER_IMPORT = 1
OBIS_POWER_EXPORT = 2

spec = importlib.util.spec_from_file_location("ortsnetz_sma", SCRIPT)
upstream = importlib.util.module_from_spec(spec)
spec.loader.exec_module(upstream)

try:
    with open(OPTIONS) as f:
        options = json.load(f)
except (OSError, ValueError):
    options = {}

plant_capacity_kwp = options.get("plant_capacity_kwp")
battery_capacity_kwh = options.get("battery_capacity_kwh")
battery_soc_entity = options.get("battery_soc_entity")
pv_forecast_entity = options.get("pv_forecast_entity")
send_grid_power = options.get("send_grid_power", True)

# Static site data only has to be sent once after start (API.md).
static_sent = False
warned = set()

# Grid power samples per meter serial since the last payload, and the serial
# of the meter the current measurement comes from.
power_samples = {}
last_serial = None


def warn_once(msg):
    if msg not in warned:
        warned.add(msg)
        upstream.log(msg)


def ha_state(entity_id):
    """Returns (value, unit) of a numeric entity, or None if unavailable."""
    request = urllib.request.Request(
        f"{HA_API}/states/{entity_id}",
        headers={"Authorization": f"Bearer {os.environ.get('SUPERVISOR_TOKEN', '')}"},
    )
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            state = json.load(response)
        value = float(state["state"])
    except (OSError, ValueError, KeyError, TypeError):
        warn_once(f"Entität {entity_id} ist nicht verfügbar oder nicht numerisch.")
        return None
    if value != value or value in (float("inf"), float("-inf")):
        return None
    return value, state.get("attributes", {}).get("unit_of_measurement")


def battery_soc():
    state = ha_state(battery_soc_entity)
    if state is None:
        return None
    value, _ = state
    if not 0 <= value <= 100:
        warn_once(f"Ladezustand {value} aus {battery_soc_entity} liegt nicht zwischen 0 und 100.")
        return None
    return round(value, 1)


def pv_forecast():
    if plant_capacity_kwp is None:
        warn_once("PV-Prognose wird nur mit gesetzter Anlagengröße (plant_capacity_kwp) gesendet.")
        return None
    state = ha_state(pv_forecast_entity)
    if state is None:
        return None
    value, unit = state
    if unit not in ENERGY_TO_KWH:
        warn_once(f"Einheit '{unit}' von {pv_forecast_entity} wird nicht unterstützt (Wh, kWh, MWh).")
        return None
    kwh = value * ENERGY_TO_KWH[unit]
    if not 0 <= kwh <= 10 * plant_capacity_kwp:
        warn_once(f"PV-Prognose {kwh} kWh liegt nicht zwischen 0 und 10 kWh je kWp.")
        return None
    return round(kwh, 3)


def decode_power(data):
    """Returns (serial, grid power in W) of an EMETER telegram, or None.

    Same validation as upstream telegramm_dekodieren, which drops the power values.
    """
    if len(data) < 32 or data[:8] != b"SMA\x00\x00\x04\x02\xa0":
        return None
    end = 16 + int.from_bytes(data[12:14], "big")
    if (end < 28 or end + 4 != len(data) or data[end:] != b"\x00" * 4
            or data[14:16] != b"\x00\x10"
            or int.from_bytes(data[16:18], "big") != upstream.EMETER_PROTOCOL_ID):
        return None

    values = {}
    pos = 28
    while pos < end:
        if pos + 4 > end:
            return None
        channel, index, kind, tariff = data[pos:pos + 4]
        if data[pos:pos + 4] == b"\x90\x00\x00\x00":  # 144:0.0.0, software version
            length = 8
        elif kind in (4, 8):
            length = 4 + kind
        else:
            return None
        if pos + length > end:
            return None
        if channel == 0 and tariff == 0 and kind == 4 and index in (OBIS_POWER_IMPORT, OBIS_POWER_EXPORT):
            values[index] = int.from_bytes(data[pos + 4:pos + 8], "big")
        pos += length
    if len(values) != 2:
        return None
    serial = int.from_bytes(data[20:24], "big")
    return serial, (values[OBIS_POWER_IMPORT] - values[OBIS_POWER_EXPORT]) / 10


class PowerSocket:
    """Socket wrapper that collects the grid power of every received telegram,
    including those upstream drains unread between two uploads."""

    def __init__(self, sock):
        self._sock = sock

    def __getattr__(self, name):
        return getattr(self._sock, name)

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return self._sock.__exit__(*exc)

    def recvfrom(self, *args):
        data, address = self._sock.recvfrom(*args)
        power = decode_power(data)
        if power is not None:
            serial, watts = power
            power_samples.setdefault(serial, []).append(watts)
        return data, address


def grid_power():
    """Average grid power of the measured meter since the last payload."""
    samples = power_samples.get(last_serial)
    power_samples.clear()
    if not samples:
        return None
    return round(sum(samples) / len(samples), 1)


original_socket = upstream.multicast_socket
original_receive = upstream.messung_empfangen
original_payload = upstream.payload_erstellen
original_send = upstream.senden


def multicast_socket():
    return PowerSocket(original_socket())


def messung_empfangen(sock):
    global last_serial
    result = original_receive(sock)
    if result is not None:
        last_serial = result[0]
    return result



def payload_erstellen(werte):
    payload = original_payload(werte)
    if send_grid_power:
        value = grid_power()
        if value is not None:
            payload["grid_power_w"] = value
    if not static_sent:
        if plant_capacity_kwp is not None:
            payload["plant_capacity_kwp"] = plant_capacity_kwp
        if battery_capacity_kwh is not None:
            payload["battery_capacity"] = battery_capacity_kwh
    for key, entity, read in (("battery_soc_percent", battery_soc_entity, battery_soc),
                              ("pv_forecast_kwh", pv_forecast_entity, pv_forecast)):
        if entity:
            value = read()
            if value is not None:
                payload[key] = value
    return payload


def senden(payload):
    global static_sent
    ok = original_send(payload)
    if ok:
        static_sent = True
    return ok


if send_grid_power:
    upstream.multicast_socket = multicast_socket
    upstream.messung_empfangen = messung_empfangen
upstream.payload_erstellen = payload_erstellen
upstream.senden = senden

if __name__ == "__main__":
    raise SystemExit(upstream.main(sys.argv[1:]))
