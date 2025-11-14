export const colors = {
  // Background colors
  background: '#0b132b',
  backgroundSecondary: '#0d1630',
  backgroundCard: '#1c2541',
  backgroundCardDark: '#151e38',
  backgroundOverlay: 'rgba(11,19,43,0.95)',
  
  // Gradient colors
  gradientStart: '#6c63ff',
  gradientEnd: '#8b7fff',
  gradientBlueStart: '#38c4fc',
  gradientBlueEnd: '#76caf5',
  
  // Text colors
  textPrimary: '#ffffff',
  textSecondary: '#a9b4d1',
  textAccent: '#cbb8ff',
  textBlue: '#68d4ff',
  textError: '#ff3b30',
  
  // UI colors
  border: 'rgba(255,255,255,0.1)',
  borderLight: 'rgba(255,255,255,0.05)',
  borderMedium: 'rgba(255,255,255,0.2)',
  
  // Accent colors
  accentPurple: 'rgba(108,99,255,0.1)',
  accentPurpleMedium: 'rgba(108,99,255,0.2)',
  accentBlue: 'rgba(104,212,255,0.1)',
  accentBlueMedium: 'rgba(104,212,255,0.2)',
  accentPurpleText: 'rgba(203,184,255,0.1)',
  accentError: 'rgba(255,59,48,0.1)',
  accentErrorMedium: 'rgba(255,59,48,0.2)',
  accentErrorBorder: 'rgba(255,59,48,0.5)',
  
  // Glass effect
  glassBackground: 'rgba(28,37,65,0.6)',
  glassBackgroundLight: 'rgba(28,37,65,0.8)',
  glassBackgroundDark: 'rgba(21,30,56,0.6)',
  glassBackgroundDarkLight: 'rgba(21,30,56,0.8)',
  
  // White overlays
  whiteOverlay: 'rgba(255,255,255,0.05)',
  whiteOverlayLight: 'rgba(255,255,255,0.1)',
  whiteOverlayMedium: 'rgba(255,255,255,0.2)',
};

export const typography = {
  fontWeight: {
    regular: '400',
    medium: '500',
    semiBold: '600',
    bold: '700',
  },
  fontSize: {
    xs: 12,
    sm: 13,
    base: 14,
    md: 15,
    lg: 16,
    xl: 17,
    '2xl': 20,
    '3xl': 32,
  },
  lineHeight: {
    tight: 18,
    normal: 19.5,
    relaxed: 21,
    loose: 22,
    xl: 24,
    '2xl': 26,
    '3xl': 38.4,
  },
};

export const spacing = {
  xs: 4,
  sm: 6,
  md: 8,
  lg: 10,
  xl: 12,
  '2xl': 16,
  '3xl': 20,
  '4xl': 24,
  '5xl': 40,
  '6xl': 48,
};

export const borderRadius = {
  sm: 6.8,
  md: 16,
  lg: 24,
  xl: 48,
  full: 1000, // Pill shape
};

export const shadows = {
  // Primary button shadow
  primary: {
    shadowColor: '#6c63ff',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.3,
    shadowRadius: 15,
    elevation: 10,
  },
  // Card shadow
  card: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.25,
    shadowRadius: 12,
    elevation: 8,
  },
  // Message bubble shadow
  message: {
    shadowColor: '#6c63ff',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 6,
    elevation: 4,
  },
};

export const blur = {
  light: 20,
  medium: 80,
  heavy: 100,
  xl: 120,
};

