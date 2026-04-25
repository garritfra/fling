module.exports = {
  root: true,
  env: { es2022: true, node: true },
  parser: "@typescript-eslint/parser",
  parserOptions: { ecmaVersion: 2022, sourceType: "module", project: ["tsconfig.json"] },
  plugins: ["@typescript-eslint", "import", "boundaries"],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:boundaries/recommended",
    "google",
  ],
  ignorePatterns: ["lib/**", "node_modules/**", "scripts/**", "migrations/**", "test/**", "vitest.config.ts"],
  settings: {
    "import/resolver": {
      node: { extensions: [".js", ".ts"] },
    },
    "boundaries/elements": [
      { type: "core",     pattern: "src/core/*",                   capture: ["domain"] },
      // File-specific patterns must (a) precede the generic `feature` folder
      // pattern and (b) use `mode: "file"`. Default mode is `folder` which
      // silently appends `/**/*` to the pattern, so a file like
      // src/features/lists/routes.ts never matches the "routes" pattern
      // under default mode and the routes/service/repo direction rules
      // never fire.
      { type: "routes",   pattern: "src/features/*/routes.ts",   mode: "file", capture: ["feature"] },
      { type: "service",  pattern: "src/features/*/service.ts",  mode: "file", capture: ["feature"] },
      { type: "repo",     pattern: "src/features/*/repo.ts",     mode: "file", capture: ["feature"] },
      { type: "schemas",  pattern: "src/features/*/schemas.ts",  mode: "file", capture: ["feature"] },
      { type: "events",   pattern: "src/features/*/events.ts",   mode: "file", capture: ["feature"] },
      { type: "triggers", pattern: "src/features/*/triggers.ts", mode: "file", capture: ["feature"] },
      { type: "module",   pattern: "src/features/*/module.ts",   mode: "file", capture: ["feature"] },
      // Generic feature folder fallback (any other file under a feature dir).
      { type: "feature",  pattern: "src/features/*",             capture: ["feature"] },
      { type: "api",      pattern: "src/api/*" },
    ],
  },
  rules: {
    "quotes": ["error", "double", { "avoidEscape": true }],
    "max-len": ["warn", { "code": 100 }],
    "@typescript-eslint/no-explicit-any": "off",
    "require-jsdoc": "off",
    "valid-jsdoc": "off",
    "boundaries/element-types": ["error", {
      "default": "allow",
      "rules": [
        { "from": "core",
          "disallow": ["feature", "routes", "service", "repo", "schemas", "events", "triggers", "module"] },
        { "from": "routes",  "disallow": ["repo"] },
        { "from": "schemas", "disallow": ["routes", "service", "repo"] },
        { "from": [["feature", { "feature": "${feature}" }]],
          "disallow": [["feature",  { "feature": "!${feature}" }],
                       ["routes",   { "feature": "!${feature}" }],
                       ["service",  { "feature": "!${feature}" }],
                       ["repo",     { "feature": "!${feature}" }],
                       ["schemas",  { "feature": "!${feature}" }],
                       ["events",   { "feature": "!${feature}" }],
                       ["triggers", { "feature": "!${feature}" }],
                       ["module",   { "feature": "!${feature}" }]] },
        { "from": [["routes",  { "feature": "${feature}" }]],
          "disallow": [["routes",  { "feature": "!${feature}" }],
                       ["service", { "feature": "!${feature}" }],
                       ["repo",    { "feature": "!${feature}" }]] },
        { "from": [["service", { "feature": "${feature}" }]],
          "disallow": [["service", { "feature": "!${feature}" }],
                       ["repo",    { "feature": "!${feature}" }]] }
      ]
    }],
    "boundaries/no-unknown": ["error"],
    "boundaries/no-unknown-files": "off",
    "boundaries/no-private": "off",
    "boundaries/entry-point": "off"
  }
};
