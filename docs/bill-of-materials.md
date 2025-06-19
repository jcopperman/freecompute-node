# Bill of Materials – Free Compute Node

This guide outlines possible hardware configurations for building your own Free Compute Node, based on your budget, environment, and performance needs. All options are designed to be locally sourced or easily repurposed.

---

## Tier 1: Minimal Viable Node

**Use case:** Personal node, basic hosting, file sharing, small services.

* **Device:** Raspberry Pi 4 (4GB or 8GB) or used Intel NUC
* **Power:** 65W USB-C adapter, or 12V DC with solar regulator
* **Storage:** 64GB microSD (boot), 256GB external SSD (data)
* **Cooling:** Passive or USB fan
* **Networking:** Ethernet preferred, Wi-Fi fallback

Optional:

* Small solar panel (100–150W)
* MPPT charge controller
* 12V 20Ah lithium battery (LiFePO₄)

---

## Tier 2: Reliable Local Host

**Use case:** Small teams, schools, clinics, media storage, AI inference.

* **Device:** Refurbished Dell OptiPlex or HP ProDesk (Intel i5/i7, 16GB RAM)
* **Power:** 300W ATX PSU or DC inverter input
* **Storage:** 512GB–1TB SSD
* **Cooling:** Internal fan or external airflow mod
* **Networking:** Wired Ethernet, with optional Tailscale mesh

Optional:

* 300W–400W solar panel
* MPPT solar controller
* 12V 50Ah LiFePO₄ battery

---

## Tier 3: Mesh Hub or Edge DC

**Use case:** Community node, hub for federated mesh, AI/ML local services.

* **Device:** Intel NUC 11/12, or Lenovo Tiny with Ryzen or i7
* **Memory:** 32GB RAM
* **Storage:** NVMe SSD (1TB+), secondary external SSD for backups
* **Power:** 500W inverter-compatible supply
* **Cooling:** Quiet active cooling (Noctua or modded airflow)
* **Networking:** Wired, Tailscale or ZeroTier mesh-ready, optional LTE failover

Recommended:

* 500W+ solar panel array
* 12V 100Ah LiFePO₄ battery
* Rackmount battery box (optional)

---

## Notes

* Use what you have. Old, repaired, salvaged — if it runs Linux, it counts.
* Start small. Even the minimal node can federate and serve real value.
* Mix and match. Power system from Tier 3, compute from Tier 1? Totally fine.
* The only rule: you own it.

---

## Still to come:

* Diagrams and wiring setups for off-grid power
* Photos of real node builds
* Print-friendly single-page spec sheet