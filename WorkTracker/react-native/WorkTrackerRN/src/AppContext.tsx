// src/AppContext.tsx
import React, { createContext, useEffect, useState } from 'react';
import { WorkMonth } from './models/models';
import { loadMonths, saveMonths, loadCollapsedMonths, saveCollapsedMonths, loadSidebarVisible, saveSidebarVisible } from './storage/storage';

type AppContextValue = {
  months: WorkMonth[];
  setMonths: (m: WorkMonth[]) => void;
  hourlyRate: number;
  setHourlyRate: (r: number) => void;
  collapsedMonths: Set<string>;
  toggleCollapsed: (id: string) => void;
  isCollapsed: (id: string) => boolean;
  sidebarVisible: boolean;
  setSidebarVisible: (v: boolean) => void;
};

export const AppContext = createContext<AppContextValue | null>(null);

export const AppProvider: React.FC<{children: React.ReactNode}> = ({ children }) => {
  const [months, setMonthsState] = useState<WorkMonth[]>([]);
  const [hourlyRate, setHourlyRate] = useState<number>(5.0);
  const [collapsedMonths, setCollapsedMonths] = useState<Set<string>>(new Set());
  const [sidebarVisible, setSidebarVisibleState] = useState<boolean>(true);

  useEffect(() => {
    (async () => {
      const loaded = await loadMonths();
      setMonthsState(loaded);
      const collapsed = await loadCollapsedMonths();
      setCollapsedMonths(new Set(collapsed));
      const sidebar = await loadSidebarVisible();
      setSidebarVisibleState(sidebar);
    })();
  }, []);

  useEffect(() => {
    saveMonths(months);
  }, [months]);

  useEffect(() => {
    saveCollapsedMonths(Array.from(collapsedMonths));
  }, [collapsedMonths]);

  useEffect(() => {
    saveSidebarVisible(sidebarVisible);
  }, [sidebarVisible]);

  const setMonths = (m: WorkMonth[]) => setMonthsState(m);

  const toggleCollapsed = (id: string) => {
    setCollapsedMonths(prev => {
      const copy = new Set(prev);
      if (copy.has(id)) copy.delete(id); else copy.add(id);
      return copy;
    });
  };
  const isCollapsed = (id: string) => collapsedMonths.has(id);

  const setSidebarVisible = (v: boolean) => setSidebarVisibleState(v);

  return (
    <AppContext.Provider value={{
      months, setMonths,
      hourlyRate, setHourlyRate,
      collapsedMonths, toggleCollapsed, isCollapsed,
      sidebarVisible, setSidebarVisible
    }}>
      {children}
    </AppContext.Provider>
  );
};
