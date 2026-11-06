import { Ionicons } from '@expo/vector-icons';
import { Tabs } from 'expo-router';
import { useReadySession } from '../../core/session';
import { modules } from '../../modules';
import { colors } from '../../ui/theme';

export default function TabsLayout() {
  const { household } = useReadySession();

  return (
    <Tabs screenOptions={{ headerShown: false, tabBarActiveTintColor: colors.primary }}>
      {modules.map((m) => (
        <Tabs.Screen
          key={m.id}
          name={m.route}
          options={{
            title: m.title,
            href: household.activeModules.includes(m.id) ? undefined : null,
            tabBarIcon: ({ color, size }) => <Ionicons name={m.icon} color={color as string} size={size} />,
          }}
        />
      ))}
      <Tabs.Screen
        name="household"
        options={{
          title: 'Haushalt',
          tabBarIcon: ({ color, size }) => <Ionicons name="home-outline" color={color as string} size={size} />,
        }}
      />
    </Tabs>
  );
}
