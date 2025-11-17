// src/ui/SettingsModal.tsx
import React, { useContext, useState } from 'react';
import { Modal, View, Text, TextInput, TouchableOpacity, StyleSheet } from 'react-native';
import { AppContext } from '../AppContext';

export default function SettingsModal({ visible, onClose } : { visible?: boolean; onClose: () => void; }) {
  const ctx = useContext(AppContext)!;
  const [rate, setRate] = useState<string>(String(ctx.hourlyRate));

  function save() {
    const parsed = parseFloat(rate.replace(',', '.')) || 0;
    ctx.setHourlyRate(parsed);
    onClose();
  }

  return (
    <Modal visible={!!visible} animationType="slide" transparent>
      <View style={styles.backdrop}>
        <View style={styles.container}>
          <Text style={styles.title}>Definições</Text>
          <Text>Taxa por Hora (€)</Text>
          <TextInput style={styles.input} value={rate} onChangeText={setRate} keyboardType="decimal-pad" />
          <View style={{flexDirection:'row', justifyContent:'flex-end'}}>
            <TouchableOpacity onPress={onClose} style={[styles.btn, { backgroundColor:'#eee' }]}><Text>Cancelar</Text></TouchableOpacity>
            <TouchableOpacity onPress={save} style={[styles.btn, { backgroundColor:'#1976D2', marginLeft:8 }]}><Text style={{color:'white'}}>Guardar</Text></TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: { flex:1, backgroundColor:'rgba(0,0,0,0.35)', justifyContent:'center', alignItems:'center' },
  container: { width:320, backgroundColor:'white', borderRadius:8, padding:16 },
  title: { fontSize:16, fontWeight:'700', marginBottom:8 },
  input: { borderWidth:1, borderColor:'#ddd', borderRadius:6, padding:8, marginVertical:12 },
  btn: { padding:10, borderRadius:6 }
});
