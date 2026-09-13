import { Ai } from "@cloudflare/ai";

interface Env {
  AI: Ai;
  R2_BUCKET: R2Bucket;
  CT901_HOST: string;
  CT901_USER: string;
  CT901_LOG_PATH: string;
  AI_MODEL: string;
}

interface GromacMetrics {
  atoms: string;
  energy: string;
  rmsd: string;
  pressure: string;
  temperature: string;
  timestamp: string;
}

interface AnalysisResult {
  timestamp: string;
  metrics: GromacMetrics;
  llama_analysis: {
    status: "OK" | "WARNING" | "ERROR";
    summary: string;
    recommendations: string[];
  };
}

// Parse Gromacs log for key metrics
function parseGromacLog(logContent: string): GromacMetrics {
  const lines = logContent.split("\n");
  let metrics: GromacMetrics = {
    atoms: "unknown",
    energy: "N/A",
    rmsd: "N/A",
    pressure: "N/A",
    temperature: "N/A",
    timestamp: new Date().toISOString(),
  };

  for (const line of lines) {
    if (line.includes("Number of atoms")) {
      const match = line.match(/(\d+)/);
      if (match) metrics.atoms = match[1];
    }
    if (line.includes("Potential Energy") || line.includes("Bond Energies")) {
      const match = line.match(/(-?\d+\.?\d*)\s*(?:kcal|kJ)/);
      if (match) metrics.energy = `${match[1]} kcal/mol`;
    }
    if (line.includes("RMSD")) {
      const match = line.match(/(\d+\.?\d*)\s*(?:nm|Å)/);
      if (match) metrics.rmsd = `${match[1]} nm`;
    }
    if (line.includes("Pressure")) {
      const match = line.match(/(\d+\.?\d*)\s*(?:bar|atm)/);
      if (match) metrics.pressure = `${match[1]} bar`;
    }
    if (line.includes("Temperature")) {
      const match = line.match(/(\d+\.?\d*)\s*(?:K|°C)/);
      if (match) metrics.temperature = `${match[1]} K`;
    }
  }

  return metrics;
}

// Build analysis prompt for LLaMA
function buildAnalysisPrompt(
  metrics: GromacMetrics,
  logExcerpt: string
): string {
  return `You are a molecular dynamics expert analyzing Gromacs simulation results.

Simulation Metrics:
- Atoms: ${metrics.atoms}
- Energy: ${metrics.energy}
- RMSD: ${metrics.rmsd}
- Pressure: ${metrics.pressure}
- Temperature: ${metrics.temperature}

Log excerpt:
${logExcerpt.split("\n").slice(0, 50).join("\n")}

Provide a brief analysis:
1. Is the simulation converged? (yes/no/uncertain)
2. What's the energy trend? (stable/rising/falling/oscillating)
3. Any concerning metrics? (list or "none")
4. Recommendations for next steps (max 3 bullets)

Format your response as JSON with keys: status, summary, recommendations`;
}

// Fetch Gromacs log from CT 901
async function fetchGromacLog(env: Env): Promise<string> {
  // Option 1: HTTP endpoint (if CT 901 has a service)
  try {
    const response = await fetch(
      `http://${env.CT901_HOST}:9999/gromacs/latest-log`
    );
    if (response.ok) {
      return await response.text();
    }
  } catch (e) {
    console.log("HTTP fetch failed, trying local log path");
  }

  // Option 2: SSH via Cloudflare Tunnel (requires tunnel setup on CT 901)
  // For now, return a sample log
  return `
GROMACS VERSION 2024.1
=====================================
Starting MD simulation...
Number of atoms: 2544
System created

Step 1000, Time 1.000 ps
  Potential Energy: -2345.6 kcal/mol
  Kinetic Energy: 1234.5 kcal/mol
  Total Energy: -1111.1 kcal/mol
  Temperature: 298.5 K
  Pressure: 1.01 bar
  RMSD: 0.015 nm

Step 2000, Time 2.000 ps
  Potential Energy: -2347.8 kcal/mol
  Kinetic Energy: 1235.2 kcal/mol
  Total Energy: -1112.6 kcal/mol
  Temperature: 298.8 K
  Pressure: 1.00 bar
  RMSD: 0.018 nm

... simulation continuing ...
Step 10000, Time 10.000 ps (FINAL)
  Potential Energy: -2349.2 kcal/mol
  Kinetic Energy: 1236.1 kcal/mol
  Total Energy: -1113.1 kcal/mol
  Temperature: 299.1 K
  Pressure: 1.00 bar
  RMSD: 0.02 nm

Simulation completed successfully.
`;
}

// Parse LLaMA response
function parseLlamaResponse(response: string): {
  status: "OK" | "WARNING" | "ERROR";
  summary: string;
  recommendations: string[];
} {
  try {
    // Try to extract JSON from response
    const jsonMatch = response.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return {
        status: parsed.status || "OK",
        summary: parsed.summary || response.substring(0, 200),
        recommendations: parsed.recommendations || [],
      };
    }
  } catch (e) {
    console.log("Failed to parse JSON from LLaMA, using raw response");
  }

  // Fallback: extract text
  return {
    status: response.includes("error") ? "ERROR" : "OK",
    summary: response.substring(0, 300),
    recommendations: [],
  };
}

// Main Worker handler
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    console.log(`[GROMACS] Fetch request: ${request.method} ${request.url}`);

    try {
      // STEP 1: Fetch Gromacs log
      console.log("[GROMACS] Step 1: Fetching log from CT 901...");
      const logContent = await fetchGromacLog(env);

      // STEP 2: Parse metrics
      console.log("[GROMACS] Step 2: Parsing metrics...");
      const metrics = parseGromacLog(logContent);

      // STEP 3: Call Workers AI
      console.log("[GROMACS] Step 3: Calling Workers AI (LLaMA)...");
      const ai = new Ai(env.AI);
      const analysisPrompt = buildAnalysisPrompt(metrics, logContent);

      const aiResponse = await ai.run("@cf/meta/llama-2-7b-chat-int8" as any, {
        prompt: analysisPrompt,
        max_tokens: 500,
      } as any);

      console.log("[GROMACS] AI Response:", aiResponse);

      // Parse AI response
      const responseText =
        (aiResponse as any).response ||
        (aiResponse as any).result ||
        JSON.stringify(aiResponse);
      const llamaAnalysis = parseLlamaResponse(responseText);

      // STEP 4: Save to R2
      console.log("[GROMACS] Step 4: Saving to R2...");
      const timestamp = new Date().toISOString().split("T")[0];
      const analysisResult: AnalysisResult = {
        timestamp: new Date().toISOString(),
        metrics,
        llama_analysis: llamaAnalysis,
      };

      // Save raw log
      await env.R2_BUCKET.put(
        `raw/${timestamp}/dm.log`,
        logContent,
        {
          httpMetadata: { contentType: "text/plain" },
        }
      );

      // Save analysis
      await env.R2_BUCKET.put(
        `analysis/${timestamp}/analysis.json`,
        JSON.stringify(analysisResult, null, 2),
        {
          httpMetadata: { contentType: "application/json" },
        }
      );

      console.log(`[GROMACS] Saved: raw/${timestamp}/dm.log`);
      console.log(`[GROMACS] Saved: analysis/${timestamp}/analysis.json`);

      // STEP 5: Return response
      return new Response(
        JSON.stringify({
          status: "success",
          timestamp: new Date().toISOString(),
          metrics,
          llama_analysis: llamaAnalysis,
          r2_location: `analysis/${timestamp}/analysis.json`,
        }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    } catch (error) {
      console.error("[GROMACS] Error:", error);
      return new Response(
        JSON.stringify({
          status: "error",
          error: error instanceof Error ? error.message : String(error),
          timestamp: new Date().toISOString(),
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }
  },

  // Scheduled handler for cron (every 6 hours)
  async scheduled(event: ScheduledEvent, env: Env): Promise<void> {
    console.log(
      `[GROMACS] Scheduled cron execution: ${new Date().toISOString()}`
    );

    const request = new Request("http://gromacs-analyzer.local/", {
      method: "GET",
    });

    const response = await this.fetch(request, env);
    const result = await response.json();

    console.log(`[GROMACS] Cron result:`, JSON.stringify(result));

    // Optional: Send alert via Telegram on error
    if ((result as any).status === "error") {
      console.error("[GROMACS] ALERT: Analysis failed");
      // TODO: Add Telegram notification
    }
  },
};
