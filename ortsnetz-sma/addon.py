#!/usr/bin/env python3
"""
Home Assistant wrapper for ortsnetz-sma-shm2.py: runs the upstream script
unchanged and adds optional API fields from the add-on options and from
Home Assistant entities to every payload.
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

# Static site data only has to be sent once after start (API.md).
static_sent = False
warned = set()


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


original_payload = upstream.payload_erstellen
original_send = upstream.senden


def payload_erstellen(werte):
    payload = original_payload(werte)
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


upstream.payload_erstellen = payload_erstellen
upstream.senden = senden

if __name__ == "__main__":
    raise SystemExit(upstream.main(sys.argv[1:]))
