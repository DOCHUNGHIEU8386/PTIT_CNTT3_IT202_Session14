
-- THỰC HÀNH SESSION 14 - MYSQL TRANSACTION & STORED PROCEDURE
-- Sinh viên: Hiếu Quang Ngọc
-- ===============================================

DROP DATABASE IF EXISTS social_network_ngoc;
CREATE DATABASE social_network_ngoc;
USE social_network_ngoc;

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    total_posts INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

INSERT INTO users (username) VALUES 
('ngoc_hieu'),
('minh_anh'),
('duc_long');

-- ================================
-- BÀI 1 + 2: STORED PROCEDURE + TRANSACTION + ROLLBACK
-- ================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_create_post_ngoc$$

CREATE PROCEDURE sp_create_post_ngoc(
    IN p_user_id INT,
    IN p_content TEXT
)
BEGIN
    DECLARE v_err_msg TEXT;
    DECLARE v_sqlstate VARCHAR(10);
    DECLARE v_total INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_sqlstate = RETURNED_SQLSTATE,
            v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SELECT 'LỖI' AS status, v_err_msg AS message;
    END;

    IF p_content IS NULL OR TRIM(p_content) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Nội dung bài viết không hợp lệ';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM users WHERE user_id = p_user_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User không tồn tại';
    END IF;

    START TRANSACTION;

    INSERT INTO posts(user_id, content)
    VALUES (p_user_id, p_content);

    UPDATE users
    SET total_posts = total_posts + 1
    WHERE user_id = p_user_id;

    COMMIT;

    SELECT total_posts INTO v_total FROM users WHERE user_id = p_user_id;

    SELECT 'THÀNH CÔNG' AS status,
           p_user_id AS user_id,
           LAST_INSERT_ID() AS post_id,
           v_total AS total_posts;
END$$

DELIMITER ;

-- ================================
-- BÀI 3: KIỂM THỬ PROCEDURE
-- ================================

TRUNCATE TABLE posts;
UPDATE users SET total_posts = 0;

CALL sp_create_post_ngoc(1, 'Bài viết đầu tiên của Ngọc');
CALL sp_create_post_ngoc(1, 'Học Transaction MySQL');
CALL sp_create_post_ngoc(2, 'Stored Procedure căn bản');
CALL sp_create_post_ngoc(3, 'Xử lý lỗi với Rollback');

-- ================================
-- BÀI 4: KIỂM TRA TÍNH NHẤT QUÁN
-- ================================

SELECT 
    u.user_id,
    u.username,
    u.total_posts AS stored_count,
    COUNT(p.post_id) AS actual_count,
    CASE 
        WHEN u.total_posts = COUNT(p.post_id) THEN 'OK'
        ELSE 'ERROR'
    END AS integrity_status
FROM users u
LEFT JOIN posts p ON u.user_id = p.user_id
GROUP BY u.user_id, u.username, u.total_posts;

-- ================================
-- BÀI 5: STRESS TEST
-- ================================

CALL sp_create_post_ngoc(1, 'Stress test 1');
CALL sp_create_post_ngoc(1, 'Stress test 2');
CALL sp_create_post_ngoc(1, 'Stress test 3');
CALL sp_create_post_ngoc(1, 'Stress test 4');
CALL sp_create_post_ngoc(1, 'Stress test 5');

-- ================================
-- BÀI 6: STORED PROCEDURE KIỂM TRA TOÀN VẸN
-- ================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_check_integrity_ngoc$$

CREATE PROCEDURE sp_check_integrity_ngoc()
BEGIN
    SELECT 
        u.user_id,
        u.username,
        u.total_posts AS stored_count,
        COUNT(p.post_id) AS actual_count,
        CASE 
            WHEN u.total_posts = COUNT(p.post_id) THEN 'NHẤT QUÁN'
            ELSE 'KHÔNG NHẤT QUÁN'
        END AS status
    FROM users u
    LEFT JOIN posts p ON u.user_id = p.user_id
    GROUP BY u.user_id, u.username, u.total_posts;
END$$

DELIMITER ;

CALL sp_check_integrity_ngoc();
