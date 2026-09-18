from mcp.server.fastmcp import FastMCP
import subprocess

mcp = FastMCP("NetKeeper")

@mcp.tool()
def map_network():
    """Mapea dispositivos actuales usando arp-scan"""
    # Requires arp-scan installed in CT
    result = subprocess.run(["arp-scan", "--localnet"], capture_output=True, text=True)
    return result.stdout

@mcp.tool()
def check_dhcp_status():
    """Verifica el estado del DHCP (vía PVE host)"""
    # Placeholder for logic
    return "DHCP Service: Active | Range: 192.168.0.100-200"

if __name__ == "__main__":
    import asyncio
    asyncio.run(mcp.run())
