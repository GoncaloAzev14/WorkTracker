// src/screens/ContentView.tsx
import React, { useContext, useMemo, useState } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet } from 'react-native';
import { AppContext } from '../AppContext';
import { WorkMonth } from '../models/models';
import MonthScreen from './MonthScreen';
import NewSheetModal from '../ui/NewSheetModal';
import RenameModal from '../ui/RenameModal';
import SettingsModal from '../ui/SettingsModal';

export default function ContentView() {
  const ctx = useContext(AppContext)!;
  const [selectedMonthId, setSelectedMonthId] = useState<string | null>(null);
  const [showNew, setShowNew] = useState(false);
  const [showRename, setShowRename] = useState(false);
  const [renameTarget, setRenameTarget] = useState<WorkMonth | null>(null);
  const months = ctx.months;

  const selectedMonth = useMemo(() => months.find(m => m.id === selectedMonthId) ?? null, [months, selectedMonthId]);

  return (
    <View style={{flex:1, flexDirection:'row'}}>
      <View style={styles.sidebar}>
        <Text style={styles.title}>Meses ({months.length})</Text>
        <FlatList
          data={[...months].sort((a,b) => new Date(b.month).getTime() - new Date(a.month).getTime())}
          keyExtractor={i => i.id}
          renderItem={({item}) => (
            <TouchableOpacity onPress={() => setSelectedMonthId(item.id)} onLongPress={() => { setRenameTarget(item); setShowRename(true); }}>
              <View style={styles.monthRow}>
                <Text style={styles.monthName}>{item.name || 'Sem Título'}</Text>
                <Text style={styles.monthSubtitle}>{new Date(item.month).toLocaleString('pt-PT',{month:'long', year:'numeric'})}</Text>
              </View>
            </TouchableOpacity>
          )}
        />
        <TouchableOpacity style={styles.addBtn} onPress={() => setShowNew(true)}>
          <Text style={{color:'white'}}>+ Nova Folha</Text>
        </TouchableOpacity>
      </View>

      <View style={{flex:1}}>
        {selectedMonth ? (
          <MonthScreen workMonth={selectedMonth} onUpdate={(m)=> {
            // update month in context
            const idx = ctx.months.findIndex(x => x.id === m.id);
            if (idx >= 0) {
              const newMonths = [...ctx.months];
              newMonths[idx] = m;
              ctx.setMonths(newMonths);
            }
          }} />
        ) : (
          <View style={{flex:1, justifyContent:'center', alignItems:'center'}}>
            <Text style={{color:'#888'}}>Seleciona uma folha</Text>
          </View>
        )}
      </View>

      <NewSheetModal visible={showNew} onClose={()=>setShowNew(false)} />
      <RenameModal visible={showRename} month={renameTarget} onClose={()=>setShowRename(false)} />
      <SettingsModal onClose={function (): void {
        throw new Error('Function not implemented.');
      } } />
    </View>
  );
}

const styles = StyleSheet.create({
  sidebar: { width:320, borderRightWidth:1, borderRightColor:'#eee', padding:12 },
  title: { fontSize:18, fontWeight:'700', marginBottom:8 },
  monthRow: { paddingVertical:8, borderBottomWidth:1, borderBottomColor:'#f1f1f1' },
  monthName: { fontSize:14 },
  monthSubtitle: { fontSize:12, color:'#777' },
  addBtn: { marginTop:12, backgroundColor:'#1976D2', padding:12, alignItems:'center', borderRadius:8 }
});
