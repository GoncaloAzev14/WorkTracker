// src/screens/MonthScreen.tsx
import React, { useContext, useState } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, SafeAreaView } from 'react-native';
import { AppContext } from '../AppContext';
import { entryHours, defaultPeriodFor, generateId, WorkMonth, WorkEntry } from '../models/models';
import AddDayModal from '../ui/AddDayModal';
import DayEditorModal from '../ui/DayEditorModal'; // Import the new modal

// 1. Fix the props interface to accept workMonth directly
interface MonthScreenProps {
  workMonth?: WorkMonth;
  onUpdate?: (updated: WorkMonth) => void;
  route?: any; 
  navigation?: any; 
}

export default function MonthScreen({ route, navigation, workMonth, onUpdate }: MonthScreenProps) {
  const ctx = useContext(AppContext)!;
  
  // Logic to find the correct month data
  let currentMonth: WorkMonth | undefined = workMonth;
  if (!currentMonth && route?.params?.monthId) {
    currentMonth = ctx.months.find(m => m.id === route.params.monthId);
  }

  const [showAddDay, setShowAddDay] = useState(false);
  const [editingEntry, setEditingEntry] = useState<WorkEntry | null>(null); // Track which day we are editing

  if (!currentMonth) {
    return (
      <SafeAreaView style={{flex:1, justifyContent:'center', alignItems:'center'}}>
        <Text style={{color:'#888'}}>Nenhuma folha selecionada.</Text>
      </SafeAreaView>
    );
  }

  const sortedEntries = [...currentMonth.entries].sort((a,b) => new Date(a.day).getTime() - new Date(b.day).getTime());
  const totalEstimated = currentMonth.entries.reduce((s,e) => s + entryHours(e) * ctx.hourlyRate, 0);
  const totalActual = currentMonth.entries.filter(e => e.isPaid).reduce((s,e) => s + entryHours(e) * ctx.hourlyRate, 0);

  // Add a new day logically following the last one
  function addNextDay() {
    if (!currentMonth) return;
    let next: Date;
    
    if (sortedEntries.length === 0) {
      const d = new Date(currentMonth.month);
      d.setDate(1);
      next = d;
    } else {
      next = new Date(sortedEntries[sortedEntries.length - 1].day);
      next.setDate(next.getDate() + 1);
    }

    const defaultPeriod = defaultPeriodFor(next);
    const newEntry = { 
      id: generateId(), 
      day: new Date(next.getFullYear(), next.getMonth(), next.getDate()).toISOString(), 
      periods: [defaultPeriod], 
      isPaid: false 
    };

    saveMonthUpdate({ ...currentMonth, entries: [...currentMonth.entries, newEntry] });
  }

  // Central function to save changes
  function saveMonthUpdate(updatedMonth: WorkMonth) {
    if (onUpdate) {
      onUpdate(updatedMonth);
    } else {
      const updatedMonths = ctx.months.map(m => m.id === updatedMonth.id ? updatedMonth : m);
      ctx.setMonths(updatedMonths);
    }
  }

  function handleEntrySaved(updatedEntry: WorkEntry) {
    if (!currentMonth) return;
    const newEntries = currentMonth.entries.map(e => e.id === updatedEntry.id ? updatedEntry : e);
    saveMonthUpdate({ ...currentMonth, entries: newEntries });
  }

  function renderEntry(item: WorkEntry) {
    const hours = entryHours(item);
    return (
      <TouchableOpacity 
        style={styles.entryRow} 
        onPress={() => setEditingEntry(item)} // Open modal instead of navigating
      >
        <View>
          <Text style={{fontWeight:'600', fontSize:16}}>
            { new Date(item.day).toLocaleDateString('pt-PT', { day:'2-digit', month:'long' }) }
          </Text>
          <View style={{marginTop:4}}>
            {item.periods.length > 0 ? (
               <Text style={{color:'#666', fontSize:12}}>
                 { item.periods.map((p:any) => 
                   `${new Date(p.startTime).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}-${new Date(p.endTime).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}`
                 ).join(' | ') }
               </Text>
            ) : (
              <Text style={{color:'#d32f2f', fontSize:12}}>Sem horário</Text>
            )}
          </View>
        </View>
        <View style={{alignItems:'flex-end'}}>
          <Text style={{fontWeight:'700', fontSize:16}}>€{ (hours * ctx.hourlyRate).toFixed(2) }</Text>
          <Text style={{fontSize:13, color:'#666'}}>{ hours.toFixed(1) }h</Text>
        </View>
      </TouchableOpacity>
    );
  }

  return (
    <SafeAreaView style={{flex:1, backgroundColor:'#fff'}}>
      <View style={styles.header}>
        <Text style={styles.title}>{currentMonth.name}</Text>
        <Text style={{color:'#666'}}>{ new Date(currentMonth.month).toLocaleString('pt-PT', { month:'long', year:'numeric' }) }</Text>
      </View>

      <View style={styles.summary}>
        <View>
          <Text style={{color:'#666', fontSize:12}}>Estimado</Text>
          <Text style={{fontSize:18, fontWeight:'600'}}>{`€${totalEstimated.toFixed(2)}`}</Text>
        </View>
        <View style={{alignItems:'flex-end'}}>
          <Text style={{color:'#666', fontSize:12}}>Ganho</Text>
          <Text style={{fontSize:18, color:'#1b8f3b', fontWeight:'700'}}>{`€${totalActual.toFixed(2)}`}</Text>
        </View>
      </View>

      <FlatList
        data={sortedEntries}
        keyExtractor={(i:any)=>i.id}
        renderItem={({item}) => renderEntry(item)}
        contentContainerStyle={{padding:16, paddingBottom: 100}}
        ListEmptyComponent={<Text style={{color:'#888', padding:20, textAlign:'center'}}>Adicione o primeiro dia abaixo</Text>}
      />

      <View style={styles.fabContainer}>
        <TouchableOpacity style={styles.primaryButton} onPress={addNextDay}>
          <Text style={{color:'white', fontWeight:'bold', fontSize:16}}>+ Adicionar Dia</Text>
        </TouchableOpacity>
      </View>

      <AddDayModal visible={showAddDay} monthId={currentMonth.id} onClose={() => setShowAddDay(false)} />
      
      {/* Inline Editor */}
      <DayEditorModal 
        visible={!!editingEntry} 
        entry={editingEntry}
        onClose={() => setEditingEntry(null)} 
        onSave={handleEntrySaved}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  header: { padding:16, borderBottomWidth:1, borderBottomColor:'#f1f1f1', backgroundColor:'#fff' },
  title: { fontWeight:'800', fontSize:22 },
  summary: { flexDirection:'row', justifyContent:'space-between', padding:16, backgroundColor:'#f9f9f9', borderBottomWidth:1, borderBottomColor:'#eee' },
  entryRow: { backgroundColor:'#fff', padding:14, borderRadius:12, marginBottom:10, flexDirection:'row', justifyContent:'space-between', alignItems:'center', shadowColor:'#000', shadowOpacity:0.03, shadowRadius:4, elevation:2, borderWidth:1, borderColor:'#f0f0f0' },
  fabContainer: { padding:16, position:'absolute', bottom:0, left:0, right:0, backgroundColor:'rgba(255,255,255,0.95)', borderTopWidth:1, borderTopColor:'#eee' },
  primaryButton: { backgroundColor:'#007aff', padding:16, borderRadius:14, alignItems:'center', shadowColor:'#007aff', shadowOpacity:0.3, shadowRadius:5 }
});