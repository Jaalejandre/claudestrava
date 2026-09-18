from mcp.server.fastmcp import FastMCP
import sqlite3

mcp = FastMCP("KanbanAdapter")
DB_PATH = "/root/.hermes/kanban.db"

@mcp.tool()
def get_tasks():
    """Obtiene todas las tareas activas del Kanban"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    tasks = conn.execute("SELECT id, title, status FROM tasks WHERE status != 'done'").fetchall()
    return [dict(t) for t in tasks]

@mcp.tool()
def move_task(task_id: str, new_status: str):
    """Mueve una tarea a un nuevo estado"""
    conn = sqlite3.connect(DB_PATH)
    conn.execute("UPDATE tasks SET status = ? WHERE id = ?", (new_status, task_id))
    conn.commit()
    return f"Tarea {task_id} movida a {new_status}"

if __name__ == "__main__":
    import asyncio
    from mcp.server.stdio import stdio_server
    asyncio.run(mcp.run())
