// src/ui/DayEditorModal.tsx
import React, { useState, useEffect } from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet, TextInput, ScrollView, Alert } from 'react-native';
import { WorkEntry, WorkPeriod, defaultPeriodFor } from '../models/models';

interface DayEditorModalProps {
  visible: boolean;
  onClose: () => void;
  entry: WorkEntry | null;
  onSave: (updatedEntry: WorkEntry) => void;
}

export default function DayEditorModal({ visible, onClose, entry, onSave }: DayEditorModalProps) {
  const [periods, setPeriods] = useState<WorkPeriod[]>([]);

  useEffect(() => {
    if (entry) {
      // Create a copy of the periods so we don't edit the original until "Save" is clicked
      setPeriods(entry.periods.map(p => ({ ...p })));
    }
  }, [entry]);

  if (!entry) return null;

  const handleSave = () => {
    onSave({ ...entry, periods: periods });
    onClose();
  };

  const addPeriod = () => {
    // Smart default: Start 1 hour after the last period ends, or 9:00 if empty
    let startHour = 9;
    if (periods.length > 0) {
      const last = periods[periods.length - 1];
      startHour = new Date(last.endTime).getHours() + 1;
    }
    
    const baseDate = new Date(entry.day);
    const newP = defaultPeriodFor(baseDate);
    
    const s = new Date(newP.startTime); s.setHours(startHour, 0);
    const e = new Date(newP.endTime); e.setHours(startHour + 1, 0);
    
    newP.startTime = s.toISOString();
    newP.endTime = e.toISOString();
    
    setPeriods([...periods, newP]);
  };

  const removePeriod = (id: string) => {
    setPeriods(periods.filter(p => p.id !== id));
  };

  const updateTime = (id: string, field: 'startTime' | 'endTime', text: string) => {
    // Simple parser for HH:mm input
    const [hh, mm] = text.split(':').map(Number);
    if (isNaN(hh) || isNaN(mm)) return;

    setPeriods(periods.map(p => {
      if (p.id === id) {
        const d = new Date(p[field]);
        d.setHours(hh);
        d.setMinutes(mm);
        return { ...p, [field]: d.toISOString() };
      }
      return p;
    }));
  };

  const formatTime = (iso: string) => {
    const d = new Date(iso);
    return `${d.getHours().toString().padStart(2,'0')}:${d.getMinutes().toString().padStart(2,'0')}`;
  };

  return (
    <Modal animationType="slide" transparent={true} visible={visible} onRequestClose={onClose}>
      <View style={styles.centeredView}>
        <View style={styles.modalView}>
          <View style={styles.header}>
            <Text style={styles.title}>Editar Dia</Text>
            <TouchableOpacity onPress={onClose}><Text style={styles.closeLink}>Cancelar</Text></TouchableOpacity>
          </View>

          <ScrollView style={{marginTop:10}}>
            {periods.length === 0 ? (
              <Text style={{color:'#999', fontStyle:'italic', textAlign:'center', padding:20}}>Sem horários registados.</Text>
            ) : (
              periods.map((p, index) => (
                <View key={p.id} style={styles.periodRow}>
                  <View style={styles.timeBlock}>
                    <Text style={styles.label}>Início</Text>
                    <TextInput 
                      style={styles.input} 
                      defaultValue={formatTime(p.startTime)}
                      maxLength={5}
                      keyboardType="numeric"
                      onEndEditing={(e) => updateTime(p.id, 'startTime', e.nativeEvent.text)}
                    />
                  </View>
                  <Text style={{fontSize:20, color:'#ccc'}}>→</Text>
                  <View style={styles.timeBlock}>
                    <Text style={styles.label}>Fim</Text>
                    <TextInput 
                      style={styles.input} 
                      defaultValue={formatTime(p.endTime)}
                      maxLength={5}
                      keyboardType="numeric"
                      onEndEditing={(e) => updateTime(p.id, 'endTime', e.nativeEvent.text)}
                    />
                  </View>
                  <TouchableOpacity onPress={() => removePeriod(p.id)} style={styles.deleteBtn}>
                    <Text style={{color:'white', fontWeight:'bold'}}>×</Text>
                  </TouchableOpacity>
                </View>
              ))
            )}
            
            <TouchableOpacity style={styles.addBtn} onPress={addPeriod}>
              <Text style={{color:'#007aff', fontWeight:'600'}}>+ Adicionar Horário</Text>
            </TouchableOpacity>
          </ScrollView>

          <TouchableOpacity style={styles.saveBtn} onPress={handleSave}>
            <Text style={{color:'white', fontWeight:'bold', fontSize:16}}>Guardar</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  centeredView: { flex:1, justifyContent:'flex-end', backgroundColor:'rgba(0,0,0,0.5)' },
  modalView: { backgroundColor:'white', borderTopLeftRadius:20, borderTopRightRadius:20, padding:20, height:'60%' },
  header: { flexDirection:'row', justifyContent:'space-between', alignItems:'center', marginBottom:10 },
  title: { fontSize:20, fontWeight:'bold' },
  closeLink: { color:'#007aff', fontSize:16 },
  periodRow: { flexDirection:'row', alignItems:'center', justifyContent:'space-between', marginBottom:12, backgroundColor:'#f9f9f9', padding:10, borderRadius:10 },
  timeBlock: { alignItems:'center' },
  label: { fontSize:10, color:'#888', marginBottom:4 },
  input: { fontSize:18, fontWeight:'600', borderBottomWidth:1, borderColor:'#ddd', textAlign:'center', minWidth:60, padding:4 },
  deleteBtn: { backgroundColor:'#ff3b30', width:30, height:30, borderRadius:15, justifyContent:'center', alignItems:'center', marginLeft:10 },
  addBtn: { padding:15, alignItems:'center', borderStyle:'dashed', borderWidth:1, borderColor:'#007aff', borderRadius:10, marginTop:10, marginBottom:20 },
  saveBtn: { backgroundColor:'#007aff', padding:16, borderRadius:12, alignItems:'center' }
});