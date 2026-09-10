-- Insert 5 new users
INSERT INTO users (name, username, email, password, role, bio, location, github, website, joined_at) VALUES
('Alice Smith', 'alice_smith', 'alice@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZBcK3x7v5y6v7v8v9v0v1v2v3v4v5', 'USER', 'Loves algorithms', 'New York', 'alice_dev', 'https://alice.dev', CURRENT_TIMESTAMP),
('Bob Johnson', 'bob_johnson', 'bob@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZBcK3x7v5y6v7v8v9v0v1v2v3v4v5', 'USER', 'Competitive programmer', 'San Francisco', 'bob_coder', 'https://bob.io', CURRENT_TIMESTAMP),
('Charlie Lee', 'charlie_lee', 'charlie@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZBcK3x7v5y6v7v8v9v0v1v2v3v4v5', 'USER', 'Student', 'Boston', 'charlie99', 'https://charlielee.com', CURRENT_TIMESTAMP),
('Diana Prince', 'diana_prince', 'diana@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZBcK3x7v5y6v7v8v9v0v1v2v3v4v5', 'USER', 'Software Engineer', 'Seattle', 'diana_code', 'https://dianaprince.org', CURRENT_TIMESTAMP),
('Ethan Hunt', 'ethan_hunt', 'ethan@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZBcK3x7v5y6v7v8v9v0v1v2v3v4v5', 'USER', 'Full-stack developer', 'Austin', 'ethanhunt', 'https://ethanhunt.dev', CURRENT_TIMESTAMP);

-- Insert accepted submissions for these users (up to 5 problems each)
INSERT INTO submissions (user_id, problem_id, code, language, status, passed_test_cases, total_test_cases, execution_time_ms, memory_mb, submitted_at) VALUES
-- Alice: 3 problems solved
((SELECT id FROM users WHERE email='alice@example.com'), (SELECT id FROM problems WHERE slug='two-sum'), '// solution', 'java', 'ACCEPTED', 5, 5, 120, 15.2, CURRENT_TIMESTAMP),
((SELECT id FROM users WHERE email='alice@example.com'), (SELECT id FROM problems WHERE slug='binary-search'), '// solution', 'java', 'ACCEPTED', 4, 4, 90, 12.0, CURRENT_TIMESTAMP),
((SELECT id FROM users WHERE email='alice@example.com'), (SELECT id FROM problems WHERE slug='palindrome-number'), '// solution', 'java', 'ACCEPTED', 3, 3, 80, 10.5, CURRENT_TIMESTAMP),
-- Bob: 5 problems solved
((SELECT id FROM users WHERE email='bob@example.com'), (SELECT id FROM problems WHERE slug='maximum-in-an-array'), '// solution', 'java', 'ACCEPTED', 4, 4, 70, 11.3, CURRENT_TIMESTAMP),
((SELECT id FROM users WHERE email='bob@example.com'), (SELECT id FROM problems WHERE slug='count-vowels'), '// solution', 'java', 'ACCEPTED', 6, 6, 60, 9.8, CURRENT_TIMESTAMP),
((SELECT id FROM users WHERE email='bob@example.com'), (SELECT id FROM problems WHERE slug='sum-from-one-to-n'), '// solution', 'java', 'ACCEPTED', 5, 5, 50, 9.0, CURRENT_TIMESTAMP),
((SELECT id FROM users WHERE email='bob@example.com'), (SELECT id FROM problems WHERE slug='valid-parentheses'), '// solution', 'java', 'ACCEPTED', 7, 7, 100, 13.1, CURRENT_TIMESTAMP),
((SELECT id FROM users WHERE email='bob@example.com'), (SELECT id FROM problems WHERE slug='product-except-self'), '// solution', 'java', 'ACCEPTED', 8, 8, 150, 20.0, CURRENT_TIMESTAMP),
-- Charlie: 2 problems solved
((SELECT id FROM users WHERE email='charlie@example.com'), (SELECT id FROM problems WHERE slug='first-unique-character'), '// solution', 'java', 'ACCEPTED', 5, 5, 110, 14.0, CURRENT_TIMESTAMP),
((SELECT id FROM users WHERE email='charlie@example.com'), (SELECT id FROM problems WHERE slug='longest-common-prefix'), '// solution', 'java', 'ACCEPTED', 4, 4, 95, 11.5, CURRENT_TIMESTAMP),
-- Diana: 4 problems solved
((SELECT id FROM users WHERE email='diana@example.com'), (SELECT id FROM problems WHERE slug='maximum-subarray'), '// solution', 'java', 'ACCEPTED', 10, 10, 200, 25.0, CURRENT_TIMESTAMP),
((SELECT id FROM users WHERE email='diana@example.com'), (SELECT id FROM problems WHERE slug='trapping-rain-water'), '// solution', 'java', 'ACCEPTED', 8, 8, 180, 22.0, CURRENT_TIMESTAMP),
((SELECT id FROM users WHERE email='diana@example.com'), (SELECT id FROM problems WHERE slug='longest-increasing-subsequence'), '// solution', 'java', 'ACCEPTED', 6, 6, 160, 19.0, CURRENT_TIMESTAMP),
((SELECT id FROM users WHERE email='diana@example.com'), (SELECT id FROM problems WHERE slug='coin-change'), '// solution', 'java', 'ACCEPTED', 5, 5, 140, 17.0, CURRENT_TIMESTAMP),
-- Ethan: 1 problem solved
((SELECT id FROM users WHERE email='ethan@example.com'), (SELECT id FROM problems WHERE slug='longest-consecutive-sequence'), '// solution', 'java', 'ACCEPTED', 7, 7, 130, 16.0, CURRENT_TIMESTAMP);
