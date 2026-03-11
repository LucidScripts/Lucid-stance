interface Props {
  label: string;
  value: number;
  min: number;
  max: number;
  step: number;
  onChange: (value: number) => void;
}

export default function StanceSlider({ label, value, min, max, step, onChange }: Props) {
  return (
    <div className="stance-slider">
      <div className="slider-label">
        <span>{label}</span>
        <span className="slider-value">{value.toFixed(3)}</span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => onChange(parseFloat(e.target.value))}
      />
    </div>
  );
}
