// src/ui/NewSheetModal.tsx
import React, { useContext, useState } from 'react';
import { Modal, View, Text, TextInput, TouchableOpacity, StyleSheet } from 'react-native';
import { AppContext } from '../AppContext';
import { WorkMonth, generateId } from '../models/models';

export default function NewSheetModal({ visible, onClose } : { visible: boolean; onClose: () => void; }) {
  const ctx = useContext(AppContext)!;
  const [name, setName] = useState<string>('');

  function createMonth() {
    const monthDate = new Date();
    const firstOfMonth = new Date(monthDate.getFullYear(), monthDate.getMonth(), 1).toISOString();
    const newMonth: WorkMonth = {
      id: generateId(),
      month: firstOfMonth,
      entries: [],
      name: name.trim() || `Folha ${new Date().toLocaleString()}`,
      notes: ''
    };
    ctx.setMonths([ ...ctx.months, newMonth ]);
    setName('');
    onClose();
  }

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.backdrop}>
        <View style={styles.container}>
          <Text style={styles.title}>Nova Folha</Text>
          <TextInput
            placeholder="Nome da Folha"
            value={name}
            onChangeText={setName}
            style={styles.input}
            autoFocus
          />
          <View style={styles.actions}>
            <TouchableOpacity onPress={onClose} style={[styles.btn, styles.btnCancel]}>
              <Text>Cancelar</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={createMonth} style={[styles.btn, styles.btnOk]}>
              <Text style={{color:'white'}}>Criar</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: { flex:1, backgroundColor:'rgba(0,0,0,0.35)', justifyContent:'center', alignItems:'center' },
  container: { width: 320, backgroundColor:'white', borderRadius:8, padding:16 },
  title: { fontSize:18, fontWeight:'700', marginBottom:8 },
  input: { borderWidth:1, borderColor:'#ddd', borderRadius:6, padding:8, marginBottom:12 },
  actions: { flexDirection:'row', justifyContent:'flex-end' },
  btn: { padding:10, borderRadius:6, marginLeft:8 },
  btnCancel: { backgroundColor:'#f1f1f1' },
  btnOk: { backgroundColor:'#1976D2' }
});
