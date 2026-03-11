export interface StanceValues {
  camber_front: number;
  camber_rear: number;
  ride_height: number;
  track_width_front: number;
  track_width_rear: number;
}

export interface SliderLimit {
  min: number;
  max: number;
  step: number;
}

export type StanceLimits = Record<keyof StanceValues, SliderLimit>;

export interface NUIOpenMessage {
  action: 'open';
  stance: StanceValues;
  limits: StanceLimits;
}

export interface NUIUpdateMessage {
  action: 'updateStance';
  stance: StanceValues;
}

export interface NUICloseMessage {
  action: 'close';
}

export type NUIMessage = NUIOpenMessage | NUIUpdateMessage | NUICloseMessage;
