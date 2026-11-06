import fs from 'node:fs';
import path from 'node:path';
import type { ConfigContext, ExpoConfig } from 'expo/config';

// Zwei Firebase-Projekte: `development` (Tests, Emulator) und `production` (echte Liste).
// Die Variante wird über APP_VARIANT gesetzt (eas.json setzt sie pro Build-Profil).
const variant = process.env.APP_VARIANT === 'production' ? 'production' : 'development';
const isProd = variant === 'production';

const googleServicesFile = `./firebase/${isProd ? 'prod' : 'dev'}/google-services.json`;

/** Web-Client-ID (OAuth client_type 3) aus google-services.json, nötig für Google Sign-In + Firebase Auth. */
function readWebClientId(file: string): string | undefined {
  const fullPath = path.resolve(__dirname, file);
  if (!fs.existsSync(fullPath)) return undefined;
  const json = JSON.parse(fs.readFileSync(fullPath, 'utf8'));
  const clients: { client_id: string; client_type: number }[] = json.client?.[0]?.oauth_client ?? [];
  return clients.find((c) => c.client_type === 3)?.client_id;
}

const easProjectId = process.env.EAS_PROJECT_ID;

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...config,
  name: isProd ? 'Fling' : 'Fling (dev)',
  slug: 'fling',
  scheme: 'fling',
  version: '1.0.0',
  orientation: 'portrait',
  icon: './assets/images/icon.png',
  userInterfaceStyle: 'light',
  runtimeVersion: { policy: 'appVersion' },
  updates: easProjectId ? { url: `https://u.expo.dev/${easProjectId}` } : undefined,
  android: {
    package: isProd ? 'de.garritfra.fling' : 'de.garritfra.fling.dev',
    googleServicesFile,
    adaptiveIcon: {
      backgroundColor: '#E6F4FE',
      foregroundImage: './assets/images/android-icon-foreground.png',
      backgroundImage: './assets/images/android-icon-background.png',
      monochromeImage: './assets/images/android-icon-monochrome.png',
    },
  },
  plugins: [
    'expo-router',
    '@react-native-firebase/app',
    '@react-native-firebase/auth',
    '@react-native-google-signin/google-signin',
  ],
  experiments: { typedRoutes: true },
  extra: {
    variant,
    googleWebClientId: readWebClientId(googleServicesFile),
    eas: easProjectId ? { projectId: easProjectId } : undefined,
  },
});
