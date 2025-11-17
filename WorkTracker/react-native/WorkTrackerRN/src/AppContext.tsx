// src/AppContext.tsx
import React, { createContext, useEffect, useState } from 'react';
import { WorkMonth } from './models/models';
import { loadMonths, saveMonths } from './storage/storage';

type AppContextValue = {
  months: WorkMonth[];
  setMonths: (m: WorkMonth[]) => void;
  hourlyRate: number;
  setHourlyRate: (v: number) => void;
};

export const AppContext = createContext<AppContextValue | null>(null);

export const AppProvider: React.FC<{children: React.ReactNode}> = ({ children }) => {
  const [months, setMonthsState] = useState<WorkMonth[]>([]);
  const [hourlyRate, setHourlyRate] = useState<number>(5.0);

  useEffect(() => {
    (async () => {
      const loaded = await loadMonths();
      setMonthsState(loaded);
    })();
  }, []);

  useEffect(() => {
    // save on change
    saveMonths(months);
  }, [months]);

  const setMonths = (m: WorkMonth[]) => setMonthsState(m);

  return (
    <AppContext.Provider value={{ months, setMonths, hourlyRate, setHourlyRate }}>
      {children}
    </AppContext.Provider>
  );
};
