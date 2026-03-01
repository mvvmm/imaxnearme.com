import { useState, useEffect } from "react";

interface GeolocationState {
  lat: number;
  lng: number;
  loading: boolean;
  error: string | null;
  located: boolean;
}

const US_CENTER = { lat: 39.8, lng: -98.6 };
const DEFAULT_ZOOM = 4;
const LOCATED_ZOOM = 8;

export function useGeolocation() {
  const [state, setState] = useState<GeolocationState>({
    ...US_CENTER,
    loading: true,
    error: null,
    located: false,
  });

  useEffect(() => {
    if (!navigator.geolocation) {
      setState((s) => ({ ...s, loading: false, error: "Geolocation not supported" }));
      return;
    }

    // Check permissions first — iOS Safari silently denies without HTTPS
    const tryGeolocate = () => {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          setState({
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
            loading: false,
            error: null,
            located: true,
          });
        },
        (err) => {
          setState((s) => ({ ...s, loading: false, error: err.message }));
        },
        { enableHighAccuracy: true, timeout: 15000, maximumAge: 300000 }
      );
    };

    if (navigator.permissions) {
      navigator.permissions.query({ name: "geolocation" }).then((result) => {
        if (result.state === "denied") {
          setState((s) => ({ ...s, loading: false, error: "Permission denied" }));
        } else {
          tryGeolocate();
        }
      }).catch(() => {
        // permissions API not supported (older iOS), just try directly
        tryGeolocate();
      });
    } else {
      tryGeolocate();
    }
  }, []);

  return { ...state, defaultZoom: state.located ? LOCATED_ZOOM : DEFAULT_ZOOM };
}
