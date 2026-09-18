# Network Infrastructure Audit & Nginx vs Cloudflare Analysis
**Date**: 2026-09-17  
**Context**: Evaluate current network setup + compare reverse proxy options

---

## 1. CURRENT INFRASTRUCTURE

### Network Topology
```
Internet (187.190.189.68)
    ↓
[Proxmox Host 192.168.0.52]
    ├─ vmbr0 (bridge, 192.168.0.0/24)
    │   └─ Tailscale: 100.85.38.121 (VPN overlay)
    │
    ├─ CT 109 (claude-dev, 192.168.0.64) ← YOU ARE HERE
    │   ├─ OmniRoute :20128 (HTTP, no TLS)
    │   ├─ Telegram bridge :3000
    │   ├─ Prototipos :8877
    │   ├─ ConfirmaCitas :8090
    │   ├─ Samba :445 (vault SMB)
    │   └─ DNS :53
    │
    ├─ CT 901 (ubuntu, 192.168.0.230)
    │   └─ Entrenador L'Étape :8003
    │
    └─ CT 103 (ollama, 192.168.0.99)
        └─ Ollama API :11434
```

### Current Service Exposure
| Port | Service | Host | Status | TLS |
|------|---------|------|--------|-----|
| :20128 | OmniRoute (LLM gateway) | CT 109 | Running | ❌ HTTP only |
| :8090 | ConfirmaCitas | CT 109 | Running | ❌ HTTP |
| :8877 | Prototipos (airbnb-admin) | CT 109 | Running | ❌ HTTP |
| :8003 | Entrenador L'Étape | CT 901 | Running | ❌ HTTP |
| :11434 | Ollama API | CT 103 | Running | ❌ HTTP |
| :3000 | Telegram bridge | CT 109 | Running | ❌ HTTP |
| :8000 | ? | CT 109 | Running | ? |
| :445 | Samba (SMB) | CT 109 | Running | ❌ SMB |

### Current Proxy Setup
- ❌ **No Nginx** (not installed)
- ❌ **No Caddy** (not installed)
- ❌ **No reverse proxy layer** (services exposed directly)
- ✅ **Firewall**: UFW + CrowdSec active (DROP policy, blacklist enforcement)
- ✅ **DNS**: Cloudflare 1.1.1.1 (resolver only)

### Vulnerabilities (Current State)
1. **No TLS termination** — all internal traffic HTTP
2. **Direct exposure** — services accessible from internet (187.190.189.68)
3. **Port collision risk** — many services on different ports
4. **No rate limiting** — DDoS/brute-force unmitigated at application level
5. **No request filtering** — malformed requests, bot traffic, SQL injection reach services
6. **No log aggregation** — security visibility limited to firewall

---

## 2. OPTION A: NGINX REVERSE PROXY (Self-Hosted)

### What Nginx Does
```
Internet → [Nginx :443 TLS] → [OmniRoute :20128 HTTP] (internal)
             ├─ termination (HTTPS)
             ├─ request filtering
             ├─ rate limiting
             ├─ virtual hosts (domain-based routing)
             └─ caching (optional)
```

### Setup
```bash
# Install
apt-get install nginx

# Config: /etc/nginx/nginx.conf
upstream omniroute {
    server 127.0.0.1:20128;
}

upstream prototipos {
    server 127.0.0.1:8877;
}

upstream entrenador {
    server 192.168.0.230:8003;
}

server {
    listen 443 ssl http2;
    server_name api.tudominio.com;
    
    ssl_certificate /etc/letsencrypt/live/tudominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tudominio.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;
    
    # Request filtering
    if ($request_method !~ ^(GET|POST|PUT|DELETE|HEAD|OPTIONS)$) {
        return 405;
    }
    
    location / {
        proxy_pass http://omniroute;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;  # Redirect HTTP → HTTPS
}
```

### Costs (Self-Hosted)
- **Software**: FREE (open source)
- **SSL Certificate**: FREE (Let's Encrypt, auto-renew)
- **Infrastructure**: Minimal CPU/RAM (Nginx ~50 MB RAM, <5% CPU)
- **Maintenance**: Manual (updates, cert rotation, config debugging)
- **Bandwidth**: Unlimited (on your connection)

**Total Monthly**: ~$0 (only electricity for CT 109)

### Pros
✅ Full control over routing  
✅ No vendor lock-in  
✅ Very fast (minimal latency)  
✅ Works offline (no external service required)  
✅ Can implement custom logic (Lua scripts)  

### Cons
❌ Manual certificate management (Let's Encrypt auto-renewal needed)  
❌ Manual security updates  
❌ You manage DDoS mitigation (iptables, CrowdSec)  
❌ Harder to scale (single-server bottleneck)  
❌ Limited bot/malware detection  
❌ Requires maintaining infrastructure knowledge  

---

## 3. OPTION B: CLOUDFLARE REVERSE PROXY (SaaS)

### What Cloudflare Does
```
Internet → [Cloudflare CDN :443 TLS] → [Your IP 187.190.189.68] → [CT 109 Services]
             ├─ DDoS protection (50+ Tbps)
             ├─ rate limiting + bot management
             ├─ SSL/TLS offload
             ├─ caching edge locations (300+ worldwide)
             ├─ request filtering (WAF rules)
             └─ analytics + security alerts
```

### Setup
1. **Register domain** at registrar (Namecheap, GoDaddy, etc.)
2. **Add domain to Cloudflare** (change NS records)
3. **Create DNS A record**: `your.domain → 187.190.189.68` (your external IP)
4. **Configure routing rules** in Cloudflare dashboard:
   ```
   api.tudominio.com/v1/* → http://192.168.0.64:20128
   prototipos.tudominio.com/* → http://192.168.0.64:8877
   entrenador.tudominio.com/* → http://192.168.0.230:8003
   ```
5. **Enable SSL/TLS**: Full (Strict) mode, or use Cloudflare-issued cert on origin

### Costs (Free Tier)
| Feature | Free | Pro | Business |
|---------|------|-----|----------|
| DDoS Protection | 3.2 Tbps | Unlimited | Unlimited |
| Bot Management | Basic | ✓ | ✓ |
| WAF (Web App Firewall) | Limited | ✓ | ✓ |
| Rate Limiting | No | 10 rules | Unlimited |
| Caching | Yes | 30 days | Custom |
| Analytics | Basic | Advanced | Advanced |
| **Monthly Cost** | **$0** | **$20** | **$200** |

**Recommendation for you**: **Free Tier** ($0) is sufficient initially.

### Free Tier Limits
- ✓ HTTPS/TLS termination
- ✓ Basic DDoS (L3/L4)
- ✓ DNS hosting (unlimited records)
- ✓ Basic caching
- ✓ Email routing (free)
- ❌ Advanced bot management
- ❌ Rate limiting (need Pro)
- ❌ WAF custom rules (need Pro)

### Pros
✅ **Global DDoS protection** (50+ Tbps)  
✅ **Automatic SSL/TLS** (Cloudflare-issued cert)  
✅ **Zero maintenance** (no cert rotation, no updates)  
✅ **Edge caching** (faster for static assets)  
✅ **Analytics + alerts** (security dashboard)  
✅ **Bot detection** (Pro: $20/mo)  
✅ **DNS failover** (redundancy)  
✅ **Free tier is usable** ($0/mo)  

### Cons
❌ **Vendor lock-in** (tied to Cloudflare)  
❌ **Latency added** (DNS lookups, edge processing) — typically +10–50ms  
❌ **Free tier limitations** (no rate limiting, basic WAF)  
❌ **Privacy concern** (Cloudflare sees all traffic)  
❌ **Overkill for internal projects** (Entrenador, Prototipos are not public)  
❌ **Extra complexity** (DNS, routing rules, origin server config)  

---

## 4. COMPARISON TABLE

| Aspect | Nginx | Cloudflare Free | Cloudflare Pro |
|--------|-------|-----------------|-----------------|
| **Setup Time** | 2–4 hours | 30 min | 30 min |
| **Monthly Cost** | $0 | $0 | $20 |
| **TLS Termination** | ✓ (Let's Encrypt) | ✓ | ✓ |
| **DDoS Protection** | ❌ (manual) | ✓ (3.2 Tbps) | ✓ (unlimited) |
| **Bot Detection** | ❌ | Limited | ✓ (advanced) |
| **Rate Limiting** | ✓ (manual) | ❌ | ✓ (10 rules) |
| **Edge Caching** | ❌ | ✓ (global) | ✓ (global) |
| **Maintenance** | High | None | None |
| **Latency** | Minimal | +10–50ms | +10–50ms |
| **Best For** | Internal API, control | Public apps, free DDoS | Public apps, advanced security |

---

## 5. RECOMMENDATION FOR YOUR CASE

### Your Current Situation
- **Services**: Mix of internal (OmniRoute, ConfirmaCitas) + semi-public (Prototipos, Entrenador)
- **Traffic**: Low–moderate (personal projects)
- **Security**: Firewall + CrowdSec active, but no TLS
- **Budget**: $2–3/day token spend (very tight)

### Hybrid Approach (RECOMMENDED)
```
┌─ OmniRoute (:20128) → [Nginx] → HTTPS (:443)
│  ├─ Internal API, high value
│  └─ No need for Cloudflare (not public-facing)
│
├─ Prototipos (:8877) → [Cloudflare Free] → domain.com/prototipos
│  ├─ Public demo, benefits from CDN caching
│  └─ Free tier DDoS protection
│
└─ Entrenador (:8003) → [Keep HTTP] (internal, no public access)
   └─ No need to expose
```

### Step-by-Step
1. **Phase 1 (Week 1)**: Install Nginx on CT 109, proxy only OmniRoute
   - Cost: $0
   - Effort: 2 hours
   - Benefit: TLS for API, clean routing

2. **Phase 2 (Week 2)**: Register domain (e.g., `tudominio.com`)
   - Cost: $10–15/year
   - Effort: 30 min
   - Benefit: Professional URLs

3. **Phase 3 (Week 3)**: Add Cloudflare Free for Prototipos
   - Cost: $0
   - Effort: 30 min
   - Benefit: DDoS protection, global caching, analytics

4. **Future**: If Prototipos gets public traffic, upgrade Cloudflare to Pro ($20/mo)

### Quick Win (If Time-Constrained)
**Use Cloudflare Free tier for everything NOW** ($0/mo):
- No setup required for Nginx
- Instant DDoS protection
- Includes free domain (e.g., tudominio.pages.dev) or register your own
- Minimal latency impact for your use case
- Zero maintenance

Then add Nginx later if you want more control.

---

## 6. IMPLEMENTATION NOTES

### Nginx Quick Install
```bash
# Install + SSL
apt-get update && apt-get install -y nginx certbot python3-certbot-nginx

# Auto-renew Let's Encrypt
systemctl enable certbot.timer

# Start
systemctl start nginx
systemctl enable nginx

# Verify
curl -v https://localhost:20128
```

### Cloudflare Quick Setup
1. Go to cloudflare.com → Sign up (free)
2. Add site → Enter your domain
3. Change NS records at your registrar to Cloudflare's
4. Add DNS A record: `@` → `187.190.189.68`
5. Create page rule: `*.tudominio.com/*` → proxy to origin

---

## RECOMMENDATION SUMMARY

| Use Case | Best Option | Cost |
|----------|------------|------|
| Internal API (OmniRoute) | Nginx | $0 |
| Public demo (Prototipos) | Cloudflare Free | $0 |
| Protected research (Entrenador) | Keep private (no proxy) | $0 |
| Full redundancy + scaling | Nginx + Cloudflare Pro | $20/mo |

**Your move**: Start with **Cloudflare Free** (instant, $0, no config), add Nginx later if needed.

---

**Generated**: 2026-09-17, SatanZote AI
