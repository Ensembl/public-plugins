const commonColorsToRGBMap = {
  'red'        : { r: 255, g: 0, b: 0 },
  'blue'       : { r: 0, g: 0, b: 250 },
  'green'      : { r: 1, g: 128, b: 0 }, // setting the value of the r channel to 1 instead of 0, because the pdbe molstar plugin has a bug interpreting all colors with r set to 0 as black
  'orange'     : { r: 255, g: 165, b: 0 }
};

export const getHexColor = (a, b) => {
  const red   = sinToHex(a, b,  0 * Math.PI * 2/3); // 0   deg
  const blue  = sinToHex(a, b, 1 * Math.PI * 2/3); // 120 deg
  const green = sinToHex(a, b, 2 * Math.PI * 2/3); // 240 deg

  return `#${red}${green}${blue}`;
};

const sinToHex = (a, b, phase) => {
  const sin = Math.sin(Math.PI / b * 2 * a + phase);
  const intg = Math.floor(sin * 127) + 128;
  const hex = intg.toString(16);

  return hex.length === 1 ? `0${hex}` : hex;
};

export const getRGBFromHex = (hexColor) => {
  if (hexColor in commonColorsToRGBMap) {
    return commonColorsToRGBMap[hexColor];
  }

  const colorAsNumber = parseInt(hexColor.replace('#', ''), 16);
  const red = (colorAsNumber >> 16) & 255;
  const green = (colorAsNumber >> 8) & 255;
  const blue = colorAsNumber & 255;

  return { r: red, g: green, b: blue };
};
