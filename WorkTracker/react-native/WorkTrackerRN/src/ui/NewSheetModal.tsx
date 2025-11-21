// src/ui/NewSheetModal.tsx
import React, { useContext, useEffect, useState } from 'react';
import { Modal, View, Text, TextInput, TouchableOpacity, StyleSheet } from 'react-native';
import { Picker } from '@react-native-picker/picker';
import { AppContext } from '../AppContext';
import { generateId, startOfMonth, monthDisplayName } from '../models/models';

export default function NewSheetModal({ visible, onClose, onCreate } : {
  visible: boolean;
  onClose: () => void;
  onCreate?: (newMonthId?: string) => void;
}) {
  const ctx = useContext(AppContext)!;
  const current = new Date();
  const [name, setName] = useState('');
  const [selectedMonthNumber, setSelectedMonthNumber] = useState<number>(current.getMonth() + 1);
  const [selectedYear, setSelectedYear] = useState<number>(current.getFullYear());

  useEffect(() => {
    if (visible) {
      const now = new Date();
      setSelectedMonthNumber(now.getMonth() + 1);
      setSelectedYear(now.getFullYear());
      setName('');
    }
  }, [visible]);

  function create() {
    const monthIso = startOfMonth(selectedYear, selectedMonthNumber);
    const finalName = name.trim().length ? name.trim() : monthDisplayName(monthIso);
    const newMonth = {
      id: generateId(),
      month: monthIso,
      entries: [],
      notes: '',
      name: finalName
    };
    ctx.setMonths([ ...ctx.months, newMonth ]);
    onClose();
    if (onCreate) onCreate(newMonth.id);
  }

  const years = Array.from({length: 11}, (_,i) => 2020 + i);

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.backdrop}>
        <View style={styles.container}>
          <Text style={styles.title}>Nova Folha</Text>

          <TextInput placeholder="Nome da folha (opcional)" value={name} onChangeText={setName} style={styles.input} />

          <Text style={{color:'#666', marginBottom:8}}>Período</Text>
          <View style={{flexDirection:'row', justifyContent:'space-between'}}>
            <View style={styles.pickerWrap}>
              <Picker selectedValue={selectedMonthNumber} onValueChange={v => setSelectedMonthNumber(Number(v))}>
                {Array.from({length:12}, (_,i) => i+1).map(m => (
                  <Picker.Item key={m} label={new Date(0,m-1).toLocaleString('pt-PT',{month:'long'})} value={m} />
                ))}
              </Picker>
            </View>

            <View style={styles.pickerWrap}>
              <Picker selectedValue={selectedYear} onValueChange={v => setSelectedYear(Number(v))}>
                {years.map(y => <Picker.Item key={y} label={String(y)} value={y} />)}
              </Picker>
            </View>
          </View>

          <View style={{flexDirection:'row', justifyContent:'flex-end', marginTop:16}}>
            <TouchableOpacity onPress={() => { onClose(); }} style={[styles.btn, {backgroundColor:'#eee', marginRight:8}]}>
              <Text>Cancelar</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={create} style={[styles.btn, {backgroundColor:'#007aff'}]}>
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
  container: { width: 420, backgroundColor:'white', borderRadius:12, padding:18 },
  title: { fontSize:18, fontWeight:'700', marginBottom:8 },
  input: { borderWidth:1, borderColor:'#e6e6e6', borderRadius:8, padding:10, marginBottom:12 },
  pickerWrap: { flex:1, borderWidth:1, borderColor:'#f1f1f1', marginHorizontal:6, borderRadius:8, overflow:'hidden', height:120 },
  btn: { padding:10, borderRadius:8, minWidth:90, alignItems:'center' }
});
