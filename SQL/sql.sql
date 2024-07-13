CREATE TABLE IF NOT EXISTS player_packages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    steam_id VARCHAR(50) DEFAULT NULL,
    discord_id VARCHAR(50) DEFAULT NULL,
    package_id VARCHAR(50) NOT NULL,
    priority INT NOT NULL,
    purchase_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(steam_id, package_id),
    UNIQUE(discord_id, package_id)
);
