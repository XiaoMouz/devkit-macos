const normalize = (value) =>
  String(value ?? "")
    .normalize("NFKC")
    .toLowerCase()
    .trim();

export function searchTools(tools, query) {
  const needle = normalize(query);
  const terms = needle.split(/\s+/).filter(Boolean);
  if (!terms.length) return tools;
  return tools
    .map((tool, order) => {
      const id = normalize(tool.id);
      const names = [tool.name, tool.nameEn].map(normalize);
      const haystack = [
        id,
        ...names,
        normalize(tool.summary),
        normalize(tool.summaryEn),
      ].join(" ");
      if (!terms.every((term) => haystack.includes(term))) return null;
      const exact = id === needle || names.includes(needle);
      const score =
        (exact ? 1000 : 0) +
        terms.reduce(
          (total, term) =>
            total +
            (id.startsWith(term) || names.some((name) => name.startsWith(term))
              ? 30
              : id.includes(term) || names.some((name) => name.includes(term))
                ? 15
                : 1),
          0,
        );
      return { tool, score, order };
    })
    .filter(Boolean)
    .sort((a, b) => b.score - a.score || a.order - b.order)
    .map((result) => result.tool);
}
