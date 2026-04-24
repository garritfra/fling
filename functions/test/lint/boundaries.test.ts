import { describe, it, expect } from "vitest";
import { ESLint } from "eslint";

// We deliberately drop `parserOptions.project` here so that synthetic fixture
// filePaths (which do not exist on disk) don't trip typescript-eslint's
// "file is not in the project" check. The boundaries plugin relies on the
// filePath string, not on type information.
const eslint = new ESLint({
  overrideConfigFile: ".eslintrc.cjs",
  cwd: process.cwd(),
  overrideConfig: {
    parserOptions: { project: null },
  },
});

const fixtures: Array<{ name: string; filePath: string; code: string; mustError: RegExp }> = [
  {
    name: "core cannot import a feature module",
    filePath: "src/core/auth/bad.ts",
    code: `import { FEATURE_NAME } from "../../features/me/module";\nexport const x = FEATURE_NAME;\n`,
    mustError: /element-types|boundaries/,
  },
  {
    name: "feature cannot import another feature directly",
    filePath: "src/features/lists/bad.ts",
    code: `import { FEATURE_NAME } from "../me/module";\nexport const x = FEATURE_NAME;\n`,
    mustError: /element-types|boundaries/,
  },
];

describe("ESLint boundaries", () => {
  for (const f of fixtures) {
    it(f.name, async () => {
      const results = await eslint.lintText(f.code, { filePath: f.filePath });
      const messages = results.flatMap((r) => r.messages);
      expect(
        messages.some((m) => m.ruleId && /boundaries\//.test(m.ruleId))
      ).toBe(true);
    });
  }
});
