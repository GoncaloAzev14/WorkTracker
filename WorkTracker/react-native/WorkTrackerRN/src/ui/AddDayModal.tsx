// src/ui/AddDayModal.tsx
import React, { useContext, useState } from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { AppContext } from '../AppContext';
import { WorkEntry, defaultPeriodFor, generateId } from '../models/models';

export default function AddDayModal({ visible, monthId, onClose } : { visible: boolean; monthId: string | null; onClose: () => void; }) {
  const ctx = useContext(AppContext)!;
  const [date, setDate] = useState(new Date());
  const [showPicker, setShowPicker] = useState(false);

  function addDay() {
    if (!monthId) return onClose();
    const month = ctx.months.find(m => m.id === monthId);
    if (!month) return onClose();

    const entry: WorkEntry = {
      id: generateId(),
      day: new Date(date.getFullYear(), date.getMonth(), date.getDate()).toISOString(),
      periods: [ defaultPeriodFor(date) ],
      isPaid: false
    };
    const updated = ctx.months.map(m => m.id === monthId ? { ...m, entries: [...m.entries, entry] } : m);
    ctx.setMonths(updated);
    onClose();
  }

  return (
    <Modal visible={visible} transparent animationType="fade">
      <View style={styles.backdrop}>
        <View style={styles.container}>
          <Text style={styles.title}>Adicionar Dia</Text>
          <TouchableOpacity onPress={() => setShowPicker(true)} style={styles.dateBtn}>
            <Text>{ date.toLocaleDateString() }</Text>
          </TouchableOpacity>

          {showPicker && (
            <DateTimePicker
              value={date}
              mode="date"
              display="default"
              onChange={(_, d) => { setShowPicker(false); if (d) setDate(d); }}
            />
          )}

          <View style={{flexDirection:'row', justifyContent:'flex-end', marginTop:12}}>
            <TouchableOpacity onPress={onClose} style={[styles.btn, { backgroundColor:'#eee' }]}><Text>Cancelar</Text></TouchableOpacity>
            <TouchableOpacity onPress={addDay} style={[styles.btn, { backgroundColor:'#1976D2', marginLeft:8 }]}><Text style={{color:'white'}}>Adicionar</Text></TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: { flex:1, backgroundColor:'rgba(0,0,0,0.35)', justifyContent:'center', alignItems:'center' },
  container: { width:320, backgroundColor:'white', borderRadius:8, padding:16 },
  title: { fontSize:16, fontWeight:'700', marginBottom:12 },
  dateBtn: { padding:12, borderRadius:6, borderWidth:1, borderColor:'#ddd', alignItems:'center' },
  btn: { padding:10, borderRadius:6 }
});
