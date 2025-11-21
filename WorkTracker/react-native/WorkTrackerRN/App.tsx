// App.tsx
import 'react-native-gesture-handler';
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { AppProvider } from './src/AppContext';
import MonthsListScreen from './src/screens/MonthsListScreen';
import MonthScreen from './src/screens/MonthScreen';
import EntryScreen from './src/screens/EntryScreen';

export type RootStackParamList = {
  MonthsList: undefined;
  Month: { monthId: string };
  Entry: { monthId: string; entryId: string };
};

const Stack = createStackNavigator<RootStackParamList>();

export default function App() {
  return (
    <AppProvider>
      <NavigationContainer>
        <Stack.Navigator initialRouteName="MonthsList" screenOptions={{ headerShown: false }}>
          <Stack.Screen name="MonthsList" component={MonthsListScreen} options={{ title: 'Meses' }} />
          <Stack.Screen name="Month" component={MonthScreen} options={({ route }) => ({ title: 'Folha' })} />
          <Stack.Screen name="Entry" component={EntryScreen} options={{ title: 'Entrada' }} />
        </Stack.Navigator>
      </NavigationContainer>
    </AppProvider>
  );
}
