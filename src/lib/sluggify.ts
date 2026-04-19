// Taken from
// https://equk.co.uk/2023/02/02/generating-slug-from-title-in-astro/
export default function (title: string) {
  return (
    title
      // Remove leading & trailing whitespace
      .trim()
      // Remove special characters
      .replace(/[^A-Za-z0-9 ]/g, "")
      // Replace spaces
      .replace(/\s+/g, "-")
      // Remove leading & trailing separtors
      .replace(/^-+|-+$/g, "")
      // Output lowercase
      .toLowerCase()
  );
}
