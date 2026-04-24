module.exports = {
  root: true,
  env: { es2022: true, node: true },
  parser: "@typescript-eslint/parser",
  parserOptions: { ecmaVersion: 2022, sourceType: "module", project: ["tsconfig.json"] },
  plugins: ["@typescript-eslint", "import"],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "google",
  ],
  ignorePatterns: ["lib/**", "node_modules/**", "scripts/**", "migrations/**", "test/**", "vitest.config.ts"],
  rules: {
    "quotes": ["error", "double", { "avoidEscape": true }],
    "max-len": ["warn", { "code": 100 }],
    "@typescript-eslint/no-explicit-any": "off",
    "require-jsdoc": "off",
    "valid-jsdoc": "off"
  }
};
