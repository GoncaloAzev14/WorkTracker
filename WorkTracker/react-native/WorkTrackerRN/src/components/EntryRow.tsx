// src/components/EntryRow.tsx
import React, { useState, useContext } from 'react';
import { View, Text, Switch, TouchableOpacity, StyleSheet } from 'react-native';
import type { WorkEntry, WorkPeriod } from '../models/models';
import { AppContext } from '../AppContext';
import { defaultPeriodFor, generateId } from '../models/models';
import EditPeriodModal from '../ui/EditPeriodModal';

export default function EntryRow({ entry, monthId, onDeleted } : {
  entry: WorkEntry;
  monthId: string;
  onDeleted?: () => void;
}) {

  const ctx = useContext(AppContext)!;

  const [editPeriodId, setEditPeriodId] = useState<string | null>(null);
  const [showEdit, setShowEdit] = useState(false);

  function togglePaid(v: boolean) {
    const updated = ctx.months.map(m => {
      if (m.id !== monthId) return m;

      return {
        ...m,
        entries: m.entries.map(e =>
          e.id === entry.id ? { ...e, isPaid: v } : e
        )
      };
    });

    ctx.setMonths(updated);
  }

  function addPeriod() {
    const newP: WorkPeriod = defaultPeriodFor(new Date(entry.day));
    newP.id = generateId();

    const updated = ctx.months.map(m => {
      if (m.id !== monthId) return m;

      return {
        ...m,
        entries: m.entries.map(e =>
          e.id === entry.id ? { ...e, periods: [...e.periods, newP] } : e
        )
      };
    });

    ctx.setMonths(updated);
  }

  function deleteEntry() {
    const updated = ctx.months.map(m => {
      if (m.id !== monthId) return m;
      return {
        ...m,
        entries: m.entries.filter(e => e.id !== entry.id)
      };
    });

    ctx.setMonths(updated);
    onDeleted?.();
  }

  function openEdit(pId: string) {
    setEditPeriodId(pId);
    setShowEdit(true);
  }

  const hours = entry.periods.reduce((acc,p) => {
    const s = new Date(p.startTime).getTime();
    const e = new Date(p.endTime).getTime();
    return acc + Math.max(0,(e-s)/3600000);
  }, 0);

  return (
    <View style={styles.container}>
      
      <View style={{flex:1}}>
        <Text style={styles.dateText}>
          { new Date(entry.day).toLocaleDateString('pt-PT',{ day:'2-digit', month:'2-digit', year:'numeric' }) }
        </Text>

        <View style={{flexDirection:'row', flexWrap:'wrap'}}>
          {entry.periods.map(period => (
            <TouchableOpacity
              key={period.id}
              onPress={() => openEdit(period.id)}
              style={styles.periodBox}
            >
              <Text style={styles.periodText}>
                {new Date(period.startTime).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}
                {' - '}
                {new Date(period.endTime).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      <View style={styles.right}>
        <Text style={styles.hours}>{hours.toFixed(1)}h</Text>
        <Text style={styles.price}>€{ (hours * ctx.hourlyRate).toFixed(2) }</Text>

        <Switch value={entry.isPaid} onValueChange={togglePaid} style={{marginVertical:4}} />

        <TouchableOpacity onPress={addPeriod}>
          <Text style={styles.actionText}>+ Período</Text>
        </TouchableOpacity>

        <TouchableOpacity onPress={deleteEntry}>
          <Text style={[styles.actionText, {color:'red'}]}>Apagar</Text>
        </TouchableOpacity>
      </View>

      {editPeriodId && (
        <EditPeriodModal
          visible={showEdit}
          monthId={monthId}
          entryId={entry.id}
          periodId={editPeriodId}
          onClose={() => { setShowEdit(false); setEditPeriodId(null); }}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding:12,
    borderBottomWidth:1,
    borderBottomColor:'#eee',
    flexDirection:'row'
  },
  dateText: {
    fontWeight:'600',
    marginBottom:4
  },
  periodBox: {
    backgroundColor:'#f1f1f1',
    paddingVertical:4,
    paddingHorizontal:6,
    borderRadius:6,
    marginRight:6,
    marginBottom:6
  },
  periodText: {
    fontSize:12
  },
  right: {
    alignItems:'flex-end'
  },
  hours: {
    fontWeight:'600'
  },
  price: {
    fontWeight:'700',
    marginBottom:4
  },
  actionText: {
    fontSize:12,
    marginTop:4
  }
});
