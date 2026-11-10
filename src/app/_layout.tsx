import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { SessionProvider, useSession } from '../core/session';
import { colors } from '../ui/theme';

SplashScreen.preventAutoHideAsync();

function RootNavigator() {
  const { status } = useSession();

  useEffect(() => {
    if (status !== 'loading') SplashScreen.hide();
  }, [status]);

  if (status === 'loading') return null;

  return (
    <Stack screenOptions={{ contentStyle: { backgroundColor: colors.background } }}>
      <Stack.Protected guard={status === 'signedOut'}>
        <Stack.Screen name="sign-in" options={{ headerShown: false }} />
      </Stack.Protected>
      <Stack.Protected guard={status === 'needsPerson'}>
        <Stack.Screen name="who-am-i" options={{ headerShown: false }} />
      </Stack.Protected>
      <Stack.Protected guard={status === 'ready'}>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="catalog" options={{ title: 'Katalog' }} />
        <Stack.Screen name="join" options={{ title: 'Haushalt beitreten', presentation: 'modal' }} />
      </Stack.Protected>
    </Stack>
  );
}

export default function RootLayout() {
  return (
    <SessionProvider>
      <StatusBar style="dark" />
      <RootNavigator />
    </SessionProvider>
  );
}
