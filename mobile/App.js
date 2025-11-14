import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { Platform } from 'react-native';
import AppNavigator from './navigation/AppNavigator';

export default function App() {
  return (
    <>
      <StatusBar 
        style="light" 
        translucent={Platform.OS === 'android'}
        backgroundColor="transparent"
      />
      <AppNavigator />
    </>
  );
}
