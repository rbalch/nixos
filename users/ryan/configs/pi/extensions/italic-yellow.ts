import {
  Theme,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";

const patchKey = Symbol.for("ryan.pi.italic-yellow");
const foregroundColor = /\x1b\[(?:3[0-9]|9[0-7]|38;(?:5;\d{1,3}|2;\d{1,3};\d{1,3};\d{1,3}))m/g;
const themePrototype = Theme.prototype as typeof Theme.prototype & {
  [patchKey]?: boolean;
};

export default function (_pi: ExtensionAPI): void {
  if (themePrototype[patchKey]) return;

  const italic = themePrototype.italic;
  themePrototype.italic = function (text: string): string {
    // Pi renders the whole thinking block as italic gray text. Keep that
    // color, while making Markdown emphasis in the answer yellow.
    if (text.includes(this.getFgAnsi("thinkingText"))) {
      return italic.call(this, text);
    }

    const textWithoutColor = text.replace(foregroundColor, "");
    return this.fg("warning", italic.call(this, textWithoutColor));
  };
  themePrototype[patchKey] = true;
}
