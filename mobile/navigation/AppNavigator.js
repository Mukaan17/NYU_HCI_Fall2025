import React, { useState, useEffect } from 'react';
import { View, ActivityIndicator, StyleSheet } from 'react-native';
import { NavigationContainer, useNavigationState } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { SafeAreaProvider, useSafeAreaInsets } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useNavigation } from '@react-navigation/native';

import Welcome from '../screens/Welcome';
import Permissions from '../screens/Permissions';
import Dashboard from '../screens/Dashboard';
import Chat from '../screens/Chat';
import Map from '../screens/Map';
import Safety from '../screens/Safety';
import NavBar from '../components/NavBar';
import { spacing } from '../constants/theme';

const Stack = createStackNavigator();
const Tab = createBottomTabNavigator();

// Wrapper component to add NavBar overlay to MainTabs
function MainTabsWithNavBar() {
  const navigation = useNavigation();
  const insets = useSafeAreaInsets();
  
  // Get the current route from the tab navigator
  const routeState = useNavigationState(state => {
    // Find the Main route
    const mainRoute = state?.routes?.find(r => r.name === 'Main');
    // Get the nested tab navigator state
    const tabState = mainRoute?.state;
    // Get the active tab route
    const activeTabRoute = tabState?.routes?.[tabState?.index];
    return activeTabRoute?.name || 'DashboardTab';
  });

  // Map route names to tab IDs
  const getActiveTab = () => {
    if (routeState === 'DashboardTab') return 'dashboard';
    if (routeState === 'ChatTab') return 'chat';
    if (routeState === 'MapTab') return 'map';
    if (routeState === 'SafetyTab') return 'safety';
    return 'dashboard';
  };

  const handleTabPress = (tabId) => {
    if (tabId === 'dashboard') {
      navigation.navigate('DashboardTab');
    } else if (tabId === 'chat') {
      navigation.navigate('ChatTab');
    } else if (tabId === 'map') {
      navigation.navigate('MapTab');
    } else if (tabId === 'safety') {
      navigation.navigate('SafetyTab');
    }
  };

  return (
    <View style={{ flex: 1 }}>
      <MainTabs />
      {/* NavBar overlay - positioned consistently across all screens */}
      <View style={[styles.navBarOverlay, { paddingBottom: insets.bottom }]}>
        <NavBar activeTab={getActiveTab()} onTabPress={handleTabPress} />
      </View>
    </View>
  );
}

function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarStyle: { display: 'none' },
      }}
    >
      <Tab.Screen name="DashboardTab" component={Dashboard} />
      <Tab.Screen name="ChatTab" component={Chat} />
      <Tab.Screen name="MapTab" component={Map} />
      <Tab.Screen name="SafetyTab" component={Safety} />
    </Tab.Navigator>
  );
}

export default function AppNavigator() {
  const [initialRoute, setInitialRoute] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Reset onboarding to start from Welcome screen
    const resetOnboarding = async () => {
      try {
        await AsyncStorage.removeItem('hasSeenWelcome');
        await AsyncStorage.removeItem('hasCompletedPermissions');
        console.log('Onboarding reset - app will start from Welcome screen');
      } catch (error) {
        console.error('Error resetting onboarding:', error);
      }
    };
    
    // Reset onboarding on app start (for development)
    resetOnboarding().then(() => checkOnboardingStatus());
  }, []);

  const checkOnboardingStatus = async () => {
    try {
      const hasSeenWelcome = await AsyncStorage.getItem('hasSeenWelcome');
      const hasCompletedPermissions = await AsyncStorage.getItem('hasCompletedPermissions');

      if (!hasSeenWelcome) {
        setInitialRoute('Welcome');
      } else if (!hasCompletedPermissions) {
        setInitialRoute('Permissions');
      } else {
        setInitialRoute('Main');
      }
    } catch (error) {
      console.error('Error checking onboarding status:', error);
      setInitialRoute('Welcome');
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading || !initialRoute) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#6c63ff" />
      </View>
    );
  }

  return (
    <SafeAreaProvider>
      <NavigationContainer>
        <Stack.Navigator
          initialRouteName={initialRoute}
          screenOptions={{
            headerShown: false,
            animationEnabled: true,
            cardStyleInterpolator: ({ current, next, layouts }) => {
              return {
                cardStyle: {
                  transform: [
                    {
                      translateX: current.progress.interpolate({
                        inputRange: [0, 1],
                        outputRange: [layouts.screen.width, 0],
                      }),
                    },
                  ],
                },
              };
            },
            transitionSpec: {
              open: {
                animation: 'timing',
                config: {
                  duration: 300,
                },
              },
              close: {
                animation: 'timing',
                config: {
                  duration: 300,
                },
              },
            },
          }}
        >
          <Stack.Screen name="Welcome" component={Welcome} />
          <Stack.Screen name="Permissions" component={Permissions} />
          <Stack.Screen name="Main" component={MainTabsWithNavBar} />
        </Stack.Navigator>
      </NavigationContainer>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#0b132b',
  },
  navBarOverlay: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    paddingHorizontal: spacing['2xl'], // 16pt horizontal padding
    paddingTop: spacing['2xl'], // 16pt top padding (Apple standard)
    pointerEvents: 'box-none', // Allow touches to pass through to content below
  },
});

