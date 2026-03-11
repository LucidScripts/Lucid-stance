import { StanceValues, StanceLimits } from '../types';
import StanceSlider from './StanceSlider';

interface Props {
  stance: StanceValues;
  limits: StanceLimits;
  onChange: (stance: StanceValues) => void;
  onSave: () => void;
  onReset: () => void;
  onClose: () => void;
}

const LABELS: Record<keyof StanceValues, string> = {
  camber_front: 'Front Camber',
  camber_rear: 'Rear Camber',
  ride_height: 'Ride Height',
  track_width_front: 'Front Track Width',
  track_width_rear: 'Rear Track Width',
};

const GROUPS = [
  { title: 'Camber', keys: ['camber_front', 'camber_rear'] as (keyof StanceValues)[] },
  { title: 'Ride Height', keys: ['ride_height'] as (keyof StanceValues)[] },
  { title: 'Track Width', keys: ['track_width_front', 'track_width_rear'] as (keyof StanceValues)[] },
];

export default function StancePanel({ stance, limits, onChange, onSave, onReset, onClose }: Props) {
  const handleSliderChange = (key: keyof StanceValues, value: number) => {
    onChange({ ...stance, [key]: value });
  };

  return (
    <div className="stance-panel">
      <div className="stance-header">
        <h2>Vehicle Stance</h2>
        <button className="close-btn" onClick={onClose}>X</button>
      </div>
      <div className="stance-body">
        {GROUPS.map((group) => (
          <div key={group.title} className="stance-group">
            <h3>{group.title}</h3>
            {group.keys.map((key) => (
              <StanceSlider
                key={key}
                label={LABELS[key]}
                value={stance[key]}
                min={limits[key].min}
                max={limits[key].max}
                step={limits[key].step}
                onChange={(val) => handleSliderChange(key, val)}
              />
            ))}
          </div>
        ))}
      </div>
      <div className="stance-footer">
        <button className="btn btn-save" onClick={onSave}>Save</button>
        <button className="btn btn-reset" onClick={onReset}>Reset</button>
      </div>
    </div>
  );
}
