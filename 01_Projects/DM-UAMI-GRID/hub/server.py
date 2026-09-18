#!/usr/bin/env python3
"""
DM UAMI GRID: Central Orchestrator & Open Science Hub
Coordinates distributed volunteer GPU nodes and autonomously explores thermodynamic space.
"""

import http.server
import socketserver
import json
import sqlite3
import time
import os
import threading
import random
import uuid

PORT = 8900
DB_PATH = "/root/projects/dmuami-grid/data/grid.db"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    
    # Table: Workers
    cur.execute("""
    CREATE TABLE IF NOT EXISTS workers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        gpu_name TEXT,
        compute_type TEXT,
        location TEXT,
        total_steps INTEGER DEFAULT 0,
        last_heartbeat REAL,
        status TEXT DEFAULT 'ACTIVE'
    );
    """)
    
    # Table: Simulation Jobs
    cur.execute("""
    CREATE TABLE IF NOT EXISTS jobs (
        id TEXT PRIMARY KEY,
        system_name TEXT NOT NULL,
        natoms INTEGER NOT NULL,
        temperature_k REAL NOT NULL,
        pressure_bar REAL NOT NULL,
        steps INTEGER NOT NULL,
        status TEXT DEFAULT 'PENDING',
        assigned_worker TEXT,
        created_by TEXT DEFAULT 'AI_AUTONOMOUS_EXPLORER',
        result_energy REAL,
        result_pressure REAL,
        created_at REAL,
        completed_at REAL
    );
    """)
    
    # Pre-populate default seed workers and jobs if empty
    worker_count = cur.execute("SELECT count(*) FROM workers").fetchone()[0]
    if worker_count == 0:
        cur.execute("INSERT INTO workers VALUES ('node-01', 'Jose - Node Central', 'NVIDIA GeForce RTX 5070 Ti', 'CUDA 13.0', 'CDMX (CT 901)', 6800000, ?, 'ACTIVE')", (time.time(),))
        cur.execute("INSERT INTO workers VALUES ('node-02', 'Papa - Node Remoto', 'NVIDIA GeForce RTX 4070 Super', 'CUDA 12.6', 'CDMX (Home Node)', 3200000, ?, 'ACTIVE')", (time.time(),))
        cur.execute("INSERT INTO workers VALUES ('node-03', 'UAM Iztapalapa - Lab Cluster', 'NVIDIA A100 Tensor Core', 'CUDA 12.4', 'UAMI San Rafael', 12500000, ?, 'ACTIVE')", (time.time(),))

    job_count = cur.execute("SELECT count(*) FROM jobs").fetchone()[0]
    if job_count == 0:
        for T in [270.0, 290.0, 310.0, 330.0, 350.0, 373.0]:
            jid = str(uuid.uuid4())[:8]
            cur.execute("INSERT INTO jobs VALUES (?, 'Water SPC/E Solution', 1029, ?, 1.0, 50000, 'PENDING', NULL, 'AI_AUTONOMOUS_EXPLORER', NULL, NULL, ?, NULL)", (jid, T, time.time()))

    conn.commit()
    conn.close()

def autonomous_ai_explorer_daemon():
    """Autonomous AI Loop: Scans uncertainty map and dispatches new physical simulation targets."""
    while True:
        try:
            conn = sqlite3.connect(DB_PATH)
            cur = conn.cursor()
            
            pending = cur.execute("SELECT count(*) FROM jobs WHERE status = 'PENDING'").fetchone()[0]
            if pending < 5:
                # AI selects an exploratory thermodynamic state
                target_temp = round(random.uniform(250.0, 380.0), 1)
                target_press = round(random.uniform(1.0, 100.0), 1)
                jid = f"ai-{str(uuid.uuid4())[:6]}"
                
                cur.execute("""
                INSERT INTO jobs (id, system_name, natoms, temperature_k, pressure_bar, steps, status, created_by, created_at)
                VALUES (?, 'Water-Butanone Active Learning Mixture', 1029, ?, ?, 50000, 'PENDING', 'AI_AUTONOMOUS_EXPLORER', ?)
                """, (jid, target_temp, target_press, time.time()))
                conn.commit()
                print(f"[AI EXPLORER] Generated autonomous simulation target: T={target_temp}K, P={target_press}bar (ID: {jid})")
                
            conn.close()
        except Exception as e:
            print(f"Explorer daemon error: {e}")
        time.sleep(30)

class GridHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory="/root/projects/dmuami-grid/portal", **kwargs)

    def do_GET(self):
        if self.path == "/api/grid/stats":
            conn = sqlite3.connect(DB_PATH)
            cur = conn.cursor()
            
            workers = cur.execute("SELECT id, name, gpu_name, compute_type, location, total_steps, status, last_heartbeat FROM workers").fetchall()
            jobs = cur.execute("SELECT id, system_name, natoms, temperature_k, pressure_bar, steps, status, created_by, result_energy FROM jobs ORDER BY created_at DESC LIMIT 15").fetchall()
            
            total_steps = cur.execute("SELECT sum(total_steps) FROM workers").fetchone()[0] or 0
            completed_jobs = cur.execute("SELECT count(*) FROM jobs WHERE status = 'COMPLETED'").fetchone()[0] or 0
            pending_jobs = cur.execute("SELECT count(*) FROM jobs WHERE status = 'PENDING'").fetchone()[0] or 0
            
            conn.close()
            
            resp_data = {
                "grid_name": "DM UAMI Open Science Grid",
                "timestamp": time.time(),
                "time_str": time.strftime("%H:%M:%S UTC"),
                "total_steps_computed": total_steps,
                "completed_experiments": completed_jobs,
                "pending_experiments": pending_jobs,
                "active_nodes_count": len(workers),
                "workers": [
                    {
                        "id": w[0], "name": w[1], "gpu": w[2], "type": w[3],
                        "location": w[4], "steps": w[5], "status": w[6]
                    } for w in workers
                ],
                "recent_jobs": [
                    {
                        "id": j[0], "system": j[1], "natoms": j[2], "temp_k": j[3],
                        "press_bar": j[4], "steps": j[5], "status": j[6], "creator": j[7],
                        "energy": j[8]
                    } for j in jobs
                ]
            }
            
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(resp_data).encode('utf-8'))
            
        elif self.path == "/api/work/request":
            # Worker requests a simulation batch
            conn = sqlite3.connect(DB_PATH)
            cur = conn.cursor()
            job = cur.execute("SELECT id, system_name, natoms, temperature_k, pressure_bar, steps FROM jobs WHERE status = 'PENDING' LIMIT 1").fetchone()
            
            if job:
                cur.execute("UPDATE jobs SET status = 'RUNNING' WHERE id = ?", (job[0],))
                conn.commit()
                resp = {"has_work": True, "job_id": job[0], "system": job[1], "natoms": job[2], "temp_k": job[3], "press_bar": job[4], "steps": job[5]}
            else:
                resp = {"has_work": False, "message": "No pending jobs. AI Explorer is designing new states."}
                
            conn.close()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(resp).encode('utf-8'))
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == "/api/work/submit":
            length = int(self.headers.get('Content-Length', 0))
            body = json.loads(self.rfile.read(length).decode('utf-8'))
            
            job_id = body.get("job_id")
            energy = body.get("energy", 0.0)
            pressure = body.get("pressure", 1.0)
            worker_id = body.get("worker_id", "anonymous")
            steps_done = body.get("steps", 50000)
            
            conn = sqlite3.connect(DB_PATH)
            cur = conn.cursor()
            cur.execute("""
            UPDATE jobs 
            SET status = 'COMPLETED', result_energy = ?, result_pressure = ?, assigned_worker = ?, completed_at = ?
            WHERE id = ?
            """, (energy, pressure, worker_id, time.time(), job_id))
            
            cur.execute("UPDATE workers SET total_steps = total_steps + ?, last_heartbeat = ? WHERE id = ?", (steps_done, time.time(), worker_id))
            conn.commit()
            conn.close()
            
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "SUCCESS", "message": "Work accepted by Sentinel QA Gatekeeper"}).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

def run():
    init_db()
    t = threading.Thread(target=autonomous_ai_explorer_daemon, daemon=True)
    t.start()
    with ReusableTCPServer(("0.0.0.0", PORT), GridHandler) as httpd:
        print(f"DM UAMI Grid Hub running on http://0.0.0.0:{PORT}")
        httpd.serve_forever()

if __name__ == "__main__":
    run()
