const COUNTRY_CODES: Record<string, string> = {
  '963': '963',
  '90': '90',
  '964': '964',
};

const LOCAL_PREFIX_MAP: Record<string, string> = {
  '9': '963',
  '5': '90',
  '7': '964',
};

export function normalizePhone(phone: string): string {
  let cleaned = phone.replace(/[^0-9]/g, '');

  if (cleaned.startsWith('00')) {
    cleaned = cleaned.substring(2);
  }

  for (const code of Object.keys(COUNTRY_CODES)) {
    if (cleaned.startsWith(code)) {
      return cleaned;
    }
  }

  if (cleaned.startsWith('0')) {
    const secondDigit = cleaned[1];
    const mapped = LOCAL_PREFIX_MAP[secondDigit];
    if (mapped) {
      return mapped + cleaned.substring(1);
    }
    return cleaned.substring(1);
  }

  return cleaned;
}
