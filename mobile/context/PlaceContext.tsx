// mobile/context/PlaceContext.tsx
import React, { createContext, useContext, useState } from "react";

export type SelectedPlace = {
  name: string;
  latitude: number;
  longitude: number;
  walkTime?: string;
  distance?: string;
  address?: string;
  image?: string | null;   // ✅ Add this line
} | null;

type PlaceContextType = {
  selectedPlace: SelectedPlace;
  setSelectedPlace: (p: SelectedPlace) => void;
};

const PlaceContext = createContext<PlaceContextType>({
  selectedPlace: null,
  setSelectedPlace: () => {},
});

export function PlaceProvider({ children }: { children: React.ReactNode }) {
  const [selectedPlace, setSelectedPlace] = useState<SelectedPlace>(null);

  return (
    <PlaceContext.Provider value={{ selectedPlace, setSelectedPlace }}>
      {children}
    </PlaceContext.Provider>
  );
}

export function usePlace() {
  return useContext(PlaceContext);
}
