import { component, defineMarkdocConfig, nodes } from "@astrojs/markdoc/config";
import { details, summary } from "./src/markdoc/details.ts";

export default defineMarkdocConfig({
  nodes: {
    document: {
      ...nodes.document,
      render: null,
    },
  },
  tags: {
    timestamp: {
      render: component("./src/components/Timestamp.astro"),
      attributes: {
        date: {
          type: String,
          required: true,
        },
        time: {
          type: String,
          required: false,
        },
      },
    },
    "content-link": {
      render: component("./src/components/ContentLink.astro"),
      attributes: {
        collectionName: { type: String, required: true },
        id: { type: String, required: true },
        anchor: { type: String, required: false },
      },
    },
    alert: {
      render: component("./src/components/Alert.astro"),
    },
    details,
    summary,
    // fragment: {
    //   render: "Fragment",
    //   attributes: {
    //     slot: { type: String, required: false },
    //   },
    // },
    fragment: {
      render: component("./src/components/MarkdocFragment.astro"),
      attributes: {
        slot: { type: String, required: false },
      },
    },
    image: {
      render: component("./src/components/MarkdocImage.astro"),
      attributes: {
        width: {
          type: String,
          required: false,
        },
        height: {
          type: String,
          required: false,
        },
        ...nodes.image.attributes,
      },
    },
  },
});
