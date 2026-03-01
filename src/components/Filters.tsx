import { useState } from "react";
import type { Filters as FiltersType, FilterKey } from "../types";

interface Props {
  filters: FiltersType;
  onToggle: (key: FilterKey) => void;
  venueCount: number;
  totalCount: number;
  showInfo: boolean;
  onToggleInfo: () => void;
}

const FILTER_OPTIONS: { key: FilterKey; label: string; color: string }[] = [
  { key: "film", label: "15/70mm Film", color: "#ef4444" },
  { key: "gtLaser", label: "GT Laser", color: "#f59e0b" },
  { key: "laser", label: "Laser", color: "#3b82f6" },
  { key: "dome", label: "Dome", color: "#a855f7" },
];

export function Filters({
  filters,
  onToggle,
  venueCount,
  totalCount,
  showInfo,
  onToggleInfo,
}: Props) {
  const [collapsed, setCollapsed] = useState(false);

  return (
    <div className={`filters-panel ${collapsed ? "filters-collapsed" : ""}`}>
      <div className="filters-header">
        <h1>IMAX Near Me</h1>
        <div className="filters-header-actions">
          <button
            className={`info-toggle ${showInfo ? "active" : ""}`}
            onClick={onToggleInfo}
            aria-label="Toggle info panel"
            title="About IMAX projectors"
          >
            <svg
              width="14"
              height="14"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="16" x2="12" y2="12" />
              <line x1="12" y1="8" x2="12.01" y2="8" />
            </svg>
          </button>
          <button
            className="filters-collapse-toggle"
            onClick={() => setCollapsed((c) => !c)}
            aria-label={collapsed ? "Show filters" : "Hide filters"}
          >
            <svg
              className="collapse-chevron"
              width="12"
              height="12"
              viewBox="0 0 12 12"
              fill="none"
            >
              <path
                d="M2.5 4.5L6 8L9.5 4.5"
                stroke="currentColor"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>
        </div>
      </div>
      <div className="filters-body">
        <div className="filters-body-inner">
          <div className="filters-subtitle">Filter by projector</div>
          <div className="filter-buttons">
            {FILTER_OPTIONS.map(({ key, label, color }) => (
              <button
                key={key}
                className={`filter-btn ${filters[key] ? "active" : ""}`}
                style={{
                  borderColor: filters[key] ? color : "rgba(255,255,255,0.12)",
                  backgroundColor: filters[key] ? `${color}22` : "transparent",
                  color: filters[key] ? color : "rgba(255,255,255,0.4)",
                }}
                onClick={() => onToggle(key)}
              >
                <span
                  className="dot"
                  style={{
                    backgroundColor: filters[key]
                      ? color
                      : "rgba(255,255,255,0.2)",
                  }}
                />
                {label}
              </button>
            ))}
          </div>
          <div className="venue-count">
            <strong>{venueCount}</strong> of {totalCount} venues
          </div>
        </div>
      </div>
    </div>
  );
}
