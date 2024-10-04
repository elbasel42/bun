const RGBA = "RGBA";
const LAB = "LAB";
const SRGB = "SRGB";
const HSL = "HSL";
const HWB = "HWB";
const SRGBLinear = "SRGBLinear";
const P3 = "P3";
const A98 = "A98";
const ProPhoto = "ProPhoto";
const Rec2020 = "Rec2020";
const XYZd50 = "XYZd50";
const XYZd65 = "XYZd65";
const LCH = "LCH";
const OKLAB = "OKLAB";
const OKLCH = "OKLCH";
const color_spaces = [
  RGBA,
  LAB,
  SRGB,
  HSL,
  HWB,
  SRGBLinear,
  P3,
  A98,
  ProPhoto,
  Rec2020,
  XYZd50,
  XYZd65,
  LCH,
  OKLAB,
  OKLCH,
];

type ColorSpaces =
  | typeof RGBA
  | typeof LAB
  | typeof SRGB
  | typeof HSL
  | typeof HWB
  | typeof SRGBLinear
  | typeof P3
  | typeof A98
  | typeof ProPhoto
  | typeof Rec2020
  | typeof XYZd50
  | typeof XYZd65
  | typeof LCH
  | typeof OKLAB
  | typeof OKLCH;

type Foo = "a" | "b";

let code: Map<ColorSpaces, string[]> = new Map();

initColorSpaces();
addConversions();
await generateCode();

function initColorSpaces() {
  for (const space of color_spaces as ColorSpaces[]) {
    code.set(space, []);
  }
}

async function generateCode() {
  const output = `//!This file is generated by \`color_via.ts\`. Do not edit it directly!
const color = @import("./color.zig");
const RGBA = color.RGBA;
const LAB = color.LAB;
const LCH = color.LCH;
const SRGB = color.SRGB;
const HSL = color.HSL;
const HWB = color.HWB;
const SRGBLinear = color.SRGBLinear;
const P3 = color.P3;
const A98 = color.A98;
const ProPhoto = color.ProPhoto;
const XYZd50 = color.XYZd50;
const XYZd65 = color.XYZd65;
const OKLAB = color.OKLAB;
const OKLCH = color.OKLCH;
const Rec2020 = color.Rec2020;

pub const generated_color_conversions = struct {
${(() => {
  let result = "";
  for (const [space, functions] of code) {
    result += "\n";
    result += `pub const convert_${space} = struct {\n`;
    result += functions.join("\n");
    result += "\n};";
  }
  return result;
})()}
};`;
  await Bun.$`echo ${output} > src/css/values/color_generated.zig; zig fmt src/css/values/color_generated.zig
`;
}

function addConversions() {
  // Once Rust specialization is stable, this could be simplified.
  via("LAB", "XYZd50", "XYZd65");
  via("ProPhoto", "XYZd50", "XYZd65");
  via("OKLCH", "OKLAB", "XYZd65");

  via("LAB", "XYZd65", "OKLAB");
  via("LAB", "XYZd65", "OKLCH");
  via("LAB", "XYZd65", "SRGB");
  via("LAB", "XYZd65", "SRGBLinear");
  via("LAB", "XYZd65", "P3");
  via("LAB", "XYZd65", "A98");
  via("LAB", "XYZd65", "ProPhoto");
  via("LAB", "XYZd65", "Rec2020");
  via("LAB", "XYZd65", "HSL");
  via("LAB", "XYZd65", "HWB");

  via("LCH", "LAB", "XYZd65");
  via("LCH", "XYZd65", "OKLAB");
  via("LCH", "XYZd65", "OKLCH");
  via("LCH", "XYZd65", "SRGB");
  via("LCH", "XYZd65", "SRGBLinear");
  via("LCH", "XYZd65", "P3");
  via("LCH", "XYZd65", "A98");
  via("LCH", "XYZd65", "ProPhoto");
  via("LCH", "XYZd65", "Rec2020");
  via("LCH", "XYZd65", "XYZd50");
  via("LCH", "XYZd65", "HSL");
  via("LCH", "XYZd65", "HWB");

  via("SRGB", "SRGBLinear", "XYZd65");
  via("SRGB", "XYZd65", "OKLAB");
  via("SRGB", "XYZd65", "OKLCH");
  via("SRGB", "XYZd65", "P3");
  via("SRGB", "XYZd65", "A98");
  via("SRGB", "XYZd65", "ProPhoto");
  via("SRGB", "XYZd65", "Rec2020");
  via("SRGB", "XYZd65", "XYZd50");

  via("P3", "XYZd65", "SRGBLinear");
  via("P3", "XYZd65", "OKLAB");
  via("P3", "XYZd65", "OKLCH");
  via("P3", "XYZd65", "A98");
  via("P3", "XYZd65", "ProPhoto");
  via("P3", "XYZd65", "Rec2020");
  via("P3", "XYZd65", "XYZd50");
  via("P3", "XYZd65", "HSL");
  via("P3", "XYZd65", "HWB");

  via("SRGBLinear", "XYZd65", "OKLAB");
  via("SRGBLinear", "XYZd65", "OKLCH");
  via("SRGBLinear", "XYZd65", "A98");
  via("SRGBLinear", "XYZd65", "ProPhoto");
  via("SRGBLinear", "XYZd65", "Rec2020");
  via("SRGBLinear", "XYZd65", "XYZd50");
  via("SRGBLinear", "XYZd65", "HSL");
  via("SRGBLinear", "XYZd65", "HWB");

  via("A98", "XYZd65", "OKLAB");
  via("A98", "XYZd65", "OKLCH");
  via("A98", "XYZd65", "ProPhoto");
  via("A98", "XYZd65", "Rec2020");
  via("A98", "XYZd65", "XYZd50");
  via("A98", "XYZd65", "HSL");
  via("A98", "XYZd65", "HWB");

  via("ProPhoto", "XYZd65", "OKLAB");
  via("ProPhoto", "XYZd65", "OKLCH");
  via("ProPhoto", "XYZd65", "Rec2020");
  via("ProPhoto", "XYZd65", "HSL");
  via("ProPhoto", "XYZd65", "HWB");

  via("XYZd50", "XYZd65", "OKLAB");
  via("XYZd50", "XYZd65", "OKLCH");
  via("XYZd50", "XYZd65", "Rec2020");
  via("XYZd50", "XYZd65", "HSL");
  via("XYZd50", "XYZd65", "HWB");

  via("Rec2020", "XYZd65", "OKLAB");
  via("Rec2020", "XYZd65", "OKLCH");
  via("Rec2020", "XYZd65", "HSL");
  via("Rec2020", "XYZd65", "HWB");

  via("HSL", "XYZd65", "OKLAB");
  via("HSL", "XYZd65", "OKLCH");
  via("HSL", "SRGB", "XYZd65");
  via("HSL", "SRGB", "HWB");

  via("HWB", "SRGB", "XYZd65");
  via("HWB", "XYZd65", "OKLAB");
  via("HWB", "XYZd65", "OKLCH");

  // RGBA is an 8-bit version. Convert to SRGB, which is a
  // more accurate floating point representation for all operations.
  via("RGBA", "SRGB", "LAB");
  via("RGBA", "SRGB", "LCH");
  via("RGBA", "SRGB", "OKLAB");
  via("RGBA", "SRGB", "OKLCH");
  via("RGBA", "SRGB", "P3");
  via("RGBA", "SRGB", "SRGBLinear");
  via("RGBA", "SRGB", "A98");
  via("RGBA", "SRGB", "ProPhoto");
  via("RGBA", "SRGB", "XYZd50");
  via("RGBA", "SRGB", "XYZd65");
  via("RGBA", "SRGB", "Rec2020");
  via("RGBA", "SRGB", "HSL");
  via("RGBA", "SRGB", "HWB");
}

function via<T extends ColorSpaces, U extends Exclude<ColorSpaces, T>, V extends Exclude<ColorSpaces, U>>(
  from: T,
  middle: U,
  to: V,
) {
  // Generate T, U, V function (where T, U, V are ColorSpaces)
  let fromFunctions = code.get(from) || [];
  fromFunctions.push(`pub fn into${to}(this: *const ${from}) ${to} {
  const xyz: ${middle} = this.into${middle}();
  return xyz.into${to}();
}
`);
  code.set(from, fromFunctions);

  // Generate V, U, function
  let toFunctions = code.get(to) || [];
  toFunctions.push(`pub fn into${from}(this: *const ${to}) ${from} {
  const xyz: ${middle} = this.into${middle}();
  return xyz.into${from}();
}
`);
  code.set(to, toFunctions);
}
