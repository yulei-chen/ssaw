import { fromZonedTime, toZonedTime } from 'date-fns-tz'

/** Browser's IANA timezone (e.g. America/Los_Angeles) */
export function getBrowserTimezone(): string {
  return Intl.DateTimeFormat().resolvedOptions().timeZone
}

/** Convert UTC ISO string to local HH:mm in given timezone */
export function getTimeInTimezone(
  isoUtc: string,
  tz: string,
): { hours: number; minutes: number } {
  const date = toZonedTime(new Date(isoUtc), tz)
  return { hours: date.getHours(), minutes: date.getMinutes() }
}

/** Get UTC ISO start and end for a calendar day in given timezone */
export function getDayUtcRange(
  date: string,
  tz: string,
): { start: string; end: string } {
  const [y, mo, d] = date.split('-').map(Number)
  const month = (mo ?? 1) - 1
  const startLocal = fromZonedTime(new Date(y!, month, d ?? 1, 0, 0, 0), tz)
  const endLocal = fromZonedTime(new Date(y!, month, d ?? 1, 23, 59, 59, 999), tz)
  return {
    start: startLocal.toISOString(),
    end: endLocal.toISOString(),
  }
}

/** Convert date + HH:mm in given timezone to ISO UTC string */
export function toUtc(date: string, timeHHmm: string, tz: string): string {
  const [y, mo, day] = date.split('-').map(Number)
  const [h, m] = timeHHmm.split(':').map(Number)
  const month = (mo ?? 1) - 1
  const localDate = new Date(y ?? 0, month, day ?? 1, h ?? 0, m ?? 0, 0, 0)
  const utcDate = fromZonedTime(localDate, tz)
  return utcDate.toISOString()
}

/** Format HH:mm from hours/minutes */
export function formatHHmm(hours: number, minutes: number): string {
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`
}
