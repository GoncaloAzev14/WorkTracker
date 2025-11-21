import AsyncStorage from '@react-native-async-storage/async-storage';
import type { WorkMonth } from '../models/models';

const MONTHS_KEY = 'WorkTracker:months_v1';
const COLLAPSED_KEY = 'WorkTracker:collapsedMonths_v1';
const SIDEBAR_KEY = 'WorkTracker:sidebarVisible_v1';

export async function saveMonths(months: WorkMonth[]) {
  try {
    await AsyncStorage.setItem(MONTHS_KEY, JSON.stringify(months));
  } catch (e) {
    console.warn('saveMonths failed', e);
  }
}

export async function loadMonths(): Promise<WorkMonth[]> {
  try {
    const raw = await AsyncStorage.getItem(MONTHS_KEY);
    if (!raw) return [];
    return JSON.parse(raw) as WorkMonth[];
  } catch (e) {
    console.warn('loadMonths failed', e);
    return [];
  }
}

export async function saveCollapsedMonths(ids: string[]) {
  try {
    await AsyncStorage.setItem(COLLAPSED_KEY, JSON.stringify(ids));
  } catch (e) {
    console.warn('saveCollapsedMonths failed', e);
  }
}

export async function loadCollapsedMonths(): Promise<string[]> {
  try {
    const raw = await AsyncStorage.getItem(COLLAPSED_KEY);
    if (!raw) return [];
    return JSON.parse(raw);
  } catch (e) {
    return [];
  }
}

export async function saveSidebarVisible(v: boolean) {
  try { await AsyncStorage.setItem(SIDEBAR_KEY, JSON.stringify(v)); } catch(e){}
}

export async function loadSidebarVisible(): Promise<boolean> {
  try {
    const raw = await AsyncStorage.getItem(SIDEBAR_KEY);
    if (!raw) return true;
    return JSON.parse(raw);
  } catch (e) { return true; }
}
