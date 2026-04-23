const MILLIS_AND_UTC = /\.\d{3}Z$/;

export function toDateTimeAttribute(date: Date): string {
  const offset = -date.getTimezoneOffset();
  const pad = (n: number) => String(n).padStart(2, "0");
  const sign = offset >= 0 ? "+" : "-";
  const hours = pad(Math.floor(Math.abs(offset) / 60));
  const minutes = pad(Math.abs(offset) % 60);
  return date
    .toISOString()
    .replace(MILLIS_AND_UTC, `${sign}${hours}:${minutes}`);
}

export function formatDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}
