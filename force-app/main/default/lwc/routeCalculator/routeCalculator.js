import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import breadBasket from '@salesforce/resourceUrl/BreadBasket';
import optimiseRoute from '@salesforce/apex/BreadController.optimiseRoute';
import getDirections from '@salesforce/apex/BreadController.getDirections';
import LEAFLET_JS  from '@salesforce/resourceUrl/leaflet';
import LEAFLET_CSS from '@salesforce/resourceUrl/leaflet';

const TILE_URL   = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
const TILE_ATTR  = '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
const ROUTE_COLOR = '#0176d3';
const HOME_COLOR  = '#032d60';
const STOP_COLOR  = '#0176d3';
const initRouteSummary = {
  distance: '0.0 km',
  duration: '0 min',
  stops: 0,
  order: 'N/A',
};

let leafletLoaded = false;

export default class RouteCalculator extends LightningElement {
  @api coordinates = [];
  isLoading    = false;
  errorMessage = '';
  routeSummary = initRouteSummary;
  mapReady     = false;

  // _nextId = 4;
  _map    = null;
  _layers = [];

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

  @api resetAll() {
    // this.coordinates = [];
    // this._nextId      = 4;
    this.errorMessage = '';
    this.routeSummary = initRouteSummary;
    this.mapReady     = false;
    this._destroyMap();
  }

  @api async calculateRoute() {
    this.errorMessage = '';
    this.routeSummary = initRouteSummary;

    console.log('*** Calculating route for coordinates:', this.coordinates);
    // Validate coords
    const filled = this.coordinates.filter(c => c.lat !== '' && c.lng !== '');
    if (filled.length < 2) {
      this.errorMessage = 'Please select at least one delivery point.';
      return;
    }
  
    const invalid = filled.find(
      c => Number.isNaN(Number.parseFloat(c.lat)) || Number.isNaN(Number.parseFloat(c.lng))
    );
    if (invalid) {
      this.errorMessage = 'One or more coordinates are not valid numbers.';
      return;
    }

    this.isLoading = true;
  
    try {
      // Build coordinate array [[lng, lat], ...] for ORS
      const coords = filled.map(c => [Number.parseFloat(c.lng), Number.parseFloat(c.lat)]);
      console.log('*** coords:', coords);
      // ── Step 1: Call Apex to optimise waypoint order ─────────────────
      // Apex → Named Credential → ORS /v2/optimization
      // API key stays server-side, never touches the browser
      const optimResult = JSON.parse(
        await optimiseRoute({ coordinatesJson: JSON.stringify(coords) })
      );

      const { orderedJobIds, orderedCoords } = optimResult;
      console.log('*** orderedCoords:', orderedCoords);
      // Build human-readable stop order label
      const orderedJobNames = orderedJobIds.map(id => {
        console.log('*** Finding name for job ID:', id);
        return this.coordinates.find(c => c.id === id)?.name || `Stop ${id}`;
      });
      const stopLabels = ['Salesforce Bakery', ...orderedJobNames, 'Salesforce Bakery'];
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
                border:3px solid #fff;box-shadow:0 2px 6px rgba(0,0,0,.35);">
                <img src="${breadBasket}" style="width:28px;height:28px;" alt="Bread Basket"></img></div>`,
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
