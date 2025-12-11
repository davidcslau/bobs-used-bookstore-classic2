-- =============================================
-- Bob's Used Bookstore - PostgreSQL Seed Data
-- Reference Data and Sample Books
-- =============================================

-- =============================================
-- Seed Reference Data
-- =============================================

-- Book Types
INSERT INTO "ReferenceData" ("Id", "Type", "Value", "Active", "CreatedDate") VALUES
    (1, 'BookType', 'Hardcover', TRUE, CURRENT_TIMESTAMP),
    (2, 'BookType', 'Trade Paperback', TRUE, CURRENT_TIMESTAMP),
    (3, 'BookType', 'Mass Market Paperback', TRUE, CURRENT_TIMESTAMP)
ON CONFLICT ("Id") DO NOTHING;

-- Conditions
INSERT INTO "ReferenceData" ("Id", "Type", "Value", "Active", "CreatedDate") VALUES
    (4, 'Condition', 'New', TRUE, CURRENT_TIMESTAMP),
    (5, 'Condition', 'Like New', TRUE, CURRENT_TIMESTAMP),
    (6, 'Condition', 'Good', TRUE, CURRENT_TIMESTAMP),
    (7, 'Condition', 'Acceptable', TRUE, CURRENT_TIMESTAMP)
ON CONFLICT ("Id") DO NOTHING;

-- Genres
INSERT INTO "ReferenceData" ("Id", "Type", "Value", "Active", "CreatedDate") VALUES
    (8, 'Genre', 'Biographies', TRUE, CURRENT_TIMESTAMP),
    (9, 'Genre', 'Children''s Books', TRUE, CURRENT_TIMESTAMP),
    (10, 'Genre', 'History', TRUE, CURRENT_TIMESTAMP),
    (11, 'Genre', 'Literature & Fiction', TRUE, CURRENT_TIMESTAMP),
    (12, 'Genre', 'Mystery, Thriller & Suspense', TRUE, CURRENT_TIMESTAMP),
    (13, 'Genre', 'Science Fiction & Fantasy', TRUE, CURRENT_TIMESTAMP),
    (14, 'Genre', 'Travel', TRUE, CURRENT_TIMESTAMP)
ON CONFLICT ("Id") DO NOTHING;

-- Publishers
INSERT INTO "ReferenceData" ("Id", "Type", "Value", "Active", "CreatedDate") VALUES
    (15, 'Publisher', 'Arcadia Books', TRUE, CURRENT_TIMESTAMP),
    (16, 'Publisher', 'Astral Publishing', TRUE, CURRENT_TIMESTAMP),
    (17, 'Publisher', 'Moonlight Publishing', TRUE, CURRENT_TIMESTAMP),
    (18, 'Publisher', 'Dreamscape Press', TRUE, CURRENT_TIMESTAMP),
    (19, 'Publisher', 'Enchanted Library', TRUE, CURRENT_TIMESTAMP),
    (20, 'Publisher', 'Fantasia House', TRUE, CURRENT_TIMESTAMP),
    (21, 'Publisher', 'Horizon Books', TRUE, CURRENT_TIMESTAMP),
    (22, 'Publisher', 'Infinity Press', TRUE, CURRENT_TIMESTAMP),
    (23, 'Publisher', 'Paradigm Publishing', TRUE, CURRENT_TIMESTAMP),
    (24, 'Publisher', 'Aurora Publishing', TRUE, CURRENT_TIMESTAMP)
ON CONFLICT ("Id") DO NOTHING;

-- Update sequence to continue from last ID
SELECT setval('"ReferenceData_Id_seq"', (SELECT MAX("Id") FROM "ReferenceData"));

-- =============================================
-- Seed Sample Books
-- =============================================
INSERT INTO "Book" ("Id", "Title", "Author", "ISBN", "PublisherId", "BookTypeId", "GenreId", "ConditionId", "Price", "QuantityOnHand", "CoverImageUrl", "CreatedDate") VALUES
    (1, '2020: The Apocalypse', 'Li Juan', '6556784356', 15, 1, 13, 5, 10.95, 25, '/images/coverimages/apocalypse.png', CURRENT_TIMESTAMP),
    (2, 'Children Of Iron', 'Nikki Wolf', '7665438976', 16, 1, 11, 6, 13.95, 3, '/images/coverimages/childrenofiron.png', CURRENT_TIMESTAMP),
    (3, 'Gold In The Dark', 'Richard Roe', '5442280765', 17, 1, 13, 5, 6.50, 10, '/images/coverimages/goldinthedark.png', CURRENT_TIMESTAMP),
    (4, 'Leagues Of Smoke', 'Pat Candella', '4556789542', 18, 2, 11, 7, 3.00, 1, '/images/coverimages/leaguesofsmoke.png', CURRENT_TIMESTAMP),
    (5, 'Alone With The Stars', 'Carlos Salazar', '4563358087', 19, 2, 12, 5, 15.95, 5, '/images/coverimages/alonewiththestars.png', CURRENT_TIMESTAMP),
    (6, 'The Girl In The Polaroid', 'Terri Whitlock', '2354435678', 20, 1, 12, 6, 8.25, 2, '/images/coverimages/girlinthepolaroid.png', CURRENT_TIMESTAMP),
    (7, '1001 Jokes', 'Mary Major', '6554789632', 21, 2, 11, 5, 13.95, 7, '/images/coverimages/1001jokes.png', CURRENT_TIMESTAMP),
    (8, 'My Search For Meaning', 'Mateo Jackson', '4558786554', 22, 3, 8, 7, 5.00, 15, '/images/coverimages/mysearchformeaning.png', CURRENT_TIMESTAMP)
ON CONFLICT ("Id") DO NOTHING;

-- Update sequence to continue from last ID
SELECT setval('"Book_Id_seq"', (SELECT MAX("Id") FROM "Book"));
