// src/screens/EntryScreen.tsx
import React, { useContext, useEffect, useMemo, useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Alert, FlatList } from 'react-native';
import { AppContext } from '../AppContext';
import type { WorkEntry, WorkPeriod } from '../models/models';
import { generateId, defaultPeriodFor } from '../models/models';
import EditPeriodModal from '../ui/EditPeriodModal';

export default function EntryScreen({ route, navigation } : {
  route: { params: { monthId: string; entryId: string } };
  navigation: any;
}) {
  const { monthId, entryId } = route.params;
  const ctx = useContext(AppContext)!;

  const [entry, setEntry] = useState<WorkEntry | null>(null);
  const [editPeriodId, setEditPeriodId] = useState<string | null>(null);
  const [showEditModal, setShowEditModal] = useState(false);

  // find month & entry whenever context changes
  useEffect(() => {
    const month = ctx.months.find(m => m.id === monthId);
    const e = month?.entries.find(x => x.id === entryId) ?? null;
    setEntry(e ? JSON.parse(JSON.stringify(e)) : null); // clone to local state
  }, [ctx.months, monthId, entryId]);

  // derived values
  const totalHours = useMemo(() => {
    if (!entry) return 0;
    return entry.periods.reduce((acc, p) => {
      const s = new Date(p.startTime).getTime();
      const e = new Date(p.endTime).getTime();
      return acc + Math.max(0, (e - s) / 3600000);
    }, 0);
  }, [entry]);

  const totalPay = useMemo(() => totalHours * ctx.hourlyRate, [totalHours, ctx.hourlyRate]);

  function persistLocalEntry(updatedEntry: WorkEntry) {
    // write back to context (persist)
    const updatedMonths = ctx.months.map(m => {
      if (m.id !== monthId) return m;
      return {
        ...m,
        entries: m.entries.map(en => en.id === updatedEntry.id ? updatedEntry : en)
      };
    });
    ctx.setMonths(updatedMonths);
  }

  function togglePaid(v: boolean) {
    if (!entry) return;
    const updated = { ...entry, isPaid: v };
    setEntry(updated);
    persistLocalEntry(updated);
  }

  function addDefaultPeriod() {
    if (!entry) return;
    const newPeriod: WorkPeriod = defaultPeriodFor(new Date(entry.day));
    newPeriod.id = generateId();
    const updated = { ...entry, periods: [...entry.periods, newPeriod] };
    setEntry(updated);
    persistLocalEntry(updated);
  }

  function deleteEntry() {
    Alert.alert('Apagar Entrada', 'Tem a certeza que pretende apagar esta entrada?', [
      { text: 'Cancelar', style: 'cancel' },
      {
        text: 'Apagar',
        style: 'destructive',
        onPress: () => {
          const updatedMonths = ctx.months.map(m => {
            if (m.id !== monthId) return m;
            return { ...m, entries: m.entries.filter(e => e.id !== entryId) };
          });
          ctx.setMonths(updatedMonths);
          navigation.goBack();
        }
      }
    ]);
  }

  function openEditPeriod(periodId: string) {
    setEditPeriodId(periodId);
    setShowEditModal(true);
  }

  if (!entry) {
    return (
      <View style={styles.empty}>
        <Text style={{ color: '#666' }}>Entrada não encontrada.</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Dia: {new Date(entry.day).toLocaleDateString('pt-PT', { day: '2-digit', month: '2-digit', year: 'numeric' })}</Text>
        <Text style={styles.subtitle}>Hora total: {totalHours.toFixed(2)} h  •  €{totalPay.toFixed(2)}</Text>
      </View>

      <View style={styles.actionsRow}>
        <TouchableOpacity style={styles.actionBtn} onPress={() => togglePaid(!entry.isPaid)}>
          <Text>{entry.isPaid ? 'Desmarcar Pago' : 'Marcar Como Pago'}</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.actionBtn} onPress={addDefaultPeriod}>
          <Text>+ Período</Text>
        </TouchableOpacity>

        <TouchableOpacity style={[styles.actionBtn, { backgroundColor: '#FFCDD2' }]} onPress={deleteEntry}>
          <Text style={{ color: '#b00020' }}>Apagar Entrada</Text>
        </TouchableOpacity>
      </View>

      <Text style={styles.sectionTitle}>Períodos</Text>

      <FlatList
        data={[...entry.periods].sort((a,b) => new Date(a.startTime).getTime() - new Date(b.startTime).getTime())}
        keyExtractor={(p) => p.id}
        renderItem={({ item }) => {
          const s = new Date(item.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
          const e = new Date(item.endTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
          const hours = Math.max(0, (new Date(item.endTime).getTime() - new Date(item.startTime).getTime())/3600000);
          return (
            <TouchableOpacity style={styles.periodRow} onPress={() => openEditPeriod(item.id)}>
              <View>
                <Text style={styles.periodTime}>{s} — {e}</Text>
                <Text style={styles.periodSub}>{hours.toFixed(2)} h</Text>
              </View>
              <View style={{ alignItems: 'flex-end' }}>
                <Text style={styles.periodPay}>€{(hours * ctx.hourlyRate).toFixed(2)}</Text>
                <Text style={{ fontSize: 12, color: '#666' }}>Tocar para editar</Text>
              </View>
            </TouchableOpacity>
          );
        }}
        ListEmptyComponent={<Text style={{ color: '#666', padding: 12 }}>Sem períodos — adiciona um.</Text>}
      />

      {editPeriodId && (
        <EditPeriodModal
          visible={showEditModal}
          monthId={monthId}
          entryId={entryId}
          periodId={editPeriodId}
          onClose={() => {
            setShowEditModal(false);
            setEditPeriodId(null);
            // refresh local entry from context (in case modal changed it)
            const month = ctx.months.find(m => m.id === monthId);
            const updatedEntry = month?.entries.find(e => e.id === entryId) ?? null;
            setEntry(updatedEntry ? JSON.parse(JSON.stringify(updatedEntry)) : null);
          }}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: '#fff' },
  empty: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  header: { marginBottom: 12 },
  title: { fontSize: 18, fontWeight: '700' },
  subtitle: { color: '#666', marginTop: 4 },
  actionsRow: { flexDirection: 'row', gap: 8, marginBottom: 12 },
  actionBtn: { padding: 10, backgroundColor: '#eee', borderRadius: 8, marginRight: 8 },
  sectionTitle: { fontWeight: '700', marginBottom: 8, marginTop: 8 },
  periodRow: { padding: 12, borderRadius: 8, backgroundColor: '#fafafa', marginBottom: 8, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  periodTime: { fontWeight: '600' },
  periodSub: { color: '#666', fontSize: 12 },
  periodPay: { fontWeight: '700' }
});
