import { useEffect, useRef, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import "leaflet.heat";
import type { HeatmapPoint } from "../api/services";
import { MapPin, Flame, Eye } from "lucide-react";

/* ─── Fix default Leaflet marker icon path (Vite bundling issue) ── */
// @ts-ignore
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png",
  iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png",
  shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png",
});

/* ─── Custom marker icons per priority ─────────────────────────── */
function createPriorityIcon(priority: string) {
  const colors: Record<string, string> = {
    critical: "#ef4444",
    high: "#f97316",
    medium: "#eab308",
    low: "#3b82f6",
  };
  const color = colors[priority] || "#6b7280";

  return L.divIcon({
    className: "custom-marker",
    html: `
      <div style="
        width: 28px; height: 28px;
        background: ${color};
        border: 3px solid white;
        border-radius: 50% 50% 50% 0;
        transform: rotate(-45deg);
        box-shadow: 0 2px 8px rgba(0,0,0,0.3);
        display: flex; align-items: center; justify-content: center;
      ">
        <div style="
          width: 8px; height: 8px;
          background: white;
          border-radius: 50%;
          transform: rotate(45deg);
        "></div>
      </div>
    `,
    iconSize: [28, 28],
    iconAnchor: [14, 28],
    popupAnchor: [0, -30],
  });
}

/* ─── Heatmap overlay layer ────────────────────────────────────── */
function HeatmapLayer({ points }: { points: HeatmapPoint[] }) {
  const map = useMap();
  const layerRef = useRef<any>(null);

  useEffect(() => {
    if (layerRef.current) {
      map.removeLayer(layerRef.current);
    }
    if (points.length === 0) return;

    const heatData = points.map((p) => {
      const weight =
        p.priority === "critical" ? 1.0 :
          p.priority === "high" ? 0.75 :
            p.priority === "medium" ? 0.5 : 0.3;
      return [p.latitude, p.longitude, weight] as [number, number, number];
    });

    layerRef.current = (L as any).heatLayer(heatData, {
      radius: 30,
      blur: 20,
      maxZoom: 17,
      max: 1.0,
      gradient: {
        0.2: "#3b82f6",
        0.4: "#22d3ee",
        0.6: "#facc15",
        0.8: "#f97316",
        1.0: "#ef4444",
      },
    });

    layerRef.current.addTo(map);

    return () => {
      if (layerRef.current) map.removeLayer(layerRef.current);
    };
  }, [points, map]);

  return null;
}

/* ─── Auto-fit bounds when points change ───────────────────────── */
function FitBounds({ points }: { points: HeatmapPoint[] }) {
  const map = useMap();

  useEffect(() => {
    if (points.length === 0) return;
    const bounds = L.latLngBounds(points.map((p) => [p.latitude, p.longitude]));
    map.fitBounds(bounds, { padding: [40, 40], maxZoom: 14 });
  }, [points, map]);

  return null;
}

/* ─── Priority label/color helpers ─────────────────────────────── */
const PRIORITY_LABEL: Record<string, string> = {
  critical: "Nghiêm trọng",
  high: "Cao",
  medium: "Trung bình",
  low: "Thấp",
};
const PRIORITY_DOT: Record<string, string> = {
  critical: "bg-red-500",
  high: "bg-orange-500",
  medium: "bg-yellow-400",
  low: "bg-blue-500",
};

/* ═══════════════════════════════════════════════════════════════════
   MAIN COMPONENT: IncidentHeatmap
   Props:
     - points: HeatmapPoint[]  (from /api/analytics/heatmap)
   ═══════════════════════════════════════════════════════════════════ */
interface IncidentHeatmapProps {
  points: HeatmapPoint[];
}

type ViewMode = "heatmap" | "markers" | "both";

export default function IncidentHeatmap({ points }: IncidentHeatmapProps) {
  const [viewMode, setViewMode] = useState<ViewMode>("both");

  const showHeatmap = viewMode === "heatmap" || viewMode === "both";
  const showMarkers = viewMode === "markers" || viewMode === "both";

  return (
    <div className="bg-white rounded-2xl border border-gray-200/80 shadow-sm overflow-hidden flex flex-col">
      {/* ── Header ─── */}
      <div className="px-5 py-3.5 border-b border-gray-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <MapPin className="h-5 w-5 text-primary" />
          <h3 className="text-base font-semibold text-gray-900">
            Bản đồ Sự cố
          </h3>
          <span className="text-xs bg-gray-100 text-gray-500 px-2 py-0.5 rounded-full font-medium">
            {points.length} điểm
          </span>
        </div>

        <div className="flex items-center gap-4">
          {/* Legend */}
          <div className="hidden md:flex items-center gap-3 text-[11px] text-gray-400">
            {(["low", "medium", "high", "critical"] as const).map((p) => (
              <span key={p} className="flex items-center gap-1">
                <span className={`h-2 w-2 rounded-full ${PRIORITY_DOT[p]}`} />
                {PRIORITY_LABEL[p]}
              </span>
            ))}
          </div>

          {/* View mode toggle */}
          <div className="flex bg-gray-100 rounded-lg p-0.5 text-xs font-medium">
            <button
              onClick={() => setViewMode("heatmap")}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md transition-all ${viewMode === "heatmap"
                  ? "bg-white text-primary shadow-sm"
                  : "text-gray-500 hover:text-gray-700"
                }`}
            >
              <Flame className="h-3.5 w-3.5" /> Nhiệt
            </button>
            <button
              onClick={() => setViewMode("markers")}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md transition-all ${viewMode === "markers"
                  ? "bg-white text-primary shadow-sm"
                  : "text-gray-500 hover:text-gray-700"
                }`}
            >
              <MapPin className="h-3.5 w-3.5" /> Điểm
            </button>
            <button
              onClick={() => setViewMode("both")}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md transition-all ${viewMode === "both"
                  ? "bg-white text-primary shadow-sm"
                  : "text-gray-500 hover:text-gray-700"
                }`}
            >
              <Eye className="h-3.5 w-3.5" /> Tất cả
            </button>
          </div>
        </div>
      </div>

      {/* ── Map ─── */}
      <div className="h-[500px] relative">
        {points.length > 0 ? (
          <MapContainer
            center={[10.7769, 106.7009]}
            zoom={12}
            style={{ height: "100%", width: "100%" }}
            zoomControl={true}
            attributionControl={false}
          >
            <TileLayer url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png" />
            <FitBounds points={points} />

            {/* Heatmap layer */}
            {showHeatmap && <HeatmapLayer points={points} />}

            {/* Individual markers */}
            {showMarkers &&
              points.map((p, idx) => (
                <Marker
                  key={idx}
                  position={[p.latitude, p.longitude]}
                  icon={createPriorityIcon(p.priority)}
                >
                  <Popup>
                    <div className="min-w-[180px] p-1">
                      <p className="font-bold text-gray-900 text-sm mb-1">
                        {p.category}
                      </p>
                      <div className="flex items-center gap-1.5 mb-2">
                        <span
                          className={`h-2 w-2 rounded-full ${PRIORITY_DOT[p.priority] || "bg-gray-400"
                            }`}
                        />
                        <span className="text-xs text-gray-600">
                          {PRIORITY_LABEL[p.priority] || p.priority}
                        </span>
                      </div>
                      <div className="text-[11px] text-gray-400 border-t border-gray-100 pt-1.5 font-mono">
                        📍 {p.latitude.toFixed(5)}, {p.longitude.toFixed(5)}
                      </div>
                    </div>
                  </Popup>
                </Marker>
              ))}
          </MapContainer>
        ) : (
          <div className="h-full flex flex-col items-center justify-center text-gray-400 bg-gray-50/50">
            <MapPin className="h-14 w-14 text-gray-200 mb-3" />
            <p className="text-sm font-medium text-gray-500">
              Chưa có dữ liệu tọa độ
            </p>
            <p className="text-xs text-gray-400 mt-1">
              Các sự cố sẽ xuất hiện trên bản đồ khi có dữ liệu từ API.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
