# 4nine64 bv — website

Tweetalige one-pager (NL/EN) met de zakelijke gegevens van 4nine64 bv. Statische HTML, geen
build. Lettertypen staan in `site/fonts/` (zelf gehost, geen request naar Google).

| map/bestand | wat |
|---|---|
| `site/` | wat er live staat: `index.html`, `fonts.css`, `fonts/`, `assets/` |
| `index.html`, `alt.html` | de twee ontwerpvoorstellen A en B (oktober 2026); B is het ontwerp dat live staat |
| `assets/` | logo-varianten (origineel, dark, op indigo) |
| `docker-compose.yml`, `nginx.conf` | nginx op de server, container `4nine64-web` op netwerk `deploy_vzc` |
| `deploy/4nine64.caddy` | het Caddy-blok; staat op de server in `Caddyfile.local` van de voorzieningencatalogus |
| `scripts/deploy.sh` | uitrollen vanaf de werkplek |

## Uitrollen

```bash
bash scripts/deploy.sh
```

Synchroniseert `site/` naar `root@178.104.240.234:/srv/4nine64`, start nginx, zet (eenmalig) het
Caddy-blok en controleert of Caddy de site kan bereiken. Tekst wijzigen = `site/index.html`
aanpassen en opnieuw deployen; er is niets te bouwen.

## DNS (bij TransIP, zone 4nine64.nl)

Stand op 5 oktober 2026: het domein wees naar de TransIP-parkeerpagina ("Bezet!"). Om te zetten:

1. `A  4nine64.nl      → 178.104.240.234`
2. `A  www.4nine64.nl  → 178.104.240.234` (of CNAME naar `4nine64.nl`)
3. **AAAA-record (`2a01:7c8:3:1337::27`) verwijderen** — de Hetzner heeft geen IPv6; laat je dit
   staan, dan komen IPv6-bezoekers nog op TransIP uit en mislukt de certificaataanvraag deels.
4. `MX 10 4nine64.nl` wijst naar het domein zelf. Zolang er geen mail op `@4nine64.nl` wordt
   gebruikt (e-mail op de site is `toine@freedom.nl`) kun je het MX-record het beste weghalen;
   wil je ooit wél mail op dit domein, dan moet het naar een echte mailserver wijzen, niet naar
   de Hetzner.

Caddy haalt het Let's Encrypt-certificaat zelf zodra het A-record naar de server wijst; tot die
tijd meldt `docker logs deploy-caddy-1` een mislukte aanvraag voor 4nine64.nl. Dat herstelt
vanzelf.

## Nog open

- Algemene voorwaarden en privacyverklaring staan niet op de pagina (blok op 6 oktober 2026 verwijderd).
- Vestigingsadres staat bewust niet op de site.
