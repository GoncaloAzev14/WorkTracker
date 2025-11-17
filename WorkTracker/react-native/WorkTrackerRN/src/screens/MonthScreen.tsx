// src/screens/MonthScreen.tsx
import React, { useContext, useMemo, useState } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet } from 'react-native';
import type { WorkMonth } from '../models/models';
import { AppContext } from '../AppContext';
import EntryRow from '../components/EntryRow';
import AddDayModal from '../ui/AddDayModal';
import RenameModal from '../ui/RenameModal';
import SettingsModal from '../ui/SettingsModal';
import { generateMonthPDF } from '../utils/PDFGenerator';

export default function MonthScreen({ workMonth, onUpdate } : { workMonth: WorkMonth; onUpdate: (m: WorkMonth) => void; }) {
  const ctx = useContext(AppContext)!;
  const [local, setLocal] = useState(workMonth);
  const [showAddDay, setShowAddDay] = useState(false);
  const [showRename, setShowRename] = useState(false);
  const [showSettings, setShowSettings] = useState(false);

  // keep local in sync when parent changes
  React.useEffect(() => setLocal(workMonth), [workMonth]);

  function updateMonth(m: WorkMonth) {
    setLocal(m);
    onUpdate(m);
  }

  return (
    <View style={{flex:1, padding:12}}>
      <View style={styles.header}>
        <View>
          <Text style={{fontSize:16, fontWeight:'600'}}>{local.name}</Text>
          <Text style={{color:'#666'}}>{ new Date(local.month).toLocaleString('pt-PT',{month:'long', year:'numeric'}) }</Text>
        </View>
        <View style={{flexDirection:'row', alignItems:'center'}}>
          <TouchableOpacity onPress={() => setShowAddDay(true)} style={styles.btn}><Text>+ Dia</Text></TouchableOpacity>
          <TouchableOpacity onPress={() => setShowRename(true)} style={[styles.btn, {marginLeft:8}]}><Text>Renomear</Text></TouchableOpacity>
          <TouchableOpacity onPress={() => setShowSettings(true)} style={[styles.btn, {marginLeft:8}]}><Text>Definições</Text></TouchableOpacity>
        </View>
      </View>

      <FlatList
        data={[...local.entries].sort((a,b)=> new Date(a.day).getTime() - new Date(b.day).getTime())}
        keyExtractor={i => i.id}
        renderItem={({item}) => (
          <EntryRow entry={item} monthId={local.id} onDeleted={() => {
            const entries = local.entries.filter(x => x.id !== item.id);
            const updated = {...local, entries};
            updateMonth(updated);
          }} />
        )}
      />

      <View style={styles.totals}>
        <Text>Total Estimado: €{ local.entries.reduce((s,e)=> s + e.periods.reduce((a,p)=> a + ((new Date(p.endTime).getTime()-new Date(p.startTime).getTime())/3600000) * ctx.hourlyRate,0),0).toFixed(2) }</Text>
      </View>

      <AddDayModal visible={showAddDay} monthId={local.id} onClose={() => setShowAddDay(false)} />
      <RenameModal visible={showRename} month={local} onClose={() => setShowRename(false)} />
      <SettingsModal visible={showSettings} onClose={() => setShowSettings(false)} />

      <TouchableOpacity
        style={styles.btn}
        onPress={() => generateMonthPDF(local, ctx.hourlyRate)}
      >
        <Text>Exportar PDF</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  header: { flexDirection:'row', justifyContent:'space-between', alignItems:'center', marginBottom:12 },
  btn: { padding:8, borderRadius:6, backgroundColor:'#eee' },
  totals: { borderTopWidth:1, borderTopColor:'#eee', paddingTop:12, marginTop:12 }
});
