// src/screens/ContentView.tsx
import React, { useContext, useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, FlatList, LayoutAnimation, Platform, UIManager } from 'react-native';
import { AppContext } from '../AppContext';
import { WorkMonth, monthDisplayName, generateId, startOfMonth } from '../models/models';
import MonthScreen from './MonthScreen';
import NewSheetModal from '../ui/NewSheetModal';
import SettingsModal from '../ui/SettingsModal';
import RenameModal from '../ui/RenameModal'; // Import the RenameModal

if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

export default function ContentView() {
  const ctx = useContext(AppContext)!;
  const [selectedMonthID, setSelectedMonthID] = useState<string | null>(null);
  const [showNewSheet, setShowNewSheet] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  
  // State for renaming/deleting
  const [monthToRename, setMonthToRename] = useState<WorkMonth | null>(null);

  useEffect(() => {
    if (selectedMonthID && !ctx.months.find(m => m.id === selectedMonthID)) {
      setSelectedMonthID(null);
    }
  }, [ctx.months]);

  const sidebarWidth = ctx.sidebarVisible ? 300 : 0;

  function toggleSidebar() {
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    ctx.setSidebarVisible(!ctx.sidebarVisible);
  }

  function createDefaultMonth() {
    const now = new Date();
    const iso = startOfMonth(now.getFullYear(), now.getMonth() + 1);
    const newMonth: WorkMonth = { id: generateId(), month: iso, entries: [], notes: '', name: monthDisplayName(iso) };
    ctx.setMonths([ ...ctx.months, newMonth ]);
    setSelectedMonthID(newMonth.id);
  }

  return (
    <View style={{flex:1, flexDirection:'row'}}>
      {ctx.sidebarVisible && (
        <View style={[styles.sidebar, { width: sidebarWidth }]}>
          <View style={styles.sidebarHeader}>
            <Text style={styles.title}>Meses</Text>
            <TouchableOpacity onPress={toggleSidebar} style={styles.collapseBtn}>
              <Text style={{fontSize:20}}>⇤</Text>
            </TouchableOpacity>
          </View>

          <FlatList
            data={[...ctx.months].sort((a,b) => new Date(b.month).getTime() - new Date(a.month).getTime())}
            keyExtractor={i => i.id}
            renderItem={({item}) => {
              const hasContent = item.entries.length > 0 || item.notes.trim().length > 0;
              return (
                <TouchableOpacity
                  onPress={() => setSelectedMonthID(item.id)}
                  onLongPress={() => setMonthToRename(item)} // Long press triggers Rename/Delete
                  style={[styles.monthRow, selectedMonthID === item.id ? styles.monthRowActive : null]}
                >
                  <View>
                    <Text style={styles.monthName}>{item.name || 'Sem Título'}</Text>
                    <Text style={styles.monthSubtitle}>{monthDisplayName(item.month)}</Text>
                  </View>
                  <View style={{alignItems:'flex-end'}}>
                    {hasContent && <Text style={{color:'#4caf50', fontSize:10}}>●</Text>}
                  </View>
                </TouchableOpacity>
              );
            }}
            ItemSeparatorComponent={() => <View style={{height:1, backgroundColor:'#f1f1f1'}} />}
          />

          <View style={styles.sidebarFooter}>
            <TouchableOpacity style={styles.primaryBtn} onPress={() => setShowNewSheet(true)}>
              <Text style={{color:'white', fontWeight:'600'}}>Nova Folha</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.secondaryBtn} onPress={() => setShowSettings(true)}>
              <Text style={{color:'#333'}}>Definições</Text>
            </TouchableOpacity>
          </View>
        </View>
      )}

      <View style={{flex:1}}>
        <View style={styles.topBar}>
          {!ctx.sidebarVisible && (
            <TouchableOpacity style={styles.expandBtn} onPress={toggleSidebar}>
              <Text style={{fontSize:20}}>☰</Text>
            </TouchableOpacity>
          )}
          <View style={{flex:1, alignItems:'center'}}>
            <Text style={{fontWeight:'700', fontSize:16}}>
                {selectedMonthID ? (ctx.months.find(m=>m.id===selectedMonthID)?.name ?? 'Folha') : 'WorkTracker'}
            </Text>
          </View>

          <View style={{position:'absolute', right:12}}>
            <TouchableOpacity onPress={createDefaultMonth} style={styles.smallBtn}>
              <Text style={{fontSize:12, fontWeight:'600'}}>+ Atual</Text>
            </TouchableOpacity>
          </View>
        </View>

        <View style={{flex:1, backgroundColor:'#f5f5f5'}}>
          {selectedMonthID ? (
            (() => {
              const m = ctx.months.find(x => x.id === selectedMonthID);
              if (!m) return <EmptyPlaceholder/>;
              return <MonthScreen workMonth={m} onUpdate={(updated)=> {
                const idx = ctx.months.findIndex(x=>x.id===updated.id);
                if (idx >= 0) {
                  const copy = [...ctx.months]; copy[idx] = updated;
                  ctx.setMonths(copy);
                }
              }} />;
            })()
          ) : (
            <EmptyPlaceholder />
          )}
        </View>
      </View>

      <NewSheetModal visible={showNewSheet} onClose={() => setShowNewSheet(false)} />
      <SettingsModal visible={showSettings} onClose={() => setShowSettings(false)} />
      
      {/* Rename Modal Integration */}
      <RenameModal 
        visible={!!monthToRename} 
        month={monthToRename} 
        onClose={() => setMonthToRename(null)} 
      />
    </View>
  );
}

function EmptyPlaceholder() {
  return (
    <View style={{flex:1, justifyContent:'center', alignItems:'center'}}>
      <Text style={{color:'#888'}}>Seleciona uma folha ou cria uma nova</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  sidebar: { backgroundColor:'#fff', borderRightWidth:1, borderRightColor:'#e0e0e0', flexShrink:0 },
  sidebarHeader: { flexDirection:'row', alignItems:'center', justifyContent:'space-between', padding:16, borderBottomWidth:1, borderBottomColor:'#eee' },
  title: { fontSize:20, fontWeight:'800' },
  collapseBtn: { padding:4 },
  monthRow: { padding:14, flexDirection:'row', justifyContent:'space-between', alignItems:'center' },
  monthRowActive: { backgroundColor:'#eef6ff', borderLeftWidth:3, borderLeftColor:'#007aff' },
  monthName: { fontWeight:'600', fontSize:15 },
  monthSubtitle: { color:'#666', fontSize:13, marginTop:2 },
  sidebarFooter: { padding:16, gap:10, borderTopWidth:1, borderTopColor:'#eee' },
  primaryBtn: { backgroundColor:'#007aff', padding:14, borderRadius:10, alignItems:'center' },
  secondaryBtn: { backgroundColor:'#f5f5f5', padding:14, borderRadius:10, alignItems:'center' },
  topBar: { height:50, borderBottomWidth:1, borderBottomColor:'#e0e0e0', alignItems:'center', justifyContent:'center', flexDirection:'row', backgroundColor:'#fff' },
  expandBtn: { padding:12, marginLeft:4 },
  smallBtn: { paddingHorizontal:12, paddingVertical:6, backgroundColor:'#eee', borderRadius:16 }
})