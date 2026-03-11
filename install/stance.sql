CREATE TABLE IF NOT EXISTS `lucid_stance` (
    `plate` VARCHAR(8) NOT NULL,
    `camber_front` FLOAT NOT NULL DEFAULT 0.0,
    `camber_rear` FLOAT NOT NULL DEFAULT 0.0,
    `height_front` FLOAT NOT NULL DEFAULT 0.0,
    `height_rear` FLOAT NOT NULL DEFAULT 0.0,
    `track_width_front` FLOAT NOT NULL DEFAULT 0.0,
    `track_width_rear` FLOAT NOT NULL DEFAULT 0.0,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
