import { useState, useEffect, useCallback } from 'react';
import { StanceValues, StanceLimits, NUIMessage } from './types';
import { fetchNUI } from './utils/nui';
import StancePanel from './components/StancePanel';

function App() {
  const [visible, setVisible] = useState(false);
  const [stance, setStance] = useState<StanceValues | null>(null);
  const [limits, setLimits] = useState<StanceLimits | null>(null);

  useEffect(() => {
    const handler = (event: MessageEvent<NUIMessage>) => {
      const { action } = event.data;
      if (action === 'open') {
        setStance(event.data.stance);
        setLimits(event.data.limits);
        setVisible(true);
      } else if (action === 'updateStance') {
        setStance(event.data.stance);
      } else if (action === 'close') {
        setVisible(false);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const handleChange = useCallback((newStance: StanceValues) => {
    setStance(newStance);
    fetchNUI('lucid-stance:preview', { stance: newStance });
  }, []);

  const handleSave = useCallback(() => {
    if (!stance) return;
    fetchNUI('lucid-stance:save', { stance });
  }, [stance]);

  const handleReset = useCallback(() => {
    fetchNUI('lucid-stance:reset');
  }, []);

  const handleClose = useCallback(() => {
    setVisible(false);
    fetchNUI('lucid-stance:close');
  }, []);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && visible) {
        handleClose();
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [visible, handleClose]);

  if (!visible || !stance || !limits) return null;

  return (
    <StancePanel
      stance={stance}
      limits={limits}
      onChange={handleChange}
      onSave={handleSave}
      onReset={handleReset}
      onClose={handleClose}
    />
  );
}

export default App;
