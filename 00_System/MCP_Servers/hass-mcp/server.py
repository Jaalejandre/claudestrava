from mcp.server.fastmcp import FastMCP
import httpx
import os

mcp = FastMCP("HassAdapter")
HASS_URL = "http://192.168.0.103:8123"
TOKEN_PATH = "/root/.ha_token"

def get_headers():
    with open(TOKEN_PATH, "r") as f:
        token = f.read().strip()
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

@mcp.tool()
def get_entity_state(entity_id: str):
    """Consulta el estado de una entidad"""
    url = f"{HASS_URL}/api/states/{entity_id}"
    with httpx.Client() as client:
        return client.get(url, headers=get_headers()).json()

@mcp.tool()
def call_service(domain: str, service: str, entity_id: str):
    """Ejecuta un servicio de Home Assistant (ej: light.turn_on)"""
    url = f"{HASS_URL}/api/services/{domain}/{service}"
    payload = {"entity_id": entity_id}
    with httpx.Client() as client:
        return client.post(url, headers=get_headers(), json=payload).json()

if __name__ == "__main__":
    import asyncio
    asyncio.run(mcp.run())
