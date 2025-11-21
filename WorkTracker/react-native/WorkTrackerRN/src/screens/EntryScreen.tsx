// src/screens/EntryScreen.tsx
import React, { useContext, useEffect, useState } from 'react';
import { View, Text, SafeAreaView, TouchableOpacity, StyleSheet, FlatList } from 'react-native';
import { AppContext } from '../AppContext';
import EditPeriodModal from '../ui/EditPeriodModal';
import { entryHours, entryPay } from '../models/models';

export default function EntryScreen({ route, navigation } : any) {
  const { monthId, entryId } = route.params;
  const ctx = useContext(AppContext)!;
  const month = ctx.months.find(m => m.id === monthId);
  const [entry, setEntry] = useState<any>(null);
  const [showEdit, setShowEdit] = useState(false);
  const [editPeriodId, setEditPeriodId] = useState<string | null>(null);

  useEffect(() => {
    const e = month?.entries.find((x:any) => x.id === entryId) ?? null;
    setEntry(e ? JSON.parse(JSON.stringify(e)) : null);
  }, [ctx.months, monthId, entryId]);

  if (!entry) return <SafeAreaView style={{flex:1,justifyContent:'center',alignItems:'center'}}><Text>Entrada não encontrada</Text></SafeAreaView>;

  return (
    <SafeAreaView style={{flex:1, padding:16}}>
      <Text style={{fontWeight:'700'}}>{new Date(entry.day).toLocaleDateString('pt-PT', { day:'2-digit', month:'long', year:'numeric' })}</Text>
      <FlatList
        data={entry.periods}
        keyExtractor={(p:any)=>p.id}
        renderItem={({item}) => {
          const hours = entryHours({ ...entry, periods:[item] });
          return (
            <TouchableOpacity onPress={() => { setEditPeriodId(item.id); setShowEdit(true); }} style={styles.period}>
              <Text>{new Date(item.startTime).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})} - {new Date(item.endTime).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}</Text>
              <Text>€{(hours * ctx.hourlyRate).toFixed(2)}</Text>
            </TouchableOpacity>
          );
        }}
        ListEmptyComponent={<Text style={{color:'#888'}}>Sem períodos</Text>}
      />

      {editPeriodId && (
        <EditPeriodModal visible={showEdit} monthId={monthId} entryId={entryId} periodId={editPeriodId} onClose={() => { setShowEdit(false); setEditPeriodId(null); }} />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  period: { padding:12, backgroundColor:'#fff', borderRadius:8, marginTop:8, flexDirection:'row', justifyContent:'space-between' }
});
