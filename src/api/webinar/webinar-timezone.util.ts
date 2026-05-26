export function formatSlotForEmail(utcDatetime: Date, timezone: string): string {
  const d = new Date(utcDatetime);
  const tz = timezone || 'UTC';

  const datePart = new Intl.DateTimeFormat('en-GB', {
    timeZone: tz,
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(d);

  const timePart = new Intl.DateTimeFormat('en-GB', {
    timeZone: tz,
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(d);

  const tzAbbr = new Intl.DateTimeFormat('en-GB', {
    timeZone: tz,
    timeZoneName: 'short',
  }).formatToParts(d).find((p) => p.type === 'timeZoneName')?.value ?? tz;

  return `${datePart}, ${timePart} ${tzAbbr}`;
}
