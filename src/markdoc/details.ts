import type { Render } from "@astrojs/markdoc/config";
import { component } from "@astrojs/markdoc/config";
import type { Config, Node, Schema } from "@markdoc/markdoc";
import Markdoc from "@markdoc/markdoc";

export const details: Schema<Config, Render> = {
  render: component("./src/components/Details.astro"),
  transform(node: Node, config: Config) {
    const children = node.transformChildren(config);

    const summary = children.find(
      (child): child is Markdoc.Tag =>
        child instanceof Markdoc.Tag && child.name === "summary"
    );

    const summaryTag = summary
      ? new Markdoc.Tag("summary", summary.attributes, [
          new Markdoc.Tag(
            "span",
            { class: "summary-content" },
            summary.children.flatMap((child: Markdoc.RenderableTreeNode) =>
              child instanceof Markdoc.Tag && child.name === "p"
                ? child.children
                : [child]
            )
          ),
        ])
      : null;

    const rest = children.filter(
      (child) => !(child instanceof Markdoc.Tag && child.name === "summary")
    );

    return new Markdoc.Tag(
      this.render as string,
      node.attributes,
      summaryTag ? [summaryTag, ...rest] : rest
    );
  },
};

export const summary: Schema<Config, Render> = {
  render: "summary",
};
