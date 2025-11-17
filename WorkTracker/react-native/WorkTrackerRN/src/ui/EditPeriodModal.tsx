// src/ui/EditPeriodModal.tsx
import React, { useEffect, useState, useContext } from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import type { WorkMonth, WorkEntry, WorkPeriod } from '../models/models';
import { AppContext } from '../AppContext';

export default function EditPeriodModal({ visible, monthId, entryId, periodId, onClose } : {
  visible: boolean;
  monthId: string | null;
  entryId: string | null;
  periodId: string | null;
  onClose: () => void;
}) {
  const ctx = useContext(AppContext)!;
  const [start, setStart] = useState<Date | null>(null);
  const [end, setEnd] = useState<Date | null>(null);
  const [showPicker, setShowPicker] = useState<'start'|'end'|null>(null);

  useEffect(() => {
    if (!monthId || !entryId || !periodId) return;
    const m = ctx.months.find(x => x.id === monthId);
    const e = m?.entries.find(x => x.id === entryId);
    const p = e?.periods.find(x => x.id === periodId);
    if (p) {
      setStart(new Date(p.startTime));
      setEnd(new Date(p.endTime));
    }
  }, [visible, monthId, entryId, periodId]);

  function save() {
    if (!monthId || !entryId || !periodId || !start || !end) return onClose();
    const updatedMonths = ctx.months.map(m => {
      if (m.id !== monthId) return m;
      return {
        ...m,
        entries: m.entries.map(e => {
          if (e.id !== entryId) return e;
          return {
            ...e,
            periods: e.periods.map(p => p.id === periodId ? { ...p, startTime: start.toISOString(), endTime: end.toISOString() } : p)
          };
        })
      };
    });
    ctx.setMonths(updatedMonths);
    onClose();
  }

  function removePeriod() {
    if (!monthId || !entryId || !periodId) return onClose();
    const updatedMonths = ctx.months.map(m => {
      if (m.id !== monthId) return m;
      return {
        ...m,
        entries: m.entries.map(e => {
          if (e.id !== entryId) return e;
          return { ...e, periods: e.periods.filter(p => p.id !== periodId) };
        })
      };
    });
    ctx.setMonths(updatedMonths);
    onClose();
  }

  return (
    <Modal visible={visible} transparent animationType="slide">
      <View style={styles.backdrop}>
        <View style={styles.container}>
          <Text style={styles.title}>Editar Período</Text>

          <TouchableOpacity onPress={() => setShowPicker('start')} style={styles.dtButton}>
            <Text>Início: {start ? start.toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'}) : '-'}</Text>
          </TouchableOpacity>

          <TouchableOpacity onPress={() => setShowPicker('end')} style={styles.dtButton}>
            <Text>Fim: {end ? end.toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'}) : '-'}</Text>
          </TouchableOpacity>

          {showPicker && (
            <DateTimePicker
              value={ showPicker === 'start' ? (start ?? new Date()) : (end ?? new Date()) }
              mode="time"
              display="default"
              onChange={(_, d) => {
                setShowPicker(null);
                if (!d) return;
                if (showPicker === 'start') setStart(d);
                else setEnd(d);
              }}
            />
          )}

          <View style={{flexDirection:'row', justifyContent:'space-between', marginTop:12}}>
            <TouchableOpacity onPress={removePeriod} style={[styles.btn, { backgroundColor:'#FFCDD2' }]}>
              <Text>Apagar Período</Text>
            </TouchableOpacity>
            <View style={{flexDirection:'row'}}>
              <TouchableOpacity onPress={onClose} style={[styles.btn, { backgroundColor:'#eee', marginRight:8 }]}><Text>Cancelar</Text></TouchableOpacity>
              <TouchableOpacity onPress={save} style={[styles.btn, { backgroundColor:'#1976D2' }]}><Text style={{color:'white'}}>Guardar</Text></TouchableOpacity>
            </View>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: { flex:1, backgroundColor:'rgba(0,0,0,0.35)', justifyContent:'center', alignItems:'center' },
  container: { width:340, backgroundColor:'white', borderRadius:8, padding:16 },
  title: { fontSize:16, fontWeight:'700', marginBottom:10 },
  dtButton: { padding:10, borderRadius:6, borderWidth:1, borderColor:'#eee', marginBottom:8 },
  btn: { padding:10, borderRadius:6, minWidth:90, alignItems:'center' }
});
