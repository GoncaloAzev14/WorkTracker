// src/screens/MonthScreen.tsx
import React, { useContext, useState } from 'react';
import { 
  View, Text, FlatList, TouchableOpacity, StyleSheet, SafeAreaView, 
  TextInput, LayoutAnimation, Platform, UIManager, KeyboardAvoidingView, Alert
} from 'react-native';
import { AppContext } from '../AppContext';
import { entryHours, defaultPeriodFor, generateId, WorkMonth, WorkEntry } from '../models/models';
import AddDayModal from '../ui/AddDayModal';
import DayEditorModal from '../ui/DayEditorModal';
import { exportMonthToPDF } from '../utils/PDFGenerator'; // <--- IMPORTAR ISTO

if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

interface MonthScreenProps {
  workMonth?: WorkMonth;
  onUpdate?: (updated: WorkMonth) => void;
  route?: any;
  navigation?: any;
}

export default function MonthScreen({ route, navigation, workMonth, onUpdate }: MonthScreenProps) {
  const ctx = useContext(AppContext)!;
  
  let currentMonth: WorkMonth | undefined = workMonth;
  if (!currentMonth && route?.params?.monthId) {
    currentMonth = ctx.months.find(m => m.id === route.params.monthId);
  }

  const [showAddDay, setShowAddDay] = useState(false);
  const [editingEntry, setEditingEntry] = useState<WorkEntry | null>(null);
  const [notesOpen, setNotesOpen] = useState(false);

  if (!currentMonth) {
    return (
      <View style={{flex:1, justifyContent:'center', alignItems:'center'}}>
        <Text style={{color:'#888'}}>Nenhuma folha selecionada.</Text>
      </View>
    );
  }

  const sortedEntries = [...currentMonth.entries].sort((a,b) => new Date(a.day).getTime() - new Date(b.day).getTime());
  const totalEstimated = currentMonth.entries.reduce((s,e) => s + entryHours(e) * ctx.hourlyRate, 0);
  const totalActual = currentMonth.entries.filter(e => e.isPaid).reduce((s,e) => s + entryHours(e) * ctx.hourlyRate, 0);

  const allPaid = sortedEntries.length > 0 && sortedEntries.every(e => e.isPaid);

  // --- ACTIONS ---

  function saveUpdate(updatedMonth: WorkMonth) {
    if (onUpdate) {
      onUpdate(updatedMonth);
    } else {
      const copy = ctx.months.map(m => m.id === updatedMonth.id ? updatedMonth : m);
      ctx.setMonths(copy);
    }
  }

  function togglePaid(entry: WorkEntry) {
    if (!currentMonth) return;
    const updatedEntry = { ...entry, isPaid: !entry.isPaid };
    const newEntries = currentMonth.entries.map(e => e.id === entry.id ? updatedEntry : e);
    saveUpdate({ ...currentMonth, entries: newEntries });
  }

  function toggleSelectAll() {
    if (!currentMonth) return;
    const newValue = !allPaid;
    const newEntries = currentMonth.entries.map(e => ({ ...e, isPaid: newValue }));
    saveUpdate({ ...currentMonth, entries: newEntries });
  }

  function updateNotes(text: string) {
    if (!currentMonth) return;
    saveUpdate({ ...currentMonth, notes: text });
  }

  function toggleNotesSection() {
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    setNotesOpen(!notesOpen);
  }

  // FUNÇÃO DE EXPORTAR PDF
  async function handleExportPDF() {
    if (currentMonth) {
      await exportMonthToPDF(currentMonth, ctx.hourlyRate);
    }
  }

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
    const newEntry: WorkEntry = { 
      id: generateId(), 
      day: new Date(next.getFullYear(), next.getMonth(), next.getDate()).toISOString(), 
      periods: [defaultPeriod], 
      isPaid: false 
    };

    saveUpdate({ ...currentMonth, entries: [...currentMonth.entries, newEntry] });
  }

  // --- RENDERERS ---

  const renderEntry = ({ item }: { item: WorkEntry }) => {
    const hours = entryHours(item);
    return (
      <TouchableOpacity style={styles.card} onPress={() => setEditingEntry(item)}>
        <TouchableOpacity onPress={(e) => { e.stopPropagation(); togglePaid(item); }} style={styles.checkBtn}>
          <Text style={[styles.checkIcon, item.isPaid ? styles.checkIconActive : styles.checkIconInactive]}>
            {item.isPaid ? '✓' : '○'}
          </Text>
        </TouchableOpacity>

        <View style={{flex:1, marginLeft: 10}}>
          <Text style={[styles.cardDate, item.isPaid && {color:'#2e7d32'}]}>
            {new Date(item.day).toLocaleDateString('pt-PT', {day:'2-digit', month:'long'})}
          </Text>
          <Text style={styles.cardTime}>
            {item.periods.length > 0 
              ? item.periods.map(p => `${new Date(p.startTime).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}-${new Date(p.endTime).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}`).join(', ')
              : 'Sem horário'
            }
          </Text>
        </View>

        <View style={{alignItems:'flex-end'}}>
          <Text style={[styles.cardPrice, item.isPaid && {color:'#2e7d32'}]}>
            €{(hours * ctx.hourlyRate).toFixed(2)}
          </Text>
          <Text style={styles.cardHours}>{hours.toFixed(1)}h</Text>
        </View>
      </TouchableOpacity>
    );
  };

  return (
    <SafeAreaView style={{flex:1, backgroundColor:'#fff'}}>
      {/* HEADER */}
      <View style={styles.header}>
        <View style={{flex:1}}>
          <Text style={styles.title}>{currentMonth.name}</Text>
          <Text style={styles.subtitle}>{ new Date(currentMonth.month).toLocaleString('pt-PT', { month:'long', year:'numeric' }) }</Text>
        </View>
        
        {/* Botões de Ação no Topo */}
        <View style={{flexDirection:'row', alignItems:'center'}}>
            {/* Botão Exportar PDF */}
            <TouchableOpacity onPress={handleExportPDF} style={[styles.headerBtn, { marginRight: 16 }]}>
                <Text style={{fontSize:24}}>📄</Text>
                <Text style={{fontSize:10, color:'#007aff', fontWeight:'600'}}>PDF</Text>
            </TouchableOpacity>

            {/* Botão Selecionar Tudo */}
            <TouchableOpacity onPress={toggleSelectAll} style={styles.headerBtn}>
                <Text style={{fontSize:24, color:'#007aff'}}>
                    {allPaid ? '☑' : '☐'}
                </Text>
                <Text style={{fontSize:10, color:'#007aff', fontWeight:'600'}}>
                    {allPaid ? 'Todos' : 'Todos'}
                </Text>
            </TouchableOpacity>
        </View>
      </View>

      {/* SUMMARY */}
      <View style={styles.summary}>
        <View>
          <Text style={styles.summaryLabel}>Estimado</Text>
          <Text style={styles.summaryValue}>{`€${totalEstimated.toFixed(2)}`}</Text>
        </View>
        <View style={{alignItems:'flex-end'}}>
          <Text style={styles.summaryLabel}>Pago</Text>
          <Text style={[styles.summaryValue, {color:'#2e7d32'}]}>{`€${totalActual.toFixed(2)}`}</Text>
        </View>
      </View>

      {/* LIST OF DAYS */}
      <FlatList
        data={sortedEntries}
        keyExtractor={(i)=>i.id}
        renderItem={renderEntry}
        contentContainerStyle={{padding:16}}
        ListEmptyComponent={<Text style={{textAlign:'center', color:'#999', marginTop:20}}>Sem dias registados</Text>}
        style={{flex:1}} 
      />

      {/* FIXED FOOTER AREA */}
      <KeyboardAvoidingView 
        behavior={Platform.OS === "ios" ? "padding" : undefined} 
        keyboardVerticalOffset={ Platform.OS === "ios" ? 60 : 0 }
        style={styles.footerContainer}
      >
        <TouchableOpacity style={styles.addButton} onPress={addNextDay}>
          <Text style={styles.addButtonText}>+ Adicionar Dia</Text>
        </TouchableOpacity>

        <View style={styles.notesSection}>
          <TouchableOpacity onPress={toggleNotesSection} style={styles.notesHeader}>
            <Text style={styles.notesTitle}>Notas</Text>
            <Text style={{color:'#666'}}>{notesOpen ? '▼' : '▲'}</Text>
          </TouchableOpacity>
          
          {notesOpen && (
            <View style={styles.notesBody}>
              <TextInput
                style={styles.notesInput}
                multiline
                placeholder="Escreva observações..."
                value={currentMonth?.notes || ''}
                onChangeText={updateNotes}
              />
            </View>
          )}
        </View>
      </KeyboardAvoidingView>

      <AddDayModal visible={showAddDay} monthId={currentMonth.id} onClose={()=>setShowAddDay(false)} />
      
      <DayEditorModal 
        visible={!!editingEntry} 
        entry={editingEntry} 
        onClose={() => setEditingEntry(null)}
        onSave={(updated) => {
            if (!currentMonth) return;
            const newEntries = currentMonth.entries.map(e => e.id === updated.id ? updated : e);
            saveUpdate({ ...currentMonth, entries: newEntries });
        }}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  header: { padding:16, borderBottomWidth:1, borderBottomColor:'#eee', backgroundColor:'white', flexDirection:'row', justifyContent:'space-between', alignItems:'center' },
  title: { fontSize:20, fontWeight:'800' },
  subtitle: { color:'#666', marginTop:2 },
  headerBtn: { alignItems:'center', justifyContent:'center' },
  
  summary: { flexDirection:'row', justifyContent:'space-between', padding:16, backgroundColor:'#f9f9f9', borderBottomWidth:1, borderBottomColor:'#eee' },
  summaryLabel: { fontSize:12, color:'#666', textTransform:'uppercase' },
  summaryValue: { fontSize:18, fontWeight:'700', marginTop:2 },
  
  card: { backgroundColor:'white', padding:14, borderRadius:12, marginBottom:10, flexDirection:'row', alignItems:'center', borderWidth:1, borderColor:'#f0f0f0', shadowColor:'#000', shadowOpacity:0.05, shadowRadius:3, elevation:2 },
  cardDate: { fontSize:16, fontWeight:'600' },
  cardTime: { fontSize:12, color:'#666', marginTop:4 },
  cardPrice: { fontSize:16, fontWeight:'700' },
  cardHours: { fontSize:12, color:'#666' },

  checkBtn: { padding: 4 },
  checkIcon: { fontSize: 22, fontWeight: 'bold' },
  checkIconActive: { color: '#2e7d32' },
  checkIconInactive: { color: '#ccc' },

  // FIXED FOOTER STYLES
  footerContainer: { 
    backgroundColor:'white', 
    borderTopWidth:1, 
    borderTopColor:'#eee', 
    padding:16,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: -3 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 5,
  },
  addButton: { 
    backgroundColor:'#007aff', 
    padding:14, 
    borderRadius:12, 
    alignItems:'center', 
    marginBottom:12 
  },
  addButtonText: { color:'white', fontWeight:'bold', fontSize:16 },
  
  notesSection: { 
    backgroundColor: '#f5f5f5', 
    borderRadius: 10, 
    overflow: 'hidden' 
  },
  notesHeader: { 
    flexDirection: 'row', 
    justifyContent: 'space-between', 
    padding: 12, 
    backgroundColor: '#eee' 
  },
  notesTitle: { fontWeight: 'bold', color: '#555' },
  notesBody: { padding: 12 },
  notesInput: { fontSize: 16, color: '#333', minHeight: 60, textAlignVertical: 'top' },
});