Config = {}

Config.Command = 'stance'
Config.OwnerOnly = true -- Only let the owner adjust it.

Config.Defaults = {
    camber_front = 0.0,
    camber_rear  = 0.0,
    ride_height = 0.0,
    track_width_front = 0.0,
    track_width_rear  = 0.0,
}

Config.Limits = {
    camber_front      = { min = -0.35, max = 0.35, step = 0.001 },
    camber_rear       = { min = -0.35, max = 0.35, step = 0.001 },
    ride_height       = { min = -0.18, max = 0.18, step = 0.002 },
    track_width_front = { min = -0.3,  max = 0.3,  step = 0.005 },
    track_width_rear  = { min = -0.3,  max = 0.3,  step = 0.005 },
}
