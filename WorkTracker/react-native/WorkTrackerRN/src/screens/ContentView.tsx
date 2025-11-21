// src/screens/ContentView.tsx
import React, { useContext, useMemo, useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, FlatList, Animated, LayoutAnimation, Platform, UIManager } from 'react-native';
import { AppContext } from '../AppContext';
import { WorkMonth, monthDisplayName, generateId, startOfMonth } from '../models/models';
import MonthScreen from './MonthScreen';
import NewSheetModal from '../ui/NewSheetModal';

// LayoutAnimation on Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

export default function ContentView() {
  const ctx = useContext(AppContext)!;
  const [selectedMonthID, setSelectedMonthID] = useState<string | null>(null);
  const [showNewSheet, setShowNewSheet] = useState(false);

  // ensure selection remains valid after months change
  useEffect(() => {
    if (selectedMonthID && !ctx.months.find(m => m.id === selectedMonthID)) {
      setSelectedMonthID(null);
    }
  }, [ctx.months]);

  const sidebarWidth = ctx.sidebarVisible ? 320 : 0;

  function toggleSidebar() {
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    ctx.setSidebarVisible(!ctx.sidebarVisible);
  }

  function createDefaultMonth() {
    // helper to create a new month for current month (same default behavior as Swift's bottom button)
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
              <Text>⇤</Text>
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
                  onLongPress={() => {
                    // open rename modal (reuse NewSheetModal or a rename modal you already have)
                    // For brevity here we'll just set selection
                    setSelectedMonthID(item.id);
                  }}
                  style={[styles.monthRow, selectedMonthID === item.id ? styles.monthRowActive : null]}
                >
                  <View>
                    <Text style={styles.monthName}>{item.name || 'Sem Título'}</Text>
                    <Text style={styles.monthSubtitle}>{monthDisplayName(item.month)}</Text>
                  </View>
                  <View style={{alignItems:'flex-end'}}>
                    {hasContent ? <Text style={{color:'green'}}>●</Text> : null}
                  </View>
                </TouchableOpacity>
              );
            }}
            ItemSeparatorComponent={() => <View style={{height:1, backgroundColor:'#f1f1f1'}} />}
          />

          <View style={styles.sidebarFooter}>
            <TouchableOpacity style={styles.primaryBtn} onPress={() => { setShowNewSheet(true); }}>
              <Text style={{color:'white'}}>Nova Folha</Text>
            </TouchableOpacity>

            <TouchableOpacity style={[styles.secondaryBtn, { marginTop:8 }]} onPress={() => ctx.setSidebarVisible(false)}>
              <Text>Ocultar Painel</Text>
            </TouchableOpacity>
          </View>
        </View>
      )}

      <View style={{flex:1}}>
        <View style={styles.topBar}>
          {!ctx.sidebarVisible && (
            <TouchableOpacity style={styles.expandBtn} onPress={toggleSidebar}>
              <Text>☰</Text>
            </TouchableOpacity>
          )}
          <View style={{flex:1, alignItems:'center'}}>
            <Text style={{fontWeight:'700'}}>{selectedMonthID ? (ctx.months.find(m=>m.id===selectedMonthID)?.name ?? 'Folha') : 'Seleciona uma folha'}</Text>
          </View>

          <View style={{position:'absolute', right:12}}>
            <TouchableOpacity onPress={() => {
              // quick add default month (same as Swift bottom action)
              createDefaultMonth();
            }} style={styles.smallBtn}>
              <Text>+Mês</Text>
            </TouchableOpacity>
          </View>
        </View>

        <View style={{flex:1}}>
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
    </View>
  );
}

function EmptyPlaceholder() {
  return (
    <View style={{flex:1, justifyContent:'center', alignItems:'center'}}>
      <Text style={{color:'#888'}}>Seleciona uma folha</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  sidebar: { backgroundColor:'#fafafa', borderRightWidth:1, borderRightColor:'#eee', flexShrink:0 },
  sidebarHeader: { flexDirection:'row', alignItems:'center', justifyContent:'space-between', padding:12 },
  title: { fontSize:18, fontWeight:'700' },
  collapseBtn: { padding:8 },
  monthRow: { padding:12, flexDirection:'row', justifyContent:'space-between', alignItems:'center' },
  monthRowActive: { backgroundColor:'#eef6ff' },
  monthName: { fontWeight:'600' },
  monthSubtitle: { color:'#666', fontSize:12 },
  sidebarFooter: { padding:12 },
  primaryBtn: { backgroundColor:'#1976D2', padding:12, borderRadius:8, alignItems:'center' },
  secondaryBtn: { padding:10, borderRadius:8, alignItems:'center', backgroundColor:'#eee' },
  topBar: { height:56, borderBottomWidth:1, borderBottomColor:'#f1f1f1', alignItems:'center', justifyContent:'center', flexDirection:'row' },
  expandBtn: { padding:10, marginLeft:8 },
  smallBtn: { padding:6, backgroundColor:'#eee', borderRadius:6 }
})