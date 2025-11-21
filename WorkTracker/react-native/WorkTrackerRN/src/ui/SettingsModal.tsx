// src/ui/SettingsModal.tsx
import React, { useContext, useState, useEffect } from 'react';
import { 
  Modal, View, Text, TextInput, TouchableOpacity, StyleSheet, 
  Keyboard, Pressable 
} from 'react-native';
import { AppContext } from '../AppContext';

export default function SettingsModal({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  const ctx = useContext(AppContext);
  const [rate, setRate] = useState('5.0');

  useEffect(() => {
    if (visible && ctx) {
      setRate(String(ctx.hourlyRate));
    }
  }, [visible, ctx]);

  function handleSave() {
    if (ctx) {
      const val = parseFloat(rate.replace(',', '.'));
      if (!isNaN(val)) {
        ctx.setHourlyRate(val);
      }
    }
    onClose();
  }

  // Prevent the modal from not rendering if context is briefly missing
  // We just render with default/current state if ctx is null
  
  return (
    <Modal 
      visible={visible} 
      animationType="fade" 
      transparent={true}
      onRequestClose={onClose}
    >
      {/* Use Pressable for the backdrop to strictly handle the 'close' action */}
      <Pressable style={styles.backdrop} onPress={onClose}>
        <Pressable 
          style={styles.container} 
          onPress={(e) => e.stopPropagation()} // Stop click from reaching backdrop
        >
          <TouchableOpacity activeOpacity={1} onPress={Keyboard.dismiss} style={{width:'100%'}}>
            <Text style={styles.title}>Definições</Text>
            
            <View style={styles.inputContainer}>
              <Text style={styles.label}>Valor Hora (€)</Text>
              <TextInput 
                style={styles.input} 
                value={rate}
                onChangeText={setRate}
                keyboardType="decimal-pad"
                selectTextOnFocus
                autoFocus={false} // Disable autoFocus temporarily to prevent glitches
              />
            </View>

            <View style={styles.footer}>
              <TouchableOpacity onPress={onClose} style={[styles.btn, styles.btnCancel]}>
                <Text style={styles.textCancel}>Cancelar</Text>
              </TouchableOpacity>
              <TouchableOpacity onPress={handleSave} style={[styles.btn, styles.btnSave]}>
                <Text style={styles.textSave}>Guardar</Text>
              </TouchableOpacity>
            </View>
          </TouchableOpacity>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', alignItems: 'center' },
  container: { width: '85%', maxWidth: 320, backgroundColor: 'white', borderRadius: 16, padding: 24, shadowColor: '#000', shadowOffset: {width:0, height:4}, shadowOpacity:0.25, shadowRadius:10, elevation:5 },
  title: { fontSize: 20, fontWeight: 'bold', marginBottom: 20, textAlign: 'center', color: '#333' },
  inputContainer: { marginBottom: 24 },
  label: { fontSize: 14, color: '#666', marginBottom: 8, textTransform:'uppercase', letterSpacing:0.5 },
  input: { fontSize: 24, borderBottomWidth: 2, borderBottomColor: '#007aff', paddingVertical: 8, textAlign: 'center', color: '#333', fontWeight:'600' },
  footer: { flexDirection: 'row', justifyContent: 'space-between', gap: 12 },
  btn: { flex: 1, paddingVertical: 12, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
  btnCancel: { backgroundColor: '#f5f5f5' },
  btnSave: { backgroundColor: '#007aff' },
  textCancel: { color: '#666', fontWeight: '600' },
  textSave: { color: 'white', fontWeight: '600' }
});