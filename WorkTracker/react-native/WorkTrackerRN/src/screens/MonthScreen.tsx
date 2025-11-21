// src/screens/MonthScreen.tsx
import React, { useContext, useState } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, SafeAreaView } from 'react-native';
import { AppContext } from '../AppContext';
import { entryHours, defaultPeriodFor, generateId, WorkMonth } from '../models/models'; // Added WorkMonth to imports
import { StackNavigationProp } from '@react-navigation/stack';
import { RootStackParamList } from '../../App';
import AddDayModal from '../ui/AddDayModal';
import EditPeriodModal from '../ui/EditPeriodModal';

type NavProp = StackNavigationProp<RootStackParamList, 'Month'>;

// Define a flexible interface for props
interface MonthScreenProps {
  // Optional because they might not be present when embedding directly
  route?: any; 
  navigation?: NavProp; 
  
  // New props for embedding in ContentView
  workMonth?: WorkMonth;
  onUpdate?: (updated: WorkMonth) => void;
}

export default function MonthScreen({ route, navigation, workMonth, onUpdate }: MonthScreenProps) {
  const ctx = useContext(AppContext)!;
  
  // 1. Determine which month to show
  // If 'workMonth' is passed directly, use it. Otherwise, look in context using route.params.id
  let currentMonth: WorkMonth | undefined = workMonth;

  if (!currentMonth && route?.params?.monthId) {
    currentMonth = ctx.months.find(m => m.id === route.params.monthId);
  }

  const [showAddDay, setShowAddDay] = useState(false);
  const [editPeriod, setEditPeriod] = useState<{ entryId:string; periodId:string } | null>(null);

  // Guard clause if no month is found
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

    // 2. Handle the Update
    const updatedMonthData = { 
      ...currentMonth, 
      entries: [...currentMonth.entries, newEntry] 
    };

    if (onUpdate) {
      // Use the callback provided by ContentView
      onUpdate(updatedMonthData);
    } else {
      // Fallback to global context update (Legacy behavior)
      const updatedMonths = ctx.months.map(m => m.id === currentMonth!.id ? updatedMonthData : m);
      ctx.setMonths(updatedMonths);
    }
  }

  function renderEntry(item: any) {
    const e = item;
    const hours = entryHours(e);
    return (
      <TouchableOpacity 
        style={styles.entryRow} 
        onPress={() => {
          // Ensure navigation exists before trying to use it
          if (navigation && currentMonth) {
            navigation.navigate('Entry', { monthId: currentMonth.id, entryId: e.id });
          } else {
            console.log("Navigation not available or implemented for embedded view");
            // Optional: Handle editing in a modal here for web view
          }
        }}
      >
        <View>
          <Text style={{fontWeight:'600'}}>{ new Date(e.day).toLocaleDateString('pt-PT', { day:'2-digit', month:'long' }) }</Text>
          <Text style={{color:'#666', fontSize:12}}>{ e.periods.map((p:any) => `${new Date(p.startTime).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}-${new Date(p.endTime).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}`).join(' | ') }</Text>
        </View>
        <View style={{alignItems:'flex-end'}}>
          <Text style={{fontWeight:'700'}}>€{ (hours * ctx.hourlyRate).toFixed(2) }</Text>
          <Text style={{fontSize:12, color:'#666'}}>{ hours.toFixed(1) }h</Text>
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
          <Text style={{color:'#666'}}>Total Estimado</Text>
          <Text style={{fontSize:18}}>{`€${totalEstimated.toFixed(2)}`}</Text>
        </View>
        <View style={{alignItems:'flex-end'}}>
          <Text style={{color:'#666'}}>Total Atual</Text>
          <Text style={{fontSize:18, color:'#1b8f3b', fontWeight:'700'}}>{`€${totalActual.toFixed(2)}`}</Text>
        </View>
      </View>

      <FlatList
        data={sortedEntries}
        keyExtractor={(i:any)=>i.id}
        renderItem={({item}) => renderEntry(item)}
        contentContainerStyle={{padding:16}}
        ListEmptyComponent={<Text style={{color:'#888', padding:12}}>Sem entradas</Text>}
      />

      <View style={{padding:16}}>
        <TouchableOpacity style={[styles.primaryButton]} onPress={() => { addNextDay(); }}>
          <Text style={{color:'white', fontWeight:'700'}}>Adicionar Próximo Dia</Text>
        </TouchableOpacity>
      </View>

      {/* Ensure Modals use correct ID */}
      <AddDayModal visible={showAddDay} monthId={currentMonth.id} onClose={() => setShowAddDay(false)} />
      {editPeriod && (
        <EditPeriodModal visible={!!editPeriod} monthId={currentMonth.id} entryId={editPeriod.entryId} periodId={editPeriod.periodId} onClose={() => setEditPeriod(null)} />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  header: { padding:16, borderBottomWidth:1, borderBottomColor:'#f1f1f1', backgroundColor:'#fff' },
  title: { fontWeight:'700', fontSize:18 },
  summary: { flexDirection:'row', justifyContent:'space-between', padding:16, backgroundColor:'#fafafa', borderBottomWidth:1, borderBottomColor:'#eee' },
  entryRow: { backgroundColor:'#fff', padding:12, borderRadius:10, marginBottom:10, flexDirection:'row', justifyContent:'space-between', alignItems:'center', shadowColor:'#000', shadowOpacity:0.02, elevation:0.5 },
  primaryButton: { backgroundColor:'#007aff', padding:14, borderRadius:12, alignItems:'center' }
});