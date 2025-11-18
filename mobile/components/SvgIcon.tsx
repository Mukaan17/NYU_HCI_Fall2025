import React from "react";
import { StyleProp, ViewStyle } from "react-native";

const icons: Record<string, any> = {
  temp: require("../media/temp.svg").default,
  clock: require("../media/clock.svg").default,
  icon: require("../media/icon.svg").default,
  chat: require("../media/chat.svg").default,
  home: require("../media/home.svg").default,
  map: require("../media/map.svg").default,
  safety: require("../media/safety.svg").default,
};

export default function SvgIcon({
  name,
  size = 24,
  color = "#FFF",
  style,
}: {
  name: keyof typeof icons;
  size?: number;
  color?: string;
  style?: StyleProp<ViewStyle>;
}) {
  const IconComponent = icons[name];

  if (!IconComponent) {
    console.warn(`❌ SvgIcon: '${name}' not found.`);
    return null;
  }

  return (
    <IconComponent
      width={size}
      height={size}
      fill={color}
      // Some SVGs use stroke instead of fill
      stroke={color}
      style={style}
    />
  );
}

