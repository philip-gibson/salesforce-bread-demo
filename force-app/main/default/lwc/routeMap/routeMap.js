import { LightningElement, track } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import optimiseRoute from '@salesforce/apex/BreadController.optimiseRoute';
import getDirections from '@salesforce/apex/BreadController.getDirections';

// ─── IMPORTANT ───────────────────────────────────────────────────────────────
// Before deploying, upload Leaflet as a Static Resource in Salesforce:
//   1. Download leaflet.js and leaflet.css from https://leafletjs.com/download.html
//   2. Zip them together into leaflet.zip with the structure:
//        leaflet.zip/leaflet/leaflet.js
//        leaflet.zip/leaflet/leaflet.css
//   3. In Salesforce Setup → Static Resources → New
//      Name: "leaflet", Cache Control: Public
//   4. Upload the zip file
// ─────────────────────────────────────────────────────────────────────────────
import LEAFLET_JS  from '@salesforce/resourceUrl/leaflet';
import LEAFLET_CSS from '@salesforce/resourceUrl/leaflet';

const TILE_URL   = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
const TILE_ATTR  = '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
const ROUTE_COLOR = '#0176d3';
const HOME_COLOR  = '#032d60';
const STOP_COLOR  = '#0176d3';

let leafletLoaded = false;

export default class RouteMap extends LightningElement {

    // ── Reactive state ───────────────────────────────────────────────────────
    @track coordinates = [
        { id: 1, lat: '', lng: '', isFirst: true,  displayIndex: '' },
        { id: 2, lat: '', lng: '', isFirst: false, displayIndex: 2  },
        { id: 3, lat: '', lng: '', isFirst: false, displayIndex: 3  },
    ];

    @track isLoading    = false;
    @track errorMessage = '';
    @track routeSummary = null;
    @track mapReady     = false;

    _nextId = 4;
    _map    = null;
    _layers = [];

    // ── Getters ──────────────────────────────────────────────────────────────
    get coordinateCount() {
        return this.coordinates.length;
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────
    connectedCallback() {
        this._loadLeaflet();
    }

    async _loadLeaflet() {
        if (leafletLoaded) return;
        try {
            await Promise.all([
                loadStyle(this,  LEAFLET_CSS + '/leaflet/leaflet.css'),
                loadScript(this, LEAFLET_JS  + '/leaflet/leaflet.js'),
            ]);
            leafletLoaded = true;
        } catch (e) {
            this.errorMessage = 'Failed to load map library. Ensure the "leaflet" Static Resource is uploaded.';
        }
    }

    // ── Field handlers ───────────────────────────────────────────────────────
    handleCoordChange(event) {
        const { id, field } = event.target.dataset;
        const numId = parseInt(id, 10);
        this.coordinates = this.coordinates.map(c =>
            c.id === numId ? { ...c, [field]: event.target.value.trim() } : c
        );
    }

    addCoordinate() {
        const idx = this._nextId++;
        this.coordinates = [
            ...this.coordinates,
            { id: idx, lat: '', lng: '', isFirst: false, displayIndex: this.coordinates.length + 1 }
        ];
        this._reindex();
    }

    removeCoordinate(event) {
        const numId = parseInt(event.target.dataset.id, 10);
        this.coordinates = this.coordinates.filter(c => c.id !== numId);
        this._reindex();
    }

    _reindex() {
        this.coordinates = this.coordinates.map((c, i) => ({
            ...c,
            isFirst:      i === 0,
            displayIndex: i === 0 ? '' : i + 1,
        }));
    }

    resetAll() {
        this.coordinates = [
            { id: 1, lat: '', lng: '', isFirst: true,  displayIndex: '' },
            { id: 2, lat: '', lng: '', isFirst: false, displayIndex: 2  },
            { id: 3, lat: '', lng: '', isFirst: false, displayIndex: 3  },
        ];
        this._nextId      = 4;
        this.errorMessage = '';
        this.routeSummary = null;
        this.mapReady     = false;
        this._destroyMap();
    }

    // ── Route calculation (via Apex) ─────────────────────────────────────────
    async calculateRoute() {
        this.errorMessage = '';
        this.routeSummary = null;

        // Validate coords
        const filled = this.coordinates.filter(c => c.lat !== '' && c.lng !== '');
        if (filled.length < 2) {
            this.errorMessage = 'Please enter at least 2 waypoints (start + 1 stop).';
            return;
        }

        const invalid = filled.find(
            c => isNaN(parseFloat(c.lat)) || isNaN(parseFloat(c.lng))
        );
        if (invalid) {
            this.errorMessage = 'One or more coordinates are not valid numbers.';
            return;
        }

        this.isLoading = true;

        try {
            // Build coordinate array [[lng, lat], ...] for ORS
            const coords = filled.map(c => [parseFloat(c.lng), parseFloat(c.lat)]);

            // ── Step 1: Call Apex to optimise waypoint order ─────────────────
            // Apex → Named Credential → ORS /v2/optimization
            // API key stays server-side, never touches the browser
            const optimResult = JSON.parse(
                await optimiseRoute({ coordinatesJson: JSON.stringify(coords) })
            );

            const { orderedJobIds, orderedCoords } = optimResult;

            // Build human-readable stop order label
            const stopLabels = ['🏠 Home', ...orderedJobIds.map(id => `Stop ${id}`), '🏠 Home'];
            const orderText  = stopLabels.join(' → ');

            // ── Step 2: Call Apex to get road-snapped GeoJSON ────────────────
            // Apex → Named Credential → ORS /v2/directions
            const geojsonString = await getDirections({
                orderedCoordsJson: JSON.stringify(orderedCoords)
            });

            const geojson = JSON.parse(geojsonString);
            const summary = geojson.features[0].properties.summary;

            // ── Step 3: Build route summary ──────────────────────────────────
            this.routeSummary = {
                distance: this._formatDistance(summary.distance),
                duration: this._formatDuration(summary.duration),
                stops:    filled.length - 1,
                order:    orderText,
            };

            // ── Step 4: Draw on Leaflet map ──────────────────────────────────
            await this._drawMap(geojson, orderedCoords, filled, orderedJobIds);

        } catch (err) {
            // AuraHandledException messages are in err.body.message
            this.errorMessage = (err.body && err.body.message) || err.message || 'An unexpected error occurred.';
        } finally {
            this.isLoading = false;
        }
    }

    // ── Map rendering (Leaflet) ──────────────────────────────────────────────
    async _drawMap(geojson, orderedCoords, filledCoords, orderedJobIds) {
        if (!leafletLoaded) {
            await this._loadLeaflet();
        }

        // eslint-disable-next-line no-undef
        const L = window.L;
        if (!L) {
            this.errorMessage = 'Leaflet not available. Check your Static Resource.';
            return;
        }

        this.mapReady = true;

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            try {
                const container = this.refs.mapContainer;
                if (!container) return;

                this._destroyMap();

                this._map = L.map(container).setView(
                    [filledCoords[0].lat, filledCoords[0].lng],
                    10
                );

                L.tileLayer(TILE_URL, { attribution: TILE_ATTR, maxZoom: 19 }).addTo(this._map);

                const routeLayer = L.geoJSON(geojson, {
                    style: { color: ROUTE_COLOR, weight: 5, opacity: 0.85 },
                }).addTo(this._map);
                this._layers.push(routeLayer);

                // Home marker
                const homeIcon = L.divIcon({
                    html: `<div style="background:${HOME_COLOR};color:#fff;border-radius:50%;
                        width:36px;height:36px;display:flex;align-items:center;
                        justify-content:center;font-size:18px;font-weight:bold;
                        border:3px solid #fff;box-shadow:0 2px 6px rgba(0,0,0,.35);">🏠</div>`,
                    className: '', iconSize: [36, 36], iconAnchor: [18, 18],
                });
                L.marker([filledCoords[0].lat, filledCoords[0].lng], { icon: homeIcon })
                    .bindPopup('<b>🏠 Home / Start</b>')
                    .addTo(this._map);

                // Numbered stop markers
                orderedJobIds.forEach((jobId, visitOrder) => {
                    const coord = filledCoords[jobId];
                    const label = visitOrder + 1;
                    const stopIcon = L.divIcon({
                        html: `<div style="background:${STOP_COLOR};color:#fff;border-radius:50%;
                            width:30px;height:30px;display:flex;align-items:center;
                            justify-content:center;font-size:13px;font-weight:700;
                            border:3px solid #fff;box-shadow:0 2px 6px rgba(0,0,0,.3);">${label}</div>`,
                        className: '', iconSize: [30, 30], iconAnchor: [15, 15],
                    });
                    L.marker([coord.lat, coord.lng], { icon: stopIcon })
                        .bindPopup(`<b>Stop ${label}</b><br>Lat: ${coord.lat}<br>Lng: ${coord.lng}`)
                        .addTo(this._map);
                });

                this._map.fitBounds(routeLayer.getBounds(), { padding: [40, 40] });

            } catch (mapErr) {
                this.errorMessage = `Map render error: ${mapErr.message}`;
            }
        }, 100);
    }

    _destroyMap() {
        if (this._map) {
            this._layers.forEach(l => l.remove());
            this._layers = [];
            this._map.remove();
            this._map = null;
        }
    }

    // ── Formatting helpers ───────────────────────────────────────────────────
    _formatDistance(metres) {
        return metres >= 1000
            ? `${(metres / 1000).toFixed(1)} km`
            : `${Math.round(metres)} m`;
    }

    _formatDuration(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        return h > 0 ? `${h}h ${m}m` : `${m} min`;
    }
}
