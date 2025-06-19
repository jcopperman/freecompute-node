# How It Works

The Free Compute Node is a small, self-contained unit that runs essential infrastructure locally — no cloud, no monthly bills, no dependency on constant connectivity.

Each node provides:

* **Local compute** for running services and containers
* **Internal storage** for backups, apps, and media
* **Optional AI tools** that don’t need internet access
* **Mesh networking** so nodes can discover and support each other
* **Resilience** against load-shedding and line cuts through solar and local fallback routes

---

## Basic Architecture

```
[ Power Input ] — Solar or AC Grid
        │
        ▼
[ Compute Unit ] — Low-power server, mini-PC, or Raspberry Pi
        │
 ┌──────┴─────────────┬─────────────────────┐
 │                    │                     │
 ▼                    ▼                     ▼
[ Storage Layer ]   [ App Layer ]       [ AI Layer ]
 MinIO, Nextcloud   CapRover, Dokku     Ollama, Whisper
        │
        ▼
[ Networking ]
 Tailscale, IPFS, LoRa
```

---

## Setup Flow

1. **Flash the image or run install script** on your local device
2. **Power up** — solar, UPS, or wall power
3. **Access the local dashboard** via LAN or `.local` domain
4. **Configure your services** via CapRover or compose files
5. **Optional: connect to the mesh** via Tailscale or ZeroTier
6. **It just works** — even with no internet

---

## Who Can Run One

Anyone with:

* A device (Raspberry Pi 4, Intel NUC, old workstation, mini-PC)
* Basic Linux knowledge (or help from someone who has it)
* A power source (solar, UPS, or stable grid)
* A need to host, store, or compute **on their own terms**

These nodes can be used by:

* Individuals and families
* Schools and clinics
* Co-ops and collectives
* Developers and creators

They scale out, not up — one becomes two, two become a mesh.

And the best part: you don’t need permission from anyone to start.