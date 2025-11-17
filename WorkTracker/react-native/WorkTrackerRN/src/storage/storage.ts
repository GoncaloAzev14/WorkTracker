// src/storage.ts
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { WorkMonth } from '../models/models';

const KEY = 'WorkMonths_v1';

export async function saveMonths(months: WorkMonth[]): Promise<void> {
  try {
    await AsyncStorage.setItem(KEY, JSON.stringify(months));
  } catch (e) {
    console.warn('Failed to save months', e);
  }
}

export async function loadMonths(): Promise<WorkMonth[]> {
  try {
    const raw = await AsyncStorage.getItem(KEY);
    if (!raw) return [];
    return JSON.parse(raw) as WorkMonth[];
  } catch (err) {
    console.warn('Failed to load months (try legacy conversion?)', err);
    return [];
  }
}

// If you have legacy format conversion needed, implement here similar to Swift's loadLegacyMonths.
