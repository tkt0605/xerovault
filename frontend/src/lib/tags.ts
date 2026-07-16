export function parseTags(input: string): string[] {
  return Array.from(
    new Set(
      input
        .split(',')
        .map((t) => t.trim())
        .filter((t) => t.length > 0)
    )
  )
}
