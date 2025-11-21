// src/screens/MonthsListScreen.tsx
import React, { useContext, useState } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, SafeAreaView } from 'react-native';
import { AppContext } from '../AppContext';
import { WorkMonth } from '../models/models';
import { entryHours, entryPay, monthDisplayName } from '../models/models';
import NewSheetModal from '../ui/NewSheetModal';
import { StackNavigationProp } from '@react-navigation/stack';
import { RootStackParamList } from '../../App';

type NavProp = StackNavigationProp<RootStackParamList, 'MonthsList'>;

export default function MonthsListScreen({ navigation }: { navigation: NavProp }) {
  const ctx = useContext(AppContext)!;
  const [showNew, setShowNew] = useState(false);

  function renderMonth(item: WorkMonth) {
    const estimated = item.entries.reduce((s, e) => s + entryHours(e) * ctx.hourlyRate, 0);
    const actual = item.entries.filter(e => e.isPaid).reduce((s, e) => s + entryHours(e) * ctx.hourlyRate, 0);

    return (
      <TouchableOpacity style={styles.card} onPress={() => navigation.navigate('Month', { monthId: item.id })}>
        <View style={{flex:1}}>
          <Text style={styles.cardTitle}>{item.name || 'Sem Título'}</Text>
          <Text style={styles.cardSub}>{monthDisplayName(item.month)}</Text>
        </View>

        <View style={{ alignItems:'flex-end' }}>
          <Text style={[styles.actual, actual > 0 ? { color: '#1b8f3b' } : { color: '#1b8f3b' } ]}>
            {actual > 0 ? `€${Math.round(actual)}` : ''}
          </Text>
          <Text style={styles.estimated}>{`€${Math.round(estimated)}`}</Text>
        </View>
      </TouchableOpacity>
    );
  }

  return (
    <SafeAreaView style={{flex:1, backgroundColor:'#f6f7fb'}}>
      <FlatList
        data={[...ctx.months].sort((a,b) => new Date(b.month).getTime() - new Date(a.month).getTime())}
        keyExtractor={m => m.id}
        contentContainerStyle={{ padding: 16, paddingBottom: 140 }}
        renderItem={({item}) => renderMonth(item)}
        ListEmptyComponent={<View style={{padding:24, alignItems:'center'}}><Text style={{color:'#888'}}>Sem folhas</Text></View>}
      />

      <View style={styles.bottomArea}>
        <TouchableOpacity style={styles.primaryButton} onPress={() => setShowNew(true)}>
          <Text style={styles.primaryButtonText}>＋  Nova Folha</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.secondaryButton} onPress={() => { /* open settings modal if you have one */ }}>
          <Text style={styles.secondaryButtonText}>⚙️ Definições</Text>
        </TouchableOpacity>
      </View>

      <NewSheetModal visible={showNew} onClose={() => setShowNew(false)} onCreate={(newMonthId?: string) => {
        setShowNew(false);
        if (newMonthId) {
          // navigate to new month page automatically (Swift behaviour: select new sheet)
          navigation.navigate('Month', { monthId: newMonthId });
        }
      }} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#fff',
    borderRadius: 18,
    padding: 18,
    marginBottom: 12,
    flexDirection: 'row',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOpacity: 0.03,
    shadowRadius: 8,
    elevation: 1
  },
  cardTitle: { fontSize: 16, fontWeight: '700', marginBottom: 6 },
  cardSub: { fontSize: 13, color: '#8b8b8b' },
  actual: { fontWeight: '700', fontSize: 14, color: '#1b8f3b' },
  estimated: { fontSize: 13, color: '#9a9a9a', marginTop: 6 },

  bottomArea: { position: 'absolute', left: 16, right: 16, bottom: 24 },
  primaryButton: { backgroundColor: '#007aff', padding: 16, borderRadius: 12, alignItems:'center' },
  primaryButtonText: { color: 'white', fontWeight:'700', fontSize:16 },
  secondaryButton: { marginTop:12, backgroundColor: '#e9e9ee', padding: 14, borderRadius: 12, alignItems:'center' },
  secondaryButtonText: { color: '#007aff', fontWeight:'600' }
});
