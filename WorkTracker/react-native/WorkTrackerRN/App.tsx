// App.tsx
import React from 'react';
import { SafeAreaView, StatusBar } from 'react-native';
import { AppProvider } from './src/AppContext';
import ContentView from './src/screens/ContentView';

export default function App() {
  return (
    <AppProvider>
      <SafeAreaView style={{flex:1}}>
        <StatusBar barStyle="dark-content" />
        <ContentView />
      </SafeAreaView>
    </AppProvider>
  );
}
