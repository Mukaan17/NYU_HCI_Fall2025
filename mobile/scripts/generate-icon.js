/**
 * @Author: Mukhil Sundararaj
 * @Date:   2025-11-19 15:36:58
 * @Last Modified by:   Mukhil Sundararaj
 * @Last Modified time: 2025-11-19 17:19:21
 */
const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const svgPath = path.join(__dirname, '../media/App Icon.svg');
const pngPath = path.join(__dirname, '../media/App Icon.png');

async function convertSvgToPng() {
  try {
    // Convert SVG to PNG at 1024x1024 (iOS app icon size)
    await sharp(svgPath)
      .resize(1024, 1024, {
        fit: 'contain',
        background: { r: 0, g: 0, b: 0, alpha: 0 } // Transparent background
      })
      .png()
      .toFile(pngPath);
    
    console.log('✅ Successfully converted App Icon.svg to App Icon.png (1024x1024)');
  } catch (error) {
    console.error('❌ Error converting SVG to PNG:', error);
    process.exit(1);
  }
}

convertSvgToPng();

