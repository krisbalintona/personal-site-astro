/** @type {import('stylelint').Config} */
export default {
  extends: [
    "stylelint-config-standard",
    "stylelint-config-standard-scss",
    "stylelint-config-astro",
  ],
  rules: {
    "custom-property-pattern": null,
    "selector-pseudo-class-no-unknown": [
      true,
      {
        ignorePseudoClasses: ["global"],
      },
    ],
  },
};
