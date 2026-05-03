CREATE DATABASE IF NOT EXISTS localisation
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE localisation;

CREATE TABLE position (
    id INT AUTO_INCREMENT PRIMARY KEY,
    latitude DOUBLE NOT NULL,
    longitude DOUBLE NOT NULL,
    date_position DATETIME NOT NULL,
    imei VARCHAR(50) NOT NULL
);
