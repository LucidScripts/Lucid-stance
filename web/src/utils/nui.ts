export function fetchNUI<T = unknown>(eventName: string, data?: unknown): Promise<T> {
  const w = window as unknown as Record<string, unknown>;
  const resourceName = typeof w.GetParentResourceName === 'function'
    ? (w.GetParentResourceName as () => string)()
    : 'lucid-stance';

  return fetch(`https://${resourceName}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data ?? {}),
  }).then((resp) => resp.json());
}
