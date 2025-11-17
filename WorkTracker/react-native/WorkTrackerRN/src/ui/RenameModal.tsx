// src/ui/RenameModal.tsx
import React, { useContext, useEffect, useState } from 'react';
import { Modal, View, Text, TextInput, TouchableOpacity, StyleSheet } from 'react-native';
import { WorkMonth } from '../models/models';
import { AppContext } from '../AppContext';

export default function RenameModal({ visible, month, onClose } : { visible: boolean; month: WorkMonth | null; onClose: () => void; }) {
  const ctx = useContext(AppContext)!;
  const [name, setName] = useState('');

  useEffect(() => {
    setName(month?.name ?? '');
  }, [month, visible]);

  function rename() {
    if (!month) return onClose();
    const updated = ctx.months.map(m => m.id === month.id ? { ...m, name: name || m.name } : m);
    ctx.setMonths(updated);
    onClose();
  }

  function remove() {
    if (!month) return onClose();
    const filtered = ctx.months.filter(m => m.id !== month.id);
    ctx.setMonths(filtered);
    onClose();
  }

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.backdrop}>
        <View style={styles.container}>
          <Text style={styles.title}>Renomear / Apagar</Text>
          <TextInput style={styles.input} value={name} onChangeText={setName} />
          <View style={{flexDirection:'row', justifyContent:'space-between'}}>
            <TouchableOpacity onPress={remove} style={[styles.btn, { backgroundColor:'#FFCDD2' }]}>
              <Text>Apagar Folha</Text>
            </TouchableOpacity>
            <View style={{flexDirection:'row'}}>
              <TouchableOpacity onPress={onClose} style={[styles.btn, { backgroundColor:'#eee', marginRight:8 }]}>
                <Text>Cancelar</Text>
              </TouchableOpacity>
              <TouchableOpacity onPress={rename} style={[styles.btn, { backgroundColor:'#1976D2' }]}>
                <Text style={{color:'white'}}>Renomear</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: { flex:1, backgroundColor:'rgba(0,0,0,0.35)', justifyContent:'center', alignItems:'center' },
  container: { width: 340, backgroundColor:'white', borderRadius:8, padding:16 },
  title: { fontSize:16, fontWeight:'700', marginBottom:8 },
  input: { borderWidth:1, borderColor:'#ddd', borderRadius:6, padding:8, marginBottom:12 },
  btn: { padding:10, borderRadius:6, minWidth:100, alignItems:'center' }
});
